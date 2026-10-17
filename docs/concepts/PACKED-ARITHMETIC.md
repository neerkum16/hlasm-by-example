# Packed Decimal Arithmetic

Scope: the decimal instructions `ZAP`, `AP`, `SP`, `CP`, `MP`, `DP` and `SRP`, and `MVC` on packed data, as used in the 15 examples of DT02ARTH. Decimal overflow and decimal divide exceptions are described as rules and are not demonstrated by a program. Conversion to and from other types is in the data conversions article. Hand-computed items are marked; the programs were not assembled or run.

Source programs: DT02ARTH.

## Central Idea

Decimal instructions work in storage on fields of any length up to 16 bytes, with no general registers for the arithmetic. Each instruction has a rule about the lengths of its two operands. A break of the rule gives a wrong result or an exception, and the assembler does not warn about it.

## Instructions

Operand lengths are coded as `field(length)`.

| Instruction | Operation | Notes |
|---|---|---|
| `ZAP op1,op2` | op1 = op2 | Clears op1 first, so lengths may differ and the sign is valid |
| `AP op1,op2` | op1 = op1 + op2 | Signed; op1 must be long enough for the result, or a decimal overflow occurs |
| `SP op1,op2` | op1 = op1 - op2 | `SP x,x` clears a field |
| `CP op1,op2` | Compare, sets the CC | 0 equal, 1 first low, 2 first high; `CP field,=P'0'` tests the sign |
| `MP op1,op2` | op1 = op1 * op2 | op2 at most 8 bytes; L1 greater than L2; the high-order L2 bytes of op1 must be zero |
| `DP op1,op2` | op1 = quotient and remainder | Quotient in the first L1-L2 bytes, remainder in the last L2 bytes, sign of the dividend |
| `SRP op1,n,round` | Shift and round | Positive n shifts left; a right shift of N is coded 64-N; the rounding digit is added to the last digit shifted out |

Arithmetic instructions set the CC (0 zero, 1 negative, 2 positive, 3 overflow), so `AP` followed by `BZ` needs no compare.

## Test Values in DT02ARTH

| Field | Definition | Bytes |
|---|---|---|
| PACKA | `PL4'12345'` | X'0012345C' |
| PACKB | `PL4'678'` | X'0000678C' |
| PACKC | `PL3'-250'` | X'00250D' |

| Operation | Result |
|---|---|
| PACKA + PACKB | 13023 |
| PACKA + PACKC | 12095 |
| PACKB - PACKA | -11667 |
| PACKA * PACKB | 8369910 |
| PACKA / PACKB | 18 remainder 141 |

## Rules

### ZAP, not MVC, moves packed data

`MVC` copies bytes only. `MVC WORKP(4),PACKA` into a zeroed `PL8` leaves the sign nibble in the middle of the field: X'0012345C0000000C'. `MVC` is safe only for a whole field of equal length (`MVC SAMELEN(4),PACKA`). `ZAP` aligns the digits at the right of the target and sets a valid sign.

### MP needs room and leading zeros

- Op2 is at most 8 bytes and op1 is longer than op2.
- The high-order L2 bytes of op1 must be zero, because the product needs room. `ZAP` the multiplicand into an 8-byte work field first. That gives the leading zero bytes.

Hand-computed: `ZAP WORKP(8),PACKA` gives X'000000000012345C'. `MP WORKP(8),PACKB(4)` then gives X'000000008369910C' (12345 * 678 = 8369910).

### DP layout

`DP DIVD(8),PACKB(4)` divides the 8-byte `DIVD` by the 4-byte `PACKB`. The quotient is in `DIVD(4)` and the remainder in `DIVD+4(4)`. The remainder has the sign of the dividend. A quotient too large for L1-L2 bytes causes a decimal divide exception.

Hand-computed: with 12345 in `DIVD` and 678 in `PACKB`, the quotient field is X'0000018C' (18) and the remainder field X'0000141C' (141).

### SRP

- A left shift is coded with a positive n. A right shift by N digits is coded 64-N.
- The rounding digit is added to the last digit shifted out. A rounding digit of 5 rounds half up, 0 truncates. It is ignored on a left shift.
- A right shift of 2 on 12345 gives 123 with rounding 5 and with 0, because the digit examined is 4.

### Clearing and testing

- `SP x,x` clears a field. `ZAP x,=P'0'` also does.
- `CP field,=P'0'` sets the CC from the sign and magnitude of a field.

## Displaying a Signed Packed Value

DT02ARTH builds a 16-character signed display in `PKDISP`:

1. `CP` the field against `=P'0'` and `MVI` the sign character (`+` or `-`).
2. `ZAP` into `WORKP(8)`.
3. `UNPK ZONE15(15),WORKP(8)` and `OI ZONE15+14,X'F0'`.
4. `MVC 1(15,10),ZONE15` places the 15 digits after the sign.

`PKDISP` and `HEXDISP` are internal routines called with `BAL 11` and left with `BR 11`. Neither can call the other, because R11 would be overwritten.

## Common Failures

| Symptom | Cause | Fix |
|---|---|---|
| Packed field with the sign in the middle | `MVC` of a shorter packed field into a longer one | Use `ZAP` |
| Decimal overflow on `AP` | Op1 too short for the result | Use a longer op1 |
| Wrong or abended `MP` | High-order bytes of op1 not zero, or op2 too long | `ZAP` into a longer field first; keep op2 at 8 bytes or less |
| Decimal divide exception | Quotient too large for L1-L2 bytes | Make op1 longer or op2 shorter |
| Right shift gives no rounding | Digit shifted out is below 5 | Check the digit, not the whole value |
