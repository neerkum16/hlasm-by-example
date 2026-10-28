# Operand Lengths: Implied and Explicit

Scope: where the length of a storage-to-storage operand comes from (`MVC`, `CLC`, `UNPK`, `ZAP`, `AP`) as seen in DS01DSCT, DS02BILD, DS02DSCT, BR09MTCH and QSAMPROC: implied from the field, coded explicitly, taken from a literal, or absent for a register operand. A length decided at run time with `EX` (VB01LOC) is summarised here and described in the EX article. Instructions not used in these programs are not described. The programs were not assembled or run, apart from the runs shown in the SYSOUT screens.

Source programs: DS01DSCT, DS02BILD, DS02DSCT, BR09MTCH, QSAMPROC, VB01BILD, VB01LOC.

## Central Idea

A storage-to-storage instruction needs a length. The assembler takes it from the length attribute of the first operand, or from what you code, and does not check it against the other operand. A length that is longer than the source copies bytes from the neighbouring storage. A length shorter than the target leaves part of it unchanged.

## Where the Length Comes From

| Operand form | Length | Example |
|---|---|---|
| Field name, no length coded | Length attribute of the field | `MVC OUTREC,BLANKS40` moves 40 (`OUTREC DS 0CL40`) |
| Field name, no length coded | Length of the packed field | `UNPK ZONE,CUSTBAL` uses 5 from `PL5` |
| Name with length coded | The coded length | `MVC OUTMSG+10(8),CUSTNO` moves 8 |
| Name with offset | Coded length is required | `MVC PRTLINE+10(20),PARTDESC` |
| Register as base | No attribute; the length must be coded | `MVC PRTLINE(50),0(1)` |
| Literal | Length of the literal text | `=C'CUST NO: '` is 9, `=CL8'P100001'` is 8, `=P'12345'` is 3 |
| `EX` register | Low byte of the register, as length - 1 | `EX 5,MVCSHOWN` with the target coded `MVC PRTLINE+20(1),INNAME` |

## The Literal Trap in DS01DSCT

`MVC OUTMSG(10),=C'CUST NO: '` copies 10 bytes from a 9-byte literal.

- The tenth byte is the first byte of the next literal in the pool. The pool is in order of first use, and the repeated `=C'CUST NO: '` and `=C'NAME:    '` in Part 2 reuse the same entries.
- The run shows `N`, `B`, `B` and `Ø` in column 10. For the last literal the tenth byte is the byte after the pool, which this program does not control.
- Fixes: `=CL10'CUST NO:'` (10 bytes), or copy 9 bytes.
- The value fields start at column 11 and are not affected.
- DS02BILD avoids the trap by making the literal length equal the move length: `MVC OUTREC(8),=CL8'P100001'` and `MVC OUTREC+10(20),=CL20'BOLT 10MM'`.

## Length Known Only at Run Time

- VB01BILD codes each name length in the instruction, because it is known when assembling: `MVC OUTNAME(12),=CL12'BOLT 10MM'`. The literal length equals the move length.
- VB01LOC gets the name length from the RDW at run time (`LH 5,INRDWLL`, `S 5,=F'17'`). An `MVC` cannot take a register length, so it uses `EX 5,MVCSHOWN` with the length minus 1 in R5.
- The coded length of the target `MVC` is 1. The register supplies the real length, 1 to 256.
- A zero length gives -1 after `BCTR`, and the move is 256 bytes. This failed in the VB01LOC run on record 4.

## Fixed Lengths Agreed by Convention

- All message constants are `CL50` and `MVC PRTLINE(50),0(1)` copies 50 bytes. The address in R1 has no length, so every message must be `CL50`. A shorter message would copy the next constant.
- BR09MTCH labels are `CL20` and the count is placed at `PRTLINE+21`. A longer label needs a new offset and a new `MVC` length.
- DS02DSCT places the part number at `PRTLINE`, the description at `PRTLINE+10` and the amount at `PRTLINE+32`.

## Digits and Truncation

| Field | Digits | Display | Result |
|---|---|---|---|
| `PL5` | 9 | `ZONE7` | Low 7 digits; leftmost 2 lost |
| `PL4` | 7 | `ZONE CL7` | 7 digits; a count over 9999999 loses its leftmost digit |
| `PL6` | 11 | `ZONE11` | All 11 digits |
| `PL5` | 9 | `ZONE CL5` (DS01DSCT) | Low 5 digits: 12345 from X'000012345C' |

- `UNPK` into a shorter field keeps the low-order digits and the sign is lost after `OI`. Size the zone as `2n-1` for an `n` byte packed field when nothing may be lost.
- The amount on the printed line is cut, but `AP` adds the full value to the total.

## Limits

- `MVC` and `CLC` move or compare at most 256 bytes. QSAMPROC clears a 559-byte area with three moves: `MVC a(256),BLANK256`, `MVC a+256(256),BLANK256`, `MVC a+512(47),BLANK256`.
- A `DC` of type C is limited to 256 bytes. `CL349` gave ASMA068S in QSAMPROC. Use `DS`, or split the constant.
- `DS 0CLn` gives its label the length n, so one `MVC` of the label moves the whole record. Keep the field lengths under it adding up to n.

## Compare Lengths Decide Matches

- `CLC` compares the number of bytes coded. `=CL3'FT'` compares 3 bytes with `FT` and a blank. `=C'FT'` compares 2 bytes and also matches `FTX`.
- `CLC SRCHKEY(8),0(7)` compares 8 bytes of the key with 8 bytes of the entry.

## Rules

- Make the literal length equal the move length, or code the move length from the literal.
- When a register is the base, code the length. Make every item that is addressed that way the same length.
- Use a field name with no length when the field is the real length you want, so a change to the `DS` changes the move.
- Size a display zone before the field it shows and note the digits lost.
- Keep a comment with the offsets of a printed line next to the code that builds it.

## Common Failures

| Symptom | Cause | Fix |
|---|---|---|
| Stray character after a label | Move length longer than the literal | Equal lengths, or `=CL10'...'` |
| Next message copied into a short message | `MVC PRTLINE(50),0(1)` with a shorter constant | Make every message `CL50` |
| Leftmost digits missing on a line | Zone shorter than the digit count | Larger zone, or accept the cut |
| Number misaligned after a label change | Fixed offset not updated | Change the offset and the `MVC` length |
| ASMA068S on a large constant | Type C over 256 bytes | `DS`, or split |
| `FTX` matches `FT` | Compare length shorter than the field | `=CL3'FT'` or a longer compare |
