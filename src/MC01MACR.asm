***********************************************************************
* MC01MACR - A Source Macro That Replaces Repeated OPENCHK/Message    *
*            Code                                                     *
* Purpose: Write two MACRO definitions - CHKOPEN and PRTMSG - that    *
*          every earlier program in this project hand-coded as a      *
*          BAL/BR subroutine pair, and use &SYSNDX with AIF to make   *
*          each EXPANSION of the macro generate its OWN uniquely      *
*          labelled code, so the SAME macro can be used any number of *
*          times in one program without a "duplicate label" error.    *
*                                                                     *
*======================================================================
* WHY A MACRO, AND NOT JUST ANOTHER BAL/BR SUBROUTINE
*======================================================================
* OPENCHK in ds02dsct.asm / qsamproc.asm / vb01loc.asm is a SUBROUTINE:
* one copy of the code exists, reached with BAL and left with BR. Every
* program that wants it has to RETYPE that subroutine, by hand, from
* scratch, which is exactly the kind of repetition this lesson removes.
*
* A MACRO is different: it is NOT a subroutine at all - it is a
* TEMPLATE the ASSEMBLER itself expands, INLINE, every place it is
* invoked, generating a fresh, independent copy of the instructions
* each time, right there in the source.  Nothing is "called" at run
* time for a macro the way BAL calls OPENCHK; by the time the program
* actually runs, the macro is long gone - only the instructions it
* generated remain, indistinguishable from code typed by hand.
*
*======================================================================
* MACRO / MEND - THE DEFINITION
*======================================================================
*         MACRO
*&LABEL   CHKOPEN &DCB,&FAILMSG
*         ...body...
*         MEND
*
* MACRO starts the definition; MEND ends it.  &LABEL is a MACRO's own
* optional LABEL parameter - whatever label the programmer codes in
* front of the macro NAME at the point of use is passed in here
* automatically.  &DCB and &FAILMSG are POSITIONAL parameters - the
* caller supplies them in order, separated by commas, with no keyword.
*
*======================================================================
* POSITIONAL vs KEYWORD PARAMETERS
*======================================================================
*     CHKOPEN INFILE,MSGOPN1          positional - order matters
*     PRTMSG  MSG=MSGSTRT,DEST=SYSOUT keyword - order does NOT matter,
*                                        and keyword parameters can
*                                        have DEFAULT values coded
*                                        right in the macro's own
*                                        prototype statement, e.g.
*                                        &DEST=SYSOUT
*
* This program's PRTMSG macro uses BOTH kinds at once: &MSG is
* positional (always required, always first), &DEST is a keyword
* parameter defaulting to SYSOUT if the caller does not override it.
*
*======================================================================
* &SYSNDX - WHY EVERY EXPANSION NEEDS ITS OWN LABELS
*======================================================================
* CHKOPEN's body branches around on a failed open test - it needs a
* label to branch to.  If that label were written as a FIXED name like
* OPNBAD, every single EXPANSION of CHKOPEN in the program would try
* to define OPNBAD AGAIN - a duplicate label, a hard assembly error,
* the very first time CHKOPEN is used twice.
*
* &SYSNDX is a SYSTEM VARIABLE SYMBOL the assembler sets, automatical
* ly to a different 4 digit number FOR EVERY MACRO INSTRUCTION INVOKED
* anywhere in the whole assembly (0001, 0002, 0003, ...) - NOT a
* parameter the caller supplies, the assembler tracks it itself.
* Appending it to an internal label - &LABEL.A&SYSNDX - manufactures a
* label GUARANTEED unique to THIS ONE expansion, no matter how many
* times the macro is invoked:
*
*     CHKOPEN INFILE,MSGOPN1     expansion #1 -> label OPNA0007
*     CHKOPEN OUTFILE,MSGOPN2    expansion #2 -> label OPNA0008
*
* (the period after &LABEL is REQUIRED - it tells the assembler where
* the symbolic variable's NAME ends and the literal text "A" begins;
* without it, the assembler would hunt for a longer variable symbol
* called &LABELA and fail to find one).
*
*======================================================================
* AIF - CONDITIONAL ASSEMBLY, NOT A RUN TIME BRANCH
*======================================================================
*     AIF  ('&FAILMSG' EQ '').NOMSG
*
* AIF tests a condition AT ASSEMBLY TIME (comparing the literal TEXT
* the caller supplied, not any run time value) and, if true, skips
* assembling source lines down to the sequence symbol named
* (.NOMSG below) - entire chunks of the macro's body can be left OUT
* of the expansion entirely depending on what the caller passed. This
* macro uses it so CHKOPEN still works even when a caller passes NO
* failure message at all (just wants the TM done, and will check the
* condition code itself) - a feature a plain hand written subroutine
* could never offer without being rewritten.
***********************************************************************
         MACRO
&LAB     CHKOPEN &DCB,&FAILMSG
.*-------------------------------------------------------------------
.* &LAB     - optional label on the macro instruction itself
.* &DCB     - the DCB to test (NOT in parentheses - one positional val)
.* &FAILMSG - optional CL50 message to print and ABEND on if the open
.*            failed; if omitted, CHKOPEN only sets the condition code
.*            and falls through, leaving the caller to test it
.*-------------------------------------------------------------------
&LAB     DS    0H
         LA    2,&DCB
         USING IHADCB,2
         TM    DCBOFLGS,DCBOFOPN
         DROP  2
         AIF   ('&FAILMSG' EQ '').NOMSG
         BO    OK&SYSNDX               * Open OK (bit ON) - branch
*                                      * AROUND the failure path AT RUN
*                                      * TIME.  AGO cannot do this job:
*                                      * is a CONDITIONAL ASSEMBLY
*                                      * unconditional and taken ONCE,
*                                      * ASSEMBLY TIME, in every
*                                      * - it would skip GENERATING
*                                      * the failure block entirely,
*                                      * is exactly the bug this
*                                      * (BNO NOGOOD&SYSNDX had no
*                                      * left to branch to, since AGO
*                                      * thrown the whole block away
*                                      * it could even be assembled).
         PRTMSG &FAILMSG,DEST=SYSPRINT
         ABEND 999,DUMP
OK&SYSNDX DS   0H                      * A real GENERATED label - needs
*                                      * &SYSNDX to stay unique across
*                                      * CHKOPEN's several expansions
.NOMSG   ANOP
         MEND

***********************************************************************
* PRTMSG - print a CL50 message (positional &MSG) to a DCB (keyword   *
*          &DEST, defaulting to SYSOUT) using PRTLINE as the 80 byte  *
*          work area - replaces the hand coded PRTMSG BAL/BR subroutin*
*          every earlier program repeated                             *
***********************************************************************
         MACRO
&LAB     PRTMSG &MSG,&DEST=SYSOUT
&LAB     DS    0H
         MVC   PRTLINE,BLANKS
         MVC   PRTLINE(50),&MSG
         PUT   &DEST,PRTLINE
         MEND

***********************************************************************
* MC01MACR - the mainline using both macros, SEVERAL times each, to   *
*             prove &SYSNDX makes every expansion assemble cleanly    *
***********************************************************************
         PRINT NOGEN
MC01MACR CSECT
         STM   14,12,12(13)
         LR    12,15
         USING MC01MACR,12
         ST    13,SAVEAREA+4
         LA    13,SAVEAREA

         OPEN  (SYSPRINT,(OUTPUT))
         CHKOPEN SYSPRINT,MSGOPN0      * Expansion #1 of CHKOPEN

         OPEN  (INFILE,(INPUT))
         CHKOPEN INFILE,MSGOPN1        * Expansion #2 - its own unique
*                                      * internal labels, no clash with
*                                      * #1's

         OPEN  (OUTFILE,(OUTPUT))
         CHKOPEN OUTFILE,MSGOPN2       * Expansion #3

         PRTMSG MSGSTRT,DEST=SYSPRINT  * Expansion #1 of PRTMSG - &DEST
*                                      * is a KEYWORD parameter;
*                                      * supplied explicitly here since
*                                      * this program's print DCB is
*                                      * named SYSPRINT, not the
*                                      * macro's default of SYSOUT

***********************************************************************
* Copy a few records from INFILE to OUTFILE, purely to give CHKOPEN   *
* something realistic to have guarded, then report and finish         *
***********************************************************************
         ZAP   RECCNT,=P'0'
         MVI   EOFSW,C'N'
COPYLOOP GET   INFILE,INAREA
         MVC   OUTAREA,INAREA
         PUT   OUTFILE,OUTAREA
         AP    RECCNT,=P'1'
         B     COPYLOOP
*        (EODAD below ends the loop - no explicit branch back needed)

EOFRTN   DS    0H
         MVI   EOFSW,C'Y'

         MVC   PRTLINE,BLANKS
         MVC   PRTLINE(16),=C'RECORDS COPIED: '
         UNPK  ZONE7,RECCNT
         OI    ZONE7+6,X'F0'
         MVC   PRTLINE+16(7),ZONE7
         PUT   SYSPRINT,PRTLINE

         PRTMSG MSGEND,DEST=SYSPRINT

         CLOSE (INFILE)
         CLOSE (OUTFILE)
         CLOSE (SYSPRINT)
         L     13,SAVEAREA+4
         LM    14,12,12(13)
         SR    15,15
         BR    14

***********************************************************************
* Data areas                                                          *
***********************************************************************
SAVEAREA DS    18F
EOFSW    DS    CL1
RECCNT   DS    PL4
PRTLINE  DS    CL80
ZONE7    DS    CL7
BLANKS   DC    CL80' '
INAREA   DS    CL80
OUTAREA  DS    CL80

MSGOPN0  DC    CL50'MC01MACR - SYSPRINT OPEN ERROR'
MSGOPN1  DC    CL50'MC01MACR - INFILE OPEN ERROR'
MSGOPN2  DC    CL50'MC01MACR - OUTFILE OPEN ERROR'
MSGSTRT  DC    CL50'MC01MACR - PROGRAM STARTED'
MSGEND   DC    CL50'MC01MACR - PROGRAM ENDED NORMALLY'

INFILE   DCB   DSORG=PS,MACRF=GM,DDNAME=INFILE,                        X
               EODAD=EOFRTN,RECFM=FB,LRECL=80,BLKSIZE=0

OUTFILE  DCB   DSORG=PS,MACRF=PM,DDNAME=OUTFILE,                       X
               RECFM=FB,LRECL=80,BLKSIZE=0

SYSPRINT DCB   DSORG=PS,MACRF=PM,DDNAME=SYSPRINT,                      X
               RECFM=FB,LRECL=80,BLKSIZE=0

         LTORG

         DCBD  DSORG=PS,DEVD=DA

         END   MC01MACR
