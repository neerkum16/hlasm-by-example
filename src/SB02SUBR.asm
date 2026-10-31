***********************************************************************
* SB02SUBR - Called Subprogram, Standard Linkage                      *
* Purpose: A SEPARATE CSECT, assembled and existing independently of  *
*          its caller, that follows the z/OS STANDARD LINKAGE         *
*          CONVENTION so that ANY correctly written caller - CALL,    *
*          LINK, or straight BALR - can invoke it safely.             *
*                                                                     *
* What "standard linkage" means, concretely, in THIS pair of programs:*
*                                                                     *
*   - R13 on entry points at a savearea the CALLER has to provide for *
*     ME (SB02SUBR's own savearea, below) - SB02SUBR must NOT use     *
*     the caller's savearea, it must SAVE its OWN registers into the  *
*     NEW one R13 points to, then chain forward/backward.             *
*   - R1 on entry points at a PARAMETER LIST - a list of fullword     *
*     ADDRESSES, one per parameter, with the HIGH ORDER BIT of the    *
*     LAST address turned on.  That bit is how a called program knows *
*     where the list ENDS without being told a count separately.      *
*   - R14 on entry holds the RETURN address - BR 14 is how control    *
*     goes back to the caller, exactly like every other program in    *
*     this project.                                                   *
*   - R15 on entry holds THIS CSECT's entry address (used the usual   *
*     way to set up addressability); on RETURN, R15 is also where a   *
*     RETURN CODE belongs - the caller is expected to look at it.     *
*                                                                     *
* SB02SUBR receives two parameters: the address of a fullword to add  *
* to, and the address of a fullword holding the amount to add.  It    *
* adds them, and sets a return code in R15: 0 for a normal add, 4 if  *
* the resulting total went negative (a deliberately simple "business  *
* rule" purely to give the caller something meaningful to test).      *
***********************************************************************
         PRINT NOGEN
SB02SUBR CSECT
***********************************************************************
* Standard entry - SAME shape as every mainline in this project, but  *
* this CSECT is never run by JCL directly; it only ever reached via   *
* CALL/LINK from SB01CALL                                             *
***********************************************************************
         STM   14,12,12(13)            * Save CALLER's regs - into the
*                                      * savearea CALLER passed in R13
         LR    12,15                   * Load base register
         USING SB02SUBR,12             * Establish addressability
         ST    13,SUBSAVE+4            * Chain back: caller's savearea
*                                      * address goes into MY savearea
         LA    14,SUBSAVE              * R14 -> my savearea (temp - R14
*                                      * gets reloaded with return addr
*                                      * before BR 14 at the very end)
         ST    14,8(,13)               * Chain fwd: caller's savearea
*                                      * points down to mine - standard
*                                      * two way savearea chain
         LR    13,14                   * R13 now -> MY savearea for
*                                      * the rest of this routine

***********************************************************************
* R1 -> parameter list: two fullword addresses, high bit set on the
*       SECOND (last) one.  Load each address, then MASK the high bit
*       off before using the second one as a real address - the bit
*       is a FLAG, not part of the address, and must be cleared or
*       the address is garbage.
***********************************************************************
         L     2,0(,1)                 * R2 -> parm 1 (the total field)
         L     3,4(,1)                 * R3 -> parm 2 (amount field),
*                                      * STILL carrying high bit flag
         N     3,=X'7FFFFFFF'          * Mask flag off - R3 is now a
*                                      * genuine address

         L     4,0(,2)                 * R4 = current value of total
         A     4,0(,3)                 * R4 = total + amount
         ST    4,0(,2)                 * Store new total back for the
*                                      * caller to see

         LTR   4,4                     * Test the new total's sign
         BM    SUBRBAD
         MVI   RETCODE,0               * Return code 0 - normal
         B     SUBRRET
SUBRBAD  MVI   RETCODE,4               * Return code 4 - total negative

***********************************************************************
* Standard exit - restore CALLER's registers using the BACKWARD chain *
*                                                                     *
* IMPORTANT: LM 14,12,12(13) restores R14, R15, AND R0-R12 all in one *
* instruction (the range wraps 14,15,0,1,...,12) - that means it      *
* RELOADS R15 with whatever was saved at ENTRY, wiping out any return *
* code set before the LM.  The return code must therefore be loaded   *
* into R15 AFTER the LM, as the very last thing before BR 14 - which  *
* is exactly why it was parked in RETCODE (a byte in storage) instead *
* of directly in R15 up above.                                        *
***********************************************************************
SUBRRET  L     13,SUBSAVE+4            * R13 -> caller's savearea again
         LM    14,12,12(13)            * Restore caller's regs - R15
*                                      * comes back as ITS ENTRY value,
*                                      * not return code, on purpose
         IC    15,RETCODE              * NOW load real return code -
*                                      * after LM, so it survives
         BR    14

***********************************************************************
* Data areas - SB02SUBR's own private savearea, used ONLY while this  *
* CSECT is active; it is NEVER the caller's savearea                  *
***********************************************************************
SUBSAVE  DS    18F
RETCODE  DS    X                       * Return code parked here, to be
*                                      * loaded into R15 AFTER LM

         END   SB02SUBR
