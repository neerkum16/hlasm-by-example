***********************************************************************
*                                                                     *
* QSAMPROC - Control Break Processing With QSAM Sequential Files      *
*                                                                     *
*=====================================================================*
* WHAT THIS PROGRAM DOES                                              *
*=====================================================================*
* It reads a sorted sequential file of user entitlement records and   *
* writes one comma delimited output record for each GROUP of input    *
* records.                                                            *
*                                                                     *
* A GROUP is all the consecutive input records that share the same    *
* customer number AND the same connect id.  Because the input file    *
* is already sorted on those two fields, every record of a group      *
* arrives together, so the program only has to notice when the key    *
* CHANGES.  That technique is called CONTROL BREAK processing and it  *
* is the single most common pattern in batch programming.             *
*                                                                     *
* While reading the records of one group the program sets three YES   *
* or NO indicator flags.  When the group ends it looks at the flags   *
* in priority order and decides one ACCESS classification for the     *
* whole group, then writes exactly one output record.                 *
*                                                                     *
*   Rule R1  service code ADM and access code F or C  -> HAS-ADM      *
*   Rule R2  service code CIT, EFT or WPS             -> HAS-PAY      *
*   Rule R3  service code FT and account prefix in a                  *
*            table of 32 qualifying prefixes          -> HAS-FTS      *
*                                                                     *
*   Rule R4  HAS-ADM            -> 'SYSTEM ADMINISTRATOR'             *
*            HAS-PAY or HAS-FTS -> 'REGULAR USER'                     *
*            otherwise          -> 'READ ONLY USER'                   *
*                                                                     *
*=====================================================================*
* FILES                                                               *
*=====================================================================*
*   AMHFIN    input, fixed length 559, must be sorted on the key      *
*   AMHFOUT   output, fixed length 559, comma delimited               *
*   SYSPRINT  messages, start and end markers, record counts          *
*                                                                     *
*=====================================================================*
* HOW THE PROGRAM IS LAID OUT                                         *
*=====================================================================*
* Assembler has no PERFORM verb.  A called routine is reached with    *
* BAL, which saves the RETURN ADDRESS in a register, and the routine  *
* ends with BR on that same register.  Because a routine that calls   *
* another routine would otherwise overwrite its own return address,   *
* this program gives every CALLING LEVEL its own register.            *
*                                                                     *
*   R10  level 1  routines called from the mainline                   *
*   R9   level 2  routines called from a level 1 routine              *
*   R8   level 3  routines called from a level 2 routine              *
*   R7   reserved for PRTMSG, which may be called from anywhere       *
*                                                                     *
* REGISTER USAGE                                                      *
*   R0,R1   used by macros, R1 also passes the message address        *
*   R2-R6   general work registers                                    *
*   R7-R10  routine linkage as described above                        *
*   R11     SECOND base register, covers bytes 4096 to 8191           *
*   R12     FIRST  base register, covers bytes 0 to 4095              *
*   R13     save area pointer                                         *
*   R14,R15 return address and entry point / return code              *
*                                                                     *
***********************************************************************
QSAMPROC CSECT
***********************************************************************
* A000-MAINLINE - standard entry linkage                              *
*                                                                     *
* STM saves the caller's 14 registers in the save area the caller     *
* gave us.  LR copies the entry point address from R15 into R12 and   *
* the USING tells the assembler that R12 is the base register, which  *
* is how every label in this program becomes addressable.  The two    *
* save area instructions chain our save area to the caller's so that  *
* a dump can walk back through the calling programs.                  *
*                                                                     *
* WHY THERE ARE TWO BASE REGISTERS                                    *
* Every storage reference is assembled as a base register plus a      *
* DISPLACEMENT, and that displacement is only 12 bits wide, so it can *
* reach 0 to 4095 bytes.  One base register therefore addresses just  *
* 4096 bytes of the program.  This program is larger than that, so    *
* anything past the 4096 byte mark - the literal pool and the DCBs at *
* the end - cannot be reached from R12 alone.  The assembler reports  *
* that as                                                             *
*        ASMA034E Operand ... beyond active USING range               *
*                                                                     *
* The fix is a SECOND base register covering the next 4096 bytes.     *
*   USING QSAMPROC,12,11  tells the assembler that R12 covers the     *
*                         first 4096 bytes and R11 the next 4096      *
*   LA 11,4095(,12)       R11 = start of program + 4095               *
*   LA 11,1(,11)          R11 = start of program + 4096               *
* Two LA instructions are needed because 4096 itself will not fit in  *
* a 12 bit displacement - the very limit being worked around.         *
*                                                                     *
* The order of the registers in the USING matters: the first one      *
* named covers the first 4096 bytes, the second the next, and so on.  *
***********************************************************************
         STM   14,12,12(13)            * Save caller's registers
         LR    12,15                   * Load first base register
         USING QSAMPROC,12,11          * R12 0-4095, R11 4096-8191
         LA    11,4095(,12)            * R11 = base + 4095
         LA    11,1(,11)               * R11 = base + 4096
         ST    13,SAVEAREA+4           * Chain savearea (backward)
         LA    13,SAVEAREA             * Load address of savearea

         BAL   10,INITIAL              * 1000 - initialise everything
         BAL   10,OPENFILE             * 2000 - open the files

***********************************************************************
* The start marker can only be printed AFTER the files are open.      *
* PUT works by branching to a routine whose address OPEN plants       *
* inside the DCB, so a PUT to an unopened file branches to address    *
* zero and the program fails immediately with an S0C1 operation       *
* exception.  Nothing may be written before OPEN has run.             *
***********************************************************************
         LA    1,MSGSTART              * R1 -> start message
         BAL   7,PRTMSG                * Print the start marker

         BAL   9,READINP               * 3000 - priming read

***********************************************************************
* The group loop.  This is a TOP TESTED loop - the end of file switch *
* is tested BEFORE the body runs, so an empty input file produces no  *
* output at all, which is exactly what the design asks for.           *
*                                                                     *
* One pass of this loop handles one complete group.                   *
***********************************************************************
GRPLOOP  CLI   EOFSW,C'Y'              * Has end of file been reached?
         BE    GRPDONE                 * Yes - no more groups

         BAL   10,INITGRP              * 1100 - reset group indicators
         BAL   10,SAVEKEY              * 3100 - remember group key
         BAL   10,PROCGRP              * 4000 - read records of group
         BAL   10,FINALCLS             * 5000 - decide classification
         BAL   10,BUILDOUT             * 6000 - build the output record
         BAL   10,WRITEOUT             * 7000 - write the output record

         B     GRPLOOP                 * Test for another group
GRPDONE  DS    0H                      * All groups have been processed

         BAL   10,CLOSFILE             * 8000 - close the data files
         BAL   10,PRTCNTS              * Print the record counts

***********************************************************************
* SYSPRINT is closed LAST, because PRTCNTS above is still writing to  *
* it.  Closing a file and then writing to it would branch through a   *
* cleared DCB and fail with an S0C1, exactly like writing before an   *
* OPEN.                                                               *
***********************************************************************
         CLOSE (SYSPRINT)              * Close the message file

***********************************************************************
* Normal termination.  Registers are restored from our save area and  *
* R15 is set to zero, which becomes the step return code.             *
***********************************************************************
         L     13,SAVEAREA+4           * Restore caller's savearea
         LM    14,12,12(13)            * Restore caller's registers
         SR    15,15                   * Set return code to 0
         BR    14                      * Return to caller

***********************************************************************
*                                                                     *
* 1000-INITIAL - Initialise every field the program uses              *
*                                                                     *
* The design document insists that everything is initialised at the   *
* start.  Storage is NOT automatically cleared, so a field that is    *
* only ever defined with DS contains whatever happened to be in that  *
* memory, and a program that reads it will behave unpredictably.      *
*                                                                     *
* Clearing 559 bytes needs three MVC instructions because MVC can     *
* move at most 256 bytes in one go.  BLANK256 is a 256 byte constant  *
* of spaces that all the clearing instructions copy from.             *
***********************************************************************
INITIAL  DS    0H                      * Routine entry point
         MVC   INREC(256),BLANK256     * Clear input area, part 1
         MVC   INREC+256(256),BLANK256 * Clear input area, part 2
         MVC   INREC+512(47),BLANK256  * Clear input area, part 3

         MVC   OUTAREA(256),BLANK256   * Clear output area, part 1
         MVC   OUTAREA+256(256),BLANK256 * Clear output area, part 2
         MVC   OUTAREA+512(47),BLANK256 * Clear output area, part 3

         MVI   EOFSW,C'N'              * End of file not yet reached
         MVI   FIRSTSW,C'Y'            * Header not written yet
         MVI   HASADM,C'N'             * Rule R1 indicator - off
         MVI   HASPAY,C'N'             * Rule R2 indicator - off
         MVI   HASFTS,C'N'             * Rule R3 indicator - off

         MVC   SAVCUST(8),BLANK256     * No group key saved yet
         MVC   SAVCONN(8),BLANK256     * No group key saved yet
         MVC   SAVACF2(8),BLANK256     * No correlation id saved yet
         MVC   FINALCLA(20),BLANK256   * No classification decided yet

***********************************************************************
* The two counters are PACKED DECIMAL fields rather than registers.   *
* Packed decimal is used because the counts are printed at the end,   *
* and ZAP / AP work directly in storage with no register juggling.    *
* ZAP with a packed zero literal is the normal way to clear a packed  *
* field, because it also sets a valid positive sign nibble.           *
***********************************************************************
         ZAP   READCNT,=P'0'           * Records read         = 0
         ZAP   WRITCNT,=P'0'           * Detail records written = 0
         BR    10                      * Return to the mainline

***********************************************************************
*                                                                     *
* 1100-INITGRP - Reset everything that belongs to ONE group           *
*                                                                     *
* This runs at the START of every group.  If the indicators were not  *
* reset here, a flag switched on by group 1 would still be on for     *
* group 2 and every later group would be misclassified.  Forgetting   *
* this reset is the classic control break bug.                        *
***********************************************************************
INITGRP  DS    0H                      * Routine entry point
         MVI   HASADM,C'N'             * Rule R1 indicator - off
         MVI   HASPAY,C'N'             * Rule R2 indicator - off
         MVI   HASFTS,C'N'             * Rule R3 indicator - off
         MVC   FINALCLA(20),BLANK256   * Clear the classification

         MVC   OUTAREA(256),BLANK256   * Clear output area, part 1
         MVC   OUTAREA+256(256),BLANK256 * Clear output area, part 2
         MVC   OUTAREA+512(47),BLANK256 * Clear output area, part 3
         BR    10                      * Return to the mainline

***********************************************************************
*                                                                     *
* 2000-OPENFILE - Open both files and prove that they really opened   *
*                                                                     *
* OPEN is a MACRO, not a machine instruction.  It expands into many   *
* instructions and it does NOT set a return code that can simply be   *
* tested.  The way to find out whether a file opened is to look at    *
* the DCBOFLGS byte inside the DCB itself and test the bit named      *
* DCBOFOPN.  If that bit is on the file is open and usable.           *
*                                                                     *
* To address a field INSIDE the DCB the program needs a map of the    *
* DCB layout.  The DCBD macro at the end of the program generates     *
* that map as a DSECT called IHADCB.  A DSECT describes a layout      *
* without reserving any storage - it is a template.  To use it,       *
* point a register at the real DCB and tell the assembler with        *
* USING that the template starts there.  DROP ends that association.  *
*                                                                     *
* TM = Test under Mask.  It tests only the bits that are ones in the  *
* mask.  BNO means 'branch if not ones', in other words branch when   *
* the tested bit is off, which here means the open failed.            *
*                                                                     *
* SYSPRINT IS OPENED FIRST, AND ON PURPOSE.                           *
* Every error path in this program reports itself by writing to       *
* SYSPRINT, so SYSPRINT has to be usable before anything else can go  *
* wrong.  If SYSPRINT itself fails to open there is nowhere to write  *
* a message, so that one case abends silently.                        *
***********************************************************************
OPENFILE DS    0H                      * Routine entry point
         OPEN  (SYSPRINT,(OUTPUT))     * Open the message file first

         LA    2,SYSPRINT              * R2 -> the SYSPRINT DCB
         USING IHADCB,2                * Map the DCB fields over R2
         TM    DCBOFLGS,DCBOFOPN       * Is the file actually open?
         DROP  2                       * Finished with that mapping
         BNO   ABENDRTN                * Cannot report - just abend

         OPEN  (AMHFIN,(INPUT))        * Open the input file

         LA    2,AMHFIN                * R2 -> the input DCB
         USING IHADCB,2                * Map the DCB fields over R2
         TM    DCBOFLGS,DCBOFOPN       * Is the file actually open?
         DROP  2                       * Finished with that mapping
         BNO   OPENERR1                * Bit is off - the open failed

         OPEN  (AMHFOUT,(OUTPUT))      * Open the output file

         LA    2,AMHFOUT               * R2 -> the output DCB
         USING IHADCB,2                * Map the DCB fields over R2
         TM    DCBOFLGS,DCBOFOPN       * Is the file actually open?
         DROP  2                       * Finished with that mapping
         BNO   OPENERR2                * Bit is off - the open failed

         BR    10                      * Return to the mainline

***********************************************************************
* Open failure paths.  Each one prints its own message and then falls *
* into the abend routine.  The design document is explicit that an    *
* I/O failure must never end with a quiet return code.                *
***********************************************************************
OPENERR1 LA    1,MSGOPNI               * R1 -> 'INPUT FILE OPEN ERROR'
         BAL   7,PRTMSG                * Print the message
         B     ABENDRTN                * Abend with a dump

OPENERR2 LA    1,MSGOPNO               * R1 -> 'OUTPUT FILE OPEN ERROR'
         BAL   7,PRTMSG                * Print the message
         B     ABENDRTN                * Abend with a dump

***********************************************************************
*                                                                     *
* 3000-READINP - Read one input record                                *
*                                                                     *
* The DCB is coded MACRF=GM, which means GET in MOVE mode, so GET     *
* copies the record from the system buffer into our own INREC area.   *
*                                                                     *
* HOW END OF FILE IS DETECTED                                         *
* QSAM does not return a status code the way COBOL does.  Instead     *
* the DCB names an EODAD routine.  When GET runs out of records it    *
* does NOT come back to the instruction after the GET - it branches   *
* straight to the EODAD address.  That is why the normal path below   *
* can simply assume a record was obtained.                            *
*                                                                     *
* QSAM preserves registers 2 to 13 across a GET, so when the EODAD    *
* routine gets control our base register R12 and our return address   *
* in R9 are both still intact.  That is what makes the BR 9 at the    *
* end of the end of file path work.                                   *
***********************************************************************
READINP  DS    0H                      * Routine entry point
         MVC   INREC(256),BLANK256     * Clear input area, part 1
         MVC   INREC+256(256),BLANK256 * Clear input area, part 2
         MVC   INREC+512(47),BLANK256  * Clear input area, part 3

         GET   AMHFIN,INREC            * Read one record into INREC
         AP    READCNT,=P'1'           * One more record has been read
         BR    9                       * Return to the caller

***********************************************************************
* READEOF - the EODAD exit named in the input DCB                     *
*                                                                     *
* Control arrives here INSTEAD of returning from the GET above.  The  *
* only job is to raise the end of file switch.  If not a single       *
* record was ever read then the file was empty, which is a normal     *
* condition but worth reporting, so a message is printed.             *
***********************************************************************
READEOF  MVI   EOFSW,C'Y'              * Remember input is finished
         CP    READCNT,=P'0'           * Were any records read at all?
         BNE   READEOF9                * Yes - nothing more to say
         LA    1,MSGNOREC              * R1 -> no records message
         BAL   7,PRTMSG                * Print the empty file message
READEOF9 BR    9                       * Return to READINP caller

***********************************************************************
* IOERRIN - the SYNAD exit named in the input DCB                     *
*                                                                     *
* SYNAD gets control on a genuine I/O ERROR, which is quite different *
* from end of file.  There is no safe way to carry on, so the program *
* reports the failure and abends.                                     *
***********************************************************************
IOERRIN  LA    1,MSGREADE              * R1 -> 'INPUT FILE READ ERROR'
         BAL   7,PRTMSG                * Print the message
         B     ABENDRTN                * Abend with a dump

***********************************************************************
*                                                                     *
* 3100-SAVEKEY - Remember the key of the group that is starting       *
*                                                                     *
* The record currently in INREC is the FIRST record of a new group.   *
* Its key is copied into save fields so that later records can be     *
* compared against it.  The correlation id is taken from this first   *
* record only, exactly as the design specifies.                       *
*                                                                     *
* These three MVC instructions are the ONLY place the group key is    *
* captured, which satisfies the 'no duplicated logic' standard.       *
***********************************************************************
SAVEKEY  DS    0H                      * Routine entry point
         MVC   SAVCUST(8),INCUSTNO     * Save key component 1
         MVC   SAVCONN(8),INCONNID     * Save key component 2
         MVC   SAVACF2(8),INACF2ID     * Save the correlation id
         BR    10                      * Return to the mainline

***********************************************************************
*                                                                     *
* 4000-PROCGRP - Process every record belonging to the current group  *
*                                                                     *
* This is the inner loop of the control break.  It is also a TOP      *
* TESTED loop, and it has THREE exit conditions, all tested before    *
* the body runs -                                                     *
*     end of file, or                                                 *
*     the customer number changed, or                                 *
*     the connect id changed                                          *
* Any one of those means the group has ended.                         *
*                                                                     *
* CLC compares character data byte by byte from left to right, so it  *
* is the right instruction for these eight byte key fields.           *
*                                                                     *
* Notice the shape of the loop body - classify the record, then read  *
* the next one.  When the loop finally exits, INREC already holds     *
* the first record of the NEXT group, which is why the mainline can   *
* go straight back to GRPLOOP without another read.                   *
***********************************************************************
PROCGRP  DS    0H                      * Routine entry point
GRPREAD  CLI   EOFSW,C'Y'              * Has the input file ended?
         BE    GRPEND                  * Yes - this group is complete
         CLC   INCUSTNO(8),SAVCUST     * Same customer number?
         BNE   GRPEND                  * No  - a new group has started
         CLC   INCONNID(8),SAVCONN     * Same connect id?
         BNE   GRPEND                  * No  - a new group has started

         BAL   9,CHKREC                * 4100 - apply rules R1, R2, R3
         BAL   9,READINP               * 3000 - read the next record
         B     GRPREAD                 * Test the loop conditions again
GRPEND   BR    10                      * Return to the mainline

***********************************************************************
*                                                                     *
* 4100-CHKREC - Apply the indicator rules to ONE record               *
*                                                                     *
* Each rule is independent, so all three are tested on every record.  *
* An indicator is only ever switched ON here - it is switched off     *
* once per group in INITGRP.  That is what makes the flags mean       *
* 'at least one record in this group matched the rule'.               *
***********************************************************************
CHKREC   DS    0H                      * Routine entry point

***********************************************************************
* Rule R1 - service code ADM together with access code F or C         *
*                                                                     *
* Two conditions joined by AND, so the first failing test branches    *
* straight past the whole rule.  CLC compares the three byte service  *
* code; CLI compares a SINGLE byte against an immediate value, which  *
* is the natural instruction for the one byte access code.            *
***********************************************************************
         CLC   INSVCCD(3),=C'ADM'      * Is the service code ADM?
         BNE   CHKR2                   * No - rule R1 cannot apply
         CLI   INACCESS,C'F'           * Access code F?
         BE    SETADM                  * Yes - rule R1 is satisfied
         CLI   INACCESS,C'C'           * Access code C?
         BE    SETADM                  * Yes - rule R1 is satisfied
         B     CHKR2                   * Neither - R1 does not apply
SETADM   MVI   HASADM,C'Y'             * Switch the R1 indicator on

***********************************************************************
* Rule R2 - service code is any one of CIT, EFT or WPS                *
*                                                                     *
* Three values joined by OR.  Any match sets the indicator, so each   *
* test branches to the same place.                                    *
***********************************************************************
CHKR2    CLC   INSVCCD(3),=C'CIT'      * Is the service code CIT?
         BE    SETPAY                  * Yes - rule R2 is satisfied
         CLC   INSVCCD(3),=C'EFT'      * Is the service code EFT?
         BE    SETPAY                  * Yes - rule R2 is satisfied
         CLC   INSVCCD(3),=C'WPS'      * Is the service code WPS?
         BE    SETPAY                  * Yes - rule R2 is satisfied
         B     CHKR3                   * None matched - R2 fails
SETPAY   MVI   HASPAY,C'Y'             * Switch the R2 indicator on

***********************************************************************
* Rule R3 - service code FT, then a table lookup on the account id    *
*                                                                     *
* The service code field is three bytes but the value FT is only two  *
* characters, so the comparison must be made against 'FT' followed by *
* a blank.  =CL3'FT' builds exactly that literal - the CL3 forces the *
* length to three and pads on the right with a blank.  Comparing      *
* against =C'FT' would compare only two bytes and would also match a  *
* value such as FTX, which would be wrong.                            *
***********************************************************************
CHKR3    CLC   INSVCCD(3),=CL3'FT'     * Is the service code FT?
         BNE   CHKRECX                 * No - rule R3 cannot apply
         BAL   8,CHKFT                 * 4110 - look the prefix up
CHKRECX  BR    9                       * Return to PROCGRP

***********************************************************************
*                                                                     *
* 4110-CHKFT - Search the qualifying prefix table                     *
*                                                                     *
* The design asks for a TABLE lookup rather than a long chain of OR   *
* tests, so that the 32 values are maintained in one place.           *
*                                                                     *
* This is a serial search with an EARLY EXIT -                        *
*   R2 points at the current table entry                              *
*   R3 counts how many entries are left to test                       *
*   BE leaves the loop the moment a match is found                    *
*   BCT keeps the loop going and guarantees it must end               *
*                                                                     *
* Falling out of the bottom of the loop means every entry was tested  *
* without a match, which is how 'not found' is detected.  Combining   *
* a counted loop with a conditional exit like this gives a search     *
* that can never run away.                                            *
*                                                                     *
* CLC is an SS format instruction and has no index register, so the   *
* table entry is addressed through the POINTER register R2 using the  *
* explicit base and displacement form 0(4,2).                         *
***********************************************************************
CHKFT    DS    0H                      * Routine entry point
         LA    2,PFXTAB                * R2 -> first table entry
         L     3,PFXCNT                * R3 = number of entries = 32
FTLOOP   CLC   INACCTID(4),0(2)        * First 4 of acct id = entry?
         BE    FTFOUND                 * Yes - stop searching
         LA    2,4(,2)                 * No  - step to the next entry
         BCT   3,FTLOOP                * Repeat while entries remain
         B     FTEXIT                  * Searched them all, no match

FTFOUND  MVI   HASFTS,C'Y'             * Switch the R3 indicator on
FTEXIT   BR    8                       * Return to CHKREC

***********************************************************************
*                                                                     *
* 5000-FINALCLS - Decide one classification for the whole group       *
*                                                                     *
* This runs ONCE per group, after every record of the group has been  *
* examined.  The rules are tested in strict priority order and the    *
* FIRST match wins, so a group that satisfies both R1 and R2 is       *
* classified as a system administrator.  Each branch jumps to the     *
* common exit so that no later test can overwrite the decision.       *
***********************************************************************
FINALCLS DS    0H                      * Routine entry point
         CLI   HASADM,C'Y'             * Priority 1 - any ADM access?
         BE    CLSADM                  * Yes - administrator wins
         CLI   HASPAY,C'Y'             * Priority 2 - payment service?
         BE    CLSREG                  * Yes - regular user
         CLI   HASFTS,C'Y'             * Priority 2 - qualifying FT?
         BE    CLSREG                  * Yes - regular user

         MVC   FINALCLA(20),CLSRDO     * Priority 3 - the default
         B     CLSEXIT

CLSADM   MVC   FINALCLA(20),CLSSYS     * 'SYSTEM ADMINISTRATOR'
         B     CLSEXIT
CLSREG   MVC   FINALCLA(20),CLSREGU    * 'REGULAR USER'
CLSEXIT  BR    10                      * Return to the mainline

***********************************************************************
*                                                                     *
* 6000-BUILDOUT - Build the comma delimited output record             *
*                                                                     *
* The output area is cleared to blanks first so that any field not    *
* explicitly filled in is left as spaces rather than as leftover      *
* data from the previous group.                                       *
*                                                                     *
* The record layout is declared further down as a run of DS           *
* statements, which means each field can be referred to by NAME and   *
* the assembler works out the displacements.  Writing OUTAREA+91      *
* everywhere would work too, but one inserted field would then break  *
* every offset in the program.                                        *
*                                                                     *
* MVI stores a single immediate byte, so it is the right instruction  *
* for the seventeen one byte comma separators.                        *
***********************************************************************
BUILDOUT DS    0H                      * Routine entry point
         MVC   OUTAREA(256),BLANK256   * Clear output area, part 1
         MVC   OUTAREA+256(256),BLANK256 * Clear output area, part 2
         MVC   OUTAREA+512(47),BLANK256 * Clear output area, part 3

* Columns 1 and 2 both carry the connect id saved for this group
         MVC   OUTNAME(8),SAVCONN      * Column 1  NAME
         MVC   OUTID(8),SAVCONN        * Column 2  ID

* Columns 3 to 6 are fixed literals required by the consuming system
         MVC   OUTTYPE(19),LITTYPE     * Column 3  TYPE
         MVC   OUTSUBTY(7),LITSUBTY    * Column 4  SUBTYPE
         MVC   OUTSTAT(6),LITSTAT      * Column 5  STATUS
         MVC   OUTDESC(37),LITDESC     * Column 6  DESCRIPTION

* Column 7 is the correlation id saved from the group's first record
         MVC   OUTACCV(8),SAVACF2      * Column 7  CORRELATIONVALUE

* Columns 8 and 9 are fixed literals
         MVC   OUTPRIV(5),LITFALSE     * Column 8  ISPRIVILEGEDFLAG
         MVC   OUTLOCK(5),LITFALSE     * Column 9  ISLOCKED

* Columns 10 to 17 stay as the blanks loaded above - nothing to do

* Column 18 is the classification decided in FINALCLS
         MVC   OUTACC(20),FINALCLA     * Column 18 ACCESS

* The seventeen separators that turn the record into a CSV line
         MVI   OUTC1,C','              * After column 1
         MVI   OUTC2,C','              * After column 2
         MVI   OUTC3,C','              * After column 3
         MVI   OUTC4,C','              * After column 4
         MVI   OUTC5,C','              * After column 5
         MVI   OUTC6,C','              * After column 6
         MVI   OUTC7,C','              * After column 7
         MVI   OUTC8,C','              * After column 8
         MVI   OUTC9,C','              * After column 9
         MVI   OUTC10,C','             * After column 10
         MVI   OUTC11,C','             * After column 11
         MVI   OUTC12,C','             * After column 12
         MVI   OUTC13,C','             * After column 13
         MVI   OUTC14,C','             * After column 14
         MVI   OUTC15,C','             * After column 15
         MVI   OUTC16,C','             * After column 16
         MVI   OUTC17,C','             * After column 17
         BR    10                      * Return to the mainline

***********************************************************************
*                                                                     *
* 7000-WRITEOUT - Write one detail record, header first if needed     *
*                                                                     *
* The design requires that the header line is written immediately     *
* before the FIRST detail record rather than when the file is opened. *
* That is what makes an empty input file produce a completely empty   *
* output file.  The FIRSTSW switch is what remembers whether the      *
* header has already been written.                                    *
*                                                                     *
* PUT in move mode copies our record into the system buffer.  There   *
* is no status field to test afterwards - a write failure drives the  *
* SYNAD exit named in the DCB, which abends the program.              *
***********************************************************************
WRITEOUT DS    0H                      * Routine entry point
         CLI   FIRSTSW,C'Y'            * Is this the first detail?
         BNE   WRTDETL                 * No - header already written
         BAL   9,WRTHDR                * 7100 - write the header line

WRTDETL  PUT   AMHFOUT,OUTAREA         * Write the detail record
         AP    WRITCNT,=P'1'           * One more record written
         BR    10                      * Return to the mainline

***********************************************************************
* 7100-WRTHDR - Write the column heading line, once only              *
***********************************************************************
WRTHDR   DS    0H                      * Routine entry point
         PUT   AMHFOUT,HDRREC          * Write the header record
         MVI   FIRSTSW,C'N'            * Never write the header again
         BR    9                       * Return to WRITEOUT

***********************************************************************
* IOERROUT - the SYNAD exit named in the output DCB                   *
***********************************************************************
IOERROUT LA    1,MSGWRITE              * R1 -> write error message
         BAL   7,PRTMSG                * Print the message
         B     ABENDRTN                * Abend with a dump

***********************************************************************
*                                                                     *
* 8000-CLOSFILE - Close the two data files                            *
*                                                                     *
* CLOSE matters more than it looks.  For an output file it is CLOSE   *
* that flushes the last partly filled buffer to disk.  A program      *
* that ends without closing can silently lose its final records.      *
*                                                                     *
* SYSPRINT is deliberately NOT closed here - the record counts still  *
* have to be printed.  The mainline closes it last of all.            *
***********************************************************************
CLOSFILE DS    0H                      * Routine entry point
         CLOSE (AMHFIN)                * Close the input file
         CLOSE (AMHFOUT)               * Close the output file
         BR    10                      * Return to the mainline

***********************************************************************
*                                                                     *
* PRTCNTS - Print the record counts and the end marker                *
*                                                                     *
* The counters are packed decimal, which is not printable, so each    *
* one goes through the standard conversion -                          *
*   UNPK  spreads the packed digits to one digit per byte             *
*   OI    forces the sign nibble of the last byte to F so it prints   *
* Without the OI the final digit would appear as a letter.            *
***********************************************************************
PRTCNTS  DS    0H                      * Routine entry point
         MVC   MSGREAD(50),MSGREADL    * 'RECORDS READ    :'
         UNPK  ZONE9(9),READCNT(5)     * Packed to zoned decimal
         OI    ZONE9+8,X'F0'           * Make the last digit printable
         MVC   MSGREAD+20(9),ZONE9     * Place the count in the text
         LA    1,MSGREAD               * R1 -> the completed message
         BAL   7,PRTMSG                * Print it

         MVC   MSGWRIT(50),MSGWRITL    * 'RECORDS WRITTEN :'
         UNPK  ZONE9(9),WRITCNT(5)     * Packed to zoned decimal
         OI    ZONE9+8,X'F0'           * Make the last digit printable
         MVC   MSGWRIT+20(9),ZONE9     * Place the count in the text
         LA    1,MSGWRIT               * R1 -> the completed message
         BAL   7,PRTMSG                * Print it

         LA    1,MSGEND                * R1 -> 'PROGRAM QSAMPROC ENDED'
         BAL   7,PRTMSG                * Print the end marker
         BR    10                      * Return to the mainline

***********************************************************************
*                                                                     *
* PRTMSG - Print one 50 byte message on SYSPRINT                      *
*                                                                     *
* Entry  R1 = address of the message text                             *
*        R7 = return address, placed there by BAL                     *
*                                                                     *
* R7 is reserved for this routine alone, which is what allows it to   *
* be called safely from the mainline, from a level 1 routine, or      *
* from an error path, without ever destroying another return address. *
* It cannot use R11, because R11 is now the second BASE register and  *
* overwriting it would make half the program unaddressable.           *
*                                                                     *
* MVC cannot take an address from a register in its source operand    *
* the way an RX instruction can, so the source is written as 0(50,1), *
* meaning 50 bytes starting at the address in R1.                     *
***********************************************************************
PRTMSG   DS    0H                      * Routine entry point
         MVC   PRTLINE(80),BLANK256    * Clear the print line
         MVC   PRTLINE(50),0(1)        * Copy 50 bytes from the address
         PUT   SYSPRINT,PRTLINE        * Write the line
         BR    7                       * Return to the caller

***********************************************************************
*                                                                     *
* ABENDRTN - Terminate abnormally with a dump                         *
*                                                                     *
* Every I/O error path ends here.  The design document is firm that   *
* an I/O failure must not end with an ordinary return code, because   *
* the files would be left open and the failure could go unnoticed by  *
* the scheduler.  ABEND with the DUMP option produces a dump for      *
* diagnosis and forces the job step to fail visibly.                  *
***********************************************************************
ABENDRTN DS    0H                      * Routine entry point
         ABEND 16,DUMP                 * User abend 16 with a dump

***********************************************************************
*                                                                     *
* DATA AREAS                                                          *
*                                                                     *
* Everything below this point is data, not instructions.  It sits     *
* AFTER the last branch so that the processor can never fall into it  *
* and try to execute it.                                              *
*                                                                     *
***********************************************************************
SAVEAREA DS    18F                     * Standard 72 byte save area

***********************************************************************
* Switches and indicators.  Each is a single character holding Y or N *
* so that CLI can test it in one instruction.                         *
***********************************************************************
EOFSW    DS    CL1                     * Y = input file has ended
FIRSTSW  DS    CL1                     * Y = header not yet written
HASADM   DS    CL1                     * Y = R1 matched in this group
HASPAY   DS    CL1                     * Y = R2 matched in this group
HASFTS   DS    CL1                     * Y = R3 matched in this group

***********************************************************************
* The saved control key.  These fields hold the key of the group      *
* currently being processed, taken from its first record.             *
***********************************************************************
SAVCUST  DS    CL8                     * Key part 1, customer number
SAVCONN  DS    CL8                     * Key part 2, connect id
SAVACF2  DS    CL8                     * Correlation id for the group
FINALCLA DS    CL20                    * Classification of the group

***********************************************************************
* Counters and conversion work areas                                  *
***********************************************************************
READCNT  DS    PL5                     * Input records read, 9 digits
WRITCNT  DS    PL5                     * Records written, 9 digits
ZONE9    DS    CL9                     * Zoned decimal work area

***********************************************************************
* INPUT RECORD AREA                                                   *
*                                                                     *
* DS 0CL559 names the whole area without reserving anything extra -   *
* the duplication factor of zero means 'define the label and the      *
* length, but do not advance the location counter'.  The fields that  *
* follow then carve that area up, and each one gets its own name.     *
*                                                                     *
* Only the fields this program actually uses are given meaningful     *
* names.  The rest are present purely to put the later fields at the  *
* correct displacement, exactly as the design document requires.      *
***********************************************************************
INREC    DS    0CL559                  * Whole input record
INCUSTNO DS    CL8                     * Key 1 - customer number
INUSERID DS    CL8                     * Not used by this program
INCONNID DS    CL8                     * Key 2 - connect id, output
INFIRST  DS    CL35                    * Not used by this program
INLAST   DS    CL35                    * Not used by this program
INEMAIL  DS    CL50                    * Not used by this program
INACF2ID DS    CL8                     * Correlation id, to output
INSVCCD  DS    CL3                     * Service code: R1, R2, R3
INACCESS DS    CL1                     * Access code, drives rule R1
INACCTTY DS    CL5                     * Not used by this program
INACCTID DS    CL30                    * Account id, first 4: rule R3
INFILLER DS    CL368                   * Remainder of the record

***********************************************************************
* OUTPUT RECORD AREA                                                  *
*                                                                     *
* The comma separators are declared as real one byte fields rather    *
* than being counted into the data fields, so that the layout in      *
* storage matches the design document column for column.              *
***********************************************************************
OUTAREA  DS    0CL559                  * Whole output record
OUTNAME  DS    CL8                     * Column 1  NAME
OUTC1    DS    CL1                     * Separator
OUTID    DS    CL8                     * Column 2  ID
OUTC2    DS    CL1                     * Separator
OUTTYPE  DS    CL19                    * Column 3  TYPE
OUTC3    DS    CL1                     * Separator
OUTSUBTY DS    CL7                     * Column 4  SUBTYPE
OUTC4    DS    CL1                     * Separator
OUTSTAT  DS    CL6                     * Column 5  STATUS
OUTC5    DS    CL1                     * Separator
OUTDESC  DS    CL37                    * Column 6  DESCRIPTION
OUTC6    DS    CL1                     * Separator
OUTACCV  DS    CL8                     * Column 7  CORRELATIONVALUE
OUTC7    DS    CL1                     * Separator
OUTPRIV  DS    CL5                     * Column 8  ISPRIVILEGEDFLAG
OUTC8    DS    CL1                     * Separator
OUTLOCK  DS    CL5                     * Column 9  ISLOCKED
OUTC9    DS    CL1                     * Separator
OUTFNAM  DS    CL1                     * Col 10 USERFIRSTNAME, blank
OUTC10   DS    CL1                     * Separator
OUTLNAM  DS    CL1                     * Col 11 USERLASTNAME, blank
OUTC11   DS    CL1                     * Separator
OUTPOWN  DS    CL1                     * Col 12 PRIMARYOWNER, blank
OUTC12   DS    CL1                     * Separator
OUTCRDT  DS    CL1                     * Col 13 CREATIONDATE, blank
OUTC13   DS    CL1                     * Separator
OUTLLOG  DS    CL1                     * Col 14 LASTLOGINDATE, blank
OUTC14   DS    CL1                     * Separator
OUTPWDT  DS    CL1                     * Col 15 PASSWORDLASTCHG, blank
OUTC15   DS    CL1                     * Separator
OUTDISDT DS    CL1                     * Col 16 DISABLEDDATE, blank
OUTC16   DS    CL1                     * Separator
OUTCOST  DS    CL1                     * Col 17 COSTCENTRE, blank
OUTC17   DS    CL1                     * Separator
OUTACC   DS    CL20                    * Column 18 ACCESS, derived
OUTFILL  DS    CL411                   * Trailing filler to reach 559

***********************************************************************
* HEADER RECORD                                                       *
*                                                                     *
* Built from several DC statements for two separate reasons -         *
*   1. one 559 character literal will not fit on a source line        *
*   2. a C type constant may be at most 256 BYTES LONG, so even the   *
*      trailing pad has to be split in two                            *
* The pieces are contiguous in storage, so HDRREC addresses all 559   *
* bytes as a single record.                                           *
*                                                                     *
* Text  = 210 bytes, pad = 256 + 93 = 349 bytes, total = 559 bytes.   *
***********************************************************************
HDRREC   DS    0CL559                  * Whole header record
         DC    C'NAME,ID,TYPE,SUBTYPE,STATUS,DESCRIPTION,'
         DC    C'ACCOUNTCORRELATIONVALUE,ISPRIVILEGEDFLAG,ISLOCKED,'
         DC    C'USERFIRSTNAME,USERLASTNAME,PRIMARYOWNER,CREATIONDATE,'
         DC    C'LASTLOGINDATE,PASSWORDLASTCHANGEDATE,DISABLEDDATE,'
         DC    C'COSTCENTRE,ACCESS'
         DC    CL256' '                * Pad part 1 - 256 byte maximum
         DC    CL93' '                 * Pad part 2 - total is 559

***********************************************************************
* QUALIFYING PREFIX TABLE - rule R3                                   *
*                                                                     *
* Thirty two four character prefixes held as one contiguous run of    *
* 128 bytes.  Keeping the count in PFXCNT next to the table means     *
* that adding or removing a prefix only requires changing the table   *
* and that one number - the search loop itself never changes.         *
***********************************************************************
PFXTAB   DS    0CL4                    * Start of the prefix table
         DC    C'2312',C'2313',C'2420',C'2421'
         DC    C'2462',C'2463',C'2504',C'2505'
         DC    C'2508',C'2510',C'2511',C'2512'
         DC    C'2513',C'2517',C'2518',C'2548'
         DC    C'2557',C'2569',C'2571',C'3007'
         DC    C'3009',C'3012',C'3015',C'3023'
         DC    C'3024',C'3025',C'3058',C'3059'
         DC    C'3508',C'3509',C'3510',C'3511'
PFXCNT   DC    F'32'                   * Number of entries in PFXTAB

***********************************************************************
* Fixed literal values for the output columns                         *
* Each one is defined with the exact length of its output field, so   *
* the MVC that moves it can never overrun or underfill the column.    *
***********************************************************************
LITTYPE  DC    CL19'PERSONAL PRIMARY ID'
LITSUBTY DC    CL7'PRIMARY'
LITSTAT  DC    CL6'ACTIVE'
LITDESC  DC    CL37'PERSONAL PRIMARY LOGIN ACCOUNT TO WBU'
LITFALSE DC    CL5'FALSE'

***********************************************************************
* The three possible classification values, rule R4                   *
***********************************************************************
CLSSYS   DC    CL20'SYSTEM ADMINISTRATOR'
CLSREGU  DC    CL20'REGULAR USER'
CLSRDO   DC    CL20'READ ONLY USER'

***********************************************************************
* Messages.  All are CL50 so that PRTMSG can move a fixed length and  *
* never has to be told how long any individual message is.            *
***********************************************************************
MSGSTART DC    CL50'QSAMPROC - PROGRAM STARTED'
MSGEND   DC    CL50'QSAMPROC - PROGRAM ENDED NORMALLY'
MSGNOREC DC    CL50'QSAMPROC - NO RECORDS IN SOURCE FILE'
MSGOPNI  DC    CL50'QSAMPROC - INPUT FILE OPEN ERROR'
MSGOPNO  DC    CL50'QSAMPROC - OUTPUT FILE OPEN ERROR'
MSGREADE DC    CL50'QSAMPROC - INPUT FILE READ ERROR'
MSGWRITE DC    CL50'QSAMPROC - OUTPUT FILE WRITE ERROR'
MSGREADL DC    CL50'QSAMPROC - RECORDS READ    :'
MSGWRITL DC    CL50'QSAMPROC - RECORDS WRITTEN :'

***********************************************************************
* Message work areas.  The count messages are built here because the  *
* number has to be edited into the middle of the text at run time.    *
***********************************************************************
MSGREAD  DS    CL50                    * Built read count line
MSGWRIT  DS    CL50                    * Built write count line
PRTLINE  DS    CL80                    * SYSPRINT output line

***********************************************************************
* BLANK256 is a block of 256 spaces used as the source of every       *
* clearing MVC in the program.  One constant serves them all.         *
***********************************************************************
BLANK256 DC    CL256' '                * 256 spaces

***********************************************************************
* FILE CONTROL BLOCKS                                                 *
*                                                                     *
* The DCB macro builds the control block that connects the program to *
* a data set.  Important operands -                                   *
*   DDNAME   the name on the DD statement in the JCL                  *
*   DSORG=PS physical sequential                                      *
*   MACRF=GM GET in move mode, the record is copied to our area       *
*   MACRF=PM PUT in move mode, our record is copied to the buffer     *
*   EODAD    where to branch when the input runs out of records       *
*   SYNAD    where to branch when a real I/O error happens            *
*   BLKSIZE=0 let the system choose the most efficient block size     *
***********************************************************************
AMHFIN   DCB   DSORG=PS,MACRF=GM,DDNAME=AMHFIN,                        X
               EODAD=READEOF,SYNAD=IOERRIN,                            X
               RECFM=FB,LRECL=559,BLKSIZE=0

AMHFOUT  DCB   DSORG=PS,MACRF=PM,DDNAME=AMHFOUT,                       X
               SYNAD=IOERROUT,                                         X
               RECFM=FB,LRECL=559,BLKSIZE=0

SYSPRINT DCB   DSORG=PS,MACRF=PM,DDNAME=SYSPRINT,                      X
               RECFM=FB,LRECL=80,BLKSIZE=0

         LTORG                         * Literal pool for the =C and =P

***********************************************************************
* DCBD generates the IHADCB dummy section used by the OPEN tests.     *
* It must come last because a DSECT ends the current control section, *
* so no real storage may be defined after it.                         *
***********************************************************************
         DCBD  DSORG=PS,DEVD=DA        * Map of the DCB for TM DCBOFLGS

         END   QSAMPROC
