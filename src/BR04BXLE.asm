***********************************************************************
* BR04BXLE - Loop Control With BXLE And BXH                           *
* Purpose: Use the Branch on indeX Low or Equal / High instructions.  *
*          BXLE r1,r3,target                                          *
*            r1   = index                                             *
*            r3   = increment (must be the EVEN register of a pair)   *
*            r3+1 = comparand (the limit)                             *
*          The index is incremented first, then compared.             *
*          BXLE branches while index <= limit, BXH while index > limit*
***********************************************************************
BR04BXLE CSECT
         STM   14,12,12(13)            * Save caller's registers
         LR    12,15                   * Load base register
         USING BR04BXLE,12             * Establish addressability
         ST    13,SAVEAREA+4           * Chain savearea (backward)
         LA    13,SAVEAREA             * Load address of savearea

         OPEN  (SYSOUT,(OUTPUT))       * Open sysout

***********************************************************************
* Example 1: BXLE walking a fullword table by address                 *
*            R6 = address of current element                          *
*            R8 = 4, the length of one entry                          *
*            R9 = address of the LAST entry                           *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(50),MSG1HDR      * Heading for example 1
         PUT   SYSOUT,OUTMSG           * Write heading

         SR    5,5                     * R5 = running total = 0
         LA    6,TABLE                 * R6 -> first table entry
         LA    8,4                     * R8 = increment, one fullword
         LA    9,TABLE+16              * R9 -> last table entry
LOOP1    L     3,0(,6)                 * Load the element R6 points at
         AR    5,3                     * Add it to the running total
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(50),MSG1ITR      * '  ENTRY VALUE'
         CVD   3,DOUBLE                * Element to packed decimal
         UNPK  ZONE,DOUBLE             * Unpack to zoned decimal
         OI    ZONE+7,X'F0'            * Fix sign nibble
         MVC   OUTMSG+50(8),ZONE       * Show the element
         PUT   SYSOUT,OUTMSG           * Write one line per entry
         BXLE  6,8,LOOP1               * R6 += R8, loop while R6 <= R9

         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(50),MSG1TOT      * '  TABLE TOTAL'
         CVD   5,DOUBLE                * Total to packed decimal
         UNPK  ZONE,DOUBLE             * Unpack to zoned decimal
         OI    ZONE+7,X'F0'            * Fix sign nibble
         MVC   OUTMSG+50(8),ZONE       * Show the total
         PUT   SYSOUT,OUTMSG           * Write the total line

***********************************************************************
* Example 2: BXH counting down with a negative increment              *
*            R6 = index, R8 = -1, R9 = 0                              *
*            BXH branches while the new index is HIGH than R9         *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(50),MSG2HDR      * Heading for example 2
         PUT   SYSOUT,OUTMSG           * Write heading

         L     6,START5                * R6 = 5, starting index
         LM    8,9,INCLIM              * R8 = -1 step, R9 = 0 limit
LOOP2    MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(50),MSG2ITR      * '  COUNTDOWN INDEX'
         CVD   6,DOUBLE                * Index to packed decimal
         UNPK  ZONE,DOUBLE             * Unpack to zoned decimal
         OI    ZONE+7,X'F0'            * Fix sign nibble
         MVC   OUTMSG+50(8),ZONE       * Show the index
         PUT   SYSOUT,OUTMSG           * Write one line per pass
         BXH   6,8,LOOP2               * R6 = R6 - 1, loop while R6 > 0

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
* Table of five fullwords                                             *
***********************************************************************
TABLE    DC    F'11'                   * Entry 1
         DC    F'22'                   * Entry 2
         DC    F'33'                   * Entry 3
         DC    F'44'                   * Entry 4
         DC    F'55'                   * Entry 5

***********************************************************************
* Loop control values                                                 *
***********************************************************************
START5   DC    F'5'                    * BXH starting index
INCLIM   DC    F'-1'                   * Increment loaded into R8
         DC    F'0'                    * Limit loaded into R9

***********************************************************************
* Messages                                                            *
***********************************************************************
MSG1HDR  DC    CL50'EXAMPLE 1 - BXLE WALKING A FULLWORD TABLE'
MSG1ITR  DC    CL50'  ENTRY VALUE'
MSG1TOT  DC    CL50'  TABLE TOTAL'
MSG2HDR  DC    CL50'EXAMPLE 2 - BXH COUNTING DOWN BY ONE'
MSG2ITR  DC    CL50'  COUNTDOWN INDEX'

***********************************************************************
* DCB for SYSOUT                                                      *
***********************************************************************
SYSOUT   DCB   DSORG=PS,MACRF=PM,DDNAME=SYSOUT,                        X
               RECFM=FB,LRECL=80,BLKSIZE=0

         END   BR04BXLE
