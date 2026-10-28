# Locate-Mode I/O (GL and PL)

Scope: `GET` and `PUT` with no area operand on a sequential QSAM file (`MACRF=GL` and `MACRF=PL`), the address returned in R1, a DSECT mapped over the returned buffer, and the point at which an output record is written, as used in VB01LOC and VB01BILD. Update-in-place locate-mode macros and other access methods are not used in any program and are not described. Move mode is in the QSAM article, and the variable-length record format is in the variable-length records article. The programs were not assembled or run, apart from the run shown in the VB01LOC SYSOUT screen.

Source programs: VB01LOC (input and output), VB01BILD (output).

## Central Idea

Move mode copies each record between the QSAM buffer and an area in the program. Locate mode copies nothing. `GET` returns the address of the next record in R1, and `PUT` returns the address of an empty buffer segment in R1. The program reads or builds the record where it is, with a DSECT supplying the field names.

## Move Mode Compared

| | Move mode | Locate mode |
|---|---|---|
| DCB `MACRF` | `GM`, `PM` | `GL`, `PL` |
| Read | `GET INFILE,INAREA` | `GET INFILE` |
| Write | `PUT OUTFILE,OUTAREA` | `PUT OUTFILE` |
| Record storage | An area the program owns | A buffer QSAM owns |
| Register after the call | Not used | R1 holds the address |
| Field names | A DSECT over `INAREA`, or a `DS 0CLn` list | A DSECT over the address in R1 |
| Output record is written | At the `PUT` | At the next `PUT` or at `CLOSE` |

DS02DSCT and QSAMPROC use move mode. VB01LOC and VB01BILD use locate mode.

## Input

```
READREC  GET   INFILE                  * R1 = address of the next record
         LR    3,1                     * Save it at once
         USING VBINRECD,3              * Names now mean D(3)
         ...                           * Read fields by name
         DROP  3
```

- `MACRF=GL` in the DCB requests locate mode. `INFILE` also has `EODAD=EOFRTN`.
- `LR 3,1` comes first because R1 is changed by the next system macro. In VB01LOC the next macro is a `PUT` in `BUILDOUT`, so the input address is kept in R3 while the output address is kept in R4.
- At end of file `GET` does not return. Control goes to `EOFRTN`, which sets `EOFSW` to `Y` and ends with `BR 10`. The `LR`, the `USING` and the count after the `GET` are skipped, so R3 still holds the address of the last record read.
- The record is in QSAM's buffer, not in the program's storage. VB01LOC's failing run shows this: a 256-byte move from the empty-name record picked up the next record (RDW, `P100005`, amount, name) because it sits next in the same buffer.

## Output

```
         PUT   OUTFILE                 * R1 = address of an empty buffer
         LR    4,1                     * Save it at once
         USING VBOUTRECD,4
         MVC   OUTRDWLL,=H'29'         * Build the whole record, RDW first
         XC    OUTRDWFL,OUTRDWFL
         ...                           * Fill the other fields
         DROP  4
```

- `MACRF=PL` requests locate mode for output.
- The program builds the whole record in the buffer, including the RDW of a variable-length record.
- There is no separate write instruction. The record is written by the next `PUT` or by `CLOSE`.
- VB01BILD has five `PUT`s and no loop. The fifth record is written by `CLOSE (OUTFILE)`, so a missing `CLOSE` loses it.
- `PUT` does not clear the buffer. The program sets every byte inside the record length. The RDW length stops the record at the end of the name, so stale bytes after it are not written.
- The buffer is big enough for the longest record (`LRECL=37`). Nothing checks that the program stays inside it. A name longer than 20 bytes in VB01BILD would run past the end.

## Two Registers, Two DSECTs

`BUILDOUT` in VB01LOC has both mappings active: `VBINRECD` on R3 (input) and `VBOUTRECD` on R4 (output).

- The layouts are identical. The output DSECT has its own field names (`OUT...` against `IN...`), so no reference can be ambiguous.
- Both registers come from R1 of two different macros. Each is saved with `LR` before the next macro runs.
- `DROP 3` and `DROP 4` follow the last use, after the `EX` target `MVCBUILD`.
- Writer and reader must describe the record identically. VB01BILD's `VBOUTRECD` and VB01LOC's `VBINRECD` have the same fields and lengths (H, H, CL8, PL5, `0CL1`), and nothing checks that they agree.

## Rules

- Save R1 with `LR` immediately after every locate-mode `GET` and `PUT`.
- Treat an input address as valid for the current record only. Do not keep it past the next `GET`.
- Set every byte of an output record that falls inside its length. The buffer holds whatever was there before.
- Close the output file, so the last record is written.
- Write a record's length before relying on it. For a variable-length record that is the RDW.
- Give the input and output DSECTs different field names when both are active.

## Common Failures

| Symptom | Cause | Fix |
|---|---|---|
| Fields read from the wrong place | R1 changed by a macro before `LR` | `LR` straight after `GET` or `PUT` |
| Last output record missing | `CLOSE` not issued | Close every output file |
| Garbage inside an output record | Field in the buffer never set | Set every byte inside the record length |
| Output record has the wrong length | RDW length not stored | Store the length before the `PUT` that writes it |
| Data from the next record appears | Move longer than the record | Check the length before the move (see the `EX` article) |
| Ambiguous field names | Same names in both DSECTs | Give each DSECT its own prefix |
