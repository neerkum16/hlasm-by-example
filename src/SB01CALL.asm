***********************************************************************
* SB01CALL - header and narrative, source lines 1-29: NOT SUPPLIED    *
* The editor photos start at line 30. Replace lines 1-29 with the     *
* original text. This block only keeps the line numbers aligned.      *
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*
*            together (forward AND backward pointers), so a dump can
*            walk the whole chain of callers.
*   R14  -> the return address (where the callee BRs back to)
*   R15  -> the callee's entry point address going IN; the callee's
*             RETURN CODE coming back OUT - the caller is expected to
*             test it after control returns.
*
* The CALL macro builds the parameter list & the high bit automatically
* and leaves R15 holding the return code when control comes back - it's
* simply a shorthand for the BALR-based sequence spelled out by hand
* further down in this same program for comparison.
*
*======================================================================
* CALL vs LINK
*======================================================================
* CALL - resolves the target's address at LINK EDIT time (the called
*         CSECT must be link-edited into the SAME load module, or be
*         resolved via an external reference) and branches to it with
*         a BALR style instruction - fast, no search of any library.
* LINK - a SUPERVISOR CALL (an SVC): it asks z/OS to locate and LOAD a
*         separate PROGRAM (by name, usually from a library) at run
*         time, run it, and return control afterward.  Slower, but the
*         called program does not have to already be bound into this
*         load module - handy for programs selected dynamically.
* Both deliver control using the SAME standard linkage described above
* - the called program cannot tell, from inside, whether it was reached
* by CALL, LINK, or BALR; all three leave R1/R13/R14/R15 set up
* identically.  This program demonstrates CALL explicitly, and shows,
* in a comment, the ONE LINE that would be used instead for LINK.
***********************************************************************
         PRINT NOGEN
SB01CALL CSECT
***********************************************************************
* A000-MAINLINE - standard entry linkage                              *
***********************************************************************
         STM   14,12,12(13)
         LR    12,15
         USING SB01CALL,12
         ST    13,SAVEAREA+4
         LA    13,SAVEAREA

         OPEN  (SYSOUT,(OUTPUT))
         MVC   OUTMSG,BLANKS
         MVC   OUTMSG(50),MSGHDR
         PUT   SYSOUT,OUTMSG

         MVC   TOTAL,=F'100'           * Starting total

***********************************************************************
* Build the parameter list, THE WAY CALL BUILDS IT INTERNALLY -       *
* shown by hand once, here, so the macro expansion below is not magic *
*                                                                     *
*    PARMLIST  DC  A(TOTAL)        word 1 - address of parameter 1
*              DC  X'80',AL3(AMOUNT) word 2 - SAME as A(AMOUNT), but
*                                      with the high order BYTE's
*                                      TOP BIT forced on, marking it
*                                      the LAST parameter
*
* AL3 is a 3 byte address length constant; combined with a 1 byte
* X'80', the two together occupy exactly one fullword, with bit 0 of
* that fullword turned on - precisely the flag format described above.
*
* NOTE: R1 must point to the list, and R15 must hold the TARGET's
* entry address, before BALR 14,15 - loading R15 is what makes this a
* call rather than a branch to nowhere; both steps are shown below.
***********************************************************************
         MVC   AMOUNT,=F'50'           * Amount to add, first call
         LA    1,PARMLST1              * R1 -> hand built parm list
         L     15,=V(SB02SUBR)         * R15 -> SB02SUBR entry addr -
*                                      * V-type addr constant, resolved
*                                      * by linkage editor at bind time
         BALR  14,15                   * R14=ret addr, branch to R15 -
*                                      * this one instruction IS a call
         BAL   10,SHOWRC               * Show TOTAL and the return code

***********************************************************************
* The SAME call again, this time using the CALL macro - it builds the
* identical parameter list (with the high bit) and does the identical
* L 15,=V(..) / BALR 14,15 sequence, just without spelling it out     *
***********************************************************************
         MVC   AMOUNT,=F'500'          * A 2nd amount - large enough to
*                                      * push TOTAL over, just exercise
*                                      * SB02SUBR's "negative" check
*                                      * is NOT triggered (total stays
*                                      * positive) - see the THIRD call
*                                      * below for the negative case
         CALL  SB02SUBR,(TOTAL,AMOUNT)
*                                      * CALL macro: builds a two word
*                                      * parameter list, HIGH BIT on
*                                      * the LAST address (AMOUNT),
*                                      * and branches exactly like the
*                                      * BALR sequence above
         BAL   10,SHOWRC

         MVC   AMOUNT,=F'-100000'      * A big negative amount, to make
*                                      * the running TOTAL go negative
*                                      * and exercise SB02SUBR's RC 4
*                                      * path
         CALL  SB02SUBR,(TOTAL,AMOUNT)
         BAL   10,SHOWRC

*         To call a DIFFERENT, dynamically loaded program instead, by
*         name, the ONLY line that changes is this one:
*              LINK  EP=SB02SUBR,PARAM=(TOTAL,AMOUNT)
*         Everything SB02SUBR does internally is identical either way.

         CLOSE (SYSOUT)
         L     13,SAVEAREA+4
         LM    14,12,12(13)
         SR    15,15
         BR    14

***********************************************************************
* SHOWRC - print the current TOTAL and the return code CALL just left *
*            in R15                                                   *
***********************************************************************
SHOWRC   DS    0H
         ST    15,SAVERC               * R15 reused by PUT below - save
*                                      * the return code immediately
         MVC   OUTMSG,BLANKS
         MVC   OUTMSG(16),=C'TOTAL NOW     : '
         L     3,TOTAL
         CVD   3,DOUBLE
         UNPK  ZONE,DOUBLE
         OI    ZONE+7,X'F0'
         MVC   OUTMSG+16(8),ZONE

         MVC   OUTMSG+30(16),=C'RETURN CODE   : '
         L     3,SAVERC
         CVD   3,DOUBLE
         UNPK  ZONE,DOUBLE
         OI    ZONE+7,X'F0'
         MVC   OUTMSG+46(8),ZONE

         PUT   SYSOUT,OUTMSG
         BR    10

***********************************************************************
* Data areas                                                          *
***********************************************************************
SAVEAREA DS    18F
TOTAL    DS    F
AMOUNT   DS    F
SAVERC   DS    F
DOUBLE   DS    D
ZONE     DS    CL8
OUTMSG   DS    CL80
BLANKS   DC    CL80' '
MSGHDR   DC    CL50'SB01CALL - CALLING SB02SUBR WITH STANDARD LINKAGE'

***********************************************************************
* PARMLST1 - a HAND BUILT parameter list, for the one illustration    *
*            call above; every CALL macro afterward builds its own    *
*            list automatically, in exactly this shape                *
***********************************************************************
PARMLST1 DC    A(TOTAL)                * Word 1: address of parameter 1
         DC    X'80',AL3(AMOUNT)       * Word 2: addr of parm 2, WITH
*                                      * the high order bit forced on -
*                                      * marks this as the LAST parm
***********************************************************************
* DCB for SYSOUT                                                      *
***********************************************************************
SYSOUT   DCB   DSORG=PS,MACRF=PM,DDNAME=SYSOUT,                        X
               RECFM=FB,LRECL=80,BLKSIZE=0

         LTORG

         END   SB01CALL
