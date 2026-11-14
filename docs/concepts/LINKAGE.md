# Program Linkage and Addressability

Scope: the standard entry and exit linkage with a backward-chained save area, the base register and `USING`, a second base register for programs over 4096 bytes, and internal routines called with `BAL`, and one separate program called with `CALL` and `BALR` (SB01CALL calling SB02SUBR): the parameter list in R1, the two-way save area chain and the return code in R15. `LINK` appears only in a comment of SB01CALL and is not run, so it is not described beyond that. Re-entrant programs are not used in any program and are not described. The programs were not assembled or run, apart from the runs shown in the SYSOUT screens.

Source programs: HELLO and every other program (entry and exit linkage), QSAMPROC (two base registers), DT01TYPE and DT02ARTH (`BAL` routines), SB01CALL and SB02SUBR (separate program, parameter list, return code).

## Central Idea

A program is entered with registers belonging to its caller. It saves them, tells the assembler which register holds its address, and restores everything before it returns. The base register works only up to 4096 bytes, so a longer program needs a second one.

## Register Conventions

| Register | Use |
|---|---|
| R0, R1 | Parameter and work registers; clobbered by system services |
| R12 | Base register (by convention in these programs) |
| R13 | Address of save area |
| R14 | Return address |
| R15 | Entry-point address on entry; return code on exit |

## Entry Linkage

```
PROG     CSECT
         STM   14,12,12(13)            * Save caller's registers
         LR    12,15                   * Load base register
         USING PROG,12                 * Establish addressability
         ST    13,SAVEAREA+4           * Chain savearea (backward)
         LA    13,SAVEAREA             * Load address of savearea
```

- `STM 14,12,12(13)` stores R14, R15 and R0 to R12 in the caller's save area, starting at displacement 12.
- `LR 12,15` copies the entry address into the base register. `USING PROG,12` tells the assembler that R12 holds the address of `PROG`, so it can turn labels into base and displacement.
- `ST 13,SAVEAREA+4` stores the caller's save area address in word 2 of this program's save area. That is the backward chain.
- `LA 13,SAVEAREA` makes R13 point to this program's save area.
- `SAVEAREA DS 18F` is 72 bytes, 18 words.

## Exit Linkage

```
         CLOSE (SYSOUT)                * Close sysout
         L     13,SAVEAREA+4           * Restore caller's savearea
         LM    14,12,12(13)            * Restore caller's registers
         SR    15,15                   * Set return code to 0
         BR    14                      * Return to caller
```

- `L 13,SAVEAREA+4` must come first, because `LM` addresses the caller's save area through R13.
- `LM 14,12,12(13)` reloads R14, R15 and R0 to R12. It restores R15 too, so `SR 15,15` has to come after it. Setting the return code before the `LM` would lose it.
- `BR 14` returns to the caller.

## Addressability

- A displacement is 12 bits, so one base register reaches 4096 bytes.
- Storage past 4096 bytes (literal pool, DCBs, data) needs another base register. The symptom is ASMA034E, operand beyond active `USING` range.

QSAMPROC uses two base registers:

```
         USING QSAMPROC,12,11
         LA    11,4095(,12)
         LA    11,1(,11)
```

- The first register named in `USING` covers the first 4096 bytes; the second covers the next 4096.
- Two `LA` instructions are used because 4096 does not fit in a 12-bit displacement.
- R11 is then not available for linkage, which is why `PRTMSG` uses R7.
- `LTORG` places the literal pool where the base registers reach it.

## Internal Routines

- `BAL 11,routine` calls an internal routine and `BR 11` returns. Parameters are in registers. In `HEXDISP`, R2 holds the address, R3 the length and R10 the output address.
- A routine that calls another routine must use a different register for the second return address, or the first return address is lost. DT02ARTH's `PKDISP` and `HEXDISP` cannot call each other because both use R11.
- QSAMPROC assigns a linkage register per calling level: R10 level 1, R9 level 2, R8 level 3, R7 `PRTMSG`. A routine must not use the register that holds its own return address for a further call.
- A routine that changes registers must say so. `HEXDISP` changes R2, R3 and R10 and does not use R4, so the caller reloads them before each call.

## Calling a Separate Program: SB01CALL and SB02SUBR

The two programs are assembled as two object decks and link-edited into one load module. `=V(SB02SUBR)` and the `CALL` macro are resolved by the linkage editor.

| Register | On entry to the called program | On return |
|---|---|---|
| R1 | Address of the parameter list | Not defined |
| R13 | Address of the caller's save area | Restored by the called program |
| R14 | Return address | Restored by `LM` |
| R15 | Entry address of the called program | Return code |

Caller, written by hand and with the macro:

```
         LA    1,PARMLST1              * R1 = parameter list
         L     15,=V(SB02SUBR)         * R15 = entry address
         BALR  14,15                   * R14 = return address, branch
         ...
         CALL  SB02SUBR,(TOTAL,AMOUNT) * The same call by macro
PARMLST1 DC    A(TOTAL)                * Word 1: address of parameter 1
         DC    X'80',AL3(AMOUNT)       * Word 2: last address, high bit on
```

- The parameter list is one fullword address per parameter. The high-order bit of the last address marks the end, so the called program needs no count.
- Per SB01CALL.md the `CALL` macro sets that bit only when `VL` is coded, and `VL` is not coded in SB01CALL. The comments in the source say the bit is set automatically. SB02SUBR masks the bit with `N 3,=X'7FFFFFFF'` and never tests it, so the run is the same either way.
- `LA 1,PARMLST1` must come before every hand-built call. The first version of SB01CALL left it out and abended with S0C4 at `L 2,0(,1)` in SB02SUBR, because R1 held whatever `OPEN` and `PUT` left in it.
- A comment in SB01CALL shows `LINK EP=SB02SUBR,PARAM=(TOTAL,AMOUNT)` as the one line that would load the program by name at run time. It was not run.

Called program, entry and exit:

```
         STM   14,12,12(13)            * Into the caller's save area
         LR    12,15
         USING SB02SUBR,12
         ST    13,SUBSAVE+4            * Backward chain
         LA    14,SUBSAVE
         ST    14,8(,13)               * Forward chain
         LR    13,14                   * R13 = own save area
         ...
         L     13,SUBSAVE+4
         LM    14,12,12(13)
         IC    15,RETCODE              * Return code after the LM
         BR    14
```

- SB02SUBR has its own save area `SUBSAVE` and chains it both ways: `ST 13,SUBSAVE+4` and `ST 14,8(,13)`. The mainlines in the other programs chain backward only.
- `LM 14,12,12(13)` reloads R15, so a return code put in R15 before the `LM` is lost. SB02SUBR keeps it in the byte `RETCODE` and loads R15 after the `LM`.
- `IC` replaces only the low byte of R15. Use `SR 15,15` first, or the other three bytes keep their old value.
- Per SB01CALL.md and SB02SUBR.md, the run prints RETURN CODE 33280 (X'00008200') on all three calls, where the third should give 4. The reading in those docs: `LM` restores R12 to the caller's base, so the `RETCODE` reference in `IC 15,RETCODE`, based on R12, reads a byte from SB01CALL and not from `RETCODE`, and the upper three bytes of R15 are the entry address that `LM` restored. This is inferred from the source and the SYSOUT, and the source is not changed. The fix suggested in the docs is untested: `SR 15,15` and `IC 15,RETCODE` before the `LM` while R12 is still valid, then `L 13,SUBSAVE+4`, `ST 15,16(,13)` and `LM 14,12,12(13)`, so that `LM` restores the return code into R15.
- `SUBSAVE` and `RETCODE` are static storage in the CSECT, so SB02SUBR is not re-entrant.
- The caller must save R15 at once. `SHOWRC` does `ST 15,SAVERC` as its first instruction, because the `PUT` that follows reuses R15.

## I/O Macros

`OPEN`, `PUT`, `GET` and `CLOSE` use R0, R1 and the system services, so values kept in those registers across a call are lost. Keep long-lived values in R2 to R11, or in storage.

## Common Failures

| Symptom | Cause | Fix |
|---|---|---|
| Return to a wrong address or abend after `BR 14` | R13 or R14 not restored | Follow the exit sequence exactly |
| Return code not 0 | `SR 15,15` before `LM`, or the `LM` restores the caller's R15 | Put `SR 15,15` after `LM` |
| ASMA034E | Program longer than 4096 bytes with one base register | Add a second base register with `USING name,12,11` |
| Value in R0 or R1 lost after `PUT` | System services use those registers | Keep the value elsewhere |
| Routine returns into itself | Return register reused for a nested call | A separate return register per level |
| S0C4 at the first use of the parameter list | R1 not loaded before the call | `LA 1,list` immediately before `L 15,...` |
| Return code in R15 is not the one set | `LM` reloaded R15 after the code was set | Load R15 after the `LM`, and clear the other bytes |
| Return code read from the wrong storage | Base register changed by `LM` before the field is addressed | Read the field before the `LM`, or use a register that stays valid |
| Return code lost in the caller | R15 reused by `PUT` or another macro | Save R15 straight after the call |
