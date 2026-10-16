***********************************************************************
* DT01TYPE - Assembler Data Types                                     *
* Purpose: Define one field of every common data type and print both  *
*          its character appearance and its true HEX content, so the  *
*          internal format of each type can be compared side by side. *
*          Lesson: the TYPE is just how the bytes are interpreted.    *
***********************************************************************
DT01TYPE CSECT
         STM   14,12,12(13)            * Save caller's registers
         LR    12,15                   * Load base register
         USING DT01TYPE,12             * Establish addressability
         ST    13,SAVEAREA+4           * Chain savearea (backward)
         LA    13,SAVEAREA             * Load address of savearea

         OPEN  (SYSOUT,(OUTPUT))       * Open sysout

         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(50),MSGHDR       * Report heading
         PUT   SYSOUT,OUTMSG           * Write heading

         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(50),MSGCOL       * Column heading
         PUT   SYSOUT,OUTMSG           * Write column heading

***********************************************************************
* C - Character.  One EBCDIC byte per character, no alignment.        *
*     Padded on the RIGHT with blanks (X'40') if too short.           *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(18),=CL18'CHARFLD  CL10'
         MVC   OUTMSG+18(10),CHARFLD   * Show it as characters
         LA    2,CHARFLD               * R2 -> field to dump
         LA    3,10                    * R3 = length to dump
         LA    10,OUTMSG+32            * R10 -> where the hex goes
         BAL   11,HEXDISP              * Build the hex display
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* C - Short constant padded with blanks on the right                  *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(18),=CL18'CHARPAD  CL5'
         MVC   OUTMSG+18(5),CHARPAD    * Show it as characters
         LA    2,CHARPAD               * R2 -> field to dump
         LA    3,5                     * R3 = length to dump
         LA    10,OUTMSG+32            * R10 -> where the hex goes
         BAL   11,HEXDISP              * Build the hex display
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* X - Hexadecimal.  Raw bytes, two hex digits per byte, no alignment. *
*     Padded on the LEFT with zeros - the opposite of C.              *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(18),=CL18'HEXFLD   XL4'
         MVC   OUTMSG+18(4),HEXFLD     * Mostly unprintable - expected
         LA    2,HEXFLD                * R2 -> field to dump
         LA    3,4                     * R3 = length to dump
         LA    10,OUTMSG+32            * R10 -> where the hex goes
         BAL   11,HEXDISP              * Build the hex display
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* B - Binary bit string.  Written as bits, stored as whole bytes.     *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(18),=CL18'BITFLD   B 1 BYTE'
         LA    2,BITFLD                * R2 -> field to dump
         LA    3,1                     * R3 = length to dump
         LA    10,OUTMSG+32            * R10 -> where the hex goes
         BAL   11,HEXDISP              * Build the hex display
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* F - Fullword binary.  4 bytes, twos complement, fullword aligned.   *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(18),=CL18'BINFULL  F 1234'
         LA    2,BINFULL               * R2 -> field to dump
         LA    3,4                     * R3 = length to dump
         LA    10,OUTMSG+32            * R10 -> where the hex goes
         BAL   11,HEXDISP              * Build the hex display
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* F negative - twos complement, note the leading FF bytes             *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(18),=CL18'BINNEG   F -1234'
         LA    2,BINNEG                * R2 -> field to dump
         LA    3,4                     * R3 = length to dump
         LA    10,OUTMSG+32            * R10 -> where the hex goes
         BAL   11,HEXDISP              * Build the hex display
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* H - Halfword binary.  2 bytes, halfword aligned.                    *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(18),=CL18'BINHALF  H -25'
         LA    2,BINHALF               * R2 -> field to dump
         LA    3,2                     * R3 = length to dump
         LA    10,OUTMSG+32            * R10 -> where the hex goes
         BAL   11,HEXDISP              * Build the hex display
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* P - Packed decimal.  TWO digits per byte, sign in the LOW nibble    *
*     of the LAST byte.  C = positive, D = negative, F = unsigned.    *
*     PL4 holds 7 digits plus the sign.                               *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(18),=CL18'PACKPOS  PL4 1234'
         LA    2,PACKPOS               * R2 -> field to dump
         LA    3,4                     * R3 = length to dump
         LA    10,OUTMSG+32            * R10 -> where the hex goes
         BAL   11,HEXDISP              * Build the hex display
         PUT   SYSOUT,OUTMSG           * Write the line

         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(18),=CL18'PACKNEG  PL4 -1234'
         LA    2,PACKNEG               * R2 -> field to dump
         LA    3,4                     * R3 = length to dump
         LA    10,OUTMSG+32            * R10 -> where the hex goes
         BAL   11,HEXDISP              * Build the hex display
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* Z - Zoned decimal.  ONE digit per byte, zone F in every byte except *
*     the last, where the zone nibble carries the sign.               *
*     Positive zoned decimal is identical to printable characters.    *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(18),=CL18'ZONEPOS  ZL6 1234'
         MVC   OUTMSG+18(6),ZONEPOS    * Prints as 001234
         LA    2,ZONEPOS               * R2 -> field to dump
         LA    3,6                     * R3 = length to dump
         LA    10,OUTMSG+32            * R10 -> where the hex goes
         BAL   11,HEXDISP              * Build the hex display
         PUT   SYSOUT,OUTMSG           * Write the line

         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(18),=CL18'ZONENEG  ZL6 -1234'
         MVC   OUTMSG+18(6),ZONENEG    * Last byte prints as M, not 4
         LA    2,ZONENEG               * R2 -> field to dump
         LA    3,6                     * R3 = length to dump
         LA    10,OUTMSG+32            * R10 -> where the hex goes
         BAL   11,HEXDISP              * Build the hex display
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* A - Address constant.  4 byte address, fullword aligned.            *
*     Y is the 2 byte form.  V is an external address.                *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(18),=CL18'ADDRFLD  A(DT01TYPE)'
         LA    2,ADDRFLD               * R2 -> field to dump
         LA    3,4                     * R3 = length to dump
         LA    10,OUTMSG+32            * R10 -> where the hex goes
         BAL   11,HEXDISP              * Build the hex display
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* E - Short floating point.  4 bytes, hex exponent plus fraction.     *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(18),=CL18'FLOATFL  E 1.5'
         LA    2,FLOATFL               * R2 -> field to dump
         LA    3,4                     * R3 = length to dump
         LA    10,OUTMSG+32            * R10 -> where the hex goes
         BAL   11,HEXDISP              * Build the hex display
         PUT   SYSOUT,OUTMSG           * Write the line

***********************************************************************
* The same four bytes seen as three different types                   *
* OVERLAY is one fullword that is also mapped as characters and hex   *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(50),MSGOVL       * Explain the overlay
         PUT   SYSOUT,OUTMSG           * Write the line

         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(18),=CL18'  AS CHARACTER'
         MVC   OUTMSG+18(4),OVLCHAR    * Same bytes as characters
         LA    2,OVLCHAR               * R2 -> field to dump
         LA    3,4                     * R3 = length to dump
         LA    10,OUTMSG+32            * R10 -> where the hex goes
         BAL   11,HEXDISP              * Build the hex display
         PUT   SYSOUT,OUTMSG           * Write the line

         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(18),=CL18'  AS BINARY'
         L     4,OVLFULL               * Same bytes as a fullword
         CVD   4,DOUBLE                * Convert to packed decimal
         UNPK  ZONE,DOUBLE             * Unpack to zoned decimal
         OI    ZONE+7,X'F0'            * Fix sign nibble so it prints
         MVC   OUTMSG+18(8),ZONE       * Show the decimal value
         LA    2,OVLFULL               * R2 -> field to dump
         LA    3,4                     * R3 = length to dump
         LA    10,OUTMSG+32            * R10 -> where the hex goes
         BAL   11,HEXDISP              * Build the hex display
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
* HEXDISP - Internal routine, print any field as hex digits           *
*   Entry  R2  = address of the field to dump                         *
*          R3  = number of bytes to dump                              *
*          R10 = address in OUTMSG where the hex should start         *
*          R11 = return address (set by BAL)                          *
*   Uses   R2, R3, R5, R6, R7, R10                                    *
*   Method one byte at a time, split into two 4 bit nibbles, and      *
*          index into a 16 byte table of printable hex digits.        *
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
DOUBLE   DS    D                       * 8-byte work area for CVD
ZONE     DS    CL8                     * Zoned decimal work area
OUTMSG   DS    CL80                    * Output message buffer
BLANKS   DC    CL80' '                 * Blank line for clearing
HEXDIGIT DC    C'0123456789ABCDEF'     * Nibble to character table

***********************************************************************
* The data types themselves                                           *
***********************************************************************
CHARFLD  DC    CL10'ABC123'            * Character, blank padded right
CHARPAD  DC    CL5'XY'                 * Short value, blank padded
HEXFLD   DC    XL4'0001ABCD'           * Hex, zero padded on the LEFT
BITFLD   DC    B'10110011'             * Bit string, one byte = X'B3'
BINFULL  DC    F'1234'                 * Fullword binary, aligned
BINNEG   DC    F'-1234'                * Negative, twos complement
BINHALF  DC    H'-25'                  * Halfword binary, aligned
PACKPOS  DC    PL4'1234'               * Packed decimal, sign nibble C
PACKNEG  DC    PL4'-1234'              * Packed decimal, sign nibble D
ZONEPOS  DC    ZL6'1234'               * Zoned decimal, positive
ZONENEG  DC    ZL6'-1234'              * Zoned decimal, negative
ADDRFLD  DC    A(DT01TYPE)             * Address constant, aligned
FLOATFL  DC    E'1.5'                  * Short floating point

***********************************************************************
* One storage area described by three different labels                *
* OVLFULL and OVLCHAR address exactly the same four bytes             *
***********************************************************************
OVLFULL  DS    0F                      * Align, reserve nothing
OVLCHAR  DC    C'1234'                 * X'F1F2F3F4' as characters

***********************************************************************
* Messages                                                            *
***********************************************************************
MSGHDR   DC    CL50'ASSEMBLER DATA TYPES - CHARACTER AND HEX VIEW'
MSGCOL   DC    CL50'FIELD    TYPE     VALUE          HEX CONTENT'
MSGOVL   DC    CL50'SAME FOUR BYTES SEEN AS TWO DIFFERENT TYPES'

***********************************************************************
* DCB for SYSOUT                                                      *
***********************************************************************
SYSOUT   DCB   DSORG=PS,MACRF=PM,DDNAME=SYSOUT,                        X
               RECFM=FB,LRECL=80,BLKSIZE=0

         LTORG                         * Literal pool

         END   DT01TYPE
