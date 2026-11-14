# Boundary Cases and Storage Overruns

Scope: the overruns and over-reads that appear in the repo's programs and runs, and how each one showed up: the 256-byte `MVC` into `PRTLINE` in VB01LOC, the 10-byte move from a 9-byte literal in DS01DSCT, the unchecked name length in VB01BILD, and the S0C7 in DS02DSCT that hid a second fault. Also included: a bad address in R1 that ended in S0C4 (SB01CALL), an `EDMK` that left R1 stale (ED01EDMK), and the table check that fires one record late (TB01TABL). Storage protection abends caused by an overrun were not seen in any run and are not described. What an overrun overwrote is known only where the docs state it. The programs were not assembled or run, apart from the runs shown in the SYSOUT screens.

Source programs: VB01LOC, DS01DSCT, VB01BILD, DS02DSCT, VB02FIX, TB01TABL, ED01EDMK, SB01CALL.

## Central Idea

Assembler does not check a length against the field it is used with. A move that is too long copies bytes from the neighbouring storage, or writes over it, and the program carries on. The damage appears where the neighbour is used, which can be a different line, a different message or a different record. Boundary values, such as zero and the longest case, are where lengths go wrong.

## Cases in the Repo

| Program | What happened | Visible symptom | Not visible |
|---|---|---|---|
| VB01LOC | Empty name: `BCTR` gives -1, `EX` moves 256 bytes into the 80-byte `PRTLINE` | Line 5 shows the next record's bytes at column 25; the end message is a blank line | What the 196 bytes after `PRTLINE` held afterwards |
| DS01DSCT | `MVC OUTMSG(10),=C'CUST NO: '` copies 10 bytes from a 9-byte literal | `N`, `B`, `B` and `Ø` in column 10 | Nothing hidden: the extra byte is the next literal's first byte |
| VB01BILD | Name length is not checked against 20 | None in the run | A name over 20 bytes would run past the end of the buffer |
| DS02DSCT (first version) | `GRANDTOT` never initialised, so `AP` abended with S0C7 | The abend, after record 1 printed correctly | A second fault: `BAL 10,ADDAMT` overwrote R10, so the return would loop |
| VB02FIX | The empty-name length is tested before `EX` | Line 5 correct, end message printed | Negative and over-256 paths, not in the test data |
| TB01TABL | `C 8,=F'200'` / `BNH` is tested after the `GET`, so the 201st record is stored in slot 201 | None: the test file has 8 records | Read from the code, not run. Slot 201 is 12 bytes past `TABLE`, where the `TABFILE` DCB follows |
| ED01EDMK | Amount 0: `EDMK` leaves R1 stale, then `BCTR 1,0` and `MVI 0(1),C'$'` store a `$` one byte before it | Blank result line, no `$` | The byte that was overwritten was not identified |
| ED01EDMK | `MVC OUTMSG(12),PATTERN` copies 12 bytes from `PATTERN CL11` | A blank at column 12, which is `X'00'` | Nothing hidden: the extra byte is the first byte of `AMTTAB` |
| SB01CALL (first version) | `LA 1,PARMLST1` missing, so `L 2,0(,1)` in SB02SUBR uses a stale R1 | S0C4 right after the heading line | The return-code defect that appeared after the fix |

## What an Overrun Overwrites

The damage follows the order of definitions in storage. In VB01LOC the data area runs `PRTLINE`, `ZONE7`, `BLANKS`, `MSGSTRT`, `MSGEND`, `MSGOPN1` and `MSGOPN2`.

- The 256-byte move starts at `PRTLINE+20`, so it ends 196 bytes past the end of `PRTLINE`.
- That reaches `ZONE7`, `BLANKS`, `MSGSTRT` and all of `MSGEND`, which is why the end message was blank.
- Hand-computed from the field lengths, assuming no padding between them: `PRTLINE` is offsets 0 to 79, `ZONE7` 80 to 86, `BLANKS` 87 to 166, `MSGSTRT` 167 to 216, `MSGEND` 217 to 266, and the move ends at offset 275, so it also reaches the first 9 bytes of `MSGOPN1`. `MSGOPN1` is used only when an open fails. `MSGOPN2` is not reached.
- `BLANKS` is the constant that `SHOWREC` copies into `PRTLINE` to clear every line. After the overrun, later lines are cleared with whatever now sits in `BLANKS`. Line 5 looks clean on the screen, so those bytes displayed as blanks; their values are not recorded.
- A different order of definitions would damage something else. The same bug could print correctly and fail later.
- The symptom is far from the cause. The wrong line 5 comes from record 4, and the missing message comes from the same move.

## Over-Reads

An over-read copies bytes that belong to something else, without damaging them.

- DS01DSCT: the tenth byte is the first byte of the next literal in the pool. The pool is in order of first use, so the stray character depends on which literal comes next. For the last literal it is the byte after the pool, which the program does not control.
- VB01LOC: the source for the 256-byte move is the empty-name record plus the start of the next record in the same buffer.
- ED01EDMK: `MVC OUTMSG(12),PATTERN` reads one byte past the 11-byte `PATTERN`. The byte is `X'00'` and shows as a blank, so the run looks correct.
- SB02SUBR reads two addresses from the list in R1 without checking the count. A list with one parameter would make `L 3,4(,1)` read the next word.

## Bad Pointers

A register with a wrong address behaves like an overrun in reverse: the program reads or writes storage it does not own.

- SB01CALL: the hand-built call had no `LA 1,PARMLST1`. R1 held what `OPEN` and `PUT` left. SB02SUBR's first instruction `L 2,0(,1)` used it as an address and the job abended S0C4 after the heading line.
- ED01EDMK: R1 is set by `EDMK` only when a digit becomes significant. For an amount of 0 R1 kept an old value, and `BCTR`/`MVI` stored a `$` through it. No abend: the address was valid, so the damage was silent.
- A stale address abends only when it points to storage the program may not use. An address inside the program's own storage changes data and the run goes on.

## One Fault Hiding Another

DS02DSCT's first version failed at `AP` on the first record. The S0C7 stopped the run before the second fault could act: `BUILDTOT` called `ADDAMT` with `BAL 10`, which overwrote R10, the return address to `MAINLOOP`, so the final `BR 10` would have branched to itself. Fixing the first fault would have exposed the second. It was found by reading the code.

SB01CALL shows the same order. The first run ended with S0C4 at the missing `LA 1,PARMLST1`. After that fix the run completed and the return code printed 33280 on all three calls. That value comes from a second fault in SB02SUBR (`IC 15,RETCODE` after `LM` has changed R12), which the abend had hidden.

## Boundary Tests

| Boundary | Example in the repo | What it showed |
|---|---|---|
| Zero | The empty name in record 4 | The only case that failed in VB01LOC |
| One | Not built | `MVC` length 1 is the smallest move |
| Typical | Names of 5, 10 and 12 bytes | Correct |
| Longest | The 20-byte name in record 3 | Correct |
| Longest plus one | Not built | Would overrun the buffer in VB01BILD |
| Counts | `PL4` counters show 7 digits | A count over 9999999 loses its leftmost digit |
| Zero amount in an edit | ED01EDMK amount 0 | Failed: `$` stored through a stale R1 |
| Table at its maximum | TB01TABL, not built (8 of 200) | Would show the check one record late |
| Empty file | TB01TABL, FS01SORT, not built | Walk prints an unfilled slot; the merge handles it by the switches |
| Zero length with the check | VB02FIX record 4 | Passed; negative and over-256 not built |

VB01BILD builds a short, a typical, a longest and an empty case. The empty case is the one that exposed the fault. Its record 4 was included on purpose, and the reader fails on it.

## Rules

- Test zero, one, the longest allowed value, and one more than that.
- Validate a length before it is used by `EX` or by a move whose length comes from data.
- Make a literal as long as the move that uses it.
- When a run is wrong in one place, look for what is defined next to the storage that was written.
- Do not count a clean first run as a pass. A fault can wait for a boundary value.
- After fixing the first failure, read the rest of the path for the next one.
- Set a register before an instruction that may leave it unchanged (`EDMK`), or test for the case first.
- Test a table count before the `GET` that would fill the next slot.
- Load R1 immediately before every call that reads a parameter list.

## Common Failures

| Symptom | Cause | Fix |
|---|---|---|
| A message or line is wrong for no clear reason | An earlier move overran its target | Check lengths and field order |
| Wrong data appears after a field | Over-read of the neighbouring storage | Match the length to the source |
| The program passes with normal data and fails on a rare record | No boundary test | Build zero and longest cases |
| A run abends on the first record | An uninitialised field | Initialise every work field |
| Fixing an abend exposes a new fault | The abend stopped the run early | Read the code after the failing point |
| S0C4 at the first instruction of a called program | R1 not loaded with the parameter list | `LA 1,list` before the call |
| A byte before an output line changes with no abend | A register used as an address was stale | Set the register first, or skip the code when it is not set |
| One record too many stored in a table | Maximum tested after the store | Test before the `GET` |
