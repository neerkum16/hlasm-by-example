# Test Coverage: Which Paths the Test Data Ran

Scope: for FS01SORT, MC01MACR, VB02FIX, SB01CALL, SB02SUBR, TB01TABL and ED01EDMK, which branches the test data ran and which it did not, how a path that never ran can be found by reading the source, test data that would run it, and comments that disagree with the code. The statements about paths come from the source and the SYSOUT screens in the program docs. The programs were not assembled or run by Claude, apart from the runs shown in the SYSOUT screens, and no result below was produced by a new run.

Source programs: FS01SORT, MC01MACR, VB02FIX, SB01CALL, SB02SUBR, TB01TABL, ED01EDMK.

## Central Idea

A clean run proves only the paths that the data took. Every `BE`, `BM`, `BH`, `BZ`, `BO` and every switch test is a path, and a test set that takes one side of each branch leaves the other side unchecked. Several defects in the repo sit on such paths, and none showed in the runs.

## How to Find an Unrun Path

1. List every conditional branch in the source.
2. For each one, find the line of test data that makes it go each way.
3. A branch with no such line is an unrun path. Write down the data that would run it.

| Program | Branch or path | Run? | Data that would run it |
|---|---|---|---|
| FS01SORT | `KEYA < KEYB`, `KEYA > KEYB`, one file at end | Yes | Test data used |
| FS01SORT | `KEYA = KEYB` (the match) | No | The same key in `FILEA` and `FILEB` |
| FS01SORT | Region change, grand total at end | Yes | Three regions |
| FS01SORT | An `OPEN` that fails | No | A missing DD |
| MC01MACR | `CHKOPEN` with a message | Yes (3 calls) | |
| MC01MACR | `CHKOPEN` without a message (`.NOMSG`) | No | A call with one operand |
| MC01MACR | Failure block (`PRTMSG`, `ABEND 999,DUMP`) | No | A missing DD |
| MC01MACR | `PRTMSG` with the default `DEST=SYSOUT` | No | A program with a `SYSOUT` DCB |
| VB02FIX | Length 0 (`NAMEZERO`) | Yes | |
| VB02FIX | Negative length (`NAMEBAD`) | No | A record whose length field is negative |
| VB02FIX | Length over 256 (`NAMEBAD`) | No | A record whose length field is above 256 |
| VB02FIX | A valid length (`NAMEOK`) | No | A record with a length from 1 to 256 |
| SB01CALL | Three calls, negative total | Yes | |
| SB02SUBR | `SUBRBAD` (`BM`, new total negative) | Yes (third call, total -99350) | |
| SB02SUBR | Non-negative total (`MVI RETCODE,0`) | Yes (first two calls) | |
| TB01TABL | Search found (MIKE), not found (ZULU), first entry (ALPHA) | Yes | |
| TB01TABL | Table at `MAXENT` (200 records) | No | 200 or more records in `TABFILE` |
| TB01TABL | Empty `TABFILE` | No | `DD DUMMY` for `TABFILE` |
| ED01EDMK | Amounts 7, 450, 1234567, 999, 1000000, 0 | Yes | |
| ED01EDMK | Negative amount | No | A packed amount with sign D |

## What the Unrun Paths Hide

| Program | Unrun path | What the source says it does |
|---|---|---|
| FS01SORT | Equal keys | The match branch processes the record from `FILEA` and reads the next record of both files, so the `FILEB` record is read past and not processed. This is read from the code and the banner, not run |
| MC01MACR | `.NOMSG` | The failure block is not generated, and the caller must test the condition code. The path assembles only if the call has one operand |
| MC01MACR | `OPEN` failure on `SYSPRINT` | `CHKOPEN` calls `PRTMSG` to `SYSPRINT`, so the message cannot be printed |
| VB02FIX | `NAMEBAD`, `NAMEOK` | Only the zero path ran, so the length test and the flag `NAMEOK` have no run behind them |
| TB01TABL | `MAXENT` | The check is one record late: the 201st `GET` stores a record in slot 201, past `TABLE` |
| ED01EDMK | Negative amount | Neither pattern has a minus sign, so a negative amount prints without one |
| SB01CALL | Return code | Prints 33280 on all three calls, which is the defect described in the linkage article. The fix has not been tried |
| SB01CALL | Negative total | `OI` after `UNPK` removes the sign: -99350 prints as 00099350. This path ran |

## Comments That Disagree with the Code

| Program | The comment says | The code does |
|---|---|---|
| FS01SORT | REGION is the match-merge key | `AKEY` and `BKEY` (columns 1-8) are compared, not the region |
| TB01TABL | A routine called `BINSRCH` | No such label; the search routine is `BSLOOP` |
| MC01MACR | A label `&LABEL.A&SYSNDX`, values `OPNA0007` and `OPNA0008`, and `BNO NOGOOD&SYSNDX` | `OK&SYSNDX` and `BO` |
| ED01EDMK | The forced `X'21'` sets R1 for the amount 0 | The `X'21'` is byte 12 and the work area has 11 bytes, so it is lost |
| ED01EDMK | `BCTR` also branches on the result | With register 0 it does not branch |

- A comment is a claim and the test data is the evidence. When they disagree, the code is what ran.
- Fix the comment or the code and record which one was wrong.

## Rules

- Write the branch list before the test data, not after.
- Give every conditional branch at least one record that takes it each way.
- Test the boundary values: 0, 1, the maximum, one more than the maximum, negative.
- Test the equal case of every comparison.
- Test an empty file.
- Test one failure of each check the program makes (a missing DD, a bad length).
- Keep a run's expected output in the doc next to the data that produced it.
- When a path cannot be run, say so in the doc, as the program docs do.

## Common Failures

| Symptom | Cause | Fix |
|---|---|---|
| Run is clean and a defect remains | The defective path never ran | Add data for that path |
| A record is missing from merged output | Equal keys were never tested | Add a record with the same key in both files |
| Storage overwritten at the table limit | Limit tested only below the maximum | Test with the maximum and one more |
| A check that was never needed to fire | No failing input | Add one failing record or a missing DD |
| Doc and code disagree | Comment not updated after a change | Correct the comment, and check the code against the run |
