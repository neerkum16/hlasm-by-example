***********************************************************************
* BR03LOOP - Basic Loop Shapes                                        *
* Purpose: Build the three common loop shapes by hand -               *
*          1. counted loop with BCT                                   *
*          2. top tested loop (DO WHILE) with C and a conditional     *
*          3. bottom tested loop (DO UNTIL)                           *
*          Plus BCTR 7,0 as the cheap "subtract one" trick.           *
***********************************************************************
BR03LOOP CSECT
         STM   14,12,12(13)            * Save caller's registers
         LR    12,15                   * Load base register
         USING BR03LOOP,12             * Establish addressability
         ST    13,SAVEAREA+4           * Chain savearea (backward)
         LA    13,SAVEAREA             * Load address of savearea

         OPEN  (SYSOUT,(OUTPUT))       * Open sysout

***********************************************************************
* Example 1: BCT - Branch on Count                                    *
*            BCT subtracts 1 from the register and branches while     *
*            the result is not zero.  Classic "do N times" loop.      *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(50),MSG1HDR      * Heading for example 1
         PUT   SYSOUT,OUTMSG           * Write heading

         L     6,COUNT5                * R6 = 5, the loop counter
         SR    7,7                     * R7 = 0, the iteration number
LOOP1    LA    7,1(,7)                 * R7 = R7 + 1
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(50),MSG1ITR      * 'BCT ITERATION'
         CVD   7,DOUBLE                * Counter to packed decimal
         UNPK  ZONE,DOUBLE             * Unpack to zoned decimal
         OI    ZONE+7,X'F0'            * Fix sign nibble
         MVC   OUTMSG+50(8),ZONE       * Show the iteration number
         PUT   SYSOUT,OUTMSG           * Write one line per pass
         BCT   6,LOOP1                 * R6 = R6 - 1, loop if not zero

***********************************************************************
* Example 2: top tested loop - DO WHILE total <= LIMIT                *
*            The test is at the TOP, so the body may run zero times.  *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(50),MSG2HDR      * Heading for example 2
         PUT   SYSOUT,OUTMSG           * Write heading

         SR    8,8                     * R8 = running total = 0
         L     9,STEP7                 * R9 = 7, the increment
LOOP2    C     8,LIMIT                 * Compare total with LIMIT (30)
         BH    LOOP2END                * Exit when total is high
         AR    8,9                     * total = total + 7
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(50),MSG2ITR      * 'RUNNING TOTAL'
         CVD   8,DOUBLE                * Total to packed decimal
         UNPK  ZONE,DOUBLE             * Unpack to zoned decimal
         OI    ZONE+7,X'F0'            * Fix sign nibble
         MVC   OUTMSG+50(8),ZONE       * Show the total
         PUT   SYSOUT,OUTMSG           * Write one line per pass
         B     LOOP2                   * Go back and test again
LOOP2END DS    0H                      * Loop exit point

***********************************************************************
* Example 3: bottom tested loop - DO UNTIL                            *
*            The test is at the BOTTOM, so the body always runs once. *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(50),MSG3HDR      * Heading for example 3
         PUT   SYSOUT,OUTMSG           * Write heading

         L     10,START16              * R10 = 16, value to halve
LOOP3    MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(50),MSG3ITR      * 'HALVING'
         CVD   10,DOUBLE               * Value to packed decimal
         UNPK  ZONE,DOUBLE             * Unpack to zoned decimal
         OI    ZONE+7,X'F0'            * Fix sign nibble
         MVC   OUTMSG+50(8),ZONE       * Show the value
         PUT   SYSOUT,OUTMSG           * Write one line per pass
         SRL   10,1                    * Shift right 1 = divide by 2
         LTR   10,10                   * Test the new value
         BNZ   LOOP3                   * Repeat until it reaches zero

***********************************************************************
* Example 4: BCTR r,0 - subtract one without branching                *
*            A second operand of 0 means "no branch", so BCTR is      *
*            used as a one instruction decrement.  Very common for    *
*            building the length-1 value needed by EX.                *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         L     11,COUNT5               * R11 = 5
         BCTR  11,0                    * R11 = 4, no branch taken
         MVC   OUTMSG(50),MSG4         * 'BCTR R11,0 GIVES'
         CVD   11,DOUBLE               * Value to packed decimal
         UNPK  ZONE,DOUBLE             * Unpack to zoned decimal
         OI    ZONE+7,X'F0'            * Fix sign nibble
         MVC   OUTMSG+50(8),ZONE       * Show the value
         PUT   SYSOUT,OUTMSG           * Write message

***********************************************************************
* Close, restore registers, and return                                *
***********************************************************************
         CLOSE (SYSOUT)                * Close sysout
         L     13,SAVEAREA+4           * Restore caller's savearea
         LM    14,12,12(13)            * Restore caller's registers
         SR    15,15                   * Set return code to 0
         BR    14                      * Return to caller

***********************************************************************
* Data areas                                                          *
***********************************************************************
SAVEAREA DS    18F                     * Save area (72 bytes)
DOUBLE   DS    D                       * 8-byte conversion work area
ZONE     DS    CL8                     * Zoned decimal work area
OUTMSG   DS    CL80                    * Output message buffer
BLANKS   DC    CL80' '                 * Blank line for clearing

***********************************************************************
* Loop control values                                                 *
***********************************************************************
COUNT5   DC    F'5'                    * Number of BCT iterations
LIMIT    DC    F'30'                   * DO WHILE limit
STEP7    DC    F'7'                    * DO WHILE increment
START16  DC    F'16'                   * DO UNTIL starting value

***********************************************************************
* Messages                                                            *
***********************************************************************
MSG1HDR  DC    CL50'EXAMPLE 1 - COUNTED LOOP USING BCT'
MSG1ITR  DC    CL50'  BCT ITERATION NUMBER'
MSG2HDR  DC    CL50'EXAMPLE 2 - TOP TESTED LOOP (DO WHILE)'
MSG2ITR  DC    CL50'  RUNNING TOTAL'
MSG3HDR  DC    CL50'EXAMPLE 3 - BOTTOM TESTED LOOP (DO UNTIL)'
MSG3ITR  DC    CL50'  CURRENT VALUE'
MSG4     DC    CL50'EXAMPLE 4 - BCTR R11,0 DECREMENTS TO'

***********************************************************************
* DCB for SYSOUT                                                      *
***********************************************************************
SYSOUT   DCB   DSORG=PS,MACRF=PM,DDNAME=SYSOUT,                        X
               RECFM=FB,LRECL=80,BLKSIZE=0

         END   BR03LOOP
