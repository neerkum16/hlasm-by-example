***********************************************************************
* BR06NEST - Nested Loops                                             *
* Purpose: Build a 4 by 4 multiplication table.                       *
*          Outer loop = one row, inner loop = one column.             *
*          Shows that the inner counter must be RESET on every pass   *
*          of the outer loop, and uses the explicit D(L,B) form of    *
*          MVC because MVC has no index register.                     *
***********************************************************************
BR06NEST CSECT
         STM   14,12,12(13)            * Save caller's registers
         LR    12,15                   * Load base register
         USING BR06NEST,12             * Establish addressability
         ST    13,SAVEAREA+4           * Chain savearea (backward)
         LA    13,SAVEAREA             * Load address of savearea

         OPEN  (SYSOUT,(OUTPUT))       * Open sysout

         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(50),MSGHDR       * Report heading
         PUT   SYSOUT,OUTMSG           * Write heading

***********************************************************************
* Outer loop - R6 counts rows, R4 holds the current row number        *
***********************************************************************
         L     6,ROWS                  * R6 = 4 rows to produce
         SR    4,4                     * R4 = current row number = 0

OUTER    LA    4,1(,4)                 * Next row number
         MVC   OUTMSG(80),BLANKS       * Clear the whole print line
         L     7,COLS                  * R7 = 4 cols - RESET EACH ROW
         SR    5,5                     * R5 = current column number = 0
         LA    11,OUTMSG               * R11 -> next field position

***********************************************************************
* Inner loop - one product per column                                 *
***********************************************************************
INNER    LA    5,1(,5)                 * Next column number
         LR    9,4                     * R9 = row (odd half of 8/9)
         SR    8,8                     * Clear even half of the pair
         MR    8,5                     * R8:R9 = row * column
         CVD   9,DOUBLE                * Product to packed decimal
         UNPK  ZONE,DOUBLE             * Unpack to zoned decimal
         OI    ZONE+7,X'F0'            * Fix sign nibble
         MVC   0(8,11),ZONE            * Explicit D(L,B) - store at R11
         LA    11,10(,11)              * Advance the output pointer
         BCT   7,INNER                 * Repeat for every column

         PUT   SYSOUT,OUTMSG           * One printed line per row
         BCT   6,OUTER                 * Repeat for every row

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
ROWS     DC    F'4'                    * Number of rows
COLS     DC    F'4'                    * Number of columns

***********************************************************************
* Messages                                                            *
***********************************************************************
MSGHDR   DC    CL50'4 BY 4 MULTIPLICATION TABLE'

***********************************************************************
* DCB for SYSOUT                                                      *
***********************************************************************
SYSOUT   DCB   DSORG=PS,MACRF=PM,DDNAME=SYSOUT,                        X
               RECFM=FB,LRECL=80,BLKSIZE=0

         END   BR06NEST
