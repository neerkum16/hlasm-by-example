***********************************************************************
* DS02BILD - Builder: Create Sample PARTFILE Records                  *
* Purpose: DS02DSCT reads PARTFILE records whose amount field (cols   *
*          31-35) is PACKED DECIMAL, not plain text, so the file      *
*          cannot be typed in with an ordinary editor.  This tiny     *
*          program builds a handful of valid sample records and       *
*          writes them out, ready for DS02DSCT to read.               *
*                                                                     *
* Each record matches the PARTD DSECT in DS02DSCT exactly -           *
*    cols  1- 8   part number        (CL8, character)                 *
*    cols  9-10   filler             (CL2, blank)                     *
*    cols 11-30   description        (CL20, character)                *
*    cols 31-35   amount             (PL5, PACKED DECIMAL)            *
*    cols 36-40   filler             (CL5, blank)                     *
*                                                                     *
* The only tricky part is column 31-35.  ZAP (Zero and Add Packed)    *
* is used here to load a KNOWN GOOD packed value straight from a      *
* packed literal - the same instruction used throughout dt02arth.asm  *
* to move packed fields correctly.  ZAP always leaves a valid sign    *
* nibble, which is exactly what makes the bytes "proper packed        *
* decimal" rather than just random bits that happen to be 5 bytes     *
* long.                                                               *
***********************************************************************
         PRINT NOGEN
DS02BILD CSECT
***********************************************************************
* A000-MAINLINE                                                       *
***********************************************************************
         STM   14,12,12(13)            * Save caller's registers
         LR    12,15                   * Load base register
         USING DS02BILD,12             * Establish addressability
         ST    13,SAVEAREA+4           * Chain savearea (backward)
         LA    13,SAVEAREA             * Load address of savearea

         OPEN  (PARTFILE,(OUTPUT))

***********************************************************************
* Five sample records.  Each one follows the same four step pattern:  *
*                                                                     *
*   1. Clear the record area                                          *
*   2. MVC the part number and description straight in as text        *
*   3. ZAP the amount in as PACKED DECIMAL, from a packed literal     *
*   4. PUT the finished record                                        *
*                                                                     *
* Writing it five times over, instead of a loop, keeps each record's  *
* part number, description and amount readable side by side in the    *
* source - this program only exists to build test data, so clarity    *
* matters more here than avoiding repetition.                         *
***********************************************************************
         MVC   OUTREC,BLANKS40
         MVC   OUTREC(8),=CL8'P100001'
         MVC   OUTREC+10(20),=CL20'BOLT 10MM'
         ZAP   OUTAMT,=P'12345'        * $123.45 if 2 decimals assumed
         PUT   PARTFILE,OUTREC

         MVC   OUTREC,BLANKS40
         MVC   OUTREC(8),=CL8'P100002'
         MVC   OUTREC+10(20),=CL20'WASHER FLAT'
         ZAP   OUTAMT,=P'500'
         PUT   PARTFILE,OUTREC

         MVC   OUTREC,BLANKS40
         MVC   OUTREC(8),=CL8'P100003'
         MVC   OUTREC+10(20),=CL20'HEX NUT'
         ZAP   OUTAMT,=P'99999'
         PUT   PARTFILE,OUTREC

         MVC   OUTREC,BLANKS40
         MVC   OUTREC(8),=CL8'P100004'
         MVC   OUTREC+10(20),=CL20'SPRING WASHER'
         ZAP   OUTAMT,=P'0'            * A zero amount is valid too
         PUT   PARTFILE,OUTREC

         MVC   OUTREC,BLANKS40
         MVC   OUTREC(8),=CL8'P100005'
         MVC   OUTREC+10(20),=CL20'COTTER PIN'
         ZAP   OUTAMT,=P'15099'
         PUT   PARTFILE,OUTREC

***********************************************************************
* Close, restore registers, and return                                *
***********************************************************************
         CLOSE (PARTFILE)
         L     13,SAVEAREA+4
         LM    14,12,12(13)
         SR    15,15
         BR    14

***********************************************************************
* Data areas                                                          *
***********************************************************************
SAVEAREA DS    18F
BLANKS40 DC    CL40' '

***********************************************************************
* OUTREC - the 40 byte record area, laid out IDENTICALLY to PARTD in  *
* DS02DSCT.  OUTAMT is positioned with ORG so it lands at the SAME    *
* displacement (byte 30, i.e. column 31) that PARTAMT occupies in the *
* PARTD DSECT - that alignment is the ENTIRE point of this program.   *
* If OUTAMT here and PARTAMT there ever drift apart, DS02DSCT would   *
* read garbage out of the wrong five bytes.                           *
***********************************************************************
OUTREC   DS    0CL40                   * Whole output record
         ORG   OUTREC+30               * Forward to byte 30 (column 31)
OUTAMT   DS    PL5                     * Amount, packed, 5 bytes
         ORG   OUTREC+40               * Step back to end of record,
*                                      * so next DS/DC after OUTREC is
*                                      * not accidentally overlaid

PARTFILE DCB   DSORG=PS,MACRF=PM,DDNAME=PARTFILE,                      X
               RECFM=FB,LRECL=40,BLKSIZE=0

         LTORG

         END   DS02BILD
