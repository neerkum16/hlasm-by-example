***********************************************************************
* REGCALC - Register Operations and Arithmetic                        *
* Purpose: Demonstrate loading, arithmetic, and displaying results.   *
***********************************************************************
REGCALC  CSECT
         STM   14,12,12(13)      * Save Caller's registers
         LR    12,15             * Load base register
         USING REGCALC,12        * Establish Addressability
         ST    13,SAVEAREA+4     * Chain savearea (backward)
         LA    13,SAVEAREA       * Load address of savearea

         OPEN  (SYSOUT,(OUTPUT)) * Open Sysout

***********************************************************************
* Example 1: Simple Addition                                          *
***********************************************************************
         L     3,NUM1            * Load NUM1 into R3
         L     4,NUM2            * Load NUM2 into R4

         MVC   OUTMSG(80),BLANKS * Clear output message
         MVC   OUTMSG(10),=C'ADDITION: '

* Display 1st number
         CVD   3,DOUBLE          * Convert NUM1 to packed decimal
         UNPK  ZONE,DOUBLE       * Unpack
         OI    ZONE+7,X'F0'      * Fix Sign
         MVC   OUTMSG+10(8),ZONE * Move first number

         MVC   OUTMSG+19(3),=C' + '

* Display 2nd number
         CVD   4,DOUBLE          * Convert NUM2 to packed decimal
         UNPK  ZONE,DOUBLE       * Unpack
         OI    ZONE+7,X'F0'      * Fix Sign
         MVC   OUTMSG+22(8),ZONE * Move second number

* Perform Addition
         AR    3,4               * Add R4 to R3 giving R3

         MVC   OUTMSG+31(3),=C' = '

* Display Result
         CVD   3,DOUBLE          * Convert NUM2 to packed decimal
         UNPK  ZONE,DOUBLE       * Unpack
         OI    ZONE+7,X'F0'      * Fix Sign
         MVC   OUTMSG+34(8),ZONE * Move result

         PUT   SYSOUT,OUTMSG     * Write message

***********************************************************************
* Example 2: Simple Subtraction                                       *
***********************************************************************
         L     5,NUM1            * Load NUM1 into R5
         L     6,NUM2            * Load NUM2 into R6

* Display Operands
         MVC   OUTMSG(80),BLANKS * Clear output message
         MVC   OUTMSG(13),=C'SUBTRACTION: '

         CVD   5,DOUBLE          * Convert NUM1 to packed decimal
         UNPK  ZONE,DOUBLE       * Unpack
         OI    ZONE+7,X'F0'      * Fix Sign
         MVC   OUTMSG+13(8),ZONE * First Number

         MVC   OUTMSG+22(1),=C'-' * Minus Sign

         CVD   6,DOUBLE          * Convert NUM1 to packed decimal
         UNPK  ZONE,DOUBLE       * Unpack
         OI    ZONE+7,X'F0'      * Fix Sign
         MVC   OUTMSG+24(8),ZONE * Second Number

* Perform Subtraction
         SR    5,6               * Sub R6 from R5 giving R5

* Display Result
         MVC   OUTMSG+33(1),=C'=' * Equal Sign

         CVD   5,DOUBLE          * Convert NUM1 to packed decimal
         UNPK  ZONE,DOUBLE       * Unpack
         OI    ZONE+7,X'F0'      * Fix Sign
         MVC   OUTMSG+35(8),ZONE * Result

         PUT   SYSOUT,OUTMSG     * Write message

***********************************************************************
* Example 3: Simple Multiplication                                    *
***********************************************************************
         L     7,NUM3            * Load NUM3 into R7
         L     8,NUM4            * Load NUM4 into R8

* Display Operands
         MVC   OUTMSG(80),BLANKS * Clear output message
         MVC   OUTMSG(16),=C'MULTIPLICATION: '

         CVD   7,DOUBLE          * Convert NUM1 to packed decimal
         UNPK  ZONE,DOUBLE       * Unpack
         OI    ZONE+7,X'F0'      * Fix Sign
         MVC   OUTMSG+16(8),ZONE * First Number

         MVC   OUTMSG+25(1),=C'*' * Minus Sign

         CVD   8,DOUBLE          * Convert NUM1 to packed decimal
         UNPK  ZONE,DOUBLE       * Unpack
         OI    ZONE+7,X'F0'      * Fix Sign
         MVC   OUTMSG+27(8),ZONE * Second Number

* Perform Subtraction
         MR    6,8               * Multiply R7 by R8
*                                * Result in R6:R7 pair(R7=low order)
* Display Result
         MVC   OUTMSG+36(1),=C'=' * Equal Sign

         CVD   7,DOUBLE          * Convert NUM3 to packed decimal
         UNPK  ZONE,DOUBLE       * Unpack
         OI    ZONE+7,X'F0'      * Fix Sign
         MVC   OUTMSG+38(8),ZONE * Result

         PUT   SYSOUT,OUTMSG     * Write message

***********************************************************************
* Example 4: Simple Division                                          *
***********************************************************************
         L     9,NUM1            * Load NUM1 into R9
         SR    8,8               * Clear R8 = 0
*                                * Now R8=0, R9=100
         D     8,NUM3            * Divide R8:R9 by NUM3
*                                * Quotient in R9, Remainder in R8

* Display Operands
         MVC   OUTMSG(80),BLANKS * Clear output message
         MVC   OUTMSG(10),=C'DIVISION: '

         L     10,NUM1           * Reload for display - NUM1
         CVD   10,DOUBLE         * Convert NUM1 to packed decimal
         UNPK  ZONE,DOUBLE       * Unpack
         OI    ZONE+7,X'F0'      * Fix Sign
         MVC   OUTMSG+10(8),ZONE * First Number

         MVC   OUTMSG+19(3),=C' / '

         L     10,NUM3           * Reload for display - NUM3
         CVD   10,DOUBLE         * Convert NUM1 to packed decimal
         UNPK  ZONE,DOUBLE       * Unpack
         OI    ZONE+7,X'F0'      * Fix Sign
         MVC   OUTMSG+22(8),ZONE * Second Number

* Display Result
         MVC   OUTMSG+31(3),=C' = '

         CVD   9,DOUBLE          * Convert NUM3 to packed decimal
         UNPK  ZONE,DOUBLE       * Unpack
         OI    ZONE+7,X'F0'      * Fix Sign
         MVC   OUTMSG+34(8),ZONE * Quotient

         MVC   OUTMSG+43(6),=C' REM='

         CVD   8,DOUBLE          * Convert NUM3 to packed decimal
         UNPK  ZONE,DOUBLE       * Unpack
         OI    ZONE+7,X'F0'      * Fix Sign
         MVC   OUTMSG+49(8),ZONE * Quotient

         PUT   SYSOUT,OUTMSG     * Write message

***********************************************************************
* Example 5: Load address with imediate values                        *
***********************************************************************
         LA    10,25             * Load immediate 25 into R10
         LA    11,75             * Load immediate 75 into R11

* Display Operands
         MVC   OUTMSG(80),BLANKS * Clear output message
         MVC   OUTMSG(14),=C'LOAD ADDRESS: '

         CVD   10,DOUBLE         * Convert R10 to packed decimal
         UNPK  ZONE,DOUBLE       * Unpack
         OI    ZONE+7,X'F0'      * Fix Sign
         MVC   OUTMSG+14(8),ZONE * First Number

         MVC   OUTMSG+23(3),=C' + '

         CVD   11,DOUBLE         * Convert R10 to packed decimal
         UNPK  ZONE,DOUBLE       * Unpack
         OI    ZONE+7,X'F0'      * Fix Sign
         MVC   OUTMSG+26(8),ZONE * Second Number

* Perform Addition
         AR    10,11             * Add R11 to R10 giving R10

* Display Result
         MVC   OUTMSG+35(3),=C' = '

         CVD   10,DOUBLE         * Convert NUM3 to packed decimal
         UNPK  ZONE,DOUBLE       * Unpack
         OI    ZONE+7,X'F0'      * Fix Sign
         MVC   OUTMSG+38(8),ZONE * Sum

         PUT   SYSOUT,OUTMSG     * Write message

***********************************************************************
* Close, Restore registers, and return                                *
***********************************************************************
         CLOSE (SYSOUT)          * Close Sysout
         L     13,SAVEAREA+4     * Restore caller's savearea
         LM    14,12,12(13)      * Restore caller's registers
         SR    15,15             * Set return code to 0
         BR    14                * Return to caller

***********************************************************************
* Data areas                                                          *
***********************************************************************
SAVEAREA DS    18F               * Save Area (72 bytes)
DOUBLE   DS    D                 * 8-byte work area for conversion
ZONE     DS    CL8               * Zoned decimal work area
OUTMSG   DS    CL80              * Output message buffer
BLANKS   DC    CL80' '           * Blank line for clearing

***********************************************************************
* Input numbers (fullword binary)                                     *
***********************************************************************
NUM1     DC    F'100'            * NUM1 = 100
NUM2     DC    F'50'             * NUM1 = 50
NUM3     DC    F'15'             * NUM1 = 10
NUM4     DC    F'5'              * NUM1 = 5

***********************************************************************
* DCB for SYSOUT
***********************************************************************
SYSOUT   DCB   DSORG=PS,MACRF=PM,DDNAME=SYSOUT,                        X
               RECFM=FB,LRECL=80,BLKSIZE=0

         END   REGCALC
