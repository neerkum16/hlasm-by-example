# Record Layouts: DS 0CLn, ORG and REDEFINES

Scope: laying out a record with a `DS 0CLn` label and named fields (`INREC` and `OUTAREA` in QSAMPROC), placing a field with `ORG` in a CSECT (`OUTREC` in DS02BILD) and giving the same bytes two names with `ORG` in a DSECT (`CUSTBAL` and `CUSTBALC` in DS01DSCT). A zero-length `DS 0CL1` that marks where a variable-length field starts, and a 4-byte RDW laid out as two halfwords (`VBINRECD` in VB01LOC, `VBOUTRECD` in VB01BILD), are also covered. `ORG` with no operand is not used in any program and is not described. The DSECT mechanism is in the DSECT article, and the RDW is in the variable-length records article. The programs were not assembled or run.

Source programs: QSAMPROC, DS01DSCT, DS02BILD, DS02DSCT, VB01BILD, VB01LOC.

## Central Idea

The assembler keeps a location counter, the address of the next byte it will define. `DS` and `DC` advance it. `ORG` sets it to a chosen value. A record layout is a set of names at fixed displacements, and `ORG` is the tool for choosing where a name goes, including a second name for bytes that already have one.

## Three Layout Styles

| Style | Example | What it gives |
|---|---|---|
| Named fields end to end | `INREC DS 0CL559` then `INCUSTNO DS CL8`, `INUSERID DS CL8`, ... | Each field in order; the label has the whole length |
| One field placed with `ORG` | `OUTREC DS 0CL40`, `ORG OUTREC+30`, `OUTAMT DS PL5`, `ORG OUTREC+40` | A named field at displacement 30 inside a record built mostly with `MVC` |
| Two names for the same bytes | `CUSTBAL DS PL5`, `ORG CUSTBAL`, `CUSTBALC DS CL5` | The REDEFINES equivalent |

## DS 0CLn

- `INREC DS 0CL559` reserves no bytes. The label gets length 559, so `MVC INREC,...` with no explicit length moves 559 bytes.
- The fields that follow define the real storage. Their lengths must add up to 559 (8 + 8 + 8 + 35 + 35 + 50 + 8 + 3 + 1 + 5 + 30 + 368 for `INREC`).
- QSAMPROC separates the output columns with one-byte fields `OUTC1` to `OUTC17`, so a field is referred to by name and not by offset.
- The same technique with a DSECT is in DS01DSCT. A DSECT separates the layout from the storage; `DS 0CLn` in a CSECT does both at once.

## ORG in a CSECT: DS02BILD

```
OUTREC   DS    0CL40                   * Whole record, length 40
         ORG   OUTREC+30               * Counter to displacement 30
OUTAMT   DS    PL5                     * Amount at column 31
         ORG   OUTREC+40               * Counter to the end of the record
PARTFILE DCB   ...                     * Next definition starts at 40
```

- The program builds the record with `MVC` and `ZAP`. Only the packed amount needs a name, so only that name is defined.
- Bytes 0 to 29 are skipped by the `ORG`. They get their values from `MVC OUTREC,BLANKS40`, not from the `DS`.
- Without the second `ORG` the counter stops at `OUTREC+35`. The `DCB` that follows is aligned, so it would start at byte 36, inside the record area. Per DS02BILD.md, `PUT` would then write bytes of the DCB into columns 36 to 40.
- The source comment on `ORG OUTREC+40` says "Step back", but the counter moves forward from 35 to 40. The comment is wrong and the code is correct.
- `OUTAMT` here and `PARTAMT` in the `PARTD` DSECT of DS02DSCT must be at the same displacement. DS02BILD writes the file and DS02DSCT reads it. Nothing checks that they agree.

## ORG in a DSECT: DS01DSCT

```
CUSTD    DSECT
CUSTNO   DS    CL8                     * +0
CUSTNAME DS    CL20                    * +8
CUSTBAL  DS    PL5                     * +28, packed
         ORG   CUSTBAL                 * Counter back to 28
CUSTBALC DS    CL5                     * +28, characters
```

- Both names address displacement 28 to 32. `UNPK ZONE,CUSTBAL` reads the bytes as packed decimal. `MVC OUTMSG+10(5),CUSTBALC` copies the same bytes as characters.
- The DSECT length is 33: the counter after `CUSTBALC` is 28 + 5.
- `ORG` copies no data. The name chosen by the instruction decides how the bytes are read.
- In real data another field, such as a type code, decides which view is valid.
- X'000012345C' read as characters shows only `*` (X'5C') on the screen. The other bytes are not printable.

## A Variable Part: VB01LOC

```
VBINRECD DSECT
INRDWLL  DS    H                       * +0  Record length, RDW included
INRDWFL  DS    H                       * +2  Reserved
INCUSTNO DS    CL8                     * +4
INAMOUNT DS    PL5                     * +12
INNAME   DS    0CL1                    * +17 Variable part starts here
```

- The RDW is two halfwords: the length and the flags.
- `INNAME DS 0CL1` reserves no bytes. It names displacement 17, and the length of the name comes from the RDW at run time, not from the layout.
- The DSECT length is 17. The record length differs per record.
- A `MVC` of `INNAME` with no length would move 1 byte, the label's length. The name needs an explicit or `EX` length.

## Rules

- Compute every displacement before coding an `ORG`. Write the expected total as a comment and compare it with `LRECL`.
- An `ORG` backward is safe in a DSECT because the DSECT has no storage. In a CSECT a backward `ORG` redefines bytes that already hold values.
- End the layout with an `ORG` to the record length when a forward `ORG` leaves the counter short, so the next definition starts after the record.
- When two programs share a file, copy the layout, do not retype it, and compare the displacements of the fields that matter.
- A label with `0CLn` has length n. A label on the first field has the length of that field only.

## Common Failures

| Symptom | Cause | Fix |
|---|---|---|
| Next definition overlaps the end of a record | No closing `ORG` | `ORG label+length` after the last field |
| Reader shows wrong packed data | Writer and reader place the field at different displacements | Compare `ORG` value and DSECT displacement |
| `MVC label,...` moves the wrong number of bytes | Label is on a field, not on the `0CLn` line | Put the label on the `DS 0CLn` |
| Record length differs from `LRECL` | Field lengths do not add up | Add them and correct the `DS` lengths or `LRECL` |
| Output field overwritten | Backward `ORG` in a CSECT over a field with a value | Use the `ORG` in a DSECT, or define the name in a map |
