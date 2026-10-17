# Program Linkage and Addressability

Scope: the standard entry and exit linkage with a backward-chained save area, the base register and `USING`, a second base register for programs over 4096 bytes, and internal routines called with `BAL`, as used in the repo programs. Forward chaining of save areas, calls to other programs (`LINK`, `CALL`) and parameter lists in R1 are not used in any program and are not described. The programs were not assembled or run.

Source programs: HELLO and every other program (entry and exit linkage), QSAMPROC (two base registers), DT01TYPE and DT02ARTH (`BAL` routines).

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
