# Packed Data Validity, Initialisation and Test Files

Scope: why a packed field must hold a valid sign nibble before `AP` uses it, which instructions check and which do not, initialising work fields with `ZAP`, building a file with packed data from a program, and reading packed bytes in ISPF Browse, as used in DS02DSCT, DS02BILD, DS01DSCT, BR09MTCH and QSAMPROC. Packed fields in other kinds of data sets are not used in any program and are not described. Packed arithmetic rules are in the packed arithmetic article. The programs were not assembled or run, apart from the runs shown in the SYSOUT screens.

Source programs: DS02DSCT, DS02BILD, DS01DSCT, BR09MTCH, QSAMPROC.

## Central Idea

A packed field is valid only when every digit nibble is 0 to 9 and the last nibble is a sign (C, D or F). Reserving storage does not make a field valid. Data that arrives from a file must already be valid. A program checks this only at the instruction that does packed arithmetic, so the fault shows up late and in another place.

## S0C7 in DS02DSCT

The first version of DS02DSCT abended with S0C7 at `AP GRANDTOT,PARMAMT` on the first record.

- `GRANDTOT DS PL6` reserves 6 bytes and gives them no value.
- `AP` needs valid packed data in both operands. Bytes that are all zeros also fail, because the last nibble 0 is not a sign.
- The fix is `ZAP GRANDTOT,=P'0'` once at the start. The result is X'00000000000C', a valid positive zero.
- A field X'0000000000' has no sign. It fails in packed arithmetic as well.

## Which Instructions Check

| Instruction | Checks packed data | Evidence |
|---|---|---|
| `AP` | Yes | `AP` abended with S0C7 on an uninitialised field (the other decimal instructions were not run on a bad field) |
| `MVC` | No | Copies bytes only |
| `UNPK` | No | `SHOWREC` printed record 1 correctly before `AP` failed |
| `OI` | No | Changes a nibble, reads no data |
| `PACK` | No | Does not check its input (DT03CONV) |

Because the first three display steps do not check, a bad field can print without error and fail only later.

## Initialising

- Every packed work field that is added to needs `ZAP field,=P'0'` before the first `AP`. DS02DSCT does it for `GRANDTOT` and `RECCNT`. BR09MTCH does it for its five counters (`CNT1`, `CNT2`, `CNTONLY1`, `CNTONLY2`, `CNTCOMM`).
- A packed literal carries the sign nibble `C`: `=P'12345'` is X'12345C'.
- `ZAP` into a longer field adds leading zero bytes and a valid sign, so field lengths may differ.
- Field sizes: `PL4` holds 7 digits, `PL5` holds 9, `PL6` holds 11. Pick the size from the largest value.

## Building a Test File: DS02BILD

A file with packed fields cannot be typed in an editor, so DS02BILD writes it.

```
         MVC   OUTREC,BLANKS40         * Clear the 40 bytes
         MVC   OUTREC(8),=CL8'P100001' * Part number
         MVC   OUTREC+10(20),=CL20'BOLT 10MM'
         ZAP   OUTAMT,=P'12345'        * Valid packed, sign C
         PUT   PARTFILE,OUTREC
```

- The five records have amounts `P'12345'`, `P'500'`, `P'99999'`, `P'0'` and `P'15099'`.
- `ZAP` from the literal gives valid digits and a valid sign without any conversion.
- The file is created on the mainframe because a text upload would damage bytes such as X'1C' and X'5C'. This is why `data/` has no `PARTFILE`.
- A file edited and saved as text loses the packed bytes. `SHOWREC` would still print digits and `AP` would then abend.
- The JCL uses `NEW,CATLG,DELETE`. If the data set exists, allocation fails, so delete it before a rerun.

## Reading Packed Bytes

| Bytes | Character view in Browse |
|---|---|
| X'000012345C' | `....*` |
| X'000000500C' | `...&.` |
| X'000099999C' | `..rræ` |
| X'000000000C' | `.....` |
| X'000015099C' | `....æ` |

- Browse in character view shows `*` for X'5C', `&` for X'50', `r` for X'99' and `æ` for X'9C'. Bytes with no printable character show as `.`.
- Use `HEX ON` to see the real bytes.
- A packed field has no decimal point. The reader decides the scale, so X'000012345C' is 12345 unless 2 decimals are assumed.
- DS01DSCT shows the same bytes as digits (`UNPK` and `OI`) and as characters (`CUSTBALC`). The character view is only a demonstration; packed bytes are not meant to be read as characters.

## Showing Packed Data

- `UNPK zone,field` and `OI zone+last,X'F0'` give printable digits. The sign is lost.
- A zone shorter than the field keeps only the low-order digits. `UNPK ZONE7,PARTAMT` shows 7 of the 9 digits of a `PL5`. An amount over 9999999 loses its leftmost digits on the line but is added to the total in full.
- `GRANDTOT` is `PL6`, 11 digits, shown in `ZONE11` without loss.
- Counters are `PL4` with a 7-byte zone. A count over 9999999 loses its leftmost digit.

## Rules

- Initialise before the first `AP`, even for a field that is "obviously zero".
- A field read from a file is valid only if the program that wrote it wrote valid packed data.
- Do not move a short packed field into a longer one with `MVC`. Use `ZAP`.
- When an `AP` abends on the first record, look for a field that was never set, not for bad input.
- Use a zone changed by `OI` for display only, never for arithmetic.

## Common Failures

| Symptom | Cause | Fix |
|---|---|---|
| S0C7 at the first `AP` | Work field never initialised | `ZAP field,=P'0'` at the start |
| Lines print but a later `AP` abends | Display instructions do not validate | Check initialisation and the input file |
| Browse shows garbage in a packed column | Character view of packed bytes | `HEX ON` |
| S0C7 after editing the test file | Text save damaged the packed bytes | Rebuild with DS02BILD |
| Rerun of DS02BILD fails at allocation | Data set exists | Delete it first |
| Total larger than the printed amounts | Display zone shorter than the field | Compare the zone length with the digit count |
