# Match-Merge of Two Sorted Files

Scope: comparing two files sorted on the same key with one current record per file, a `CLC` three-way decision, draining the rest of one file after the other ends, end-of-file switches and `HIVALUE`, as in BR09MTCH, and the same merge feeding a control break on the merged stream, as in FS01SORT. Files with more than two inputs, repeated keys paired as groups and update or transaction matching are not used in any program and are not described. Control break on one file is in the QSAM article. The programs were not assembled or run, apart from the runs shown in their SYSOUT screens.

Source programs: BR09MTCH, FS01SORT.

## Central Idea

Two files sorted in the same order never need to be searched. Keep one record from each in storage and compare their keys. The lower key cannot appear in the other file, so it is dealt with and only its own file moves forward. An equal key is dealt with in both files and both move forward. Each pass consumes at least one record, so the program ends after about the sum of the two file sizes.

## Data

| Field | Definition | Role |
|---|---|---|
| `KEY1`, `KEY2` | `CL10` | Current record of each file (the record is only the key) |
| `EOF1`, `EOF2` | `CL1`, `N` then `Y` | End-of-file switches |
| `HIVALUE` | `10X'FF'` | Placed in a key at end of file |
| `OUT1ONLY`, `OUT2ONLY`, `OUTCOMM` | Output DCBs, `LRECL=10` | Key only in file 1, only in file 2, in both |
| `CNT1`, `CNT2`, `CNTONLY1`, `CNTONLY2`, `CNTCOMM` | `PL4` | Counts |

## Decision Table

| EOF1 | EOF2 | Keys | Path | Written to | Next record from |
|---|---|---|---|---|---|
| N | N | `KEY1 = KEY2` | `MATCHED` | `OUTCOMM` | Both files |
| N | N | `KEY1 < KEY2` | `FLUSH1` | `OUT1ONLY` | File 1 |
| N | N | `KEY1 > KEY2` | `FLUSH2` | `OUT2ONLY` | File 2 |
| N | Y | not compared | `FLUSH1` | `OUT1ONLY` | File 1 |
| Y | N | not compared | `CHECK2`, then `FLUSH2` | `OUT2ONLY` | File 2 |
| Y | Y | not compared | `CHECK2`, then `ALLDONE` | none | none |

## Loop Layout

```
         BAL   10,READ1                * Priming reads
         BAL   10,READ2
MAINLOOP CLI   EOF1,C'Y'
         BE    CHECK2                  * File 1 ended
         CLI   EOF2,C'Y'
         BE    FLUSH1                  * File 2 ended, drain file 1
         CLC   KEY1,KEY2
         BE    MATCHED
         BL    FLUSH1
         B     FLUSH2
```

- `FLUSH1`: `MVC OUT1REC,KEY1`, `PUT OUT1ONLY,OUT1REC`, `AP CNTONLY1,=P'1'`, `BAL 10,READ1`, `B MAINLOOP`. `FLUSH2` is the mirror image.
- `MATCHED`: write `KEY1` once to `OUTCOMM`, count it, read both files, `B MAINLOOP`.
- `CHECK2`: file 1 has ended. If file 2 has also ended go to `ALLDONE`. Otherwise `B FLUSH2`.
- Every path ends with `B MAINLOOP` except `CHECK2`, which leaves the loop only to `ALLDONE`.

## Read Routines and End of File

- `READ1`: `MVC KEY1,BLANKS10`, `GET INFILE1,KEY1`, `AP CNT1,=P'1'`, `BR 10`.
- `GET` has no return code. At end of file it jumps to `EOF1RTN`: `MVI EOF1,C'Y'`, `MVC KEY1,HIVALUE`, `BR 10`.
- The count in `READ1` is skipped at end of file, so `CNT1` counts records, not attempts.
- An empty file sets its switch at the priming read, so the main loop handles it as a file that ended at the start.

## Hand-Computed Trace

File 1 holds keys 1, 3, 5. File 2 holds 3, 4. The key values are not from the repo's run, which has 5 records per file.

| Step | KEY1 | KEY2 | Action | Written to |
|---|---|---|---|---|
| 1 | 1 | 3 | Low: `FLUSH1`, read file 1 | `OUT1ONLY`: 1 |
| 2 | 3 | 3 | Equal: `MATCHED`, read both | `OUTCOMM`: 3 |
| 3 | 5 | 4 | High: `FLUSH2`, read file 2 gives end of file | `OUT2ONLY`: 4 |
| 4 | 5 | HIVALUE | EOF2 is Y: `FLUSH1`, read file 1 gives end of file | `OUT1ONLY`: 5 |
| 5 | HIVALUE | HIVALUE | EOF1 is Y: `CHECK2`, EOF2 is Y: `ALLDONE` | none |

Counts: read 3 and 2; file-1-only 2; file-2-only 1; common 1.

## Checking the Counts

Records read from file 1 equal file-1-only plus common. Records read from file 2 equal file-2-only plus common. The repo run gives 4 + 1 = 5 for each file, and 4 + 4 + 1 = 9 records written.

## Merge Feeding a Control Break: FS01SORT

FS01SORT merges `FILEA` and `FILEB` into one stream and prints a subtotal when the region changes. Each record is 20 bytes: key `CL8` at column 1, region `CL6` at column 9, amount as 6 zoned digits at column 15.

| File | Records |
|---|---|
| `FILEA` | A001, A003, B002, B004, C005 |
| `FILEB` | A002, B003, C004, C006 |

```
MERGE    CLI   EOFASW,C'Y'
         BE    MRGONLYB
         CLI   EOFBSW,C'Y'
         BE    MRGONLYA
         CLC   AKEY,BKEY
         BE    MRGMATCH                * Equal
         BL    MRGTAKEA                * File A lower
         B     MRGTAKEB                * File B lower
```

- Each path does `BAL 10,PROCA` or `BAL 10,PROCB`, reads the next record from only the file that was used, and branches back to `MERGE`. `PROCA` and `PROCB` both end with `B COMMON`, where the region is compared with the previous one.
- The merge key is `AKEY` and `BKEY` (columns 1 to 8), not the region. The banner comments say the region is the match-merge key; the code does not compare it.
- The control break works because the keys A, B and C rise with the regions EAST, WEST and NORTH in the test data. A control break needs the data grouped by region, not sorted by region: EAST, WEST, NORTH is not alphabetical and still gives three subtotals. A region that came back later in the merged stream would get a second subtotal.
- There is no `HIVALUE`. `AKEY` and `BKEY` keep their last value after end of file. This is safe only because `MERGE` tests the end switches before the `CLC`.
- Result: 9 detail lines in key order (A001, A002, A003, B002, B003, B004, C004, C005, C006), subtotals EAST 6000, WEST 10500 and NORTH 15000, and a grand total of 31500. The last subtotal is printed by `MRGDONE` after the loop.
- The equal-key path (`MRGMATCH`) is not exercised: no key is in both files. On equal keys the program processes the `FILEA` record and then reads both files, so the `FILEB` record with the same key is read and dropped, without a line and without adding to the totals. BR09MTCH writes an equal key once to `OUTCOMM`.
- An empty `FILEA` or `FILEB` is handled by the same switches. If both are empty the merge goes straight to `MRGDONE`, `PUTSUBT` skips the print and the grand total is 0. This case is not in the test data.

## Rules

- Both files must be sorted ascending on the same key, in the same collating sequence as `CLC` (EBCDIC). With unsorted input a match can be missed or reported as "only".
- Read only the file whose record was dealt with. After `FLUSH1` the record in `KEY2` is not dealt with yet and must stay. Only `MATCHED` reads both.
- Test the EOF switches before the `CLC`. After end of file the key is not a real key. `HIVALUE` compares higher than any printable key and is a second safeguard, not the main one.
- The priming read gives the first comparison two keys. It is the same idea as the priming read in a control-break program.
- Open `SYSPRINT` first and close it last, so open errors and the final counts can be reported.
- Decide what an equal key means before coding the match path. BR09MTCH writes it once to a common file. FS01SORT processes the `FILEA` record only and drops the `FILEB` record.
- Keys must be unique within each file. A key that appears twice in one file is not handled as a pair: the first occurrence matches the other file's key and the repeat is compared with the next key of the other file, so it ends in an "only" file.

## Common Failures

| Symptom | Cause | Fix |
|---|---|---|
| Matching key reported as "only" in both | Input not sorted | Sort both files on the same key first |
| A record lost | Both files read after `FLUSH1` or `FLUSH2` | Read only the file that was consumed |
| Program loops after one file ends | Loop compares `HIVALUE` and never leaves | Test EOF switches before the `CLC` |
| Counts do not reconcile | Count incremented in the end-of-file routine | Count only after a successful `GET`, as `READ1` does |
| Repeated key shown as "only" | Duplicate keys in one file | Remove duplicates or code a group match |
| Last records of one file missing | No drain path | Keep `FLUSH1` and `FLUSH2` running through `CHECK2` |
| A matching record disappears with no line | Equal-key path processes one record and reads both files | Process or count both records, or write the match to a common file |
| A region gets two subtotals | The same region appears twice in the merged stream | Order the keys so each region is contiguous |
| Last region has no subtotal | No `PUTSUBT` call after the loop | Call it in the end routine, as `MRGDONE` does |
