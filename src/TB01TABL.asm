***********************************************************************
* TB01TABL - Loading A Table From A File At Run Time, BXLE, And A     *
*            Binary Search                                            *
* Purpose: Read a SORTED keyed file into an in-storage table at run   *
*          time (the table does not exist until the program builds    *
*          it), step through the finished table with BXLE, then run   *
*          a BINARY SEARCH against the same table - contrasting the   *
*          O(n) serial search from br08srch.asm with an O(log n)      *
*          search that NEEDS the table to be sorted.  The number of   *
*          entries actually loaded is kept in a register throughout.  *
*                                                                     *
*======================================================================
* BUILDING THE TABLE AT RUN TIME
*======================================================================
* Every table in br05tabl.asm / br08srch.asm was a DC list - fixed,
* known at ASSEMBLY time.  Here, TABLE is declared EMPTY storage (DS),
* sized for the WORST CASE (MAXENT entries), and LOADLOOP fills it in,
* one GET per entry, incrementing R8 (the entry COUNT) as it goes -
* R8 is the register that answers "how many entries are REALLY in the
* table", as opposed to MAXENT, which only answers "how many will FIT".
* Every later routine - BXLE stepping and the binary search alike -
* uses R8's value, never MAXENT, as the true table size.
*
*======================================================================
* BXLE - BRANCH ON INDEX LESS THAN OR EQUAL
*======================================================================
*     BXLE reg1,reg3,target
*
* reg1 is the INDEX being stepped (here, R7, the CURRENT entry's
* address).  reg3 is actually an EVEN/ODD PAIR: the even register
* (R2) holds the INCREMENT added to reg1 every time, the odd register
* (R3) holds the LIMIT reg1 is compared against.  One instruction does
* ALL of: add the increment, compare against the limit, and branch to
* target if reg1 is STILL less than or equal to the limit - the
* natural instruction for "walk a table of fixed-length entries until
* you run off the end", because the loop's own trip count never has
* to be computed or decremented separately; the ADDRESS comparison
* does the job BCT's register count normally would.
*
*     LA    7,TABLE             R7 -> first entry (the index)
*     LA    2,ENTLEN             R2 = increment (one entry's length)
*     L     3,TABLEND            R3 = address of the LAST valid entry
*     ...
* STEP BXLE  7,2,STEP            add R2 to R7, compare to R3, loop
*                                   while R7 <= R3
*
* TABLEND is computed once, right after loading, as
* TABLE + (count-1)*ENTLEN - the address of the LAST entry actually
* loaded (not MAXENT's worst case address) - BXLE's limit must reflect
* the REAL count, which is exactly why R8 was tracked during loading.
*
*======================================================================
* BINARY SEARCH - WHY IT NEEDS SORTED DATA
*======================================================================
* br08srch.asm's serial search tests every entry in order until found
* or exhausted - O(n), and works on data in ANY order. Binary search
* instead keeps LOW and HIGH entry NUMBERS bracketing where the key
* could possibly be, tests the MIDDLE entry, and - because the table
* is SORTED - a single CLC immediately eliminates HALF the remaining
* candidates: if the key is less than the middle entry, it can only be
* in the LOWER half; if greater, only the UPPER half.  Repeating that
* halves the search space every pass - O(log2 n) comparisons instead
* of O(n) - but it is CORRECT ONLY because the table is known to be in
* ascending key order; on unsorted data it would silently give wrong
* answers instead of merely being slow.
*
*     LOW  = 0                       entry NUMBERS, zero based
*     HIGH = count - 1
*     DO WHILE LOW <= HIGH
*         MID = (LOW + HIGH) / 2
*         compare key to TABLE entry MID
*         if equal            -> FOUND, stop
*         if key < entry MID  -> HIGH = MID - 1
*         if key > entry MID  -> LOW  = MID + 1
*     LOOP
*     falling out of the loop (LOW > HIGH) means NOT FOUND
*
* MID's byte ADDRESS is computed from the entry NUMBER with a multiply
* (MID * ENTLEN) and an LA, because BINSRCH works in entry NUMBERS
* (needed for the +1/-1 bracket arithmetic) while the table itself is
* addressed in BYTES - the two are only connected at the point an
* entry is actually touched.
***********************************************************************
***********************************************************************
* PRTHDR - a tiny local macro: print one CL50 header, defined here,   *
*          BEFORE the CSECT, because a macro must be DEFINED before   *
*          the assembler reaches its first USE further down           *
***********************************************************************
         MACRO
         PRTHDR &MSG
         MVC   PRTLINE,BLANKS
         MVC   PRTLINE(50),&MSG
         PUT   SYSPRINT,PRTLINE
         MEND

         PRINT NOGEN
TB01TABL CSECT
         STM   14,12,12(13)
         LR    12,15
         USING TB01TABL,12
         ST    13,SAVEAREA+4
         LA    13,SAVEAREA

         OPEN  (SYSPRINT,(OUTPUT))
         OPEN  (TABFILE,(INPUT))

         PRTHDR MSGHDR1

***********************************************************************
* LOADLOOP - read the whole file into TABLE, one entry per record,    *
*            counting entries in R8 as they arrive                    *
***********************************************************************
         LA    7,TABLE                 * R7 -> next free slot in TABLE
         SR    8,8                     * R8 = entries loaded so far = 0

LOADLOOP GET   TABFILE,0(7)            * Read directly into next slot -
*                                      * move mode GET, target IS table
         LA    8,1(,8)                 * One more entry loaded
         LA    7,ENTLEN(,7)            * Advance to the next free slot
         C     8,=F'200'               * MAXENT check - never overrun
*                                      * the table's declared size
         BNH   LOADLOOP
         DC    H'0'                    * Only reached if the file had
*                                      * more than 200 records - MAXENT
*                                      * mismatch, hard stop is safest

TABEOF   DS    0H                      * EODAD target - normal EOF
         ST    8,ENTCNT                * Keep real count - used by all
*                                      * routines from here, NOT MAXENT

         MVC   PRTLINE,BLANKS
         MVC   PRTLINE(16),=C'ENTRIES LOADED: '
         CVD   8,DOUBLE
         UNPK  ZONE7,DOUBLE
         OI    ZONE7+6,X'F0'
         MVC   PRTLINE+16(7),ZONE7
         PUT   SYSPRINT,PRTLINE

***********************************************************************
* BXLE walk - print every loaded entry, oldest style of table stepping*
*             bounded by the TRUE address of the last loaded entry    *
***********************************************************************
         PRTHDR MSGHDR2

         L     8,ENTCNT
         BCTR  8,0                     * R8 = count-1 (zero based last
*                                      * entry number)
         MH    8,=H'12'                * R8 = byte offset of last entry
*                                      * (ENTLEN = 12)
         LA    3,TABLE                 * R3 = TABLE's own address
         AR    3,8                     * R3 = address of LAST loaded
*                                      * entry - BXLE's limit register
         ST    3,TABLEND

         LA    7,TABLE                 * R7 -> first entry (BXLE index)
         LA    2,ENTLEN                * R2 = increment (BXLE even reg)

BXSTEP   DS    0H
         MVC   PRTLINE,BLANKS
         MVC   PRTLINE(8),0(7)         * This entry's key
         MVC   PRTLINE+12(4),8(7)      * This entry's value - plain
*                                      * character text in this lesson
*                                      * (CL4), so the focus stays on
*                                      * BXLE / the binary search, not
*                                      * on binary-to-text conversion
         PUT   SYSPRINT,PRTLINE

         L     3,TABLEND               * Reload R3 - limit register -
*                                      * BXLE needs BOTH halves of the
*                                      * 3,R3 pair current every time
         BXLE  7,2,BXSTEP              * Add R2 to R7, compare to R3,
*                                      * loop while R7 <= R3

***********************************************************************
* Binary search - several search arguments, some present, one missing *
***********************************************************************
         PRTHDR MSGHDR3

         LA    10,SRCHLST
         L     9,NSRCH

BSOUTER  MVC   SRCHKEY,0(10)

         SR    4,4                     * R4 = LOW entry number = 0
         L     5,ENTCNT
         BCTR  5,0                     * R5 = HIGH entry no. = count-1

BSLOOP   CR    4,5                     * LOW <= HIGH ?
         BH    BSNOTFND                * No - search space exhausted

         LR    6,4                     * R6 = LOW + HIGH, computed in a
         AR    6,5                     * scratch register...
         SRA   6,1                     * ...then halved - R6 = MID #
*                                      * (SRA keeps sign; harmless here
*                                      * as LOW/HIGH never go negative)

         LR    3,6                     * R3 = MID as a BYTE OFFSET next
         MH    3,=H'12'                * R3 = MID * ENTLEN
         LA    7,TABLE(3)              * R7 -> the MID entry itself

         CLC   SRCHKEY,0(7)            * Compare key to the MID entry
         BE    BSFOUND
         BL    BSLOWER                 * Key less - search LOWER half
         LA    4,1(,6)                 * Key is greater - LOW = MID + 1
         B     BSLOOP
BSLOWER  BCTR  6,0                     * HIGH = MID - 1
         LR    5,6
         B     BSLOOP

BSFOUND  MVC   PRTLINE,BLANKS
         MVC   PRTLINE(8),SRCHKEY
         MVC   PRTLINE+10(40),MSGFND
         MVC   PRTLINE+50(4),8(7)
         B     BSPUT

BSNOTFND MVC   PRTLINE,BLANKS
         MVC   PRTLINE(8),SRCHKEY
         MVC   PRTLINE+10(40),MSGNF

BSPUT    PUT   SYSPRINT,PRTLINE
         LA    10,8(,10)
         BCT   9,BSOUTER

         CLOSE (TABFILE)
         CLOSE (SYSPRINT)
         L     13,SAVEAREA+4
         LM    14,12,12(13)
         SR    15,15
         BR    14

***********************************************************************
* Data areas                                                          *
***********************************************************************
SAVEAREA DS    18F
DOUBLE   DS    D
ZONE7    DS    CL7
PRTLINE  DS    CL80
BLANKS   DC    CL80' '
ENTCNT   DS    F
TABLEND  DS    F
SRCHKEY  DS    CL8

MSGHDR1  DC    CL50'TB01TABL - LOADING TABLE FROM FILE'
MSGHDR2  DC    CL50'TB01TABL - BXLE WALK OF LOADED ENTRIES'
MSGHDR3  DC    CL50'TB01TABL - BINARY SEARCH RESULTS'
MSGFND   DC    CL40'FOUND, VALUE IS'
MSGNF    DC    CL40'NOT FOUND IN TABLE'

ENTLEN   EQU   12                      * Length of one table entry
MAXENT   EQU   200                     * Worst case size (TABLE's DS)

SRCHLST  DC    CL8'ALPHA   '           * Should be found
         DC    CL8'MIKE    '           * Should be found
         DC    CL8'ZULU    '           * Should NOT be found
NSRCH    DC    F'3'

***********************************************************************
* TABLE - EMPTY storage, large enough for MAXENT entries; LOADLOOP    *
*         fills in only as many as the file actually contains         *
***********************************************************************
TABLE    DS    (MAXENT)CL12

TABFILE  DCB   DSORG=PS,MACRF=GM,DDNAME=TABFILE,                       X
               EODAD=TABEOF,RECFM=FB,LRECL=12,BLKSIZE=0

SYSPRINT DCB   DSORG=PS,MACRF=PM,DDNAME=SYSPRINT,                      X
               RECFM=FB,LRECL=80,BLKSIZE=0

         LTORG

         END   TB01TABL
