***********************************************************************
* BR01CMP - Compare Instructions and Conditional Branches             *
* Purpose: Show how compare instructions set the condition code (CC)  *
*          and how the extended branch mnemonics test it.             *
*          CC 0 = equal, 1 = low, 2 = high, 3 = overflow              *
***********************************************************************
BR01CMP  CSECT
         STM   14,12,12(13)            * Save caller's registers
         LR    12,15                   * Load base register
         USING BR01CMP,12              * Establish addressability
         ST    13,SAVEAREA+4           * Chain savearea (backward)
         LA    13,SAVEAREA             * Load address of savearea

         OPEN  (SYSOUT,(OUTPUT))       * Open sysout

***********************************************************************
* Example 1: CR - compare register to register (signed, arithmetic)   *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         L     3,NUMA                  * R3 = 100
         L     4,NUMB                  * R4 = 50
         CR    3,4                     * Compare R3 with R4, set CC
         BE    EX1EQ                   * CC=0 -> equal
         BL    EX1LOW                  * CC=1 -> R3 low
         B     EX1HIGH                 * CC=2 -> R3 high
EX1EQ    MVC   OUTMSG(50),MSG1EQ       * Equal text
         B     EX1PUT
EX1LOW   MVC   OUTMSG(50),MSG1LO       * Low text
         B     EX1PUT
EX1HIGH  MVC   OUTMSG(50),MSG1HI       * High text
EX1PUT   PUT   SYSOUT,OUTMSG           * Write message

***********************************************************************
* Example 2: C - compare register to a fullword in storage            *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         L     3,NUMB                  * R3 = 50
         C     3,NUMC                  * Compare R3 with NUMC (50)
         BNE   EX2NE                   * Branch if not equal
         MVC   OUTMSG(50),MSG2EQ       * Equal text
         B     EX2PUT
EX2NE    MVC   OUTMSG(50),MSG2NE       * Not equal text
EX2PUT   PUT   SYSOUT,OUTMSG           * Write message

***********************************************************************
* Example 3: CLC - compare character strings (logical, left to right) *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         CLC   NAME1(8),NAME2          * Compare 8 bytes NAME1 to NAME2
         BNH   EX3NH                   * Branch if NAME1 not high
         MVC   OUTMSG(50),MSG3HI       * NAME1 collates higher
         B     EX3PUT
EX3NH    MVC   OUTMSG(50),MSG3NH       * NAME1 not higher
EX3PUT   PUT   SYSOUT,OUTMSG           * Write message

***********************************************************************
* Example 4: CLI - compare one byte against an immediate value        *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         CLI   FLAG,C'Y'               * Is the flag byte a 'Y'?
         BE    EX4YES                  * Branch if equal
         MVC   OUTMSG(50),MSG4NO       * Flag is not Y
         B     EX4PUT
EX4YES   MVC   OUTMSG(50),MSG4YES      * Flag is Y
EX4PUT   PUT   SYSOUT,OUTMSG           * Write message

***********************************************************************
* Example 5: LTR - test a register without comparing                  *
*             LTR r,r sets CC 0=zero, 1=negative, 2=positive          *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         L     5,NUMD                  * R5 = -25
         LTR   5,5                     * Load and test R5
         BZ    EX5ZERO                 * CC=0 -> zero
         BM    EX5NEG                  * CC=1 -> negative
         MVC   OUTMSG(50),MSG5POS      * Positive text
         B     EX5PUT
EX5ZERO  MVC   OUTMSG(50),MSG5ZER      * Zero text
         B     EX5PUT
EX5NEG   MVC   OUTMSG(50),MSG5NEG      * Negative text
EX5PUT   PUT   SYSOUT,OUTMSG           * Write message

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
OUTMSG   DS    CL80                    * Output message buffer
BLANKS   DC    CL80' '                 * Blank line for clearing

***********************************************************************
* Test values                                                         *
***********************************************************************
NUMA     DC    F'100'                  * NUMA = 100
NUMB     DC    F'50'                   * NUMB = 50
NUMC     DC    F'50'                   * NUMC = 50
NUMD     DC    F'-25'                  * NUMD = -25
NAME1    DC    CL8'SMITH   '           * First name field
NAME2    DC    CL8'JONES   '           * Second name field
FLAG     DC    C'Y'                    * One byte flag

***********************************************************************
* Messages - all CL50 so every MVC can use length 50                  *
***********************************************************************
MSG1EQ   DC    CL50'CR  : NUMA IS EQUAL TO NUMB'
MSG1LO   DC    CL50'CR  : NUMA IS LOW COMPARED TO NUMB'
MSG1HI   DC    CL50'CR  : NUMA IS HIGH COMPARED TO NUMB'
MSG2EQ   DC    CL50'C   : NUMB IS EQUAL TO NUMC'
MSG2NE   DC    CL50'C   : NUMB IS NOT EQUAL TO NUMC'
MSG3HI   DC    CL50'CLC : NAME1 COLLATES HIGH TO NAME2'
MSG3NH   DC    CL50'CLC : NAME1 DOES NOT COLLATE HIGH TO NAME2'
MSG4YES  DC    CL50'CLI : FLAG BYTE IS Y'
MSG4NO   DC    CL50'CLI : FLAG BYTE IS NOT Y'
MSG5POS  DC    CL50'LTR : NUMD IS POSITIVE'
MSG5ZER  DC    CL50'LTR : NUMD IS ZERO'
MSG5NEG  DC    CL50'LTR : NUMD IS NEGATIVE'

***********************************************************************
* DCB for SYSOUT                                                      *
***********************************************************************
SYSOUT   DCB   DSORG=PS,MACRF=PM,DDNAME=SYSOUT,                        X
               RECFM=FB,LRECL=80,BLKSIZE=0

         END   BR01CMP
