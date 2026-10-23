***********************************************************************
*                                                                     *
* BR09MTCH - Comparing Two SORTED Files (Match-Merge Processing)      *
*                                                                     *
*====================================================================**
* WHAT THIS PROGRAM DOES                                              *
*====================================================================**
* We have two input files, each containing a 10 byte customer number  *
* in columns 1-10.  BOTH FILES ARE ALREADY SORTED in ascending order  *
* on that customer number.  The program compares the two files and    *
* produces THREE output files:                                        *
*                                                                     *
*  OUT1ONLY  - customer numbers that appear in INFILE1 but NOT        *
*               in INFILE2                                            *
*  OUT2ONLY  - customer numbers that appear in INFILE2 but NOT        *
*               in INFILE1                                            *
*  OUTCOMM   - customer numbers that appear in BOTH files             *
*                                                                     *
* HOW IT WORKS - THE "MATCH-MERGE" OR "BALANCED LINE" TECHNIQUE       *
* Because both files are sorted on the SAME key, we never have to     *
* search.  We simply keep ONE current record from each file in        *
* storage and compare the two keys:                                   *
*                                                                     *
*  KEY1 = KEY2   -> the customer number is in BOTH files.             *
*                   Write it to OUTCOMM, then read the NEXT record    *
*                   from BOTH files.                                  *
*                                                                     *
*  KEY1 < KEY2   -> the file 1 key is "behind".  Since file 2 is      *
*                   sorted, nothing still to come in file 2 could     *
*                   ever match this file 1 key, so it must be a       *
*                   FILE1-ONLY record.  Write it to OUT1ONLY, then    *
*                   read only the NEXT record from file 1.            *
*                                                                     *
*  KEY1 > KEY2   -> the mirror image of the line above.  Write to     *
*                   OUT2ONLY, then read only the NEXT record from     *
*                   file 2.                                           *
*                                                                     *
* This is repeated until one file runs out of records.  Whatever is   *
* LEFT OVER in the other file cannot possibly match anything, because *
* there is nothing left on the other side to compare it to, so every  *
* remaining record of that file is simply drained out to its own      *
* "ONLY" file.                                                        *
*                                                                     *
* WHY THIS ONLY WORKS BECAUSE THE FILES ARE SORTED                    *
* The entire trick depends on being able to say "this key can never   *
* appear later in the other file because the other file only goes     *
* UP from here".  If the files were NOT sorted, a match for today's   *
* file 1 key might be sitting three records further down in file 2,   *
* or it might already have gone past - we would have to search the    *
* WHOLE of one file for every record of the other, which is far       *
* slower and needs far more storage (see the companion discussion     *
* for the unsorted case).  Sorting first is what makes this simple,   *
* single-pass, constant-storage algorithm possible.                   *
*                                                                     *
*====================================================================**
* FILES USED                                                          *
*====================================================================**
*  INFILE1  input, fixed length 10, customer numbers, SORTED          *
*  INFILE2  input, fixed length 10, customer numbers, SORTED          *
*  OUT1ONLY output, fixed length 10, in file 1 only                   *
*  OUT2ONLY output, fixed length 10, in file 2 only                   *
*  OUTCOMM  output, fixed length 10, in both files                    *
*  SYSPRINT output, fixed length 80, start/end messages and counts    *
*                                                                     *
*====================================================================**
* REGISTER USAGE                                                      *
*====================================================================**
*   R10   used like a "CALL return address" register.  BAL 10,LABEL   *
*         branches to a small routine (READ1 or READ2 below) and      *
*         remembers where to come back to.  The routine ends with     *
*         BR 10, which branches back to that saved address.  This is  *
*         how Assembler does what other languages call a subroutine   *
*         call, since there is no CALL/RETURN instruction pair.       *
*   R2    scratch register, used only briefly to check a file         *
*         opened successfully (see OPENCHK below)                     *
*   R12   base register - every label in this program is really just  *
*         "R12 plus a displacement", and USING tells the assembler    *
*         to generate code that way                                   *
*   R13   points at our save area                                     *
*   R14   return address back to whoever called this program          *
*   R15   entry point address on entry, return code on exit           *
***********************************************************************
BR09MTCH CSECT
***********************************************************************
* A000-MAINLINE - Standard entry linkage                              *
*                                                                     *
* STM saves the caller's registers 14 through 12 into the save area   *
* the caller gave us (its address came in at R13).  LR 12,15 copies   *
* our own entry point address (which OS supplies in R15) into R12, so *
* R12 becomes our base register - USING then tells the assembler that *
* every label from here on is addressed as "R12 + displacement".      *
* The two save-area instructions chain our save area backward to the  *
* caller's, which is what lets a dump trace back through callers.     *
***********************************************************************
         STM   14,12,12(13)            * Save caller's registers
         LR    12,15                   * Load base register
         USING BR09MTCH,12             * Establish addressability
         ST    13,SAVEAREA+4           * Chain savearea (backward)
         LA    13,SAVEAREA             * Load address of savearea

***********************************************************************
* Clear all our working fields BEFORE we touch any of them.  Storage  *
* is NOT automatically blanked out by the assembler - a field only    *
* defined with DS contains whatever garbage happened to be there      *
* before, so every field we will test later (like EOF1/EOF2) must be  *
* given a known starting value here.                                  *
***********************************************************************
         MVC   KEY1,BLANKS10           * No file 1 key read yet
         MVC   KEY2,BLANKS10           * No file 2 key read yet
         MVI   EOF1,C'N'               * File 1 has not ended
         MVI   EOF2,C'N'               * File 2 has not ended
         ZAP   CNT1,=P'0'              * File 1 records read     = 0
         ZAP   CNT2,=P'0'              * File 2 records read     = 0
         ZAP   CNTONLY1,=P'0'          * File 1 only, written    = 0
         ZAP   CNTONLY2,=P'0'          * File 2 only, written    = 0
         ZAP   CNTCOMM,=P'0'           * Common records, written = 0

***********************************************************************
* Open SYSPRINT FIRST, before anything else, ON PURPOSE.  If any      *
* later file fails to open, the only way we can tell anybody is to    *
* write a message to SYSPRINT - so SYSPRINT must already be usable.   *
***********************************************************************
         OPEN  (SYSPRINT,(OUTPUT))
         LA    2,SYSPRINT              * R2 -> the SYSPRINT DCB
         BAL   10,OPENCHK              * Is it open? (see routine)
         BNO   ABENDRTN                * No - cannot report, abend

         LA    1,MSGSTRT               * R1 -> 'PROGRAM STARTED' text
         MVC   PRTLINE,BLANKS80        * Clear the print line
         MVC   PRTLINE(50),0(1)        * Copy the message into it
         PUT   SYSPRINT,PRTLINE        * Write the start marker

***********************************************************************
* Now open the two input files and the three output files.  Each one  *
* is checked individually with OPENCHK so that, if one fails, the     *
* message names the EXACT file that failed rather than a vague error. *
***********************************************************************
         OPEN  (INFILE1,(INPUT))
         LA    2,INFILE1
         BAL   10,OPENCHK
         BNO   OPNERR1

         OPEN  (INFILE2,(INPUT))
         LA    2,INFILE2
         BAL   10,OPENCHK
         BNO   OPNERR2

         OPEN  (OUT1ONLY,(OUTPUT))
         LA    2,OUT1ONLY
         BAL   10,OPENCHK
         BNO   OPNERR3

         OPEN  (OUT2ONLY,(OUTPUT))
         LA    2,OUT2ONLY
         BAL   10,OPENCHK
         BNO   OPNERR4

         OPEN  (OUTCOMM,(OUTPUT))
         LA    2,OUTCOMM
         BAL   10,OPENCHK
         BNO   OPNERR5
         B     PRIME

***********************************************************************
* Open failure paths - one per file, each names the file that failed  *
* before abending.  Falling through from one to the next would print  *
* the wrong name, so each ends with its own branch to ABENDRTN.       *
***********************************************************************
OPNERR1  LA    1,MSGOPN1               * 'INFILE1 OPEN ERROR'
         B     OPNERRX
OPNERR2  LA    1,MSGOPN2               * 'INFILE2 OPEN ERROR'
         B     OPNERRX
OPNERR3  LA    1,MSGOPN3               * 'OUT1ONLY OPEN ERROR'
         B     OPNERRX
OPNERR4  LA    1,MSGOPN4               * 'OUT2ONLY OPEN ERROR'
         B     OPNERRX
OPNERR5  LA    1,MSGOPN5               * 'OUTCOMM OPEN ERROR'
OPNERRX  MVC   PRTLINE,BLANKS80        * Clear the print line
         MVC   PRTLINE(50),0(1)        * Copy error message into it
         PUT   SYSPRINT,PRTLINE        * Report the file that failed
         B     ABENDRTN                * No safe way on - abend

***********************************************************************
* PRIME - read the FIRST record of each file before the main loop     *
* starts.  This is called "priming the pump".  The compare loop below *
* always looks at the CURRENT record of each file, so both files      *
* need one record loaded before the very first comparison can happen. *
* If a file is completely empty, READ1/READ2 will immediately set its *
* EOF switch to Y, and the main loop below handles that correctly.    *
***********************************************************************
PRIME    DS    0H
         BAL   10,READ1                * Load first record of file 1
         BAL   10,READ2                * Load first record of file 2

***********************************************************************
* B000-MAINLOOP - the heart of the program                            *
*                                                                     *
* Every trip around this loop looks at whichever records are          *
* currently sitting in KEY1 and KEY2 and decides ONE of four things   *
* to do, as explained in the big comment block at the top of the      *
* program.  The loop ends only when BOTH files have reached end of    *
* file.                                                               *
***********************************************************************
MAINLOOP DS    0H
         CLI   EOF1,C'Y'               * Has file 1 already ended?
         BE    CHECK2                  * Yes - has file 2 too?
         CLI   EOF2,C'Y'               * Has file 2 already ended?
         BE    FLUSH1                  * Yes, file 1 not - drain it
***********************************************************************
* Neither file has ended, so it is safe to compare their keys.        *
* CLC compares the two 10 byte fields byte by byte, left to right,    *
* exactly like comparing two words alphabetically.  BE/BL/BH test the *
* CONDITION CODE that CLC just set.                                   *
***********************************************************************
         CLC   KEY1,KEY2               * Compare the two current keys
         BE    MATCHED                 * Equal -> customer in BOTH
         BL    FLUSH1                  * KEY1 < KEY2 -> file 1 only
         B     FLUSH2                  * KEY1 > KEY2 -> file 2 only

***********************************************************************
* CHECK2 - file 1 has already ended.  All that matters now is whether *
* file 2 has ended too.  If it has, there is nothing left to compare  *
* and the whole loop is finished.  If it has not, every record left   *
* in file 2 is automatically a FILE2-ONLY record, because file 1 has  *
* nothing left to match it against.                                   *
***********************************************************************
CHECK2   DS    0H
         CLI   EOF2,C'Y'               * Has file 2 ALSO ended?
         BE    ALLDONE                 * Yes - both finished, stop
         B     FLUSH2                  * No - drain rest of file 2

***********************************************************************
* FLUSH1 - write the CURRENT file 1 record to OUT1ONLY, then read the *
* NEXT record from file 1 only.  File 2's current record is left      *
* untouched, because it has not been dealt with yet.                  *
***********************************************************************
FLUSH1   DS    0H
         MVC   OUT1REC,KEY1            * Copy key to the output area
         PUT   OUT1ONLY,OUT1REC        * Write it to file 1 only file
         AP    CNTONLY1,=P'1'          * Count a file-1-only record
         BAL   10,READ1                * Load next record from file 1
         B     MAINLOOP                * Go round and compare again

***********************************************************************
* FLUSH2 - the mirror image of FLUSH1 above, for file 2.              *
***********************************************************************
FLUSH2   DS    0H
         MVC   OUT2REC,KEY2            * Copy key to the output area
         PUT   OUT2ONLY,OUT2REC        * Write it to file 2 only file
         AP    CNTONLY2,=P'1'          * Count a file-2-only record
         BAL   10,READ2                * Load next record from file 2
         B     MAINLOOP                * Go round and compare again

***********************************************************************
* MATCHED - the two keys are IDENTICAL, so this customer number is in *
* BOTH files.  Write it ONCE to OUTCOMM, then read the NEXT record    *
* from BOTH files, since both current records have now been dealt     *
* with.                                                               *
***********************************************************************
MATCHED  DS    0H
         MVC   OUTCREC,KEY1            * Copy the matching key
*                                      * (either key would do)
         PUT   OUTCOMM,OUTCREC         * Write it to the common file
         AP    CNTCOMM,=P'1'           * Count a common record
         BAL   10,READ1                * Load next record from file 1
         BAL   10,READ2                * Load next record from file 2
         B     MAINLOOP                * Go round and compare again

***********************************************************************
* ALLDONE - both files are exhausted.  Close everything, print the    *
* final record counts, and return to whoever called this program.     *
***********************************************************************
ALLDONE  DS    0H
         CLOSE (INFILE1,,INFILE2,,OUT1ONLY,,OUT2ONLY,,OUTCOMM)

         BAL   10,PRTCNTS              * Print the five record counts

         LA    1,MSGEND                * R1 -> 'PROGRAM ENDED NORMALLY'
         MVC   PRTLINE,BLANKS80        * Clear the print line
         MVC   PRTLINE(50),0(1)        * Copy the message into it
         PUT   SYSPRINT,PRTLINE        * Write the end marker

         CLOSE (SYSPRINT)              * Closed LAST - just wrote to it

***********************************************************************
* Normal return.  Registers are restored from our save area, R15 is   *
* set to zero (a good return code), and we branch back to the caller. *
***********************************************************************
         L     13,SAVEAREA+4           * Restore caller's savearea
         LM    14,12,12(13)            * Restore caller's registers
         SR    15,15                   * Set return code to 0
         BR    14                      * Return to caller

***********************************************************************
*                                                                     *
* READ1 - read ONE record from INFILE1 into KEY1                      *
*                                                                     *
* HOW END OF FILE IS DETECTED IN QSAM                                 *
* QSAM does not give GET a "did it work" return code to test, the way *
* COBOL does with AT END.  Instead, the DCB for INFILE1 names an      *
* EODAD routine (EOF1RTN, below).  When GET finds no more records to  *
* give us, it does NOT return to the instruction after the GET at all *
* - execution jumps STRAIGHT to EOF1RTN instead.  That is why the     *
* normal path immediately below the GET can simply assume a record    *
* really was delivered into KEY1.                                     *
*                                                                     *
* QSAM is documented to preserve registers 2-13 across a GET, so R10  *
* (our saved return address) and R12 (our base register) both survive *
* untouched whichever path is taken - straight back here, or off to   *
* EOF1RTN - which is what makes "BR 10" safe in both places.          *
***********************************************************************
READ1    DS    0H                      * Routine entry point
         MVC   KEY1,BLANKS10           * Clear the key area first
         GET   INFILE1,KEY1            * Read a record (or go to EODAD)
         AP    CNT1,=P'1'              * One more file 1 record read
         BR    10                      * Return to whoever called READ1

EOF1RTN  DS    0H                      * EODAD target from INFILE1 DCB
         MVI   EOF1,C'Y'               * Remember that file 1 has ended
         MVC   KEY1,HIVALUE            * See note below on HIVALUE
         BR    10                      * Return as READ1 would have

***********************************************************************
* READ2 - the mirror image of READ1, for INFILE2.                     *
***********************************************************************
READ2    DS    0H                      * Routine entry point
         MVC   KEY2,BLANKS10           * Clear the key area first
         GET   INFILE2,KEY2            * Read a record (or go to EODAD)
         AP    CNT2,=P'1'              * One more file 2 record read
         BR    10                      * Return to whoever called READ2

EOF2RTN  DS    0H                      * EODAD target from INFILE2 DCB
         MVI   EOF2,C'Y'               * Remember that file 2 has ended
         MVC   KEY2,HIVALUE            * See note below on HIVALUE
         BR    10                      * Return as READ2 would have

***********************************************************************
* WHY KEY1/KEY2 ARE SET TO HIVALUE AT END OF FILE                     *
* The main loop ALWAYS checks the EOF switches first, so in this      *
* program the CLC compare is never actually reached once a file has   *
* ended - CHECK2/FLUSH1/FLUSH2 take over instead.  HIVALUE is set     *
* anyway purely as a SAFETY NET: X'FF' bytes compare HIGHER than any  *
* ordinary printable character, so even if a future change to this    *
* program accidentally let a stale key reach the CLC, it could never  *
* be mistaken for a real match.  Defensive touches like this are a    *
* good habit once you are comfortable with the basic logic.           *
***********************************************************************

***********************************************************************
*                                                                     *
* OPENCHK - test whether the DCB pointed to by R2 really opened       *
*                                                                     *
* OPEN is a MACRO, not a single machine instruction - it expands into *
* many instructions and does not hand back a simple yes/no answer we  *
* can test directly.  The way to find out whether a file opened is    *
* to look INSIDE its DCB at the one byte flag field DCBOFLGS, and test*
* the single bit named DCBOFOPN within it.                            *
*                                                                     *
* To address a field INSIDE the DCB we need a MAP of the DCB's        *
* layout.  The DCBD macro near the end of this program generates that *
* map as a dummy section (DSECT) called IHADCB - a template that      *
* describes the layout without reserving any storage of its own.      *
* USING IHADCB,2 tells the assembler "pretend that template starts    *
* wherever R2 is pointing right now", so DCBOFLGS below really means  *
* "the DCBOFLGS byte of whichever DCB R2 happens to address".  DROP   *
* cancels that pretence once we are done with it.                     *
*                                                                     *
* TM = Test under Mask.  It looks only at the bit positions that are  *
* 1 in the mask operand (DCBOFOPN) and sets the condition code from   *
* just those bits.  BNO after a TM means "branch if the tested bits   *
* are NOT all one", i.e. branch when the open bit is OFF, meaning the *
* open failed.  Callers of this routine test that same condition code *
* with their own BNO immediately after BAL 10,OPENCHK.                *
***********************************************************************
OPENCHK  DS    0H                      * Entry point, R2 -> a DCB
         USING IHADCB,2                * Map the DCB fields over R2
         TM    DCBOFLGS,DCBOFOPN       * Is the open-success bit on?
         DROP  2                       * Finished with that mapping
         BR    10                      * Return - CC is the answer

***********************************************************************
*                                                                     *
* PRTCNTS - print the five record counts to SYSPRINT                  *
*                                                                     *
* Each counter is held as PACKED DECIMAL (PL4), which AP (Add         *
* Packed) can update directly in storage with no register shuffling.  *
* To turn a packed number into readable text we UNPK it into a zoned  *
* decimal field, then OI (OR Immediate) the last byte with X'F0' to   *
* force a plain printable sign/digit nibble - UNPK alone can leave an *
* unprintable sign nibble in the final byte.                          *
***********************************************************************
PRTCNTS  DS    0H                      * Routine entry point
         MVC   PRTLINE,BLANKS80        * Clear the print line
         MVC   PRTLINE(20),LBL1        * 'FILE1 RECORDS READ :'
         UNPK  ZONE,CNT1               * Packed -> zoned decimal text
         OI    ZONE+6,X'F0'            * Fix the sign nibble to a digit
         MVC   PRTLINE+21(7),ZONE      * Place number after the label
         PUT   SYSPRINT,PRTLINE        * Write the line

         MVC   PRTLINE,BLANKS80
         MVC   PRTLINE(20),LBL2        * 'FILE2 RECORDS READ :'
         UNPK  ZONE,CNT2
         OI    ZONE+6,X'F0'
         MVC   PRTLINE+21(7),ZONE
         PUT   SYSPRINT,PRTLINE

         MVC   PRTLINE,BLANKS80
         MVC   PRTLINE(20),LBL3        * 'FILE1 ONLY WRITTEN :'
         UNPK  ZONE,CNTONLY1
         OI    ZONE+6,X'F0'
         MVC   PRTLINE+21(7),ZONE
         PUT   SYSPRINT,PRTLINE

         MVC   PRTLINE,BLANKS80
         MVC   PRTLINE(20),LBL4        * 'FILE2 ONLY WRITTEN :'
         UNPK  ZONE,CNTONLY2
         OI    ZONE+6,X'F0'
         MVC   PRTLINE+21(7),ZONE
         PUT   SYSPRINT,PRTLINE

         MVC   PRTLINE,BLANKS80
         MVC   PRTLINE(20),LBL5        * 'COMMON RECORDS WRITTEN:'
         UNPK  ZONE,CNTCOMM
         OI    ZONE+6,X'F0'
         MVC   PRTLINE+21(7),ZONE
         PUT   SYSPRINT,PRTLINE

         BR    10                      * Return to the caller

***********************************************************************
*                                                                     *
* ABENDRTN - something went wrong that we cannot safely recover from  *
*            (an open failure).  ABEND ends the job step with a       *
*            completion code of 999 and requests a storage dump, so   *
*            the cause can be investigated.                           *
***********************************************************************
ABENDRTN DS    0H
         ABEND 999,DUMP

***********************************************************************
* Everything below this point is DATA, not instructions.  Placing it  *
* after the last branch means the processor can never accidentally    *
* "fall into" it and try to execute it as code.                       *
***********************************************************************
SAVEAREA DS    18F                     * Standard 72 byte save area
*                                      * (caller chain, used by STM/LM)

***********************************************************************
* Current keys and end-of-file switches                               *
***********************************************************************
KEY1     DS    CL10                    * Current customer no., file 1
KEY2     DS    CL10                    * Current customer no., file 2
EOF1     DS    CL1                     * Y = file 1 reached end of file
EOF2     DS    CL1                     * Y = file 2 reached end of file

***********************************************************************
* Output record areas - one per output file                           *
***********************************************************************
OUT1REC  DS    CL10                    * Record written to OUT1ONLY
OUT2REC  DS    CL10                    * Record written to OUT2ONLY
OUTCREC  DS    CL10                    * Record written to OUTCOMM

***********************************************************************
* Counters, held as packed decimal so AP/UNPK can work on them        *
* directly.  PL4 holds up to 7 digits, which is ample for this        *
* lesson.                                                             *
***********************************************************************
CNT1     DS    PL4                     * File 1 records read
CNT2     DS    PL4                     * File 2 records read
CNTONLY1 DS    PL4                     * Records written to OUT1ONLY
CNTONLY2 DS    PL4                     * Records written to OUT2ONLY
CNTCOMM  DS    PL4                     * Records written to OUTCOMM

ZONE     DS    CL7                     * UNPK work area before printing

***********************************************************************
* Constants                                                           *
***********************************************************************
BLANKS10 DC    CL10' '                 * 10 spaces, clears KEY1/KEY2
BLANKS80 DC    CL80' '                 * 80 spaces, clears PRTLINE
HIVALUE  DC    10X'FF'                 * Highest possible value, see
*                                      * the note after EOF2RTN above

***********************************************************************
* Messages - all CL50 so they can be moved with one fixed length MVC  *
***********************************************************************
MSGSTRT  DC    CL50'BR09MTCH - PROGRAM STARTED'
MSGEND   DC    CL50'BR09MTCH - PROGRAM ENDED NORMALLY'
MSGOPN1  DC    CL50'BR09MTCH - INFILE1 OPEN ERROR'
MSGOPN2  DC    CL50'BR09MTCH - INFILE2 OPEN ERROR'
MSGOPN3  DC    CL50'BR09MTCH - OUT1ONLY OPEN ERROR'
MSGOPN4  DC    CL50'BR09MTCH - OUT2ONLY OPEN ERROR'
MSGOPN5  DC    CL50'BR09MTCH - OUTCOMM OPEN ERROR'

***********************************************************************
* Count report labels, each 20 bytes so the numeral lines up the      *
* same way in every line printed by PRTCNTS                           *
***********************************************************************
LBL1     DC    CL20'FILE1 RECORDS READ :'
LBL2     DC    CL20'FILE2 RECORDS READ :'
LBL3     DC    CL20'FILE1 ONLY WRITTEN :'
LBL4     DC    CL20'FILE2 ONLY WRITTEN :'
LBL5     DC    CL20'COMMON RECORDS WRTN:'

PRTLINE  DS    CL80                    * SYSPRINT line, built then PUT

***********************************************************************
* FILE CONTROL BLOCKS (DCBs)                                          *
*                                                                     *
*   DDNAME     the name matched against a DD statement in the JCL     *
*   DSORG=PS   physical sequential organisation                       *
*   MACRF=GM   GET in MOVE mode - the record is copied into our area  *
*   MACRF=PM   PUT in MOVE mode - our record is copied to the buffer  *
*   EODAD      where GET branches to when there are no more records   *
*   RECFM=FB   fixed length, blocked records                          *
*   LRECL      the length of one record                               *
*   BLKSIZE=0  let the system choose an efficient block size          *
***********************************************************************
INFILE1  DCB   DSORG=PS,MACRF=GM,DDNAME=INFILE1,                       X
               EODAD=EOF1RTN,RECFM=FB,LRECL=10,BLKSIZE=0

INFILE2  DCB   DSORG=PS,MACRF=GM,DDNAME=INFILE2,                       X
               EODAD=EOF2RTN,RECFM=FB,LRECL=10,BLKSIZE=0

OUT1ONLY DCB   DSORG=PS,MACRF=PM,DDNAME=OUT1ONLY,                      X
               RECFM=FB,LRECL=10,BLKSIZE=0

OUT2ONLY DCB   DSORG=PS,MACRF=PM,DDNAME=OUT2ONLY,                      X
               RECFM=FB,LRECL=10,BLKSIZE=0

OUTCOMM  DCB   DSORG=PS,MACRF=PM,DDNAME=OUTCOMM,                       X
               RECFM=FB,LRECL=10,BLKSIZE=0

SYSPRINT DCB   DSORG=PS,MACRF=PM,DDNAME=SYSPRINT,                      X
               RECFM=FB,LRECL=80,BLKSIZE=0

         LTORG                         * Literal pool for =P'0'/=P'1'
*                                      * (packed literals used above)

***********************************************************************
* DCBD generates the IHADCB dummy section used by OPENCHK above.  It  *
* must come LAST because a DSECT ends the current control section, so *
* no further real storage may be defined after it.                    *
***********************************************************************
         DCBD  DSORG=PS,DEVD=DA        * Map of a DCB, for TM DCBOFLGS

         END   BR09MTCH
