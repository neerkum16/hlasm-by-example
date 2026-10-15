***********************************************************************
* BR08SRCH - Searching A Table With An Early Exit                     *
* Purpose: Serial search of a keyed table.  Shows the found / not     *
*          found pattern, leaving a loop early, and why SS type       *
*          instructions (CLC, MVC) need a POINTER register instead    *
*          of an index - they have no index register field.           *
*          Table entry = CL8 key + F value (12 bytes)                 *
***********************************************************************
BR08SRCH CSECT
         STM   14,12,12(13)            * Save caller's registers
         LR    12,15                   * Load base register
         USING BR08SRCH,12             * Establish addressability
         ST    13,SAVEAREA+4           * Chain savearea (backward)
         LA    13,SAVEAREA             * Load address of savearea

         OPEN  (SYSOUT,(OUTPUT))       * Open sysout

         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(50),MSGHDR       * Report heading
         PUT   SYSOUT,OUTMSG           * Write heading

***********************************************************************
* Outer loop - take each search argument in turn                      *
*       R10 -> current search argument, R9 = how many are left        *
***********************************************************************
         LA    10,SRCHLST              * R10 -> first search argument
         L     9,NSRCH                 * R9 = number of arguments

NEXTARG  MVC   SRCHKEY(8),0(10)        * Copy argument to the work key

***********************************************************************
* Inner loop - serial search of the table                             *
*       R7 -> current entry, R6 = entries left to test                *
***********************************************************************
         LA    7,TABLE                 * R7 -> first table entry
         L     6,ENTRIES               * R6 = number of entries

SEARCH   CLC   SRCHKEY(8),0(7)         * Entry matches the key?
         BE    FOUND                   * Yes - leave the loop early
         LA    7,ENTLEN(,7)            * No - point at the next entry
         BCT   6,SEARCH                * Loop while entries remain

* Falling out of the loop means every entry was tested with no match
NOTFOUND MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(8),SRCHKEY       * Show the key searched for
         MVC   OUTMSG+10(40),MSGNF     * 'NOT FOUND IN TABLE'
         B     ARGPUT                  * Go and print the result

* The early exit target - R7 still points at the matching entry
FOUND    L     3,8(,7)                 * Load the value from that entry
         MVC   OUTMSG(80),BLANKS       * Clear output line
         MVC   OUTMSG(8),SRCHKEY       * Show the key searched for
         MVC   OUTMSG+10(40),MSGFND    * 'FOUND, VALUE IS'
         CVD   3,DOUBLE                * Value to packed decimal
         UNPK  ZONE,DOUBLE             * Unpack to zoned decimal
         OI    ZONE+7,X'F0'            * Fix sign nibble
         MVC   OUTMSG+50(8),ZONE       * Show the value

ARGPUT   PUT   SYSOUT,OUTMSG           * One result line per argument
         LA    10,8(,10)               * Step to next search argument
         BCT   9,NEXTARG               * Repeat for every argument

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
SRCHKEY  DS    CL8                     * Current search argument
OUTMSG   DS    CL80                    * Output message buffer
BLANKS   DC    CL80' '                 * Blank line for clearing

***********************************************************************
* Keyed table - CL8 key followed by a fullword value                  *
***********************************************************************
TABLE    DS    0F                      * Force fullword alignment
         DC    CL8'ALPHA   ',F'100'
         DC    CL8'BRAVO   ',F'200'
         DC    CL8'CHARLIE ',F'300'
         DC    CL8'DELTA   ',F'400'

ENTLEN   EQU   12                      * Length of one table entry
ENTRIES  DC    F'4'                    * Number of table entries

***********************************************************************
* Search arguments - the last one is deliberately missing             *
***********************************************************************
SRCHLST  DC    CL8'CHARLIE '           * Should be found
         DC    CL8'ALPHA   '           * Should be found
         DC    CL8'ECHO    '           * Should NOT be found
NSRCH    DC    F'3'                    * Number of search arguments

***********************************************************************
* Messages                                                            *
***********************************************************************
MSGHDR   DC    CL50'TABLE SEARCH RESULTS'
MSGFND   DC    CL40'FOUND, VALUE IS'
MSGNF    DC    CL40'NOT FOUND IN TABLE'

***********************************************************************
* DCB for SYSOUT                                                      *
***********************************************************************
SYSOUT   DCB   DSORG=PS,MACRF=PM,DDNAME=SYSOUT,                        X
               RECFM=FB,LRECL=80,BLKSIZE=0

         END   BR08SRCH
