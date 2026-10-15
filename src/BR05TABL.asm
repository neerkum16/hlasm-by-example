***********************************************************************
* BR05TABL - Looping Through A Table With An Index Register           *
* Purpose: Use indexed addressing  label(index)  to step through a    *
*          table of fixed length entries, controlled by BCT.          *
*          Each entry is 12 bytes:  CL8 name  +  F value              *
***********************************************************************
BR05TABL CSECT
         STM   14,12,12(13)            * Save caller's registers
         LR    12,15                   * Load base register
         USING BR05TABL,12             * Establish addressability
         ST    13,SAVEAREA+4           * Chain savearea (backward)
         LA    13,SAVEAREA             * Load address of savearea

         OPEN  (SYSOUT,(OUTPUT))       * Open sysout

         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(50),MSGHDR       * Report heading
         PUT   SYSOUT,OUTMSG           * Write heading

***********************************************************************
* Loop: R5 = offset into the table, R4 -> current entry               *
*       R6 = entries remaining, R7 = running total of the values      *
***********************************************************************
         SR    5,5                     * R5 = offset of first entry = 0
         L     6,ENTRIES               * R6 = number of entries = 4
         SR    7,7                     * R7 = running total = 0

LOOP     LA    4,TABLE(5)              * R4 -> entry at offset R5
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG+2(8),0(4)        * Name part: MVC needs pointer
*                                      * SS ops have no index field
         L     3,8(,4)                 * Value part of this entry
         AR    7,3                     * Add the value to the total

         CVD   3,DOUBLE                * Value to packed decimal
         UNPK  ZONE,DOUBLE             * Unpack to zoned decimal
         OI    ZONE+7,X'F0'            * Fix sign nibble
         MVC   OUTMSG+12(8),ZONE       * Show the value
         PUT   SYSOUT,OUTMSG           * Write the detail line

         LA    5,ENTLEN(,5)            * Step index to next entry
         BCT   6,LOOP                  * Repeat for every entry

***********************************************************************
* Print the total after the loop ends                                 *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(50),MSGTOT       * 'TOTAL OF VALUE COLUMN'
         CVD   7,DOUBLE                * Total to packed decimal
         UNPK  ZONE,DOUBLE             * Unpack to zoned decimal
         OI    ZONE+7,X'F0'            * Fix sign nibble
         MVC   OUTMSG+50(8),ZONE       * Show the total
         PUT   SYSOUT,OUTMSG           * Write the total line

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
* Table of four 12 byte entries - name CL8 then value F               *
***********************************************************************
TABLE    DS    0F                      * Force fullword alignment
         DC    CL8'PENCIL  ',F'120'
         DC    CL8'ERASER  ',F'45'
         DC    CL8'NOTEBOOK',F'310'
         DC    CL8'RULER   ',F'75'

ENTLEN   EQU   12                      * Length of one table entry
ENTRIES  DC    F'4'                    * Number of table entries

***********************************************************************
* Messages                                                            *
***********************************************************************
MSGHDR   DC    CL50'ITEM TABLE REPORT'
MSGTOT   DC    CL50'TOTAL OF VALUE COLUMN'

***********************************************************************
* DCB for SYSOUT                                                      *
***********************************************************************
SYSOUT   DCB   DSORG=PS,MACRF=PM,DDNAME=SYSOUT,                        X
               RECFM=FB,LRECL=80,BLKSIZE=0

         END   BR05TABL
