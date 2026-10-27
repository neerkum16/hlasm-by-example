***********************************************************************
* VB01LOC - Variable Length Files, Locate Mode I/O, And EX            *
* Purpose: Reads a RECFM=VB (variable block) file using GET in        *
*          LOCATE MODE, maps the returned buffer with a DSECT, uses   *
*          EX to MVC a field whose LENGTH IS NOT KNOWN UNTIL RUN      *
*          TIME, then builds a brand new variable length record and   *
*          writes it out using PUT in LOCATE MODE.                    *
***********************************************************************
*
*======================================================================
* WHAT "VARIABLE LENGTH" ACTUALLY MEANS ON DISK
*======================================================================
* Every fixed length file this project has used so far (qsamproc.asm,
* ds02dsct.asm, ...) has RECFM=FB - every record is EXACTLY the same
* number of bytes, so the only number the program ever needs is the
* one constant LRECL.
*
* RECFM=VB records are NOT all the same length.  To make that possible,
* z/OS prefixes EVERY LOGICAL RECORD with a 4 byte RDW - Record
* Descriptor Word:
*
*     byte 0-1   total length of THIS record, INCLUDING these 4 bytes
*     byte 2-3   reserved, always binary zero
*
*     +--------+--------+----------------------------------------+
*     |  LL (2)| 00 (2) |           the record's own data         |
*     +--------+--------+----------------------------------------+
*      <-- RDW --------> <---------- LL minus 4 bytes ----------->
*
* (Blocked VB files ALSO have a 4 byte BDW - Block Descriptor Word -
* in front of every physical block, but QSAM strips that off for you
* automatically.  The program never sees a BDW, only RDWs.)
*
* Because every record can be a different length, LRECL on a VB DCB
* does not mean "the record length" - it means the LONGEST record the
* file will ever contain, RDW included.  The program must look INSIDE
* each record's own RDW to find out how long THAT record actually is.
*
*======================================================================
* LOCATE MODE - GET AND PUT WITHOUT A MOVE
*======================================================================
* Every GET and PUT so far has been in MOVE mode (MACRF=GM / MACRF=PM):
*
*     GET INFILE,INAREA     copies the record INTO your own area
*     PUT OUTFILE,OUTAREA   copies your own area OUT to the file
*
* That copy is wasted work for a variable length record - the access
* method already has the bytes sitting in its own buffer, RDW and all,
* ready to use.  LOCATE MODE (MACRF=GL / MACRF=PL) skips the copy:
*
*     GET INFILE            no area operand at all
*
*   does not move anything - it hands back, IN REGISTER 1, the ADDRESS
*   of the next record (RDW included), sitting wherever QSAM's own
*   buffer put it.  The program reads directly out of that address.
*
*     PUT OUTFILE           no area operand at all
*
*   does not move anything either - it hands back, IN REGISTER 1, the
*   ADDRESS of an EMPTY buffer segment, big enough for one record.  The
*   program must BUILD the whole record there itself - RDW included -
*   before doing anything else.  The record is actually written out
*   the next time PUT or CLOSE is issued; there is no separate "commit"
*   instruction.
*
* Because both GET and PUT return their address in register 1, and
* this program needs to remember the INPUT record's address while it
* goes on to ask for an OUTPUT buffer (a second register 1), the very
* first thing done with each returned address is LR to save it
* somewhere else - R3 for the input record, R4 for the output buffer.
*
*======================================================================
* A DSECT OVER A LOCATE MODE BUFFER
*======================================================================
* The address GET hands back in R1 is just a number - the DSECT
* technique from ds01dsct.asm/ds02dsct.asm applies exactly as before:
* point a register at it, USING the DSECT on that register, and every
* field name in the DSECT becomes "register + displacement".  The only
* difference from ds02dsct.asm is WHERE the real storage came from -
* there it was INAREA, a buffer this program owned; here it is a
* buffer QSAM owns and merely lets the program look at.
*
* This record's FIXED fields (the RDW, the customer number, the packed
* amount) sit at fixed displacements and are read exactly like any
* other DSECT field.  The record's one VARIABLE field - a trailing
* name, which can be a different length on every single record - CANNOT
* have a fixed displacement for its END, because that end moves.  A
* DSECT can mark where the variable field STARTS (VNAME below, DS 0CL1,
* a zero length placeholder), but how many bytes actually belong to it
* has to be worked out at run time from the RDW, and moved with an
* instruction whose length is ALSO decided at run time - which is
* exactly the job EX was built for.
*
*======================================================================
* EX - DECIDING AN INSTRUCTION'S LENGTH AT RUN TIME
*======================================================================
* MVC and CLC are SS format instructions: the LENGTH to move or compare
* is baked into the instruction itself at assembly time, as one byte
* (actually "length minus 1", since a zero would be a pointless no-op).
* Every MVC used anywhere else in this project - MVC PRTLINE(50),0(1),
* MVC OUT1REC,KEY1, all of them - has a length the ASSEMBLER already
* knew when it built the program.  That is impossible here: nobody
* knows how long this record's name field is until the record itself
* has actually been read.
*
* EX reg,target solves exactly this.  It takes the SS instruction at
* label "target", REPLACES its length byte with the low order byte of
* "reg", and then executes that ONE modified instruction - the copy of
* the instruction sitting in storage is left untouched; only this one
* execution behaves differently.  The usual way to build "target" is
* to code it with a harmless placeholder length of 1:
*
*     MVCNAME  MVC   PRTNAME(1),VNAME
*
* A coded length of 1 assembles to a length BYTE of binary zero (since
* the byte always stores length-1).  EX ORs the register's low byte
* into that zero byte, so whatever the register holds becomes the
* ACTUAL length-minus-one used - which is precisely the value BCTR was
* introduced for, back in br03loop.asm ("the standard way to build the
* length-1 value that EX needs").  This program is the first time that
* promise gets cashed in:
*
*     L      5,NAMELENM1        R5 = this record's name length, minus 1
*     EX     5,MVCNAME          Move exactly that many bytes, no more
*
* A register holding a NEGATIVE OR ZERO length here (an empty name, or
* worse, a corrupt RDW) is a real danger with EX - length 0 is a
* harmless one byte move, but a huge or negative value computed from
* garbage can run the MVC far past the end of the buffer.  Production
* code validates the length before trusting it to EX; this lesson
* keeps that validation out only to keep the EX mechanics themselves
* in clear view.
***********************************************************************
         PRINT NOGEN
VB01LOC  CSECT
***********************************************************************
* A000-MAINLINE - standard entry linkage                              *
***********************************************************************
         STM   14,12,12(13)            * Save caller's registers
         LR    12,15                   * Load base register
         USING VB01LOC,12              * Establish addressability
         ST    13,SAVEAREA+4           * Chain savearea (backward)
         LA    13,SAVEAREA             * Load address of savearea

         MVI   EOFSW,C'N'              * End of file not yet reached
         ZAP   RECCNT,=P'0'            * Records read = 0

         OPEN  (SYSPRINT,(OUTPUT))
         LA    2,SYSPRINT
         BAL   10,OPENCHK
         BNO   ABENDRTN

         OPEN  (INFILE,(INPUT))
         LA    2,INFILE
         BAL   10,OPENCHK
         BNO   OPNERR1

         OPEN  (OUTFILE,(OUTPUT))
         LA    2,OUTFILE
         BAL   10,OPENCHK
         BNO   OPNERR2

         LA    1,MSGSTRT
         BAL   10,PRTMSG

         BAL   10,READREC              * Priming read - see READREC

***********************************************************************
* B000-MAINLOOP - one trip per variable length input record           *
***********************************************************************
MAINLOOP CLI   EOFSW,C'Y'
         BE    ALLDONE

         BAL   10,SHOWREC              * Print this record's fields
         BAL   10,BUILDOUT             * Write a matching VB
*                                      * record to OUTFILE
         BAL   10,READREC              * Read the next record
         B     MAINLOOP

***********************************************************************
* ALLDONE - print the record count, close everything, and return      *
***********************************************************************
ALLDONE  DS    0H
         MVC   PRTLINE,BLANKS
         MVC   PRTLINE(16),=C'RECORDS READ  : '
         UNPK  ZONE7,RECCNT
         OI    ZONE7+6,X'F0'
         MVC   PRTLINE+16(7),ZONE7
         PUT   SYSPRINT,PRTLINE

         LA    1,MSGEND
         BAL   10,PRTMSG

         CLOSE (INFILE)
         CLOSE (OUTFILE)
         CLOSE (SYSPRINT)

         L     13,SAVEAREA+4
         LM    14,12,12(13)
         SR    15,15
         BR    14

***********************************************************************
*                                                                     *
* OPNERR1 / OPNERR2 - open failure paths, same pattern as ds02dsct.asm*
***********************************************************************
OPNERR1  LA    1,MSGOPN1
         B     OPNERRX
OPNERR2  LA    1,MSGOPN2
OPNERRX  MVC   PRTLINE,BLANKS
         MVC   PRTLINE(50),0(1)
         PUT   SYSPRINT,PRTLINE
         B     ABENDRTN

***********************************************************************
*                                                                     *
* READREC - read one record from INFILE in LOCATE MODE, then work out *
*           how long its variable name field is                       *
*                                                                     *
* GET INFILE, with NO second operand, is how locate mode is requested -
* compare this with GET AMHFIN,INREC in qsamproc.asm, which copied the
* record instead.  The address QSAM hands back in R1 is saved into R3 *
* immediately, because R1 will be reused the moment PUT is called     *
* later on in BUILDOUT.                                               *
***********************************************************************
READREC  DS    0H
         GET   INFILE                  * Locate mode: R1 = record addr
*                                      * RDW included (or go EODAD)
         LR    3,1                     * Save addr - R1 will be reused
         USING VBINRECD,3              * VBINRECD layout overlays it

         LH    5,INRDWLL               * R5 = record's total length,
*                                      * RDW included (a 2 byte binary
*                                      * field)
         S     5,=F'17'                * Subtract FIXED part: 4 bytes
*                                      * of RDW + 8 bytes cust number +
*                                      * 5 bytes packed amt = 17 bytes.
*                                      * What is left is NAME field's
*                                      * actual length, in this record.
         ST    5,NAMELEN               * Save real name length (used to
*                                      * build OUTPUT record's own RDW)
         BCTR  5,0                     * R5 = name length - 1: the form
*                                      * EX always needs
         ST    5,NAMELENM1             * Save for SHOWREC and BUILDOUT

         DROP  3
         AP    RECCNT,=P'1'
         BR    10

EOFRTN   DS    0H                      * EODAD target of INFILE DCB
         MVI   EOFSW,C'Y'
         BR    10

***********************************************************************
*                                                                     *
* SHOWREC - print one record's fields, name field EX'd to its actual  *
*           length                                                    *
***********************************************************************
SHOWREC  DS    0H
         USING VBINRECD,3              * R3 still addresses this record

         MVC   PRTLINE,BLANKS
         MVC   PRTLINE(8),INCUSTNO
         UNPK  ZONE7,INAMOUNT
         OI    ZONE7+6,X'F0'
         MVC   PRTLINE+10(7),ZONE7

         L     5,NAMELENM1             * R5 = record's name length - 1
         EX    5,MVCSHOWN              * MVC PRTLINE+20(1),INNAME, with
*                                      * R5 length used - moves exactly
*                                      * as many bytes as THIS record's
*                                      * name really has, no more

         PUT   SYSPRINT,PRTLINE
         BR    10

MVCSHOWN MVC   PRTLINE+20(1),INNAME    * Placeholder length of 1 - EX
*                                      * above overwrites it at
*                                      * execution time
         DROP  3

***********************************************************************
*                                                                     *
* BUILDOUT - get an empty OUTFILE buffer in locate mode, build a new  *
*            variable length record in it, matching field for field   *
*                                                                     *
* R3 still addresses the INPUT record (VBINRECD) throughout this      *
* routine; R4 addresses the OUTPUT buffer (VBOUTRECD) once PUT hands  *
* its address back.  Two DIFFERENT DSECTs over two DIFFERENT registers*
* are active at the same time here - the same technique BUILDTOT used *
* in ds02dsct.asm for PARTD (R3) and PARMD (R1) together.             *
***********************************************************************
BUILDOUT DS    0H
         USING VBINRECD,3              * Source record (from READREC)

         PUT   OUTFILE                 * Locate mode: R1 = empty buffer
*                                      * segment, big enough for the
*                                      * longest record in this DCB
         LR    4,1                     * Save that address before R1 is
*                                      * reused again
         USING VBOUTRECD,4             * VBOUTRECD layout overlays it

         L     6,NAMELEN               * R6 = record's real name length
         A     6,=F'17'                * R6 = name length + 17 bytes =
*                                      * the TOTAL length the output
*                                      * record needs, RDW included
         STH   6,OUTRDWLL              * Store it as this record's RDW
*                                      * length half word - without
*                                      * this, QSAM would not know how
*                                      * many bytes of buffer actually
*                                      * belong to this record
         XC    OUTRDWFL,OUTRDWFL       * RDW's 2nd half word: binary
*                                      * zero. XC field,field - a field
*                                      * exclusive-ORed with ITSELF is
*                                      * always zero, same idiom as
*                                      * SR reg,reg for registers.

         MVC   OUTCUSTNO,INCUSTNO      * Fixed length field - plain MVC
         ZAP   OUTAMOUNT,INAMOUNT      * PACKED - ZAP, not MVC (see
*                                      * dt02arth.asm - MVC does not
*                                      * understand packed decimal and
*                                      * would risk leaving an invalid
*                                      * sign nibble behind)

         L     5,NAMELENM1             * Same length-1 value READREC
*                                      * already worked out for it
         EX    5,MVCBUILD              * MVC OUTNAME(1),INNAME, really
*                                      * moving exactly NAMELEN bytes

         BR    10

MVCBUILD MVC   OUTNAME(1),INNAME       * Placeholder len 1, EX'd above
         DROP  3
         DROP  4

***********************************************************************
*                                                                     *
* OPENCHK - test whether the DCB pointed to by R2 really opened       *
*           (identical routine to ds02dsct.asm / qsamproc.asm)        *
***********************************************************************
OPENCHK  DS    0H
         USING IHADCB,2
         TM    DCBOFLGS,DCBOFOPN
         DROP  2
         BR    10

***********************************************************************
*                                                                     *
* PRTMSG - print a 50 byte message addressed by R1                    *
***********************************************************************
PRTMSG   DS    0H
         MVC   PRTLINE,BLANKS
         MVC   PRTLINE(50),0(1)
         PUT   SYSPRINT,PRTLINE
         BR    10

***********************************************************************
*                                                                     *
* ABENDRTN - an open failed; there is no safe way to continue         *
***********************************************************************
ABENDRTN DS    0H
         ABEND 999,DUMP

***********************************************************************
* Data areas - all REAL storage                                       *
***********************************************************************
SAVEAREA DS    18F
EOFSW    DS    CL1
RECCNT   DS    PL4

***********************************************************************
* NAMELEN / NAMELENM1 - this record's variable name length, worked out*
* fresh by READREC every time, and reused by both SHOWREC and BUILDOUT*
* so the calculation is only done once per record.  Plain fullwords,  *
* not packed decimal - these feed EX and arithmetic on registers, not *
* AP/ZAP, so binary is the natural choice here.                       *
***********************************************************************
NAMELEN  DS    F
NAMELENM1 DS   F

PRTLINE  DS    CL80
ZONE7    DS    CL7
BLANKS   DC    CL80' '

MSGSTRT  DC    CL50'VB01LOC - PROGRAM STARTED'
MSGEND   DC    CL50'VB01LOC - PROGRAM ENDED NORMALLY'
MSGOPN1  DC    CL50'VB01LOC - INFILE OPEN ERROR'
MSGOPN2  DC    CL50'VB01LOC - OUTFILE OPEN ERROR'

***********************************************************************
* FILE CONTROL BLOCKS                                                 *
*                                                                     *
*   RECFM=VB    variable length, blocked records - every record is    *
*               prefixed with its own 4 byte RDW                      *
*   MACRF=GL    GET, LOCATE mode - no data is moved, an address is    *
*               returned in R1 instead                                *
*   MACRF=PL    PUT, LOCATE mode - no data is moved, an address of an *
*               empty buffer segment is returned in R1 instead        *
*   LRECL=37    the LONGEST possible record: 4 (RDW) + 8 (customer    *
*               number) + 5 (packed amount) + 20 (longest possible    *
*               name) = 37.  Shorter records simply use less of it.   *
***********************************************************************
INFILE   DCB   DSORG=PS,MACRF=GL,DDNAME=INFILE,                        X
               EODAD=EOFRTN,RECFM=VB,LRECL=37,BLKSIZE=0

OUTFILE  DCB   DSORG=PS,MACRF=PL,DDNAME=OUTFILE,                       X
               RECFM=VB,LRECL=37,BLKSIZE=0

SYSPRINT DCB   DSORG=PS,MACRF=PM,DDNAME=SYSPRINT,                      X
               RECFM=FB,LRECL=80,BLKSIZE=0

         LTORG

***********************************************************************
* VBINRECD - DSECT describing the INPUT buffer GET hands back         *
*                                                                     *
* INRDWLL / INRDWFL are the RDW itself - the two part header every VB *
* record carries, described in the comment block at the top of this   *
* program.  INNAME is coded as DS 0CL1 - a ZERO length placeholder,   *
* not a real field - it only exists to give a NAME to the             *
* displacement where the variable part begins; EX is what decides     *
* how many bytes starting there actually belong to this particular    *
* record.                                                             *
***********************************************************************
VBINRECD DSECT
INRDWLL  DS    H                       * Record length, RDW incl. (bin)
INRDWFL  DS    H                       * Reserved, always binary zero
INCUSTNO DS    CL8                     * Customer number, fixed length
INAMOUNT DS    PL5                     * Amount, packed, fixed length
INNAME   DS    0CL1                    * Variable name starts here -
*                                      * length set at run time

***********************************************************************
* VBOUTRECD - DSECT describing the OUTPUT buffer PUT hands back       *
*                                                                     *
* A SEPARATE DSECT from VBINRECD, even though the layout is identical,*
* because VBINRECD is overlaid on R3 (the input record) and VBOUTRECD *
* is overlaid on R4 (the output buffer) AT THE SAME TIME inside       *
* BUILDOUT.  Two active USINGs cannot safely share one set of field   *
* names - giving the output fields their own DSECT and their own names*
* keeps every reference in BUILDOUT unambiguous.                      *
***********************************************************************
VBOUTRECD DSECT
OUTRDWLL DS    H                       * Record length, RDW incl. (bin)
*                                      * BUILDOUT must set this itself
OUTRDWFL DS    H                       * Reserved - set to binary zero
OUTCUSTNO DS   CL8                     * Customer number, fixed length
OUTAMOUNT DS   PL5                     * Amount, packed, fixed length
OUTNAME  DS    0CL1                    * Variable name starts here,
*                                      * same idea as INNAME above

***********************************************************************
* DCBD generates the IHADCB dummy section used by the OPEN tests in   *
* OPENCHK.  Must be the last thing in the program (CSECT/DSECT must   *
* not restart after it) - see qsamproc.asm / LEARNING.md.             *
***********************************************************************
         DCBD  DSORG=PS,DEVD=DA        * Map of the DCB for TM DCBOFLGS

         END   VB01LOC
