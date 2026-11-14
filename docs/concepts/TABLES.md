# Tables and Indexed Addressing

Scope: fixed-length table entries, stepping through them with an index register, serial search with early exit, and the pointer register for storage-to-storage instructions, as used in BR05TABL, BR08SRCH and the prefix table search in QSAMPROC. TB01TABL adds a table filled from a file at run time, a `BXLE` walk over the loaded entries and a binary search. Tables with variable-length entries are not used in any program and are not described. Code blocks are layouts for illustration. The programs were not assembled or run, apart from the runs shown in the SYSOUT screens.

Source programs: BR05TABL, BR08SRCH, QSAMPROC, TB01TABL.

## Central Idea

A table is a run of equal-sized entries. An entry's address is the table address plus a multiple of the entry length. The index form of an address exists on some instructions and not on others, so the program keeps the computed address in a register and uses it as a plain base.

## Layout

BR05TABL entries are 12 bytes: a name `CL8` then a value `F`.

```
TABLE    DS    0F                      * Fullword alignment
         DC    CL8'PENCIL  ',F'120'
         DC    CL8'ERASER  ',F'45'
ENTLEN   EQU   12                      * Length of one entry
ENTRIES  DC    F'4'                    * Number of entries
```

- `TABLE DS 0F` aligns the table so the value in each entry is on a fullword boundary. That holds when the entry length is a multiple of 4.
- `ENTLEN EQU 12` names the entry length so no code carries the literal 12.
- `ENTRIES` sits beside the table. If an entry is added, the count must change. The count can also be calculated at assembly time from the table's length.
- Names are padded with blanks to 8 characters. A name longer than 8 would overlap the value.

## Two Registers

| Register | Holds | Changes by |
|---|---|---|
| Index (R5 in BR05TABL) | Offset of the entry from `TABLE` | `ENTLEN` each pass |
| Pointer (R4) | Address of the entry | Computed from the index |

```
         LA    4,TABLE(5)              * R4 = TABLE + R5
         MVC   OUTMSG+2(8),0(4)        * Name through the pointer
         L     3,8(,4)                 * Value at displacement 8
         LA    5,ENTLEN(,5)            * Step the index
```

- `LA 4,TABLE(5)` builds an address and reads no storage.
- SS instructions (`MVC`, `CLC`) have no index field. They take a base register and a displacement, so the pointer in R4 is used as the base.
- `L 3,8(,4)` reads a field at a fixed displacement inside the entry.
- `LA 5,ENTLEN(,5)` uses `LA` as an add-constant instruction.

## Serial Search

BR08SRCH looks up a key in a keyed table:

```
         MVC   SRCHKEY(8),0(10)        * Search argument to work key
         LA    7,TABLE                 * Pointer to first entry
         L     6,ENTRIES               * Count
SRCHLOOP CLC   SRCHKEY(8),0(7)         * Key against entry
         BE    FOUND                   * Early exit
         LA    7,ENTLEN(,7)            * Next entry
         BCT   6,SRCHLOOP              * Out of entries: not found
         ...                           * Not found path
FOUND    L     3,8(,7)                 * Value of the match
```

- Found / not-found: `BE FOUND` leaves the loop early. If `BCT` falls through, no entry matched.
- The pointer is still valid at `FOUND`, so `L 3,8(,7)` reads the value from the matching entry.
- After a failed search the pointer is past the last entry and must not be used.
- The search argument is copied to a work key so `CLC` has a fixed first operand.
- BR08SRCH output columns: key at `OUTMSG(8)`, message at `OUTMSG+10(40)`, value at `OUTMSG+50(8)`.

## Prefix Table in QSAMPROC

```
         LA    2,PFXTAB                * Pointer to the table
         L     3,PFXCNT                * Entries
PFXLOOP  CLC   INACCTID(4),0(2)        * 4-byte prefix
         BE    FOUND
         LA    2,4(,2)                 * Next entry
         BCT   3,PFXLOOP
```

The compare length decides what matches. `=CL3'FT'` compares 3 bytes with `FT` and a blank. `=C'FT'` compares 2 bytes and also matches `FTX`.

## A Table Built at Run Time: TB01TABL

```
ENTLEN   EQU   12                      * Length of one entry
MAXENT   EQU   200                     * Worst case size
TABLE    DS    (MAXENT)CL12            * Empty storage, 2400 bytes
         ...
         LA    7,TABLE                 * R7 = next free slot
         SR    8,8                     * R8 = entries loaded
LOADLOOP GET   TABFILE,0(7)            * Read straight into the slot
         LA    8,1(,8)
         LA    7,ENTLEN(,7)
         C     8,=F'200'               * MAXENT check
         BNH   LOADLOOP
         DC    H'0'                    * File had more than MAXENT
TABEOF   ST    8,ENTCNT                * EODAD: keep the real count
```

- `TABLE` is sized for the worst case. Two sizes exist: `MAXENT`, how many entries fit, and `ENTCNT`, how many are there. Every routine after the load uses `ENTCNT`. The test file has 8 records.
- `GET TABFILE,0(7)` is move mode into the slot R7 points to, so no work area and no `MVC`.
- The check is one record late. With a count of 200 the `BNH` loops back and the 201st `GET` stores into slot 201, 12 bytes past `TABLE`, before the count 201 reaches `DC H'0'`. The `TABFILE` DCB follows `TABLE`. This is read from the code and was not run.
- The check uses `=F'200'` and the later `MH` uses `=H'12'`, not `MAXENT` and `ENTLEN`. Changing the `EQU` values does not change them.
- The items after `TABLE` (the DCBs and the literal pool) must stay within 4096 bytes of the base register. A much larger `MAXENT` would put them out of reach of one base register.

## BXLE over the Loaded Entries

```
         L     8,ENTCNT
         BCTR  8,0                     * Count - 1
         MH    8,=H'12'                * Byte offset of the last entry
         LA    3,TABLE
         AR    3,8                     * R3 = address of the last entry
         ST    3,TABLEND
         LA    7,TABLE                 * R7 = index (first entry)
         LA    2,ENTLEN                * R2 = increment (even register)
BXSTEP   ...                           * Use the entry at 0(7)
         L     3,TABLEND               * R3 = limit (odd register)
         BXLE  7,2,BXSTEP              * R7 + R2; loop while R7 <= R3
```

- `BXLE` adds the increment to the index and branches while the index is not higher than the limit. The limit is the address of the last entry, not the address after it, so the loop still branches when R7 equals R3.
- The increment and the limit are in an even-odd register pair: R2 and R3.
- The loop is bottom-tested and runs at least once. With an empty file R8 is 0, `BCTR` makes it -1, R3 becomes `TABLE` - 12 and the first pass prints an unfilled slot before `BXLE` ends the loop. This was not run.
- R3 has two meanings: the `BXLE` limit during the walk and the byte offset of MID during the binary search. The search starts after the walk has ended.

## Binary Search

```
         SR    4,4                     * LOW = 0
         L     5,ENTCNT
         BCTR  5,0                     * HIGH = count - 1
BSLOOP   CR    4,5
         BH    BSNOTFND                * LOW > HIGH: not found
         LR    6,4
         AR    6,5
         SRA   6,1                     * MID = (LOW + HIGH) / 2
         LR    3,6
         MH    3,=H'12'                * MID as a byte offset
         LA    7,TABLE(3)              * R7 = address of the MID entry
         CLC   SRCHKEY,0(7)
         BE    BSFOUND
         BL    BSLOWER
         LA    4,1(,6)                 * Greater: LOW = MID + 1
         B     BSLOOP
BSLOWER  BCTR  6,0                     * Lower: HIGH = MID - 1
         LR    5,6
         B     BSLOOP
```

- LOW, HIGH and MID are entry numbers. A byte offset is built only when an entry is touched.
- LOW + HIGH is built in R6 and halved there, so R4 and R5 keep their values. `SRA` keeps the sign. LOW and HIGH go negative only for an empty table, where the loop is not entered.
- Each pass halves the range, so 8 entries take at most 4 passes.
- Test run: `ALPHA` (entry 0) and `MIKE` (entry 5) are found with values 0100 and 0600. `ZULU` is not found: it is higher than `ZEBRA` because `U` is higher than `E` in EBCDIC, so LOW passes HIGH.
- The search is correct only for a table in ascending EBCDIC key order. The program does not check the order. On an unsorted file it would report NOT FOUND for keys that are in the table.
- An empty table is handled: HIGH is -1, so `CR 4,5` goes to `BSNOTFND` at once. This was not run.
- A serial search needs no order and costs up to `ENTCNT` compares. A binary search needs the order and costs about the base-2 logarithm of `ENTCNT`.

## Rules

- Keep the pointer and the index in different registers. Instructions with an index field use the index; SS instructions use the pointer.
- Check a count that may be zero before the `BCT` loop (`LTR` and `BZ`). A count of 0 runs about 4 billion times.
- Match the compare length to the field length.
- Step by the entry length, not a literal.

## Common Failures

| Symptom | Cause | Fix |
|---|---|---|
| Assembly error on `MVC` with an index | SS instructions have no index field | Compute the address with `LA`, use it as the base |
| Loop runs too many times | `ENTRIES` zero or not updated after adding an entry | Update the count; guard zero |
| Field read from the wrong place | Displacement does not match the entry layout | Check the layout against the `DC` lines |
| Search matches a longer key | Compare length shorter than the key | Match the compare length to the field |
| Garbage after a failed search | Pointer used after the last entry | Test found / not found first |
| Keys reported NOT FOUND that are in the table | Binary search on a file not in ascending order | Sort the file, or use a serial search |
| One entry stored past the end of the table | `MAXENT` tested after the `GET` that fills the last slot | Test the count before the `GET` |
| `MAXENT` changed and the check did not follow | Literal `=F'200'` coded instead of `MAXENT` | Use the `EQU` value |
| First pass of a `BXLE` walk prints an unfilled slot | Bottom-tested loop with no entries | Test `ENTCNT` for zero before the walk |
