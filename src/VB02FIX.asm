***********************************************************************
* VB02FIX - Fixing The Empty-Name Defect In VB01LOC                   *
* Purpose: Same RECFM=VB, locate mode, EX-driven MVC pattern as       *
*          VB01LOC, but READREC now PROVES the computed name length   *
*          is safe before it is ever handed to EX.                    *
***********************************************************************
*
*======================================================================
* THE DEFECT BEING FIXED
*======================================================================
* VB01LOC computed NAMELENM1 like this and trusted it completely:
*
*     LH    5,INRDWLL         R5 = total record length, RDW included
*     S     5,=F'17'          R5 = name length (may be ZERO or worse)
*     BCTR  5,0               R5 = name length MINUS 1
*     EX    5,MVCNAME         <-- danger lives here
*
* Two ways that goes wrong:
*
*   1. EMPTY NAME.  A record whose name field is truly zero bytes long
*      makes NAMELEN (before BCTR) equal to zero.  BCTR 5,0 on a
*      register already holding ZERO does not stop at -1 - it WRAPS
*      AROUND to binary all-ones, X'FFFFFFFF' (-1 as a signed value,
*      but EX only looks at the LOW BYTE, X'FF' = 255).  EX would then
*      execute MVCNAME as if it had a length of 256 bytes - reading
*      and writing 236 bytes past the real 20 byte name field.
*
*   2. CORRUPT RDW.  INRDWLL arriving smaller than 17 (a damaged or
*      mis-pointed record) makes the subtract go NEGATIVE before BCTR
*      even runs - just as unsafe, for the same reason.
*
*======================================================================
* THE FIX - LTR AND BZ BEFORE EX, AND A HARD LIMIT OF 256
*======================================================================
* LTR reg,reg - "Load and Test Register" - copies a register onto
* itself and sets the condition code from the result, exactly as if
* the value had just been computed; it is the standard, cheap way to
* ask "is this register zero, negative, or positive?" without altering
* it.  BZ then tests for "equal" (condition code 0, meaning the value
* IS zero) and branches around the dangerous EX entirely - an empty
* name is a perfectly legal record, it just means "move nothing",
* which is a no-op, not a job for EX.
*
*     L     5,NAMELEN         R5 = name length, BEFORE BCTR
*     LTR   5,5               Set CC from R5 - zero? negative?
*     BZ    NONAME            Zero length - skip the MVC, nothing to
*                               move, EX would be unsafe here
*     BM    BADLEN            Negative - a corrupt RDW, do not trust
*                               it to EX either
*     C     5,=F'256'         MVC's hard architectural limit is 256
*                               bytes per execution
*     BH    BADLEN            Too long to be real - treat like BADLEN
*     BCTR  5,0               Only NOW is it safe to build length-1
*     EX    5,MVCNAME
*
* The 256 ceiling matters for a second reason, independent of the
* empty-name bug: MVC itself can only ever move 1-256 bytes in ONE
* execution (the length byte is one byte, "length minus one", so its
* largest value is 255, meaning 256 bytes) - EX cannot make MVC do more
* than the instruction format allows.  A record claiming a name longer
* than 256 bytes is already invalid for this file's LRECL=37 design,
* so it is rejected the same way a negative length is.
*
* This hardening is added in exactly one place - READREC - and every
* other routine (SHOWREC, BUILDOUT) is UNCHANGED from VB01LOC, because
* they simply trust the NAMELEN/NAMELENM1 values that READREC already
* validated.  Centralizing the check once, where the value is first
* computed, is cheaper and safer than repeating it at every use.
***********************************************************************
         PRINT NOGEN
VB02FIX  CSECT
***********************************************************************
* A000-MAINLINE - standard entry linkage                              *
***********************************************************************
         STM   14,12,12(13)            * Save caller's registers
         LR    12,15                   * Load base register
         USING VB02FIX,12              * Establish addressability
         ST    13,SAVEAREA+4           * Chain savearea (backward)
         LA    13,SAVEAREA             * Load address of savearea

         MVI   EOFSW,C'N'              * End of file not yet reached
         ZAP   RECCNT,=P'0'            * Records read = 0
         ZAP   BADCNT,=P'0'            * Bad / empty names rejected = 0

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

         BAL   10,READREC              * Priming read

***********************************************************************
* B000-MAINLOOP - one trip per variable length input record           *
***********************************************************************
MAINLOOP CLI   EOFSW,C'Y'
         BE    ALLDONE

         BAL   10,SHOWREC
         BAL   10,BUILDOUT
         BAL   10,READREC
         B     MAINLOOP

***********************************************************************
* ALLDONE - print counts, close everything, and return                *
***********************************************************************
ALLDONE  DS    0H
         MVC   PRTLINE,BLANKS
         MVC   PRTLINE(16),=C'RECORDS READ  : '
         UNPK  ZONE7,RECCNT
         OI    ZONE7+6,X'F0'
         MVC   PRTLINE+16(7),ZONE7
         PUT   SYSPRINT,PRTLINE

         MVC   PRTLINE,BLANKS
         MVC   PRTLINE(16),=C'BAD/EMPTY NAMES:'
         UNPK  ZONE7,BADCNT
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
* OPNERR1 / OPNERR2 - open failure paths                              *
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
* READREC - read one record, then PROVE its name length is safe       *
*           before letting anything near EX use it                    *
*                                                                     *
***********************************************************************
READREC  DS    0H
         GET   INFILE
         LR    3,1
         USING VBINRECD,3

         LH    5,INRDWLL               * R5 = record length, RDW incl.
         S     5,=F'17'                * R5 = name length (0 or worse)

         LTR   5,5                     * Test length BEFORE trusting it
         BZ    NAMEZERO                * Zero - a legal, empty name
         BM    NAMEBAD                 * Negative - corrupt RDW, reject
         C     5,=F'256'               * Over MVC's 256 byte ceiling?
         BH    NAMEBAD                 * Yes - reject it the same way

         ST    5,NAMELEN               * Safe - keep the real length
         BCTR  5,0                     * Safe to build length-1 for EX
         ST    5,NAMELENM1
         MVI   NAMEOK,C'Y'
         B     RRCOMMON

NAMEZERO ST    5,NAMELEN               * NAMELEN = 0, recorded as-is
         SR    5,5
         ST    5,NAMELENM1             * NAMELENM1 unused if NAMEOK='N'
         MVI   NAMEOK,C'N'             * Tell SHOWREC/BUILDOUT: skip EX
         AP    BADCNT,=P'1'            * (counted with NAMEBAD;
*                                      * an empty name is not an ERROR,
*                                      * but this lesson counts it here
*                                      * to keep the demo visible)
         B     RRCOMMON

NAMEBAD  MVC   NAMELEN,=F'0'           * Treat as empty - safe fallback
         MVC   NAMELENM1,=F'0'
         MVI   NAMEOK,C'N'
         AP    BADCNT,=P'1'

RRCOMMON DROP  3
         AP    RECCNT,=P'1'
         BR    10

EOFRTN   DS    0H
         MVI   EOFSW,C'Y'
         BR    10

***********************************************************************
*                                                                     *
* SHOWREC - print one record; EX only runs when NAMEOK='Y'            *
***********************************************************************
SHOWREC  DS    0H
         USING VBINRECD,3

         MVC   PRTLINE,BLANKS
         MVC   PRTLINE(8),INCUSTNO
         UNPK  ZONE7,INAMOUNT
         OI    ZONE7+6,X'F0'
         MVC   PRTLINE+10(7),ZONE7

         CLI   NAMEOK,C'Y'
         BNE   SHOWPUT                 * Empty/bad name - leave name
*                                      * area blank, skip EX
         L     5,NAMELENM1
         EX    5,MVCSHOWN

SHOWPUT  PUT   SYSPRINT,PRTLINE
         BR    10

MVCSHOWN MVC   PRTLINE+20(1),INNAME
         DROP  3

***********************************************************************
*                                                                     *
* BUILDOUT - build the matching output record; EX only runs when      *
*            NAMEOK='Y', otherwise the output record simply carries   *
*            a zero-length name field (still a perfectly valid VB     *
*            record)                                                  *
***********************************************************************
BUILDOUT DS    0H
         USING VBINRECD,3

         PUT   OUTFILE
         LR    4,1
         USING VBOUTRECD,4

         L     6,NAMELEN
         A     6,=F'17'
         STH   6,OUTRDWLL
         XC    OUTRDWFL,OUTRDWFL

         MVC   OUTCUSTNO,INCUSTNO
         ZAP   OUTAMOUNT,INAMOUNT

         CLI   NAMEOK,C'Y'
         BNE   BUILDBR                 * Empty/bad name - no move,
*                                      * OUTRDWLL already says 0 bytes
*                                      * of name, so record is still
*                                      * correctly formed
         L     5,NAMELENM1
         EX    5,MVCBUILD

BUILDBR  BR    10

MVCBUILD MVC   OUTNAME(1),INNAME
         DROP  3
         DROP  4

***********************************************************************
* OPENCHK / PRTMSG / ABENDRTN - unchanged from VB01LOC                *
***********************************************************************
OPENCHK  DS    0H
         USING IHADCB,2
         TM    DCBOFLGS,DCBOFOPN
         DROP  2
         BR    10

PRTMSG   DS    0H
         MVC   PRTLINE,BLANKS
         MVC   PRTLINE(50),0(1)
         PUT   SYSPRINT,PRTLINE
         BR    10

ABENDRTN DS    0H
         ABEND 999,DUMP

***********************************************************************
* Data areas                                                          *
***********************************************************************
SAVEAREA DS    18F
EOFSW    DS    CL1
RECCNT   DS    PL4
BADCNT   DS    PL4

NAMELEN   DS   F
NAMELENM1 DS   F
NAMEOK    DS   CL1                     * 'Y'=safe to EX, 'N'=skip it

PRTLINE  DS    CL80
ZONE7    DS    CL7
BLANKS   DC    CL80' '

MSGSTRT  DC    CL50'VB02FIX - PROGRAM STARTED'
MSGEND   DC    CL50'VB02FIX - PROGRAM ENDED NORMALLY'
MSGOPN1  DC    CL50'VB02FIX - INFILE OPEN ERROR'
MSGOPN2  DC    CL50'VB02FIX - OUTFILE OPEN ERROR'

***********************************************************************
* FILE CONTROL BLOCKS - identical DCBs to VB01LOC; same dataset shape *
***********************************************************************
INFILE   DCB   DSORG=PS,MACRF=GL,DDNAME=INFILE,                        X
               EODAD=EOFRTN,RECFM=VB,LRECL=37,BLKSIZE=0

OUTFILE  DCB   DSORG=PS,MACRF=PL,DDNAME=OUTFILE,                       X
               RECFM=VB,LRECL=37,BLKSIZE=0

SYSPRINT DCB   DSORG=PS,MACRF=PM,DDNAME=SYSPRINT,                      X
               RECFM=FB,LRECL=80,BLKSIZE=0

         LTORG

***********************************************************************
* VBINRECD / VBOUTRECD - same layouts as VB01LOC (see VBINREC.cpy /   *
* VBOUTREC.cpy for the COBOL mirror)                                  *
***********************************************************************
VBINRECD DSECT
INRDWLL  DS    H
INRDWFL  DS    H
INCUSTNO DS    CL8
INAMOUNT DS    PL5
INNAME   DS    0CL1

VBOUTRECD DSECT
OUTRDWLL  DS   H
OUTRDWFL  DS   H
OUTCUSTNO DS   CL8
OUTAMOUNT DS   PL5
OUTNAME   DS   0CL1

         DCBD  DSORG=PS,DEVD=DA

         END   VB02FIX
