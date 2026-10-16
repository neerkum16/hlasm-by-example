***********************************************************************
* DT02ARTH - Packed Decimal Arithmetic                                *
* Purpose: Demonstrate the decimal instruction set -                  *
*          ZAP  move with sign and length adjustment                  *
*          AP   add, SP subtract, CP compare                          *
*          MP   multiply, DP divide                                   *
*          SRP  shift and round                                       *
*          MVC  byte copy, and why it is NOT the same as ZAP          *
*          All decimal instructions are SS format, work in storage,   *
*          and need no registers at all.                              *
***********************************************************************
DT02ARTH CSECT
         STM   14,12,12(13)            * Save caller's registers
         LR    12,15                   * Load base register
         USING DT02ARTH,12             * Establish addressability
         ST    13,SAVEAREA+4           * Chain savearea (backward)
         LA    13,SAVEAREA             * Load address of savearea

         OPEN  (SYSOUT,(OUTPUT))       * Open sysout

         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(50),MSGHDR       * Report heading
         PUT   SYSOUT,OUTMSG           * Write heading

***********************************************************************
* Example 1: ZAP - Zero and Add Packed                                *
*            The correct way to COPY or MOVE a packed field.          *
*            It clears the target, then adds, so it handles a target  *
*            that is longer or shorter than the source and always     *
*            leaves a valid sign.                                     *
***********************************************************************
         ZAP   WORKP(8),PACKA(4)       * WORKP = PACKA, length adjusted
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(32),MSG01        * 'ZAP WORKP,PACKA'
         LA    10,OUTMSG+32            * R10 -> where the number goes
         BAL   11,PKDISP               * Format and show WORKP
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* Example 2: ZAP with a literal is how a packed field is cleared      *
***********************************************************************
         ZAP   WORKP(8),=P'0'          * WORKP = zero, sign set to C
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(32),MSG02        * 'ZAP WORKP,=P0 (CLEAR)'
         LA    10,OUTMSG+32            * R10 -> where the number goes
         BAL   11,PKDISP               * Format and show WORKP
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* Example 3: AP - Add Packed                                          *
*            The result is placed in operand 1, which must be long    *
*            enough to hold it or a decimal overflow occurs.          *
***********************************************************************
         ZAP   WORKP(8),PACKA(4)       * Start from PACKA  (12345)
         AP    WORKP(8),PACKB(4)       * Add PACKB         (  678)
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(32),MSG03        * 'AP  12345 + 678'
         LA    10,OUTMSG+32            * R10 -> where the number goes
         BAL   11,PKDISP               * Format and show WORKP
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* Example 4: AP with a negative operand is just addition              *
*            Decimal arithmetic is fully signed, no tricks needed.    *
***********************************************************************
         ZAP   WORKP(8),PACKA(4)       * Start from PACKA  (12345)
         AP    WORKP(8),PACKC(3)       * Add PACKC         ( -250)
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(32),MSG04        * 'AP  12345 + -250'
         LA    10,OUTMSG+32            * R10 -> where the number goes
         BAL   11,PKDISP               * Format and show WORKP
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* Example 5: SP - Subtract Packed                                     *
***********************************************************************
         ZAP   WORKP(8),PACKB(4)       * Start from PACKB  (  678)
         SP    WORKP(8),PACKA(4)       * Subtract PACKA    (12345)
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(32),MSG05        * 'SP  678 - 12345'
         LA    10,OUTMSG+32            * R10 -> where the number goes
         BAL   11,PKDISP               * Format and show WORKP
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* Example 6: SP a field from itself is another way to clear it        *
***********************************************************************
         SP    WORKP(8),WORKP(8)       * WORKP = WORKP - WORKP = 0
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(32),MSG06        * 'SP  FIELD FROM ITSELF'
         LA    10,OUTMSG+32            * R10 -> where the number goes
         BAL   11,PKDISP               * Format and show WORKP
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* Example 7: CP - Compare Packed                                      *
*            Sets the condition code exactly like an arithmetic       *
*            compare, so BE / BL / BH all work.  Lengths may differ.  *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         CP    PACKA(4),PACKB(4)       * Compare 12345 with 678
         BE    CP0EQ                   * CC=0 equal
         BL    CP0LOW                  * CC=1 operand 1 low
         MVC   OUTMSG(50),MSG07HI      * CC=2 operand 1 high
         B     CP0PUT
CP0EQ    MVC   OUTMSG(50),MSG07EQ      * Equal text
         B     CP0PUT
CP0LOW   MVC   OUTMSG(50),MSG07LO      * Low text
CP0PUT   PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* Example 8: CP against a literal zero is the standard sign test      *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         CP    PACKC(3),=P'0'          * Is PACKC negative?
         BNL   CP1NN                   * Branch if not negative
         MVC   OUTMSG(50),MSG08NG      * Negative text
         B     CP1PUT
CP1NN    MVC   OUTMSG(50),MSG08PS      * Zero or positive text
CP1PUT   PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* Example 9: MP - Multiply Packed                                     *
*   RULES - operand 2 may be at most 8 bytes                          *
*         - L1 must be greater than L2                                *
*         - the high order L2 bytes of operand 1 MUST be zero,        *
*           because the product needs L1+L2 digit positions           *
*   Using ZAP into an 8 byte field first guarantees the leading       *
*   zero bytes, which is why MP is almost always preceded by ZAP.     *
***********************************************************************
         ZAP   MULT(8),PACKA(4)        * MULT = 12345, leading zeros
         MP    MULT(8),PACKB(4)        * MULT = 12345 * 678
         ZAP   WORKP(8),MULT(8)        * Copy for display
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(32),MSG09        * 'MP  12345 * 678'
         LA    10,OUTMSG+32            * R10 -> where the number goes
         BAL   11,PKDISP               * Format and show WORKP
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* Example 10: DP - Divide Packed                                      *
*   The dividend is operand 1.  After the divide operand 1 holds      *
*   TWO fields side by side -                                         *
*     quotient  = the first  L1-L2 bytes                              *
*     remainder = the last   L2    bytes                              *
*   The remainder carries the sign of the dividend.                   *
*   Here L1=8 and L2=4, so quotient is DIVD(4), remainder DIVD+4(4).  *
***********************************************************************
         ZAP   DIVD(8),PACKA(4)        * Dividend = 12345
         DP    DIVD(8),PACKB(4)        * Divide by 678

         ZAP   WORKP(8),DIVD(4)        * Pick up the quotient
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(32),MSG10Q       * 'DP  12345 / 678 QUOTIENT'
         LA    10,OUTMSG+32            * R10 -> where the number goes
         BAL   11,PKDISP               * Format and show WORKP
         PUT   SYSOUT,OUTMSG           * Write the line

         ZAP   WORKP(8),DIVD+4(4)      * Pick up the remainder
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(32),MSG10R       * 'DP  12345 / 678 REMAINDER'
         LA    10,OUTMSG+32            * R10 -> where the number goes
         BAL   11,PKDISP               * Format and show WORKP
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* Example 11: SRP - Shift and Round Packed, shifting RIGHT            *
*   Operand 2 is the shift amount as a 6 bit signed value, so a       *
*   right shift of N is coded as 64-N.  Operand 3 is the rounding     *
*   digit, added to the last digit shifted out.  5 means round half   *
*   up, 0 means truncate.                                             *
*   Shifting right 2 with rounding turns 12345 into 123.              *
***********************************************************************
         ZAP   WORKP(8),PACKA(4)       * WORKP = 12345
         SRP   WORKP(8),64-2,5         * Shift right 2 digits, round
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(32),MSG11        * 'SRP RIGHT 2 ROUND 5'
         LA    10,OUTMSG+32            * R10 -> where the number goes
         BAL   11,PKDISP               * Format and show WORKP
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* Example 12: SRP shifting LEFT, which multiplies by a power of ten   *
*   A positive shift amount shifts left.  The rounding digit is       *
*   ignored on a left shift, so code it as zero.                      *
***********************************************************************
         ZAP   WORKP(8),PACKA(4)       * WORKP = 12345
         SRP   WORKP(8),2,0            * Shift left 2 = times 100
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(32),MSG12        * 'SRP LEFT 2 = TIMES 100'
         LA    10,OUTMSG+32            * R10 -> where the number goes
         BAL   11,PKDISP               * Format and show WORKP
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* Example 13: SRP right without rounding simply truncates             *
***********************************************************************
         ZAP   WORKP(8),PACKA(4)       * WORKP = 12345
         SRP   WORKP(8),64-2,0         * Shift right 2 digits, truncate
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(32),MSG13        * 'SRP RIGHT 2 TRUNCATE'
         LA    10,OUTMSG+32            * R10 -> where the number goes
         BAL   11,PKDISP               * Format and show WORKP
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* Example 14: MVC copies BYTES, it does not understand decimal data   *
*   Copying a 4 byte packed field into the FRONT of an 8 byte field   *
*   leaves the sign nibble in the middle, so the 8 byte field is no   *
*   longer a valid packed number.  ZAP is the safe instruction.       *
*   The result below is deliberately wrong - compare it to example 1. *
***********************************************************************
         ZAP   WORKP(8),=P'0'          * Start from a clean zero
         MVC   WORKP(4),PACKA          * Byte copy into FRONT - WRONG
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(32),MSG14        * 'MVC INTO FRONT - BAD SIGN'
         LA    2,WORKP                 * R2 -> field to dump in hex
         LA    3,8                     * R3 = length to dump
         LA    10,OUTMSG+32            * R10 -> where the hex goes
         BAL   11,HEXDISP              * Show raw bytes, not a number
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* Example 15: MVC is safe when it copies a WHOLE field of equal length*
***********************************************************************
         MVC   SAMELEN(4),PACKA        * Same length, byte for byte
         ZAP   WORKP(8),SAMELEN(4)     * Now it is still valid
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(32),MSG15        * 'MVC EQUAL LENGTH - OK'
         LA    10,OUTMSG+32            * R10 -> where the number goes
         BAL   11,PKDISP               * Format and show WORKP
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
* PKDISP - Internal routine, print WORKP as a signed decimal number   *
*   Entry  WORKP = the PL8 value to display                           *
*          R10   = address in OUTMSG where the number should start    *
*          R11   = return address (set by BAL)                        *
*   Output one sign character followed by 15 digits                   *
*   Note   UNPK does not produce a printable sign, so the sign is     *
*          tested with CP first and written separately.               *
***********************************************************************
PKDISP   DS    0H                      * Routine entry point
         CP    WORKP(8),=P'0'          * Test the sign of the value
         BNL   PKPOS                   * Branch if not negative
         MVI   0(10),C'-'              * Negative, write a minus sign
         B     PKUNPK
PKPOS    MVI   0(10),C'+'              * Zero or positive, write a plus
PKUNPK   UNPK  ZONE15(15),WORKP(8)     * Packed to zoned decimal
         OI    ZONE15+14,X'F0'         * Force the sign zone to F
         MVC   1(15,10),ZONE15         * Place digits after the sign
         BR    11                      * Return to the caller

***********************************************************************
* HEXDISP - Internal routine, print any field as hex digits           *
*   Entry  R2 = address, R3 = length, R10 = output address            *
*          R11 = return address (set by BAL)                          *
***********************************************************************
HEXDISP  DS    0H                      * Routine entry point
HEXLOOP  SR    5,5                     * Clear the work register
         IC    5,0(,2)                 * Insert one byte, 0 to 255
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
WORKP    DS    PL8                     * Packed accumulator, 15 digits
MULT     DS    PL8                     * Multiply work area
DIVD     DS    PL8                     * Divide work area
SAMELEN  DS    PL4                     * Same length as PACKA
ZONE15   DS    CL15                    * Zoned decimal work area
OUTMSG   DS    CL80                    * Output message buffer
BLANKS   DC    CL80' '                 * Blank line for clearing
HEXDIGIT DC    C'0123456789ABCDEF'     * Nibble to character table

***********************************************************************
* Packed decimal test values                                          *
***********************************************************************
PACKA    DC    PL4'12345'              * X'0012345C'
PACKB    DC    PL4'678'                * X'0000678C'
PACKC    DC    PL3'-250'               * X'00250D'

***********************************************************************
* Messages                                                            *
***********************************************************************
MSGHDR   DC    CL50'PACKED DECIMAL ARITHMETIC'
MSG01    DC    CL32'ZAP WORKP,PACKA'
MSG02    DC    CL32'ZAP WORKP,=P0  (CLEAR A FIELD)'
MSG03    DC    CL32'AP  12345 + 678'
MSG04    DC    CL32'AP  12345 + -250'
MSG05    DC    CL32'SP  678 - 12345'
MSG06    DC    CL32'SP  FIELD FROM ITSELF (CLEAR)'
MSG07EQ  DC    CL50'CP  PACKA IS EQUAL TO PACKB'
MSG07LO  DC    CL50'CP  PACKA IS LOW COMPARED TO PACKB'
MSG07HI  DC    CL50'CP  PACKA IS HIGH COMPARED TO PACKB'
MSG08NG  DC    CL50'CP  PACKC IS NEGATIVE'
MSG08PS  DC    CL50'CP  PACKC IS ZERO OR POSITIVE'
MSG09    DC    CL32'MP  12345 * 678'
MSG10Q   DC    CL32'DP  12345 / 678  QUOTIENT'
MSG10R   DC    CL32'DP  12345 / 678  REMAINDER'
MSG11    DC    CL32'SRP RIGHT 2 DIGITS, ROUND 5'
MSG12    DC    CL32'SRP LEFT 2 DIGITS = TIMES 100'
MSG13    DC    CL32'SRP RIGHT 2 DIGITS, TRUNCATE'
MSG14    DC    CL32'MVC INTO FRONT - BROKEN, HEX'
MSG15    DC    CL32'MVC EQUAL LENGTH - STILL VALID'

***********************************************************************
* DCB for SYSOUT                                                      *
***********************************************************************
SYSOUT   DCB   DSORG=PS,MACRF=PM,DDNAME=SYSOUT,                        X
               RECFM=FB,LRECL=80,BLKSIZE=0

         LTORG                         * Literal pool

         END   DT02ARTH
