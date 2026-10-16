***********************************************************************
* DT03CONV - Data Conversions                                         *
* Purpose: Walk the full conversion chain in both directions -        *
*          CHARACTER / ZONED   -- PACK -->  PACKED                    *
*          PACKED              -- CVB  -->  BINARY                    *
*          BINARY              -- CVD  -->  PACKED                    *
*          PACKED              -- UNPK -->  ZONED                     *
*          ZONED               -- OI   -->  PRINTABLE CHARACTER       *
*          PACKED              -- ED   -->  FORMATTED CHARACTER       *
*          Plus the classic blank and sign handling traps.            *
***********************************************************************
DT03CONV CSECT
         STM   14,12,12(13)            * Save caller's registers
         LR    12,15                   * Load base register
         USING DT03CONV,12             * Establish addressability
         ST    13,SAVEAREA+4           * Chain savearea (backward)
         LA    13,SAVEAREA             * Load address of savearea

         OPEN  (SYSOUT,(OUTPUT))       * Open sysout

         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(50),MSGHDR       * Report heading
         PUT   SYSOUT,OUTMSG           * Write heading

***********************************************************************
* Step 1: PACK - character digits to packed decimal                   *
*   PACK takes the DIGIT nibble of every source byte and discards the *
*   ZONE nibble, except for the last byte where the zone becomes the  *
*   sign.  Source digits are processed right to left.                 *
*   '00012345' is X'F0F0F0F1F2F3F4F5' and packs to X'0000012345F'.    *
***********************************************************************
         PACK  DOUBLE(8),CHARNUM(8)    * Character to packed
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(28),MSG01        * 'PACK FROM CHARACTER'
         MVC   OUTMSG+28(8),CHARNUM    * Show the source characters
         LA    2,DOUBLE                * R2 -> result to dump
         LA    3,8                     * R3 = length to dump
         LA    10,OUTMSG+40            * R10 -> where the hex goes
         BAL   11,HEXDISP              * Show the packed result in hex
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* Step 2: PACK - zoned decimal to packed decimal                      *
*   Zoned is the natural input to PACK, and the sign in the zone of   *
*   the last byte is carried straight into the packed sign nibble.    *
*   ZL6'-1234' is X'F0F0F1F2F3D4' and packs to X'0001234D'.           *
***********************************************************************
         PACK  DOUBLE(8),ZONEIN(6)     * Zoned to packed
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(28),MSG02        * 'PACK FROM ZONED, NEGATIVE'
         MVC   OUTMSG+28(6),ZONEIN     * Last byte prints as a letter
         LA    2,DOUBLE                * R2 -> result to dump
         LA    3,8                     * R3 = length to dump
         LA    10,OUTMSG+40            * R10 -> where the hex goes
         BAL   11,HEXDISP              * Show the packed result in hex
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* Step 3: PACK with LEADING blanks is harmless                        *
*   A blank is X'40', so its digit nibble is 0 and it simply packs    *
*   as a leading zero.  '   12345' gives the correct value.           *
***********************************************************************
         PACK  DOUBLE(8),CHARLEAD(8)   * Leading blanks are fine
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(28),MSG03        * 'PACK LEADING BLANKS - OK'
         MVC   OUTMSG+28(8),CHARLEAD   * Show the source characters
         LA    2,DOUBLE                * R2 -> result to dump
         LA    3,8                     * R3 = length to dump
         LA    10,OUTMSG+40            * R10 -> where the hex goes
         BAL   11,HEXDISP              * Show the packed result in hex
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* Step 4: PACK with TRAILING blanks is a bug                          *
*   The trailing blanks pack as zeros, so the value is multiplied by  *
*   a power of ten, AND the zone of the last blank is 4, which is an  *
*   INVALID sign.  Any later AP or CP would cause a data exception,   *
*   so the result is only dumped in hex here, never calculated with.  *
*   The fix is to right justify the digits before packing.            *
***********************************************************************
         PACK  DOUBLE(8),CHARTRL(8)    * Trailing blanks - BROKEN
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(28),MSG04        * 'PACK TRAILING BLANKS - BAD'
         MVC   OUTMSG+28(8),CHARTRL    * Show the source characters
         LA    2,DOUBLE                * R2 -> result to dump
         LA    3,8                     * R3 = length to dump
         LA    10,OUTMSG+40            * R10 -> where the hex goes
         BAL   11,HEXDISP              * Note the sign nibble is 4
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* Step 5: PACK a field that carries a TRAILING MINUS SIGN             *
*   Pack only the digit part, then build the sign nibble by hand -    *
*   NI clears the low nibble, OI sets it to D for negative.           *
***********************************************************************
         PACK  DOUBLE(8),CHARSGN(7)    * Pack the 7 digit characters
         CLI   CHARSGN+7,C'-'          * Is the trailing byte a minus?
         BNE   SGNDONE                 * No, leave the positive sign
         NI    DOUBLE+7,X'F0'          * Clear the sign nibble
         OI    DOUBLE+7,X'0D'          * Set it to D, meaning negative
SGNDONE  MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(28),MSG05        * 'PACK WITH TRAILING SIGN'
         MVC   OUTMSG+28(8),CHARSGN    * Show the source characters
         LA    2,DOUBLE                * R2 -> result to dump
         LA    3,8                     * R3 = length to dump
         LA    10,OUTMSG+40            * R10 -> where the hex goes
         BAL   11,HEXDISP              * Sign nibble is now D
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* Step 6: CVB - packed decimal to binary                              *
*   CVB needs an 8 byte DOUBLEWORD ALIGNED source and the value must  *
*   fit in 31 bits, otherwise a fixed point divide exception occurs.  *
*   This is the only way to get keyed in data into a register.        *
***********************************************************************
         PACK  DOUBLE(8),CHARNUM(8)    * Rebuild a clean 12345
         CVB   4,DOUBLE                * R4 = 12345 as binary
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(28),MSG06        * 'CVB PACKED TO BINARY, R4'
         LA    2,DOUBLE                * R2 -> the packed source
         LA    3,8                     * R3 = length to dump
         LA    10,OUTMSG+28            * R10 -> where the hex goes
         BAL   11,HEXDISP              * Show the packed input
         ST    4,BINWK                 * Save the binary result
         LA    2,BINWK                 * R2 -> the binary result
         LA    3,4                     * R3 = length to dump
         LA    10,OUTMSG+48            * R10 -> where the hex goes
         BAL   11,HEXDISP              * Show the binary output
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* Step 7: arithmetic in binary, to prove the conversion worked        *
***********************************************************************
         L     4,BINWK                 * R4 = 12345
         A     4,=F'55'                * R4 = 12400
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(28),MSG07        * 'BINARY ADD 55'
         LR    3,4                     * Copy the value for display
         LA    10,OUTMSG+28            * R10 -> where the number goes
         BAL   11,BINDISP              * Format and show R3
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* Step 8: CVD - binary back to packed decimal                         *
*   CVD is the mirror of CVB and also needs a doubleword target.      *
***********************************************************************
         CVD   4,DOUBLE                * Packed value of 12400
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(28),MSG08        * 'CVD BINARY TO PACKED'
         LA    2,DOUBLE                * R2 -> result to dump
         LA    3,8                     * R3 = length to dump
         LA    10,OUTMSG+40            * R10 -> where the hex goes
         BAL   11,HEXDISP              * Show the packed result in hex
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* Step 9: UNPK - packed decimal to zoned decimal                      *
*   UNPK is the mirror of PACK.  It writes one digit per byte with a  *
*   zone of F, except in the last byte where the SIGN becomes the     *
*   zone.  A positive result is already printable, a negative one is  *
*   not - the last byte shows as a letter.                            *
***********************************************************************
         ZAP   PACKWK(5),=P'-1234'     * A negative packed value
         UNPK  ZONE9(9),PACKWK(5)      * Packed to zoned decimal
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(28),MSG09        * 'UNPK PACKED TO ZONED'
         MVC   OUTMSG+28(9),ZONE9      * Last byte prints as a letter
         LA    2,ZONE9                 * R2 -> result to dump
         LA    3,9                     * R3 = length to dump
         LA    10,OUTMSG+40            * R10 -> where the hex goes
         BAL   11,HEXDISP              * Note the D zone in last byte
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* Step 10: zoned decimal to printable CHARACTER with OI               *
*   OI with X'F0' forces the zone of the last byte to F, which makes  *
*   the digit printable.  The sign is LOST, so test it first if it    *
*   matters.  This is the quick and dirty print method.               *
***********************************************************************
         UNPK  ZONE9(9),PACKWK(5)      * Packed to zoned decimal
         CP    PACKWK(5),=P'0'         * Test sign before destroying it
         BNL   OIPOS                   * Branch if not negative
         MVI   SIGNCHR,C'-'            * Remember it was negative
         B     OIFIX
OIPOS    MVI   SIGNCHR,C'+'            * Remember it was positive
OIFIX    OI    ZONE9+8,X'F0'           * Make the last digit printable
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(28),MSG10        * 'OI  ZONED TO CHARACTER'
         MVC   OUTMSG+28(1),SIGNCHR    * The sign kept separately
         MVC   OUTMSG+29(9),ZONE9      * All nine digits now print
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* Step 11: MVZ is the general way to move a ZONE nibble               *
*   MVZ copies only the high nibble of each byte.  Here it stamps an  *
*   F zone onto the last byte, exactly like the OI above, but it is   *
*   the instruction to reach for when zones must be moved around.     *
***********************************************************************
         UNPK  ZONE9(9),PACKWK(5)      * Fresh zoned value, negative
         MVZ   ZONE9+8(1),=X'F0'       * Move an F zone over the sign
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(28),MSG11        * 'MVZ FORCE THE ZONE TO F'
         MVC   OUTMSG+28(9),ZONE9      * All nine digits now print
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* Step 12: ED - packed decimal to FORMATTED character                 *
*   ED is the proper way to print a number.  The target is first      *
*   loaded with a PATTERN, then ED replaces the digit selectors with  *
*   digits, suppresses leading zeros, and prints the trailing sign    *
*   byte only when the value is negative.                             *
*   Pattern bytes used here -                                         *
*     X'40' fill character, a blank                                   *
*     X'20' digit selector                                            *
*     X'60' trailing minus, replaced by the fill if positive          *
*   ED DESTROYS the pattern, so it is copied into a work area first.  *
***********************************************************************
         ZAP   PACKWK(4),=P'12345'     * A positive value
         MVC   EDWORK(9),EDMASK1       * Load the pattern
         ED    EDWORK(9),PACKWK        * Edit the packed value into it
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(28),MSG12        * 'ED  SIMPLE MASK, POSITIVE'
         MVC   OUTMSG+28(9),EDWORK     * Leading zeros suppressed
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* Step 13: the same mask with a negative value shows the minus sign   *
***********************************************************************
         ZAP   PACKWK(4),=P'-12345'    * A negative value
         MVC   EDWORK(9),EDMASK1       * Reload the pattern
         ED    EDWORK(9),PACKWK        * Edit the packed value into it
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(28),MSG13        * 'ED  SIMPLE MASK, NEGATIVE'
         MVC   OUTMSG+28(9),EDWORK     * Trailing minus now prints
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* Step 14: a mask with a decimal point and a significance starter     *
*   X'21' is a significance starter - it selects a digit AND turns    *
*   zero suppression off, so digits after the decimal point always    *
*   print.  X'4B' is the period itself.                               *
***********************************************************************
         ZAP   PACKWK(4),=P'12345'     * 12345 becomes 123.45
         MVC   EDWORK(10),EDMASK2      * Load the decimal point pattern
         ED    EDWORK(10),PACKWK       * Edit the packed value into it
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(28),MSG14        * 'ED  MASK WITH DECIMAL POINT'
         MVC   OUTMSG+28(10),EDWORK    * Prints as 123.45
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* Step 15: a small value proves zero suppression is working           *
***********************************************************************
         ZAP   PACKWK(4),=P'7'         * 7 becomes 0.07
         MVC   EDWORK(10),EDMASK2      * Load the decimal point pattern
         ED    EDWORK(10),PACKWK       * Edit the packed value into it
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(28),MSG15        * 'ED  SMALL VALUE, SUPPRESSED'
         MVC   OUTMSG+28(10),EDWORK    * Prints as 0.07
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* Close, restore registers, and return                                *
***********************************************************************
         CLOSE (SYSOUT)                * Close sysout
         L     13,SAVEAREA+4           * Restore caller's savearea
         LM    14,12,12(13)            * Restore caller's registers
         SR    15,15                   * Set return code to 0
         BR    14                      * Return to caller

***********************************************************************
* BINDISP - Internal routine, print the binary value in R3            *
*   Entry  R3  = the value, R10 = output address                      *
*          R11 = return address (set by BAL)                          *
***********************************************************************
BINDISP  DS    0H                      * Routine entry point
         CVD   3,DBLDISP               * Binary to packed decimal
         UNPK  ZONE9(9),DBLDISP+3(5)   * Low order 5 bytes = 9 digits
         OI    ZONE9+8,X'F0'           * Make the last digit printable
         MVC   0(9,10),ZONE9           * Place the digits in the line
         BR    11                      * Return to the caller

***********************************************************************
* HEXDISP - Internal routine, print any field as hex digits           *
*   Entry  R2 = address, R3 = length, R10 = output address            *
*          R11 = return address (set by BAL)                          *
***********************************************************************
HEXDISP  DS    0H                      * Routine entry point
HEXLOOP  SR    5,5                     * Clear the work register
         IC    5,0(,2)                 * Insert one byte, value 0-255
         LR    6,5                     * Copy it
         SRL   6,4                     * R6 = high order nibble
         N     5,=F'15'                * R5 = low order nibble
         IC    7,HEXDIGIT(6)           * Translate the high nibble
         STC   7,0(,10)                * Store the first hex character
         IC    7,HEXDIGIT(5)           * Translate the low nibble
         STC   7,1(,10)                * Store the second hex character
         LA    10,2(,10)               * Advance the output pointer
         LA    2,1(,2)                 * Advance to the next input byte
         BCT   3,HEXLOOP               * Repeat for every byte
         BR    11                      * Return to the caller

***********************************************************************
* Work areas                                                          *
***********************************************************************
SAVEAREA DS    18F                     * Save area (72 bytes)
DOUBLE   DS    D                       * Doubleword required by CVB/CVD
DBLDISP  DS    D                       * Second doubleword for display
BINWK    DS    F                       * Binary work area
PACKWK   DS    PL5                     * Packed work area, 9 digits
ZONE9    DS    CL9                     * Zoned decimal work area
EDWORK   DS    CL16                    * Edit output work area
SIGNCHR  DS    CL1                     * Sign kept aside before OI
OUTMSG   DS    CL80                    * Output message buffer
BLANKS   DC    CL80' '                 * Blank line for clearing
HEXDIGIT DC    C'0123456789ABCDEF'     * Nibble to character table

***********************************************************************
* Edit patterns                                                       *
*   40 = fill character, 20 = digit selector,                         *
*   21 = significance starter, 4B = period, 60 = trailing minus       *
***********************************************************************
EDMASK1  DC    X'402020202020202060'   * 7 digits then a minus sign
EDMASK2  DC    X'4020202020214B202060' * 123.45 style with a minus

***********************************************************************
* Input fields                                                        *
***********************************************************************
CHARNUM  DC    CL8'00012345'           * Clean numeric characters
CHARLEAD DC    CL8'   12345'           * Leading blanks pack correctly
CHARTRL  DC    CL8'1234    '           * Trailing blanks, packs WRONG
CHARSGN  DC    CL8'0001234-'           * Digits plus a trailing minus
ZONEIN   DC    ZL6'-1234'              * Zoned decimal, negative

***********************************************************************
* Messages                                                            *
***********************************************************************
MSGHDR   DC    CL50'DATA CONVERSIONS - PACK, CVB, CVD, UNPK, ED'
MSG01    DC    CL28'PACK FROM CHARACTER'
MSG02    DC    CL28'PACK FROM ZONED, NEGATIVE'
MSG03    DC    CL28'PACK LEADING BLANKS   - OK'
MSG04    DC    CL28'PACK TRAILING BLANKS  - BAD'
MSG05    DC    CL28'PACK WITH TRAILING SIGN'
MSG06    DC    CL28'CVB PACKED TO BINARY'
MSG07    DC    CL28'BINARY ADD 55'
MSG08    DC    CL28'CVD BINARY TO PACKED'
MSG09    DC    CL28'UNPK PACKED TO ZONED'
MSG10    DC    CL28'OI  ZONED TO CHARACTER'
MSG11    DC    CL28'MVZ FORCE THE ZONE TO F'
MSG12    DC    CL28'ED  SIMPLE MASK, POSITIVE'
MSG13    DC    CL28'ED  SIMPLE MASK, NEGATIVE'
MSG14    DC    CL28'ED  MASK WITH DECIMAL POINT'
MSG15    DC    CL28'ED  SMALL VALUE SUPPRESSED'

***********************************************************************
* DCB for SYSOUT                                                      *
***********************************************************************
SYSOUT   DCB   DSORG=PS,MACRF=PM,DDNAME=SYSOUT,                        X
               RECFM=FB,LRECL=80,BLKSIZE=0

         LTORG                         * Literal pool

         END   DT03CONV
