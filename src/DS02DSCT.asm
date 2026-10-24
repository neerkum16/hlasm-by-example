*********************************************************************
* DS02DSCT - DSECTs For Real Files And For Parameter Lists
* Purpose: Builds on DS01DSCT.  Shows a DSECT used to map an actual
*          QSAM record read in from a file (the production use of
*          the technique), and a SECOND DSECT used to map a
*          PARAMETER LIST passed between two routines in R1 - the
*          standard way Assembler programs pass structured data to
*          each other, instead of COBOL-style USING clauses.
*********************************************************************
*
*===================================================================
* WHY TWO DSECTs IN ONE PROGRAM?
*===================================================================
* DS01DSCT showed the IDEA of a DSECT using data built with DC, just to
* keep that first lesson simple.  Real programs use a DSECT for two
* separate jobs, and this program shows both:
*
*  PARTREC   maps a REAL RECORD read from a file with GET - this is
*            exactly the problem INREC/INCUSTNO/... solved by hand in
*            qsamproc.asm, done properly this time.
*
*  PARMD     maps a PARAMETER LIST - a small block of fields built by
*            one routine and handed to another through a register,
*            the Assembler equivalent of calling a function with
*            several arguments.  BAL/BR only pass a RETURN ADDRESS;
*            if the called routine also needs DATA, a parameter list
*            pointed to by a register is how that data travels.
*
* Both are "just a DSECT" underneath - the only difference is WHOSE
* storage gets pointed at: a QSAM buffer in one case, a small CSECT
* work area built specifically to pass arguments in the other.
*********************************************************************
         PRINT NOGEN
DS02DSCT CSECT
*********************************************************************
* A000-MAINLINE
*********************************************************************
         STM   14,12,12(13)            * Save caller's registers
         LR    12,15                   * Load base register
         USING DS02DSCT,12             * Establish addressability
         ST    13,SAVEAREA+4           * Chain savearea (backward)
         LA    13,SAVEAREA             * Load address of savearea
*
         MVI   EOFSW,C'N'              * End of file not yet reached
         ZAP   RECCNT,=P'0'            * Records read = 0
         ZAP   GRANDTOT,=P'0'          * Total = 0, avoids S0C7
*                                      * See GRANDTOT's DS note: this
*                                      * ZAP is NOT optional, AP will
*                                      * abend on an unset packed field
*
         OPEN  (SYSPRINT,(OUTPUT))
         OPEN  (PARTFILE,(INPUT))
*
         LA    1,MSGSTRT
         BAL   10,PRTMSG
*
         BAL   10,READREC              * Priming read, see READREC
*
*********************************************************************
* B000-MAINLOOP - one trip per input record
*********************************************************************
MAINLOOP CLI   EOFSW,C'Y'
         BE    ALLDONE
*
         BAL   10,SHOWREC              * Print this record's fields
         BAL   10,BUILDTOT             * Pass this record's amount to a
*                                      * routine via a PARAMETER LIST
         BAL   10,READREC              * Read the next record
         B     MAINLOOP
*
*********************************************************************
* ALLDONE - print the running total built up by BUILDTOT/ADDAMT, then
*           close everything down
*********************************************************************
ALLDONE  DS    0H
         MVC   PRTLINE,BLANKS
         MVC   PRTLINE(16),=C'RUNNING TOTAL - '
         UNPK  ZONE11,GRANDTOT
         OI    ZONE11+10,X'F0'
         MVC   PRTLINE+16(11),ZONE11
         PUT   SYSPRINT,PRTLINE
*
         LA    1,MSGEND
         BAL   10,PRTMSG
*
         CLOSE (PARTFILE)
         CLOSE (SYSPRINT)
*
         L     13,SAVEAREA+4
         LM    14,12,12(13)
         SR    15,15
         BR    14
*
*********************************************************************
*
* READREC - read one record from PARTFILE, using the PARTREC DSECT
*           to describe the record's fields
*
* GET copies the next record from the file into INAREA - a REAL 40
* byte CSECT work area, the record buffer this program actually owns.
* PARTREC is only the MAP of what those 40 bytes mean.  LA+USING below
* make that map apply to INAREA, exactly as in DS01DSCT.
*********************************************************************
READREC  DS    0H
         MVC   INAREA,BLANKS40         * Clear the record area first
         GET   PARTFILE,INAREA         * Read to REAL storage or EODAD
         AP    RECCNT,=P'1'
         BR    10
*
EOFRTN   DS    0H                      * EODAD target in PARTFILE DCB
         MVI   EOFSW,C'Y'
         BR    10
*
*********************************************************************
*
* SHOWREC - print one record's fields, read through the PARTREC DSECT
*
* LA 3,INAREA + USING PARTD,3 is the whole trick: PARTNO, PARTDESC and
* PARTAMT below are not real labels with their own storage - they are
* DISPLACEMENTS into whatever R3 happens to point at, which here is
* INAREA, freshly filled in by the GET in READREC.
*********************************************************************
SHOWREC  DS    0H
         LA    3,INAREA                * R3 -> the record just read
         USING PARTD,3                 * PARTD now overlays INAREA
*
         MVC   PRTLINE,BLANKS
         MVC   PRTLINE(8),PARTNO       * Straight through the DSECT
         MVC   PRTLINE+10(20),PARTDESC
         UNPK  ZONE7,PARTAMT
         OI    ZONE7+6,X'F0'
         MVC   PRTLINE+32(7),ZONE7
         PUT   SYSPRINT,PRTLINE
*
         DROP  3
         BR    10
*
*********************************************************************
*
* BUILDTOT - build a PARAMETER LIST and pass it to ADDAMT
*
* PARMAREA is a small REAL work area, big enough to hold the two
* fields ADDAMT needs: the amount to add, and the running total to add
* it to.  PARMD is the DSECT that describes PARMAREA's layout.  This
* is exactly the pattern used to pass several arguments to a called
* routine in Assembler - R1 could equally point at storage built by a
* COMPLETELY DIFFERENT program calling this one; the technique does
* not care who built the parameter list, only that R1 points at it and
* PARMD describes it correctly.
*
* LA 1,PARMAREA loads the ADDRESS of the parameter block into R1 - by
* CONVENTION R1 is where a parameter list address is normally passed,
* the same convention OPEN/GET/PUT use internally and the same
* register a caller would find a parameter list address in on
* entry to THIS program, had one been passed.
*********************************************************************
BUILDTOT DS    0H
         LA    3,INAREA
         USING PARTD,3                 * R3 -> record, mapped by PARTD
*
         LA    1,PARMAREA              * R1 -> the parameter list
         USING PARMD,1                 * R1 -> same bytes, via PARMD
*
         MVC   PARMAMT,PARTAMT         * Copy amount, PARTD to PARMD
*                                      * Read via PARTD/R3, written via
*                                      * PARMD/R1 - two DIFFERENT
*                                      * DSECTs, each overlaying its
*                                      * OWN register, both active
*                                      * at once
         DROP  3
         DROP  1
*
         BAL   9,ADDAMT                * Level 2 call: uses R9, not R10
*                                      * BUILDTOT was itself entered
*                                      * via BAL 10 from MAINLOOP, so
*                                      * R10 holds the return address
*                                      * back to MAINLOOP.  If ADDAMT
*                                      * were also called with BAL 10
*                                      * it would OVERWRITE R10 with
*                                      * the address of the next line
*                                      * in BUILDTOT, and the next
*                                      * BR 10 would branch to ITSELF
*                                      * forever, an infinite loop,
*                                      * because the return address
*                                      * into MAINLOOP is gone.  Each
*                                      * CALLING LEVEL needs its own
*                                      * register: R10 for level 1,
*                                      * R9 for level 2 (qsamproc 12.3)
         BR    10
*
*********************************************************************
*
* ADDAMT - called with R1 pointing at a PARMD parameter list
*
* This routine has NEVER HEARD OF INAREA or PARTREC.  All it knows is
* "R1 points at something shaped like PARMD" - PARMAMT (the amount to
* add) and PARMTOT (where the running total lives).  That separation
* is the whole point: ADDAMT could be called from anywhere, by anyone,
* as long as they build a PARMD-shaped block and point R1 at it.
*
* USING PARMD,1 overlays the parameter DSECT on whatever R1 points at
* right now - the SAME technique as every USING in this program, just
* applied to an incoming register instead of one we loaded ourselves.
*********************************************************************
ADDAMT   DS    0H
         USING PARMD,1                 * R1 -> parameter list, PARMD
         AP    GRANDTOT,PARMAMT        * Add passed-in amount to total
         DROP  1
         BR    9                       * Return via R9, matches BAL 9
*                                      * that called this routine from
*                                      * BUILDTOT.  BR 10 here would be
*                                      * the infinite loop bug noted
*                                      * at the BAL 9,ADDAMT call.
*
*********************************************************************
*
* PRTMSG - print a 50 byte message addressed by R1
*********************************************************************
PRTMSG   DS    0H
         MVC   PRTLINE,BLANKS
         MVC   PRTLINE(50),0(1)
         PUT   SYSPRINT,PRTLINE
         BR    10
*
*********************************************************************
* Data areas - all REAL storage
*********************************************************************
SAVEAREA DS    18F
EOFSW    DS    CL1
RECCNT   DS    PL4
*********************************************************************
* GRANDTOT - running total, packed decimal, 6 bytes.
*
* DS reserves storage but does NOT initialize it - these bytes start
* out as whatever was already sitting in that part of memory, which
* is NOT guaranteed to be a valid packed decimal number (correct digit
* nibbles plus a valid sign nibble such as C, D or F in the last
* byte).  AP (Add Packed), like every decimal instruction, checks that
* BOTH operands already contain valid packed data before it will add
* them - it does not just treat the bytes as a number no matter what
* is in them.
*
* Forgetting to ZAP a packed field to zero before the first AP/SP/MP
* touches it is one of the most common causes of a S0C7 DATA
* EXCEPTION - and a particularly sneaky one, because the program can
* run for a while first (every MVC, UNPK and OI before the AP succeeds
* without complaint - they do not validate packed data the way AP
* does) before it finally abends the first time real arithmetic is
* attempted on the field.  See the ZAP GRANDTOT,=P'0' in A000-MAINLINE
* above - exactly the same fix already applied to RECCNT alongside it.
*********************************************************************
GRANDTOT DS    PL6                     * Running total, packed, 6 bytes
PRTLINE  DS    CL80
ZONE7    DS    CL7
ZONE11   DS    CL11
BLANKS   DC    CL80' '
BLANKS40 DC    CL40' '
*
*********************************************************************
* INAREA - the REAL 40 byte record buffer that GET fills in.  PARTD
* below is the DSECT that gives these bytes field names.  INAREA has
* no field names of its own on purpose - that is PARTD's job.
*********************************************************************
INAREA   DS    CL40
*
*********************************************************************
* PARMAREA - the REAL storage used to build the parameter list passed
* to ADDAMT.  PARMD below describes its two fields.  Just like INAREA
* above, PARMAREA has NO field names of its own on purpose - PARMD is
* what gives these bytes meaning, overlaid by USING PARMD,1 wherever
* R1 happens to point.  In a bigger program this could just as easily
* be built by a DIFFERENT CSECT calling this one with CALL instead of
* BAL - the DSECT and the R1 convention do not change either way.
*********************************************************************
PARMAREA DS    CL11                    * 5 bytes amount + 6 bytes total
*
MSGSTRT  DC    CL50'DS02DSCT - PROGRAM STARTED'
MSGEND   DC    CL50'DS02DSCT - PROGRAM ENDED NORMALLY'
*
PARTFILE DCB   DSORG=PS,MACRF=GM,DDNAME=PARTFILE,                      X
               EODAD=EOFRTN,RECFM=FB,LRECL=40,BLKSIZE=0
*
SYSPRINT DCB   DSORG=PS,MACRF=PM,DDNAME=SYSPRINT,                      X
               RECFM=FB,LRECL=80,BLKSIZE=0
*
         LTORG
*
*********************************************************************
* PARTD - DSECT describing one 40 byte part record read from PARTFILE
*
* Compare this with qsamproc.asm's INREC/INCUSTNO/INUSERID/...: that
* program carved up a record with DS statements living INSIDE its own
* CSECT, glued to one particular 559 byte buffer forever.  Here the
* fields live in a DSECT instead, so the EXACT SAME layout could be
* reused by a completely different program, or applied to a completely
* different buffer in this one (as SHOWREC and BUILDTOT both do, by
* pointing R3 at INAREA each time they need it).
*********************************************************************
PARTD    DSECT
PARTNO   DS    CL8                     * Part number
         DS    CL2                     * Filler / spacer in the record
PARTDESC DS    CL20                    * Part description
PARTAMT  DS    PL5                     * Amount, packed decimal
         DS    CL5                     * Unused filler, to reach 40
*
*********************************************************************
* PARMD - DSECT describing the parameter list passed to ADDAMT
*
* NOTE ON PARMTOT: it is defined here to show a COMPLETE parameter
* list shape (amount in, total out) even though this small program
* takes a shortcut and lets ADDAMT update GRANDTOT directly by name.
* A stricter version would ALSO use PARMTOT (for example by having
* BUILDTOT pass GRANDTOT's address as a second parameter) so that
* ADDAMT never reaches outside the data it was explicitly given - that
* discipline is exactly what makes parameter lists worth using instead
* of just letting every routine touch every CSECT label directly.
*********************************************************************
PARMD    DSECT
PARMAMT  DS    PL5                     * Amount to add, from BUILDTOT
PARMTOT  DS    PL6                     * Where the result would go in a
*                                      * stricter version of the design
*
         END   DS02DSCT
