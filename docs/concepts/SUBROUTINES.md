# Internal Subroutines with BAL

Scope: internal routines in the same CSECT called with `BAL reg,label` and left with `BR reg`, one return register per calling level, parameters in registers and in a parameter block addressed by R1, and an `EODAD` routine that returns like a routine, as used in DT01TYPE, DT02ARTH, QSAMPROC, BR09MTCH and DS02DSCT. Calls to other programs (`CALL`, `LINK`), routines with their own save area, `BALR`, `BAS` and recursion are not used in any program and are not described. Entry and exit linkage of the program itself is in the linkage article. The programs were not assembled or run, apart from the runs shown in the SYSOUT screens.

Source programs: DS02DSCT, BR09MTCH, QSAMPROC, DT01TYPE, DT02ARTH.

## Central Idea

`BAL` loads the address of the next instruction into a register and branches. `BR` on that register returns. The register is the only record of where to return, so a routine that calls another routine must not use the same register for the second call.

## Call and Return

```
         BAL   10,SHOWREC              * R10 = return address
         ...
SHOWREC  DS    0H                      * Routine
         ...
         BR    10                      * Back to the line after BAL
```

- A routine needs no save area and no linkage. It uses the registers of the caller.
- The caller sets up parameters before the `BAL`. The routine documents which registers it changes.

## One Register per Level

DS02DSCT has two levels:

| Level | Call | Return register |
|---|---|---|
| 1 | `BAL 10,SHOWREC`, `BAL 10,BUILDTOT`, `BAL 10,READREC`, `BAL 10,PRTMSG` from the mainline | R10 |
| 2 | `BAL 9,ADDAMT` from inside `BUILDTOT` | R9 |

- `BUILDTOT` was entered with `BAL 10`, so R10 holds the way back to `MAINLOOP`.
- The first version of DS02DSCT called `ADDAMT` with `BAL 10`. That overwrote R10 with an address inside `BUILDTOT`, so the final `BR 10` would branch to itself without end. The S0C7 abend hid this fault.
- The fix is `BAL 9,ADDAMT` with `BR 9` in `ADDAMT`.

QSAMPROC assigns registers by level: R10 for level 1, R9 for level 2, R8 for level 3, and R7 for `PRTMSG`, which is called from any level and so has its own register.

A routine that calls no other routine can share the register of its own level. BR09MTCH calls only leaf routines, all with `BAL 10` (`READ1`, `READ2`, `OPENCHK`, `PRTCNTS`), so R10 is never overwritten.

## Routines That Cannot Call Each Other

`PKDISP` and `HEXDISP` in DT02ARTH both use R11. If one called the other, R11 would be overwritten and the first routine could not return.

## Passing Parameters

| Method | Example |
|---|---|
| Values or addresses in registers | `HEXDISP`: R2 address, R3 length, R10 output address (DT01TYPE, DT02ARTH) |
| Address of a message | `LA 1,MSGSTRT`, `BAL 10,PRTMSG`; `PRTMSG` does `MVC PRTLINE(50),0(1)` |
| Address of a DCB | `LA 2,dcb`, `BAL 10,OPENCHK` |
| Address of a parameter block in R1 | `LA 1,PARMAREA`, `BAL 9,ADDAMT` |

- A routine that changes a parameter register says so in its comments. `HEXDISP` changes R2, R3 and R10, so the caller reloads them before each call.
- R1 is the conventional register for a parameter list address.

## Parameter Block

`BUILDTOT` fills a block and passes its address in R1. `PARMD` is the DSECT that maps it. `ADDAMT` issues `USING PARMD,1`, adds `PARMAMT` to the total, and issues `DROP 1`.

- `ADDAMT` has never heard of `INAREA` or `PARTD`. It depends only on the layout of the block, so it could be called by any code that builds one.
- `DROP` does not change a register, so R1 still holds the address at the `BAL`.
- `ADDAMT` updates `GRANDTOT` by name, outside the block. `PARMTOT` is defined and never used. A stricter routine would receive the address of the total in the block.

## Macros and Registers

- `GET`, `PUT` and `OPEN` change R0, R1, R14 and R15. QSAM preserves R2 to R13.
- Return addresses and base registers are therefore kept in R2 to R13 (R9, R10, R12 here).
- Load R1 just before use, with no macro between the `LA` and the call. DS02DSCT does `LA 1,MSGSTRT` immediately before `BAL 10,PRTMSG`.

## EODAD Routines

`EODAD=EOFRTN` in an input DCB makes `GET` jump to `EOFRTN` at end of file instead of returning.

- The `GET` is inside a routine (`READREC`, `READ1`, `READ2`), so the `EOFRTN` code runs in place of the rest of that routine and must end with `BR` on the same return register: `BR 10`.
- This works because QSAM preserves R2 to R13, so R10 still holds the address set by the `BAL` that called the read routine.
- The routine sets a switch (`EOFSW`, `EOF1`, `EOF2`) and, in BR09MTCH, moves `HIVALUE` into the key. The line after the `GET`, such as `AP CNT1,=P'1'`, is skipped, so the count is not incremented for end of file.

## Rules

- One return register per level. Write the level table as a comment at the top of the source.
- A routine ends with `BR` on the register its caller used. A mismatch such as `BAL 9` and `BR 10` loops or branches to the wrong place.
- Do not use R0, R1, R14 or R15 for anything that must survive a macro.
- Put the `LA` for a parameter immediately before the `BAL`.
- Keep the routine's parameter contract (registers in, registers changed) in its comment block.

## Common Failures

| Symptom | Cause | Fix |
|---|---|---|
| Program loops at a `BR` | Called routine used the same return register as its caller | A separate register per level |
| Return lands in the wrong place | `BAL` and `BR` use different registers | Match them |
| Parameter is wrong after a macro | R1 changed by `GET`, `PUT` or `OPEN` | Load R1 right before the call |
| Second call of a routine reads wrong data | Routine changed R2, R3 or R10 | Reload the parameters |
| End of file does not return | `EOFRTN` ends without `BR` or with the wrong register | `BR` on the caller's return register |
