# Tables and Indexed Addressing

Scope: fixed-length table entries, stepping through them with an index register, serial search with early exit, and the pointer register for storage-to-storage instructions, as used in BR05TABL, BR08SRCH and the prefix table search in QSAMPROC. Binary search and tables with variable-length entries are not used in any program and are not described. Code blocks are layouts for illustration. The programs were not assembled or run.

Source programs: BR05TABL, BR08SRCH, QSAMPROC.

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
