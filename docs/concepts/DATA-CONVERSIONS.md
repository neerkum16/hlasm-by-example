# Data Conversions and Editing

Scope: the conversions `PACK`, `UNPK`, `CVB`, `CVD`, `OI`, `MVZ` and `ED` as used in REGCALC, DT02ARTH and DT03CONV, with the number display idiom and the `ED` pattern rules. `EDMK` is not used in any program and is not described. Hand-computed items are marked; the programs were not assembled or run.

Source programs: REGCALC, DT02ARTH, DT03CONV.

## Central Idea

Arithmetic runs on one representation and printing needs another. Each conversion instruction moves data one step along a fixed chain, and every step has a size or alignment rule. Most conversion bugs come from breaking one of those rules, and the instruction does not report the error.

## The Conversion Map

```
Character ---PACK---> Packed <---PACK--- Zoned
Character <----ED---- Packed ---UNPK---> Zoned

Packed ---CVB---> Binary (register) ---CVD---> Packed
```

| From | To | Instruction | Restriction |
|---|---|---|---|
| Character or zoned digits | Packed | `PACK` | No validity check on the input |
| Packed | Zoned | `UNPK` | Output field must be large enough; zone of the last byte is the sign |
| Packed | Binary | `CVB` | Source is a doubleword-aligned, valid packed field; result must fit in 31 bits |
| Binary | Packed | `CVD` | Target is a doubleword-aligned field |
| Packed | Edited character | `ED` | Pattern size and digit count must match the field |

There is no direct path between binary and character. Binary always goes through packed. This is why the number display idiom has four instructions:

```
         CVD   3,DOUBLE                * Binary to packed
         UNPK  ZONE,DOUBLE             * Packed to zoned
         OI    ZONE+7,X'F0'            * Make last digit printable
         MVC   OUTMSG+50(8),ZONE       * Place in output line
```

## Rules per Instruction

### PACK

- The digit nibble (low half) of every source byte is kept. The zone nibble (high half) of the last source byte becomes the sign.
- The target length is coded explicitly and is filled with zeros on the left. A target that is too small loses digits on the left.
- A target 8 bytes long holds up to 15 digits, so `PACK DOUBLE(8),field` prepares the value for `CVB`.
- Leading blanks (X'40') pack as zero digits and are harmless.
- Trailing blanks pack as zero digits at the right, scale the value by a power of ten, and the last blank's zone (4) becomes an invalid sign. `CL8'1234    '` gives X'0000000123400004'. Right justify the digits first, or pack only the digit part.
- A trailing minus sign is not understood. Pack only the digits (`PACK DOUBLE(8),CHARSGN(7)`), test the last character with `CLI`, then set the sign with `NI DOUBLE+7,X'F0'` and `OI DOUBLE+7,X'0D'`.

### UNPK

- Each packed digit becomes one byte with zone F. The last byte takes the sign in its zone (C positive, D negative, F unsigned).
- A packed field of `n` bytes holds `2n-1` digits. The output field needs that many bytes.
- If the output field is shorter than the digit count, `UNPK` keeps the right-hand bytes only. A 9-digit number in an 8-byte field loses its leftmost digit and the sign.

### OI and MVZ after UNPK

- The sign in the last byte makes the digit print as a letter. Positive sign C prints `D` for a last digit 4 (`00123D`). Negative sign D prints `M` (`00123M` for -1234).
- `OI field+last,X'F0'` forces zone F so every byte prints as a digit. The sign is lost. If the sign matters, save it first (`CP PACKWK,=P'0'`, then `MVI SIGNCHR,C'-'` or `C'+'`).
- `MVZ` copies zone nibbles only, so it can move zones between any bytes.

### CVB and CVD

- Both need a doubleword target or source, declared `DS D` so it is aligned.
- `CVB` needs valid digits and a valid sign in the source. A field built from a bad `PACK` gives a data exception, not a wrong answer.
- `CVB` handles -2,147,483,648 to 2,147,483,647. A larger value is a fixed-point divide exception.
- `CVD` produces up to 15 digits. To edit the result, `ZAP` it into a smaller packed field first, sized for the largest value in the data.
- When the packed result in `DOUBLE` must be kept, use a second doubleword (`DBLDISP` in `BINDISP`) as the work area.

### ZAP, not MVC, for packed data

`ZAP` clears the target, aligns the digits to the right and gives a valid sign, so field lengths may differ. `MVC` copies bytes and nothing else. `MVC WORKP(4),PACKA` into a zeroed `PL8` leaves the sign nibble in the middle of the field. `MVC` is safe only for equal-length fields.

## Editing with ED

`ED` turns a packed field into a printable field using a pattern held in the output field. The pattern is overwritten by the result.

| Pattern byte | Meaning |
|---|---|
| X'40' | Fill character (blank); the first byte of the pattern |
| X'20' | Digit selector: replaced by a digit, or by the fill while leading zeros are being suppressed |
| X'21' | Significance starter: selects a digit and turns zero suppression off for the bytes that follow |
| X'4B' | Period, printed as is once significance is on |
| X'6B' | Comma, printed once significance is on, otherwise replaced by the fill |
| X'60' | Trailing minus: printed when the value is negative, replaced by the fill when positive |

### Four rules to check every time

1. Count the digits in the packed field. A field of `n` bytes holds `2n-1` digits.
2. Count the X'20' and X'21' bytes in the pattern. The two counts must be equal. A mismatch gives results that cannot be predicted.
3. Count every byte of the pattern, including the fill byte and punctuation. The output field has exactly that length.
4. Move the pattern to the output field before every `ED`. `ED` destroys the pattern.

```
         MVC   EDWORK(9),EDMASK1       * Reload pattern
         ED    EDWORK(9),PACKWK        * Edit the packed field
```

### Worked patterns from DT03CONV

`EDMASK1` is X'402020202020202060': fill, 7 selectors, trailing minus (9 bytes, 7 digits).

| Packed value | Result |
|---|---|
| +12345 | `   12345 ` |
| -12345 | `   12345-` |

`EDMASK2` is X'4020202020214B202060': fill, 4 selectors, starter, period, 2 selectors, trailing minus (10 bytes, 7 digits).

| Packed value | Result | Note |
|---|---|---|
| 12345 | `   123.45 ` | Digits after the starter print as is |
| 7 | `      .07 ` | The digit selected by X'21' is 0 and is still replaced by the fill |

To print `0.07`, put the significance starter one digit earlier in the pattern, so a zero before the period is printed.

### Hand-computed example with a comma

Pattern X'4020206B2020214B202060' (11 bytes: fill, 2 selectors, comma, 2 selectors, starter, period, 2 selectors, minus; 7 digits). Source `PL4'-1234567'` is X'1234567D'.

| Step | Pattern byte | Source digit | Output |
|---|---|---|---|
| 1 | X'40' | | blank |
| 2 | X'20' | 1 | `1`, significance on |
| 3 | X'20' | 2 | `2` |
| 4 | X'6B' | | `,` (significance is on) |
| 5 | X'20' | 3 | `3` |
| 6 | X'20' | 4 | `4` |
| 7 | X'21' | 5 | `5` |
| 8 | X'4B' | | `.` |
| 9 | X'20' | 6 | `6` |
| 10 | X'20' | 7 | `7` |
| 11 | X'60' | sign D | `-` |

Result: ` 12,345.67-`. For `PL4'7'` the same pattern gives `       .07 `: the leading digits, the comma and the starter digit are all replaced by the fill.

## A Complete Chain

Character `00012345` to a printed value, from DT03CONV:

| Step | Instruction | Result |
|---|---|---|
| 1 | `PACK DOUBLE(8),CHARIN(8)` | X'000000000012345F' |
| 2 | `CVB 4,DOUBLE` | R4 = X'00003039' (12345) |
| 3 | `A 4,=F'55'` | R4 = 12400 |
| 4 | `CVD 4,DOUBLE` | X'000000000012400C' |
| 5 | `ZAP PACKWK,DOUBLE` | packed field sized for the data |
| 6 | `MVC EDWORK(10),EDMASK2`, `ED EDWORK(10),PACKWK` | `   124.00 ` (hand-computed) |

## Common Failures

| Symptom | Cause | Fix |
|---|---|---|
| Value 10, 100 or 1000 times too large | Trailing blanks packed as zero digits | Right justify the digits before `PACK` |
| Last digit prints as a letter | Sign still in the zone of the last byte | `OI field+last,X'F0'` after `UNPK`, saving the sign first if needed |
| Leftmost digit and sign missing | Output field shorter than the digit count | Size the `UNPK` target for all digits |
| Data exception at `CVB` | Source not a valid packed doubleword | Check the `PACK` input and use `ZAP` to fill the doubleword |
| Second edit shows garbage | Pattern was destroyed by the first `ED` | Move the pattern again before each `ED` |
| `.07` printed instead of `0.07` | Starter sits at the digit just before the period | Move X'21' one digit earlier |
| Packed field has the sign in the middle | `MVC` used where `ZAP` was needed | Use `ZAP` |
