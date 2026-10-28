# Variable-Length Records and the RDW

Scope: `RECFM=VB` records as built by VB01BILD and read by VB01LOC: the 4-byte RDW, `LRECL` as the longest record, the length arithmetic for a record with one variable field, a DSECT that marks where the variable field starts, and how ISPF Browse shows such a file. The Block Descriptor Word is mentioned in a source comment (QSAM removes it) and is not seen by any program. Spanned records, `RECFM=V` and variable-length files read in move mode are not used in any program and are not described. Locate mode is in the locate-mode article. The programs were not assembled or run, apart from the run shown in the VB01LOC SYSOUT screen.

Source programs: VB01BILD, VB01LOC.

## Central Idea

In a fixed-length file every record has the same length, so the program needs one constant, `LRECL`. In a `RECFM=VB` file each record starts with its own 4-byte Record Descriptor Word that holds the record's length. The program must read that length from the record, because `LRECL` only gives the longest record.

## The RDW

```
byte 0-1   LL   length of THIS record, INCLUDING the 4 RDW bytes (binary)
byte 2-3   00   reserved, binary zero
```

- In the DSECT, `INRDWLL DS H` is the length and `INRDWFL DS H` is the flag halfword.
- The writer must set both. VB01BILD stores the length with `MVC OUTRDWLL,=H'n'` and clears the flags with `XC OUTRDWFL,OUTRDWFL`. VB01LOC stores a computed length with `STH 6,OUTRDWLL`.
- `LRECL=37` on a VB DCB is the longest record including its RDW: 4 + 8 + 5 + 20 = 37. It is not the length of each record.

## The Records in the Repo

Each record is the RDW, `CUSTNO` CL8, `AMOUNT` PL5 and a name of any length. The fixed part is 17 bytes, 4 of them the RDW.

| # | Customer | Name length | RDW length (LL) | RDW in hex | Data bytes (LL - 4) |
|---|---|---|---|---|---|
| 1 | `P100001` | 12 | 29 | 001D0000 | 25 |
| 2 | `P100002` | 5 | 22 | 00160000 | 18 |
| 3 | `P100003` | 20 | 37 | 00250000 | 33 |
| 4 | `P100004` | 0 | 17 | 00110000 | 13 |
| 5 | `P100005` | 10 | 27 | 001B0000 | 23 |

Record 4 is the shortest record the layout allows, with an empty name.

## Length Arithmetic

| Program | Calculation | Instructions |
|---|---|---|
| VB01BILD (writer, name length known when assembling) | RDW length = name length + 17 | `MVC OUTRDWLL,=H'29'` |
| VB01LOC (reader, length known at run time) | name length = RDW length - 17 | `LH 5,INRDWLL`, `S 5,=F'17'` |
| VB01LOC (writer, copying a record) | RDW length = name length + 17 | `L 6,NAMELEN`, `A 6,=F'17'`, `STH 6,OUTRDWLL` |

- The 17 is correct as a subtraction from the RDW length only because the 4 RDW bytes are part of the 17.
- VB01LOC saves the name length (`ST 5,NAMELEN`) and the length minus 1 (`BCTR 5,0`, `ST 5,NAMELENM1`). The second value is the form `EX` needs.

## The DSECT

```
VBINRECD DSECT
INRDWLL  DS    H                       * +0  Record length, RDW included
INRDWFL  DS    H                       * +2  Reserved
INCUSTNO DS    CL8                     * +4
INAMOUNT DS    PL5                     * +12
INNAME   DS    0CL1                    * +17 Variable part starts here
```

- The fixed fields have fixed displacements. The end of the name does not, because it changes from record to record.
- `INNAME DS 0CL1` reserves no bytes. It only gives a name to displacement 17. How many bytes belong to it comes from the RDW, and the move that copies them needs its length at run time (see the `EX` article).
- The writer VB01BILD has an identical DSECT, `VBOUTRECD`, with the `OUT` prefix.

## Building and Reading

- Writer: set the RDW length, clear the flag halfword, fill the fixed fields (`ZAP` for the packed amount), then `MVC OUTNAME(len),=CLlen'name'` with an explicit length. For the empty name VB01BILD codes no `MVC`: a machine `MVC` moves at least one byte, so only the RDW length of 17 says the name is absent.
- Literals match the move length: `=CL5'WASH '` and `=CL20'HEX NUT STAINLESS   '` are written with trailing blanks.
- Reader: trust the RDW, take the name length from it, and move exactly that many bytes. VB01LOC does no validation. A corrupt RDW or an empty name gives a wrong length, and the source comments note that production code validates the length first.

## Seeing the File

- ISPF Browse does not show the RDW. The longest line is 33 characters (`Col 001 033`), which is 37 minus the RDW.
- The packed bytes show as characters: X'5C' is `*`, X'50' is `&`, X'99' is `r`, X'9C' is `æ`, and the other bytes are `.`.
- `HEX ON` shows the RDW and the real packed bytes.
- The file cannot be typed in an editor: it has binary RDWs and packed fields. A program builds it, as with `PARTFILE` in DS02BILD. The JCL creates it with `NEW,CATLG,DELETE`, so delete the data set before a rerun.

## Rules

- Take each record's length from its RDW, never from `LRECL`.
- A length in an RDW includes the RDW. Check which form a calculation uses.
- Make the writer's and the reader's DSECT identical.
- Set the RDW flag halfword to zero.
- Handle the shortest record (empty variable field) in the reader, and test it.
- Keep a name within the longest length that `LRECL` allows. VB01BILD does not check this, and a longer name runs past the end of the buffer.

## Common Failures

| Symptom | Cause | Fix |
|---|---|---|
| Name length wrong by 4 | RDW length treated as data length | Subtract 17, not 13 |
| Every record read as the same length | `LRECL` used instead of the RDW | Read `INRDWLL` |
| Reader sees wrong fields | Writer and reader DSECTs differ | Compare both layouts |
| Line 5 shows another record's data | Reader moved 256 bytes for an empty name | Check the length before the move |
| Browse shows 33 columns for a 37-byte record | Browse hides the RDW | Not an error; `HEX ON` |
| Rerun of the builder fails at allocation | Output data set already cataloged | Delete it first |
