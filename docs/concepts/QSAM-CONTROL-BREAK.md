# QSAM Processing and Control Break

Scope: sequential files in move mode (`GET` and `PUT` with `MACRF=GM` and `PM`), the EODAD and SYNAD exits, open and close order, and control-break logic on a sorted file, as in QSAMPROC. Locate mode and other access methods are not used in any program and are not described. The outline below is a layout from the notes in LEARNING.md, not a copy of the program. The programs were not assembled or run.

Source programs: QSAMPROC (SYSOUT output also in every other program).

## Central Idea

A control-break program reads a sorted file and does work once per group of records. The group changes when a key value changes. A priming read, a loop per group, and a loop per record in the group make the logic the same for any group size.

## QSAM Calls

| Item | Use |
|---|---|
| `OPEN (dcb,(INPUT))` / `(dcb,(OUTPUT))` | Opens a file; sets no return code to test |
| `GET dcb,area` | Move mode (`MACRF=GM`): copies the next record to `area` |
| `PUT dcb,area` | Move mode (`MACRF=PM`): copies `area` to the buffer |
| `CLOSE (dcb)` | Flushes the last output buffer; skipping it can lose records |
| `EODAD=label` | Control goes to `label` instead of returning from `GET` at end of file |
| `SYNAD=label` | Control goes to `label` on a genuine I/O error |
| `LRECL=559,RECFM=FB,BLKSIZE=0` | Fixed 559-byte records, block size chosen by the system |

## Open and Close Order

- Open SYSPRINT first, because every error path writes to it.
- Close SYSPRINT last, because the counts are printed after the data files close.
- `PUT` to a file that is not open, or already closed, branches through a DCB with no write routine: S0C1.
- `OPEN` sets no return code. QSAMPROC checks that a DCB opened with `DCBD DSORG=PS`, `LA 2,dcb`, `USING IHADCB,2`, `TM DCBOFLGS,DCBOFOPN`, `DROP 2` and `BNO error`.

## EODAD

At the EODAD label R2 to R13 are preserved by QSAM. The base register and the return register of the caller of `READINP` are intact, so `BR 9` returns to the caller there.

## Control-Break Outline

```
open SYSPRINT, then the data files
priming read
outer loop (top-tested): leave at end of file
   INITGRP: reset flags and work areas
   inner loop:
      apply the rules to this record
      read the next record
      leave on end of file, customer change or connect id change
   write one record for the group
close the data files, print counts, close SYSPRINT
```

- The priming read means the first record is in the input area before the outer loop starts.
- When the inner loop exits, the input area already holds the first record of the next group.
- Flags and work areas are reset once per group in `INITGRP`. Flags are only switched on inside the record loop.
- A top-tested outer loop produces no output for an empty input.
- The header line is written just before the first detail record, not at `OPEN`, so an empty input gives an empty output.

## Record Layout

- The output record is built from named `DS` fields (`OUTNAME`, `OUTID`, and so on, with `OUTC1` to `OUTC17` for the separators). A field is referred to by name, not by offset.
- A `DC` of type C is limited to 256 bytes; types Z and P to 16 bytes. Use several `DC` statements or `DS` for a larger area.
- Clearing 559 bytes with a 256-byte constant: `MVC a(256),BLANK256`, `MVC a+256(256),BLANK256`, `MVC a+512(47),BLANK256`.

## Messages and Counters

- Message printing: `LA 1,msg`, `BAL 7,PRTMSG`. `PRTMSG` does `MVC PRTLINE(50),0(1)` and `PUT`. All messages are `CL50`.
- Counters are `PL5`: `ZAP` with `=P'0'`, `AP` with `=P'1'`. Display with `UNPK ZONE9(9),CNT(5)` and `OI ZONE9+8,X'F0'`.
- Linkage registers by calling level: R10 level 1, R9 level 2, R8 level 3, R7 `PRTMSG`. A routine must not use the register that holds its own return address for a further call.

## Common Failures

| Symptom | Cause | Fix |
|---|---|---|
| S0C1 at run time | `PUT` to SYSPRINT before it was opened | Open SYSPRINT first and close it last |
| Records missing at the end of the output | `CLOSE` skipped | Close every output file |
| ASMA068S on a blank constant | Type C longer than 256 bytes | Use `DS`, or split the constant |
| First record of a group lost or counted twice | No priming read, or the next record not kept at the break | Keep the record that caused the break for the next group |
| Header written for an empty file | Header written at `OPEN` | Write it before the first detail record |
| Return fails at EODAD | A register needed for the return was changed | Use a register from R2 to R13 that the caller left intact |
