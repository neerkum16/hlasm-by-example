***********************************************************************
* BR02MASK - Branch On Condition Masks (BC / BCR)                     *
* Purpose: Show that every extended mnemonic (BE, BH, BL, ...) is     *
*          really BC mask,target.  Mask bits: 8=equal/zero, 4=low,    *
*          2=high, 1=overflow.  Mask 15 = always, mask 0 = never.     *
***********************************************************************
BR02MASK CSECT
         STM   14,12,12(13)            * Save caller's registers
         LR    12,15                   * Load base register
         USING BR02MASK,12             * Establish addressability
         ST    13,SAVEAREA+4           * Chain savearea (backward)
         LA    13,SAVEAREA             * Load address of savearea

         OPEN  (SYSOUT,(OUTPUT))       * Open sysout

***********************************************************************
* Example 1: BC 8 is the same instruction as BE                       *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         L     3,NUMA                  * R3 = 40
         C     3,NUMB                  * Compare R3 with NUMB (40)
         BC    8,EX1EQ                 * Mask 8 = branch if equal
         MVC   OUTMSG(50),MSG1NE       * Fall through = not equal
         B     EX1PUT
EX1EQ    MVC   OUTMSG(50),MSG1EQ       * Equal path
EX1PUT   PUT   SYSOUT,OUTMSG           * Write message

***********************************************************************
* Example 2: combined masks - BC 12 means "equal or low" (= BNH)      *
*            8 (equal) + 4 (low) = 12                                 *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         L     3,NUMA                  * R3 = 40
         C     3,NUMC                  * Compare R3 with NUMC (90)
         BC    12,EX2NH                * Mask 12 = not high
         MVC   OUTMSG(50),MSG2HI       * High path
         B     EX2PUT
EX2NH    MVC   OUTMSG(50),MSG2NH       * Not high path
EX2PUT   PUT   SYSOUT,OUTMSG           * Write message

***********************************************************************
* Example 3: BC 15 is an unconditional branch - the B mnemonic        *
*            BC 0 never branches - that is the NOP mnemonic           *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         NOP   EX3BAD                  * Mask 0 - never taken, a filler
         BC    15,EX3GOOD              * Mask 15 - always taken
EX3BAD   MVC   OUTMSG(50),MSG3BAD      * Should never be reached
         B     EX3PUT
EX3GOOD  MVC   OUTMSG(50),MSG3OK       * Always reached
EX3PUT   PUT   SYSOUT,OUTMSG           * Write message

***********************************************************************
* Example 4: arithmetic sets the CC too - no compare needed           *
*            After AR: CC 0=zero, 1=negative, 2=positive, 3=overflow  *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         L     4,NUMD                  * R4 = 25
         L     5,NUME                  * R5 = -25
         AR    4,5                     * Add, result is zero -> CC=0
         BZ    EX4ZERO                 * BZ is BC 8 after arithmetic
         MVC   OUTMSG(50),MSG4NZ       * Non zero result
         B     EX4PUT
EX4ZERO  MVC   OUTMSG(50),MSG4Z        * Zero result
EX4PUT   PUT   SYSOUT,OUTMSG           * Write message

***********************************************************************
* Example 5: BCR - branch on condition to an address in a register    *
*            BCR 15,14 is exactly what BR 14 assembles into           *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(50),MSG5         * Explain BCR
         PUT   SYSOUT,OUTMSG           * Write message

***********************************************************************
* Close, restore registers, and return                                *
***********************************************************************
         CLOSE (SYSOUT)                * Close sysout
         L     13,SAVEAREA+4           * Restore caller's savearea
         LM    14,12,12(13)            * Restore caller's registers
         SR    15,15                   * Set return code to 0
         BCR   15,14                   * Unconditional branch to R14

***********************************************************************
* Data areas                                                          *
***********************************************************************
SAVEAREA DS    18F                     * Save area (72 bytes)
OUTMSG   DS    CL80                    * Output message buffer
BLANKS   DC    CL80' '                 * Blank line for clearing

***********************************************************************
* Test values                                                         *
***********************************************************************
NUMA     DC    F'40'                   * NUMA = 40
NUMB     DC    F'40'                   * NUMB = 40
NUMC     DC    F'90'                   * NUMC = 90
NUMD     DC    F'25'                   * NUMD = 25
NUME     DC    F'-25'                  * NUME = -25

***********************************************************************
* Messages                                                            *
***********************************************************************
MSG1EQ   DC    CL50'BC 8  : TAKEN - SAME AS BE'
MSG1NE   DC    CL50'BC 8  : NOT TAKEN - VALUES DIFFER'
MSG2HI   DC    CL50'BC 12 : NOT TAKEN - NUMA IS HIGH'
MSG2NH   DC    CL50'BC 12 : TAKEN - EQUAL OR LOW, SAME AS BNH'
MSG3OK   DC    CL50'BC 15 : ALWAYS BRANCHES, NOP NEVER BRANCHES'
MSG3BAD  DC    CL50'BC 15 : LOGIC ERROR - THIS SHOULD NOT PRINT'
MSG4Z    DC    CL50'AR    : RESULT IS ZERO, CC=0 SET BY ARITHMETIC'
MSG4NZ   DC    CL50'AR    : RESULT IS NOT ZERO'
MSG5     DC    CL50'BCR 15,14 IS THE SAME AS BR 14'

***********************************************************************
* DCB for SYSOUT                                                      *
***********************************************************************
SYSOUT   DCB   DSORG=PS,MACRF=PM,DDNAME=SYSOUT,                        X
               RECFM=FB,LRECL=80,BLKSIZE=0

         END   BR02MASK
