***********************************************************************
* BR07CASE - Multi Way Decisions                                      *
* Purpose: Two ways to code a CASE / SELECT construct -               *
*          1. a cascaded IF / ELSE IF ladder of compares              *
*          2. a branch table reached by a computed branch             *
*             B BRTAB(3) where R3 = (code-1) * 4                      *
***********************************************************************
BR07CASE CSECT
         STM   14,12,12(13)            * Save caller's registers
         LR    12,15                   * Load base register
         USING BR07CASE,12             * Establish addressability
         ST    13,SAVEAREA+4           * Chain savearea (backward)
         LA    13,SAVEAREA             * Load address of savearea

         OPEN  (SYSOUT,(OUTPUT))       * Open sysout

***********************************************************************
* Example 1: IF / ELSE IF ladder using CLI on a character code        *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(50),MSG1HDR      * Heading for example 1
         PUT   SYSOUT,OUTMSG           * Write heading

         MVC   OUTMSG(80),BLANKS       * Clear output line
         CLI   GRADE,C'A'              * Is the grade an A?
         BE    GRADEA                  * Yes
         CLI   GRADE,C'B'              * Else is it a B?
         BE    GRADEB                  * Yes
         CLI   GRADE,C'C'              * Else is it a C?
         BE    GRADEC                  * Yes
         MVC   OUTMSG(50),MSGGX        * None matched - the ELSE path
         B     EX1PUT
GRADEA   MVC   OUTMSG(50),MSGGA        * Grade A text
         B     EX1PUT
GRADEB   MVC   OUTMSG(50),MSGGB        * Grade B text
         B     EX1PUT
GRADEC   MVC   OUTMSG(50),MSGGC        * Grade C text
EX1PUT   PUT   SYSOUT,OUTMSG           * Write the chosen message

***********************************************************************
* Example 2: branch table driven by a numeric code                    *
*            Loop over four codes, dispatching each one               *
***********************************************************************
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(50),MSG2HDR      * Heading for example 2
         PUT   SYSOUT,OUTMSG           * Write heading

         SR    5,5                     * R5 = offset into the code list
         L     6,NCODES                * R6 = how many codes to process

CASELOOP MVC   OUTMSG(80),BLANKS       * Clear output line
         L     3,CODES(5)              * R3 = the code to dispatch on

* Range check first - a computed branch with a bad index is fatal
         C     3,=F'1'                 * Code below the low limit?
         BL    CASEDFLT                * Yes - take the default
         C     3,=F'3'                 * Code above the high limit?
         BH    CASEDFLT                * Yes - take the default

         BCTR  3,0                     * Make the code zero based
         SLL   3,2                     * Times 4 - 4 bytes per slot
         B     BRTAB(3)                * Computed branch into the table

***********************************************************************
* The branch table - every entry must be exactly one 4 byte branch    *
***********************************************************************
BRTAB    B     CASE1                   * Slot for code 1
         B     CASE2                   * Slot for code 2
         B     CASE3                   * Slot for code 3

CASE1    MVC   OUTMSG(50),MSGC1        * Code 1 action
         B     CASEEND
CASE2    MVC   OUTMSG(50),MSGC2        * Code 2 action
         B     CASEEND
CASE3    MVC   OUTMSG(50),MSGC3        * Code 3 action
         B     CASEEND
CASEDFLT MVC   OUTMSG(50),MSGCD        * Out of range action

CASEEND  L     4,CODES(5)              * Reload the code for display
         CVD   4,DOUBLE                * Code to packed decimal
         UNPK  ZONE,DOUBLE             * Unpack to zoned decimal
         OI    ZONE+7,X'F0'            * Fix sign nibble
         MVC   OUTMSG+50(8),ZONE       * Show which code was dispatched
         PUT   SYSOUT,OUTMSG           * Write one line per code
         LA    5,4(,5)                 * Step to the next code
         BCT   6,CASELOOP              * Repeat for every code

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
* Test values                                                         *
***********************************************************************
GRADE    DC    C'B'                    * Grade letter for example 1
CODES    DC    F'2'                    * Code list for example 2
         DC    F'1'
         DC    F'3'
         DC    F'9'                    * Deliberately out of range
NCODES   DC    F'4'                    * Number of codes in the list

***********************************************************************
* Messages                                                            *
***********************************************************************
MSG1HDR  DC    CL50'EXAMPLE 1 - IF / ELSE IF LADDER WITH CLI'
MSGGA    DC    CL50'  GRADE A - EXCELLENT'
MSGGB    DC    CL50'  GRADE B - GOOD'
MSGGC    DC    CL50'  GRADE C - AVERAGE'
MSGGX    DC    CL50'  GRADE NOT RECOGNISED'
MSG2HDR  DC    CL50'EXAMPLE 2 - BRANCH TABLE WITH A COMPUTED BRANCH'
MSGC1    DC    CL50'  CASE 1 SELECTED - ADD A RECORD, CODE'
MSGC2    DC    CL50'  CASE 2 SELECTED - UPDATE A RECORD, CODE'
MSGC3    DC    CL50'  CASE 3 SELECTED - DELETE A RECORD, CODE'
MSGCD    DC    CL50'  DEFAULT TAKEN - CODE OUT OF RANGE, CODE'

***********************************************************************
* DCB for SYSOUT                                                      *
***********************************************************************
SYSOUT   DCB   DSORG=PS,MACRF=PM,DDNAME=SYSOUT,                        X
               RECFM=FB,LRECL=80,BLKSIZE=0

         LTORG                         * Literal pool for =F literals

         END   BR07CASE
