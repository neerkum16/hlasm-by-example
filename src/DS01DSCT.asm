***********************************************************************
* DS01DSCT - Mapping A Record With A DSECT                            *
* Purpose: Shows the basic idea of a DSECT - a storage map that       *
*          reserves NO storage of its own.  Compares it directly      *
*          against the "DS 0CL.. plus a list of fields" technique     *
*          used earlier (see qsamproc.asm section 12.5), and shows    *
*          ORG used to overlay one field two different ways, which    *
*          is the Assembler equivalent of COBOL's REDEFINES.          *
***********************************************************************
*
*======================================================================
* WHY A DSECT INSTEAD OF "DS 0CL.. PLUS A FIELD LIST"?                *
*======================================================================
* Earlier programs (qsamproc.asm) laid out a record like this:
*
*     INREC    DS    0CL559
*     INCUSTNO DS    CL8
*     INUSERID DS    CL8
*     ...
*
* That works, but the fields and the STORAGE are glued together in one
* place.  If this record layout is used by five different programs,
* every one of them needs its own identical copy of that field list -
* copy/paste, and every copy can drift out of sync.
*
* A DSECT separates the TWO ideas that "DS 0CL.." was doing at once:
*   1. the LAYOUT  - field names, lengths, and their order
*   2. the STORAGE - actual bytes somewhere in memory
*
* A DSECT is ONLY the layout.  It assembles to ZERO bytes of its own.
* To use it, you point a register at some REAL storage (created by a
* CSECT, or read into by a GET, or passed to you by a caller) and tell
* the assembler, with USING, "pretend the DSECT starts right there".
* From that point on every field name in the DSECT becomes usable,
* and it is just "register + displacement" under the hood - exactly
* the same machine code as before, just typed with names instead of
* hand counted offsets.
*
* This is exactly how DCBD/IHADCB worked back in qsamproc.asm - that
* was a DSECT too, just one IBM wrote for you to describe a DCB.
* This program writes a small one of our own.
***********************************************************************
         PRINT NOGEN
DS01DSCT CSECT
***********************************************************************
* A000-MAINLINE - standard entry linkage, as in every earlier program *
***********************************************************************
         STM   14,12,12(13)            * Save caller's registers
         LR    12,15                   * Load base register
         USING DS01DSCT,12             * Establish addressability
         ST    13,SAVEAREA+4           * Chain savearea (backward)
         LA    13,SAVEAREA             * Load address of savearea

         OPEN  (SYSOUT,(OUTPUT))       * Open sysout

***********************************************************************
* PART 1 - POINT THE DSECT AT A REAL RECORD AND READ IT               *
*                                                                     *
* CUSTREC below is REAL storage - a CSECT field, 30 bytes, already    *
* filled in by a DC at assembly time (standing in for a record that   *
* in real life would have arrived via a GET).  CUSTD is the DSECT -   *
* no storage of its own, just names and lengths.                      *
*                                                                     *
* LA 3,CUSTREC points R3 at the real bytes.  USING CUSTD,3 tells the  *
* assembler "pretend the CUSTD layout starts at whatever R3 holds".   *
* From here on CUSTNO, CUSTNAME and CUSTBAL are usable exactly like   *
* ordinary labels - the assembler quietly turns each one into         *
* "R3 + displacement" when it generates the machine code.             *
***********************************************************************
         LA    3,CUSTREC               * R3 -> real record in storage
         USING CUSTD,3                 * CUSTD now overlays that record

         MVC   OUTMSG,BLANKS           * Clear output line
         MVC   OUTMSG(10),=C'CUST NO: '
         MVC   OUTMSG+10(8),CUSTNO     * Read straight through DSECT
         PUT   SYSOUT,OUTMSG

         MVC   OUTMSG,BLANKS
         MVC   OUTMSG(10),=C'NAME:    '
         MVC   OUTMSG+10(20),CUSTNAME  * Other field, same technique
         PUT   SYSOUT,OUTMSG

         DROP  3                       * Finished with mapping of R3

***********************************************************************
* PART 2 - THE SAME DSECT, A DIFFERENT REAL RECORD                    *
*                                                                     *
* This is the entire point of separating layout from storage.  The    *
* exact same CUSTD field names (CUSTNO, CUSTNAME, CUSTBAL) now read a *
* COMPLETELY DIFFERENT 30 bytes, just by pointing R3 somewhere else   *
* and re-establishing the USING.  Nothing about CUSTD itself changes. *
***********************************************************************
         LA    3,CUSTREC2              * R3 -> a different record
         USING CUSTD,3                 * Same DSECT over record 2

         MVC   OUTMSG,BLANKS
         MVC   OUTMSG(10),=C'CUST NO: '
         MVC   OUTMSG+10(8),CUSTNO
         PUT   SYSOUT,OUTMSG

         MVC   OUTMSG,BLANKS
         MVC   OUTMSG(10),=C'NAME:    '
         MVC   OUTMSG+10(20),CUSTNAME
         PUT   SYSOUT,OUTMSG

         DROP  3

***********************************************************************
* PART 3 - ORG, THE ASSEMBLER'S VERSION OF COBOL'S REDEFINES          *
*                                                                     *
* Inside a DSECT, ORG moves the "next free byte" pointer BACKWARDS to *
* a field already defined, so the fields that follow start OVER THE   *
* SAME BYTES as something already there.  See CUSTD below: CUSTBAL is *
* defined once as PL5 (packed decimal, for arithmetic), and again, at *
* the SAME displacement, as CUSTBALC CL5 (plain characters, for a     *
* quick display without converting it first).  Both names are valid   *
* at once - they are two different VIEWS of the identical 5 bytes.    *
*                                                                     *
* This matters because real records are sometimes genuinely ambiguous *
* - the same bytes mean different things depending on another field   *
* elsewhere in the record (a type code, for example) - and ORG is the *
* tool that lets one DSECT describe both views without copying data.  *
***********************************************************************
         LA    3,CUSTREC               * Back to record 1
         USING CUSTD,3

         MVC   OUTMSG,BLANKS
         MVC   OUTMSG(10),=C'BAL HEX: '
         UNPK  ZONE,CUSTBAL            * Read it as PACKED decimal
         OI    ZONE+4,X'F0'
         MVC   OUTMSG+10(5),ZONE
         PUT   SYSOUT,OUTMSG

         MVC   OUTMSG,BLANKS
         MVC   OUTMSG(10),=C'BAL RAW: '
         MVC   OUTMSG+10(5),CUSTBALC   * Same 5 bytes, as CHARACTERS
         PUT   SYSOUT,OUTMSG

         DROP  3

***********************************************************************
* Close, restore registers, and return                                *
***********************************************************************
         CLOSE (SYSOUT)
         L     13,SAVEAREA+4
         LM    14,12,12(13)
         SR    15,15
         BR    14

***********************************************************************
* Data areas - all REAL storage, part of this CSECT                   *
***********************************************************************
SAVEAREA DS    18F
OUTMSG   DS    CL80
BLANKS   DC    CL80' '
ZONE     DS    CL5

***********************************************************************
* Two sample "records", each 30 bytes, built as plain DC constants to *
* stand in for data that would normally arrive from a file.  Notice   *
* that THESE ARE JUST BYTES - nothing here says "this is a CUSTD".    *
* The DSECT below is what gives those bytes meaning, and only once a  *
* register is pointed at them and USING is in effect.                 *
***********************************************************************
CUSTREC  DC    CL8'10023456',CL20'JOHN SMITH          ',PL5'12345'
CUSTREC2 DC    CL8'99887766',CL20'JANE DOE            ',PL5'500'

SYSOUT   DCB   DSORG=PS,MACRF=PM,DDNAME=SYSOUT,                        X
               RECFM=FB,LRECL=80,BLKSIZE=0

         LTORG

***********************************************************************
* CUSTD - the DSECT itself.                                           *
*                                                                     *
* A DSECT statement ENDS the current CSECT and starts a brand new     *
* kind of section: one that generates NO object code and reserves NO  *
* storage, no matter how many fields it lists.  Assembling just this  *
* DSECT on its own would produce zero bytes.  Its only job is to let  *
* the assembler compute DISPLACEMENTS for each field name, so that    *
* later, with USING pointing a register at real storage, CUSTNO means *
* "whatever is at register+0", CUSTNAME means "register+8", and so on.*
*                                                                     *
* Because a DSECT must come AFTER the real CSECT code that uses it in *
* this file (the assembler reads top to bottom and a DSECT would stop *
* the CSECT from continuing), DSECTs are conventionally placed at the *
* very end of the source, same as DCBD was in qsamproc.asm.           *
***********************************************************************
CUSTD    DSECT
CUSTNO   DS    CL8                     * Customer number, 8 characters
CUSTNAME DS    CL20                    * Customer name, 20 characters
CUSTBAL  DS    PL5                     * Balance, PACKED, 5 bytes
         ORG   CUSTBAL                 * Go back, redefine the 5 bytes
CUSTBALC DS    CL5                     * ...now as plain characters

         END   DS01DSCT
