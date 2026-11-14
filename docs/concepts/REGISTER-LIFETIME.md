# Register Lifetime: What Keeps a Value and What Loses It

Scope: how long a value stays in a register in the programs of this repo, and what ends it: system macros (`OPEN`, `GET`, `PUT`, `CLOSE`), a call to another program, `LM`, a nested `BAL`, a macro that uses a register of its own, and `EDMK`. The cases are taken from SB01CALL, SB02SUBR, ED01EDMK, FS01SORT, VB01LOC, VB02FIX, TB01TABL, MC01MACR and DS02DSCT. Register pairs are in the register-pairs article, and the linkage and subroutine mechanics are in their own articles. Floating-point and access registers are not used in any program and are not described. Where the repo has no run showing a register being changed, the text says so. The programs were not assembled or run, apart from the runs shown in the SYSOUT screens.

Source programs: SB01CALL, SB02SUBR, ED01EDMK, FS01SORT, VB01LOC, VB02FIX, TB01TABL, MC01MACR, DS02DSCT.

## Central Idea

A register holds a value only until something writes to it. Assembler does not warn when that happens, and the failure appears later and elsewhere. The repo's register faults share one pattern: a value was assumed to still be there after an instruction that was known to reuse the register, or an instruction that sets a register conditionally was assumed to have set it.

## Who Changes What

| Register | Changed by | Evidence in the repo |
|---|---|---|
| R1 | `GET` and `PUT` (it returns the buffer address in locate mode), other system macros, `CALL` (the parameter list) | VB01LOC and VB02FIX do `LR 3,1` and `LR 4,1` straight after the macro; SB01CALL abended S0C4 because R1 was never loaded with the list |
| R15 | `PUT` and other system macros, `CALL` (entry address), `LM` (reloads it), the called program (return code) | `SHOWRC` in SB01CALL saves R15 first because the `PUT` that follows reuses it; SB02SUBR sets R15 after `LM` |
| R12 (base) | `LM 14,12,12(13)` restores the caller's value | `IC 15,RETCODE` after the `LM` in SB02SUBR is addressed through the caller's base |
| R10 (return) | A nested `BAL 10` | DS02DSCT's `BAL 10,ADDAMT` overwrote the return to `MAINLOOP`; FS01SORT's source comment records the same fault for `PUTSUBT` |
| R2 | The `CHKOPEN` macro (`LA 2,&DCB`) | MC01MACR uses and drops R2 in every expansion |
| R1 | `EDMK`, but only when a digit selector becomes significant | ED01EDMK: R1 is stale for the amount 0 |
| R3 | The program itself, for two purposes | TB01TABL: `BXLE` limit during the walk, MID offset during the search |
| R0, R1, R14, R15 | System macros, by the standard convention | R15 and R1 are shown in the runs above. R0 and R14 are not shown in any run |

## Cases

**Locate mode: R1 after `GET` and `PUT`.** The buffer address arrives in R1, and the next system macro changes R1. VB01LOC and VB02FIX copy it at once (`LR 3,1` for the input, `LR 4,1` for the output), and `BUILDOUT` holds both. At end of file the `LR` after the `GET` is skipped, so R3 still holds the last record's address.

**A call that was never set up: R1.** The hand-built call in SB01CALL had `L 15,=V(SB02SUBR)` and `BALR 14,15` but no `LA 1,PARMLST1`. R1 held what `OPEN` and `PUT` had left in it, and the first `L 2,0(,1)` in SB02SUBR used that value as an address: S0C4 right after the heading line.

**`LM` reloads R15 and R12.** `LM 14,12,12(13)` restores R14, R15 and R0 to R12 to the values saved at entry. In SB02SUBR:
- The return code is kept in the one-byte field `RETCODE`, because a code placed in R15 before the `LM` would be lost.
- `IC 15,RETCODE` after the `LM` is addressed through R12, which is now the caller's base. Per SB01CALL.md and SB02SUBR.md, the byte read is not `RETCODE` and the return code prints as 33280 on all three calls. This is inferred from the source and the SYSOUT.
- Only the low byte of R15 is replaced by `IC`, so the other three bytes keep the entry address that `LM` restored.

**A macro changes R15 under you.** `SHOWRC` starts with `ST 15,SAVERC` because `PUT` reuses R15. The return code is read from storage afterwards.

**A nested `BAL` replaces the return address.** `BAL 10,ADDAMT` inside a routine entered with `BAL 10` overwrites R10, and the final `BR 10` then branches into the routine itself. FS01SORT's `COMMON` calls `PUTSUBT` with `BAL 9`, so R10 still returns to `MERGE`. Details are in the subroutines article.

**A macro that uses a register.** `CHKOPEN` loads the DCB address into R2 (`LA 2,&DCB`), maps `IHADCB` on it and drops the mapping. A program that kept a value in R2 across a `CHKOPEN` loses it. MC01MACR keeps nothing in R2.

**`EDMK` sets R1 only sometimes.** For an amount with a significant digit R1 holds the address of the first digit. For 0 in ED01EDMK no digit selector becomes significant, R1 is left alone, and `BCTR 1,0` with `MVI 0(1),C'$'` store a `$` through the stale value. No abend: the address was valid, so the damage was silent.

**One register, two jobs.** TB01TABL uses R3 as the `BXLE` limit while it walks the table and as the byte offset of MID while it searches. The two uses do not overlap, because the walk has ended before the search starts. `L 3,TABLEND` reloads the limit before every `BXLE`.

**Values kept in storage.** VB01LOC stores the name length and length minus 1 (`ST 5,NAMELEN`, `ST 5,NAMELENM1`) and reloads R5 before the `EX`. VB02FIX tests the length once and keeps a one-byte flag `NAMEOK`, so `SHOWREC` and `BUILDOUT` need no register that survives from `READREC`.

## Rules

- Save R1 with `LR` immediately after a locate-mode `GET` or `PUT`.
- Load R1 and R15 immediately before every hand-built call.
- Save R15 straight after a call, before any macro runs.
- Set the return code after the `LM`, and address its field through a register that is valid after the `LM`.
- Use a separate return register for each level of `BAL`.
- Keep a value that must survive a macro or a call in R2 to R11, or in storage.
- Do not assume a register was set by an instruction that sets it only in some cases (`EDMK`). Set it first.
- When a macro uses a register, record that in its prologue comment, and do not keep values in it.
- Give one register one job in a routine, or document the change.

## Common Failures

| Symptom | Cause | Fix |
|---|---|---|
| S0C4 at the first use of a parameter list | R1 not loaded | `LA 1,list` before the call |
| Wrong fields from a locate-mode record | R1 changed by a macro before it was copied | `LR` straight after `GET` or `PUT` |
| Return code lost in the caller | R15 reused by `PUT` | `ST 15,SAVERC` first |
| Return code is not the one set | `LM` reloaded R15 and R12 | Set R15 after the `LM` through a valid base |
| Routine returns into itself | Nested `BAL` used the same return register | A different register per level |
| `$` stored before an output line | `EDMK` left R1 stale for an amount with no significant digit | Set R1 first, or test for zero |
| A value in R2 disappears around `CHKOPEN` | The macro loads R2 | Keep the value in another register |
| Wrong value after a long routine | One register used for two jobs | Separate registers, or reload |
