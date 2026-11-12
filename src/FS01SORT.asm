***********************************************************************
* FS01SORT - Match-Merge With A Control Break                         *
* Purpose: MERGE two already-sorted input files on a common key (a    *
*          classic "match-merge": take the lower key from either      *
*          file next, advance only that file), while ALSO watching    *
*          for a CONTROL BREAK on a REGION field within the merged    *
*          stream - printing a SUBTOTAL every time the region changes,*
*          and a GRAND TOTAL at the very end.  Subtotals/grand total  *
*          are kept in PACKED fields.                                 *
*                                                                     *
*======================================================================
* MATCH-MERGE vs A CONTROL BREAK - TWO DIFFERENT PROBLEMS, ONE PROGRAM
*======================================================================
* MATCH-MERGE answers "which of two sorted files has the next record,
* in overall key order?" - it only ever looks at ONE record from EACH
* file at a time (the "current" record already read from it), compares
* their keys, emits/processes whichever is LOWER, and reads the NEXT
* record from ONLY that one file - the other file's current record
* stays put, unread, until it is the low one's turn.  Equal keys are
* a MATCH - both are processed together and BOTH files advance.
*
* A CONTROL BREAK answers a completely different question: "has a
* GROUPING field changed since the last record?" - it does not care
* how many files the data came from, only that the data arrives
* already grouped (here, by REGION) - a subtotal is due whenever
* REGION in the NEWLY PROCESSED record differs from the REGION seen
* last time.
*
* This program needs BOTH because the merged OUTPUT of the two files
* must itself come out in REGION order for the control break to make
* sense - which it does, because REGION is the match-merge's own key:
* merging two files already sorted by REGION produces one combined
* stream still sorted by REGION, and the control break logic can run
* against that combined stream exactly as if it had come from one
* file all along.
*
*======================================================================
* THE MERGE LOOP ITSELF
*======================================================================
* FILEA and FILEB are each primed with one record before the loop
* starts (same "priming read" idea as every earlier program's READREC)
* EOFASW / EOFBSW separately track whether EACH file has reached its
* own end - the merge is not over until BOTH are at EOF, and once ONE
* file hits EOF, the other file's remaining records must still all be
* processed (there is no more "compare" to do - everything left in the
* surviving file is simply LOWER than nothing, by definition).
*
*    IF EOFASW = EOF              only B has anything left
*        process B's record, read next B
*    ELSE IF EOFBSW = EOF         only A has anything left
*        process A's record, read next A
*    ELSE IF KEYA = KEYB          a genuine MATCH
*        process A's record (shown), read next A AND next B
*    ELSE IF KEYA < KEYB
*        process A's record, read next A
*    ELSE
*        process B's record, read next B
*
*======================================================================
* THE CONTROL BREAK - SUBTOTAL ON CHANGE, GRAND TOTAL AT THE VERY END
*======================================================================
* LASTRGN starts the run holding a value NO real region will ever
* match (binary low-values), guaranteeing the VERY FIRST record always
* looks like a "change" and primes LASTRGN correctly without a special
* case.  Every record afterward: compare its REGION to LASTRGN; a
* difference means the PREVIOUS region's group just ended - print its
* SUBTOT, ZAP it back to zero, move the new REGION into LASTRGN -
* THEN add the current record's amount into the (now reset) subtotal,
* exactly the same shape as any running total, just reset on a trigger
* instead of only once at the very start.
*
* GRANDTOT is never reset - it accumulates every record's amount for
* the life of the run, and is printed, once, after the merge loop (and
* the final pending SUBTOT) are both finished.
***********************************************************************
         PRINT NOGEN
FS01SORT CSECT
         STM   14,12,12(13)
         LR    12,15
         USING FS01SORT,12
         ST    13,SAVEAREA+4
         LA    13,SAVEAREA

         OPEN  (SYSPRINT,(OUTPUT))
         OPEN  (FILEA,(INPUT))
         OPEN  (FILEB,(INPUT))

         MVC   PRTLINE,BLANKS
         MVC   PRTLINE(50),MSGHDR
         PUT   SYSPRINT,PRTLINE

         MVI   EOFASW,C'N'
         MVI   EOFBSW,C'N'
         MVC   LASTRGN,LOWVALS    Guarantee the first record is seen
*                                   as a region CHANGE, no special case
         ZAP   SUBTOT,=P'0'
         ZAP   GRANDTOT,=P'0'

         BAL   10,READA           Prime both files
         BAL   10,READB

***********************************************************************
* MERGE LOOP                                                          *
***********************************************************************
MERGE    CLI   EOFASW,C'Y'
         BE    MRGONLYB
         CLI   EOFBSW,C'Y'
         BE    MRGONLYA

         CLC   AKEY,BKEY
         BE    MRGMATCH
         BL    MRGTAKEA
         B     MRGTAKEB

MRGONLYB CLI   EOFBSW,C'Y'
         BE    MRGDONE            Both files are now exhausted
         BAL   10,PROCB
         BAL   10,READB
         B     MERGE

MRGONLYA CLI   EOFASW,C'Y'
         BE    MRGDONE
         BAL   10,PROCA
         BAL   10,READA
         B     MERGE

MRGMATCH BAL   10,PROCA           Equal keys - a genuine match; this
*                                   lesson shows the A side's data and
*                                   advances BOTH files together
         BAL   10,READA
         BAL   10,READB
         B     MERGE

MRGTAKEA BAL   10,PROCA
         BAL   10,READA
         B     MERGE

MRGTAKEB BAL   10,PROCB
         BAL   10,READB
         B     MERGE

***********************************************************************
* MRGDONE - print the LAST pending subtotal (CTLBRK only prints a     *
*           subtotal when a NEW region STARTS, so the final region's  *
*           total is still sitting, unprinted, in SUBTOT), then the   *
*           grand total                                               *
***********************************************************************
MRGDONE  DS    0H
         BAL   9,PUTSUBT          Same R9 convention PUTSUBT uses
*                                   everywhere it is called from - see
*                                   the note in COMMON below for why
*                                   R10 is reserved for the MERGE
*                                   level and must not be reused here

         MVC   PRTLINE,BLANKS
         MVC   PRTLINE(16),=C'GRAND TOTAL   : '
         UNPK  ZONE11,GRANDTOT
         OI    ZONE11+10,X'F0'
         MVC   PRTLINE+16(11),ZONE11
         PUT   SYSPRINT,PRTLINE

         CLOSE (FILEA)
         CLOSE (FILEB)
         CLOSE (SYSPRINT)
         L     13,SAVEAREA+4
         LM    14,12,12(13)
         SR    15,15
         BR    14

***********************************************************************
* PROCA / PROCB - process "the current record", from FILEA / FILEB    *
*                 respectively - both funnel into COMMON, below, which*
*                 does the ACTUAL control break test and accumulation,*
*                 so the break logic is written exactly ONCE regardles*
*                 of which file the record came from                  *
***********************************************************************
PROCA    DS    0H
         MVC   CURRGN,AREC+8      Region is at the same offset in both
         MVC   CURKEY,AKEY
         PACK  CURAMT,AREC+14(6)  File carries the amount as CL6
*                                   zoned/character digits; PACK turns
*                                   it into packed decimal for AP
         B     COMMON

PROCB    DS    0H
         MVC   CURRGN,BREC+8
         MVC   CURKEY,BKEY
         PACK  CURAMT,BREC+14(6)
         B     COMMON

***********************************************************************
* COMMON - the control break test, shared by both files' records      *
***********************************************************************
COMMON   DS    0H
         CLC   CURRGN,LASTRGN
         BE    COMMNOBK           Same region as last time - no break
         BAL   9,PUTSUBT          Region CHANGED - print the OLD
*                                   region's subtotal and reset it.
*                                   Uses R9, NOT R10 - COMMON itself
*                                   was reached via BAL 10 (from
*                                   MERGE, through PROCA/PROCB), so
*                                   R10 still holds the LEVEL 1 return
*                                   address back into MERGE.  This
*                                   LEVEL 2 call to PUTSUBT must use a
*                                   DIFFERENT register, or it clobbers
*                                   that saved return address - the
*                                   same per-calling-level register
*                                   discipline documented for
*                                   ds02dsct.asm's BUILDTOT/ADDAMT
*                                   (LEARNING.md section 13.3).  Using
*                                   R10 here caused an infinite loop:
*                                   BR 10 at the end of COMMNOBK ended
*                                   up branching back into the MIDDLE
*                                   of COMMON instead of to MERGE.
         MVC   LASTRGN,CURRGN     NOW remember the NEW region

COMMNOBK MVC   PRTLINE,BLANKS
         MVC   PRTLINE(8),CURKEY
         MVC   PRTLINE+10(6),CURRGN
         AP    SUBTOT,CURAMT
         AP    GRANDTOT,CURAMT
         UNPK  ZONE11,CURAMT
         OI    ZONE11+10,X'F0'
         MVC   PRTLINE+20(11),ZONE11
         PUT   SYSPRINT,PRTLINE
         BR    10

***********************************************************************
* PUTSUBT - print SUBTOT labelled with the region it belongs to (the  *
*           OLD region, still in LASTRGN at the moment this is called)*
*           then reset SUBTOT to zero for the region about to start   *
***********************************************************************
PUTSUBT  DS    0H
         CLC   LASTRGN,LOWVALS    Nothing accumulated yet (very first
*                                   call, before any record at all)?
         BE    PUTSUBTX           Skip printing a meaningless subtotal
         MVC   PRTLINE,BLANKS
         MVC   PRTLINE(10),=C'SUBTOTAL -'
         MVC   PRTLINE+11(6),LASTRGN
         UNPK  ZONE11,SUBTOT
         OI    ZONE11+10,X'F0'
         MVC   PRTLINE+20(11),ZONE11
         PUT   SYSPRINT,PRTLINE
PUTSUBTX ZAP   SUBTOT,=P'0'
         BR    9                  Matches BAL 9 at both call sites
*                                   (COMMON and MRGDONE) - R9 is
*                                   PUTSUBT's OWN dedicated linkage
*                                   register, never R10, so calling
*                                   PUTSUBT never clobbers whatever
*                                   level PUTSUBT's caller is itself
*                                   nested inside

***********************************************************************
* READA / READB - priming and subsequent reads from each file         *
***********************************************************************
READA    DS    0H
         GET   FILEA,AREC
         MVC   AKEY,AREC
         BR    10
AEOF     MVI   EOFASW,C'Y'
         BR    10

READB    DS    0H
         GET   FILEB,BREC
         MVC   BKEY,BREC
         BR    10
BEOF     MVI   EOFBSW,C'Y'
         BR    10

***********************************************************************
* Data areas                                                          *
***********************************************************************
SAVEAREA DS    18F
EOFASW   DS    CL1
EOFBSW   DS    CL1
AKEY     DS    CL8
BKEY     DS    CL8
CURKEY   DS    CL8
CURRGN   DS    CL6
LASTRGN  DS    CL6
LOWVALS  DC    X'000000000000'    Binary low-values - lower than any
*                                   real region code, guaranteeing the
*                                   first comparison always "changes"
CURAMT   DS    PL6
SUBTOT   DS    PL6
GRANDTOT DS    PL6
ZONE11   DS    CL11
PRTLINE  DS    CL80
BLANKS   DC    CL80' '
MSGHDR   DC    CL50'FS01SORT - MATCH-MERGE WITH REGION CONTROL BREAK'

***********************************************************************
* Record layout, both files identical: CL8 key, CL6 region, PL6 amount*
***********************************************************************
AREC     DS    CL20
BREC     DS    CL20

FILEA    DCB   DSORG=PS,MACRF=GM,DDNAME=FILEA,                         X
               EODAD=AEOF,RECFM=FB,LRECL=20,BLKSIZE=0

FILEB    DCB   DSORG=PS,MACRF=GM,DDNAME=FILEB,                         X
               EODAD=BEOF,RECFM=FB,LRECL=20,BLKSIZE=0

SYSPRINT DCB   DSORG=PS,MACRF=PM,DDNAME=SYSPRINT,                      X
               RECFM=FB,LRECL=80,BLKSIZE=0

         LTORG

         END   FS01SORT
