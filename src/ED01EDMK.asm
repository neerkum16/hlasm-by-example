***********************************************************************
* ED01EDMK - EDMK With A Floating Currency Sign                       *
* Purpose: ED and EDMK a handful of packed decimal amounts through    *
*          patterns that suppress leading zeros, insert a comma and a *
*          decimal point, and FLOAT a '$' so it sits directly in front*
*          of the first significant digit - a different position on   *
*          every amount, worked out at RUN TIME, not assembly time.   *
*                                                                     *
*======================================================================
* ED / EDMK REFRESHER
*======================================================================
* ED (Edit) and EDMK (Edit and Mark) both take a PATTERN built out of
* special bytes and OVERLAY that pattern, in place, with digits taken
* from a packed decimal SOURCE field - turning raw packed decimal into
* printable, formatted text in one instruction.  The pattern bytes:
*
*     X'20'    DIGIT SELECTOR - consumes one digit from the source;
*             LEADING ZERO digits are replaced by the FILL byte
*             instead of being printed, UNTIL the first significant
*             (non-zero) digit is reached - that is what "zero
*             suppression" means mechanically.
*     X'21'    DIGIT SELECTOR, SIGNIFICANCE START - same as X'20', but
*             ALSO forces "significance" on at this position even if
*             the digit itself is zero.  Used right before the last
*             digit, so an amount of exactly zero still prints that
*             one zero instead of suppressing every digit.
*     C' '     the FILL byte itself (any byte can be used, blank is the
*             overwhelmingly common choice) - every position not yet
*             "significant" gets overwritten with this byte.
*     C','/C'.'  MESSAGE INSERTION bytes - printed literally, UNLESS a
*             digit selector to their LEFT has not yet become
*             significant, in which case THEY are replaced by the fill
*             byte too.  That is how a comma correctly disappears from
*             "000,001,234" leaving "      1,234" - the comma right
*             after the suppressed zeros is itself suppressed with
*             them.
*
* The source's SIGN NIBBLE (the last nibble of the packed field) is
* inspected automatically: ED/EDMK insert nothing extra for it by
* themselves, but the LAST byte of the pattern is conventionally a
* digit selector too, and a separate MVZ/OI trick is used if a minus
* sign needs to be displayed - not shown in this lesson, which sticks
* to UNSIGNED, always positive amounts for clarity.
*
*======================================================================
* EDMK vs ED - THE ONE DIFFERENCE, AND WHY IT MATTERS FOR A '$'
*======================================================================
* ED and EDMK are otherwise identical - EDMK does everything ED does,
* PLUS one extra thing: the FIRST time a digit selector becomes
* significant, EDMK stores THAT PATTERN BYTE'S ADDRESS into R1 (R1 is
* otherwise left completely alone, not even its LOW byte).  Before the
* very first significant digit, R1 is untouched by EDMK at all.
*
* That returned address is exactly where the FIRST printed digit will
* end up - which means R1-1 is exactly ONE BYTE BEFORE it: precisely
* where a floating currency sign belongs, however many fill bytes were
* suppressed before it.  The standard idiom:
*
*     EDMK  PATTERN,PACKFLD    R1 <- address of the first significant
*                                digit's position in PATTERN
*     BCTR  1,0                Back up one byte - the position
*                                immediately BEFORE it
*     MVI   0(1),C'$'          Drop the currency sign there - it now
*                                sits snug against the first digit, no
*                                matter how many leading positions were
*                                blanked out
*
* BCTR 1,0 is doing the exact same "subtract one from a register"
* trick used for EX's length-minus-one all through this project - here
* it decrements an ADDRESS by one byte instead of a length by one unit
* (BCTR also branches on the result, which is harmless here since
* nothing follows it).
*
* An amount of EXACTLY ZERO is the one case needing care: EDMK does
* NOT set R1 at all if NO digit selector ever became significant on
* its own, which is why the pattern always ends in an X'21' - forcing
* at least the final digit to be "significant" guarantees R1 always
* gets set, so the $ is never left pointing at garbage.
***********************************************************************
         PRINT NOGEN
ED01EDMK CSECT
         STM   14,12,12(13)
         LR    12,15
         USING ED01EDMK,12
         ST    13,SAVEAREA+4
         LA    13,SAVEAREA

         OPEN  (SYSOUT,(OUTPUT))
         MVC   OUTMSG,BLANKS
         MVC   OUTMSG(60),MSGHDR
         PUT   SYSOUT,OUTMSG

***********************************************************************
* Loop over a small table of packed decimal amounts, editing each one *
* with the SAME reusable pattern (PATTERN is overlaid fresh every     *
* iteration, since ED/EDMK destroy the pattern bytes as they go)      *
***********************************************************************
         LA    7,AMTTAB                * R7 -> first table entry
         L     6,AMTCNT                * R6 = number of entries

EDLOOP   MVC   OUTMSG,BLANKS

         MVC   PATTERN,PATMAST         * Refresh a clean pattern copy -
*                                      * EDMK overwrites PATTERN,
*                                      * so MASTER copy must be re-
*                                      * copied before every use
         EDMK  PATTERN,0(7)            * Edit amount at 0(7); R1 <-
*                                      * address of first significant
*                                      * digit's slot in PATTERN
         BCTR  1,0                     * Back up one byte - the slot
*                                      * immediately in front of it
         MVI   0(1),C'$'               * Float the $ into place

         MVC   OUTMSG(12),PATTERN      * Show the floating-$ result
         MVC   OUTMSG+20(14),=C'(SOURCE VALUE:'
         UNPK  ZONESHOW,0(5,7)         * Show the raw packed value too,
*                                      * for comparison - 5 bytes, this
*                                      * table's packed field length
         OI    ZONESHOW+9,X'F0'
         MVC   OUTMSG+35(10),ZONESHOW
         MVI   OUTMSG+45,C')'

         PUT   SYSOUT,OUTMSG

         LA    7,AMTLEN(,7)            * Step to the next table entry
         BCT   6,EDLOOP

***********************************************************************
* A SECOND pattern, with a comma inserted, shown against a LARGER     *
* amount - demonstrates that the comma is suppressed right along with *
* the leading zeros in front of it when the amount is small           *
***********************************************************************
         MVC   OUTMSG,BLANKS
         MVC   OUTMSG(60),MSGCOMMA
         PUT   SYSOUT,OUTMSG

         LA    7,AMTTAB2
         L     6,AMTCNT2

EDLOOP2  MVC   OUTMSG,BLANKS
         MVC   PATTERN2,PATMAST2
         EDMK  PATTERN2,0(7)
         BCTR  1,0
         MVI   0(1),C'$'
         MVC   OUTMSG(11),PATTERN2
         PUT   SYSOUT,OUTMSG
         LA    7,AMTLEN2(,7)
         BCT   6,EDLOOP2

         CLOSE (SYSOUT)
         L     13,SAVEAREA+4
         LM    14,12,12(13)
         SR    15,15
         BR    14

***********************************************************************
* Data areas                                                          *
***********************************************************************
SAVEAREA DS    18F
OUTMSG   DS    CL80
BLANKS   DC    CL80' '
ZONESHOW DS    CL10
MSGHDR   DC    CL60'ED01EDMK - FLOATING $ WITH EDMK (SIMPLE AMOUNTS)'
MSGCOMMA DC    CL60'ED01EDMK - FLOATING $ WITH A COMMA (LARGER AMOUNTS)X
               '

***********************************************************************
* PATMAST / PATTERN - a 12 byte edit pattern for a 5 byte packed field*
* (PL5 = up to 9 digits).  Format: 20 20 20 20 20 20 20 20 21 40 ...  *
* one digit selector per expected digit (9 digits -> 9 selectors), the*
* LAST one is X'21' to guarantee significance / R1 is always set, and *
* two spare bytes at the front for the floating $ and an extra blank. *
***********************************************************************
PATMAST  DC    X'402020202020202020202021' * 11 bytes: fill,8*sel,sel21
PATTERN  DS    CL11

AMTTAB   DC    PL5'0'                  * Zero - proves R1 still gets
*                                      * set via the forced X'21'
         DC    PL5'7'
         DC    PL5'450'
         DC    PL5'1234567'
AMTLEN   EQU   5
AMTCNT   DC    F'4'

***********************************************************************
* PATMAST2 / PATTERN2 - adds a comma 3 digits in from the right, for  *
* amounts up to 9,999,999 - the comma is a MESSAGE INSERTION byte, not*
* a digit selector, so it is suppressed automatically while everything*
* to its left is still non-significant                                *
***********************************************************************
PATMAST2 DC    X'40202020202020',C',',X'202021'
PATTERN2 DS    CL11

AMTTAB2  DC    PL5'1234567'
         DC    PL5'999'
         DC    PL5'1000000'
AMTLEN2  EQU   5
AMTCNT2  DC    F'3'

SYSOUT   DCB   DSORG=PS,MACRF=PM,DDNAME=SYSOUT,                        X
               RECFM=FB,LRECL=80,BLKSIZE=0

         LTORG

         END   ED01EDMK
