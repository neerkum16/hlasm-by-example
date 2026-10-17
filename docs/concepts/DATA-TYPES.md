# Data Types and Storage

Scope: the `DC` types C, X, B, F, H, P, Z, A and E as defined and displayed in DT01TYPE, with the alignment, padding and length rules seen in the other programs. The types D, S, Y, V and Q are not used in any program and are not described. Hand-computed items are marked; the programs were not assembled or run.

Source programs: DT01TYPE (all other programs use the same types).

## Central Idea

Storage holds bytes with no type attached. The `DC` type decides which bytes the assembler builds. The instruction decides how those bytes are read. The same four bytes can be a character string, a number or an address depending on the instruction that touches them.

## The Types

| Type | Example | Stored bytes | Alignment | Notes |
|---|---|---|---|---|
| C | `CL10'ABC123'` | C1C2C3F1F2F3 40404040 | none | One byte per character; a short value is padded on the right with X'40' |
| X | `XL4'0001ABCD'` | 0001ABCD | none | Two hex digits per byte; a short value is padded on the left with zeros |
| B | `B'10110011'` | B3 | none | Written as bits, stored as whole bytes |
| F | `F'-1234'` | FFFFFB2E | fullword | 4 bytes, two's complement |
| H | `H'-25'` | FFE7 | halfword | 2 bytes, two's complement |
| P | `PL4'-1234'` | 0001234D | none | Two digits per byte; sign in the low nibble of the last byte (C positive, D negative, F unsigned) |
| Z | `ZL6'-1234'` | F0F0F1F2F3D4 | none | One digit per byte; zone F except the last byte, whose zone carries the sign |
| A | `A(DT01TYPE)` | 00008000 | fullword | 4 byte address; the value depends on where the program is loaded |
| E | `E'1.5'` | 41180000 | fullword | Short floating point: sign and exponent byte, then fraction |

## Same Bytes, Different Reading

X'F1F2F3F4' is `1234` when read as characters and -235736076 when read as a signed fullword. DT01TYPE overlays the same four bytes as characters and as binary to show this. No instruction checks that the bytes suit the way it reads them.

## Rules

### Padding and truncation

- Type C pads on the right with blanks (X'40'). A value longer than the stated length is cut on the right: a `CL18` literal longer than 18 characters keeps only 18.
- Type X pads on the left with zeros.
- Message constants in these programs are `CL50`, so every `MVC OUTMSG(50),msg` uses the same length.

### Length limits

- A `DC` of type C is limited to 256 bytes. `CL349` gave ASMA068S in QSAMPROC. Use `DS` for a large area, or split the constant (`CL256` plus `CL93`).
- A `DC` of type Z or P is limited to 16 bytes.

### Alignment

- `F`, `H` and `A` align to a boundary when no length is coded. Instructions such as `CVB` and `CVD` need a doubleword, declared `DS D`.
- `DS 0F` forces fullword alignment for the item that follows and takes no storage. BR05TABL puts it in front of the table so the value in each 12-byte entry is on a fullword boundary.
- `DS 0H` defines a label with no storage and no alignment requirement beyond a halfword. BR03LOOP uses it as a loop exit target.
- `EQU` defines a value (for example `ENTLEN EQU 12`) and takes no storage.

### Literals

`=F'15'` and similar literals are stored in the literal pool. `LTORG` places the pool at that point so it is within reach of the base register.

### Signs in packed and zoned fields

- A positive zoned value with sign C prints its last digit as a letter: `ZL6'1234'` prints `00123D`. Only sign F prints as a digit.
- `UNPK` into an 8 byte field keeps 8 digits. A 9 digit number loses its leftmost digit and the sign.

## Showing Bytes as Hex

DT01TYPE prints each field as characters and as hex, using an internal routine called with `BAL 11,routine` and ended with `BR 11`. Parameters are in registers: R2 holds the address, R3 the length and R10 the output address.

To convert one byte to two hex characters: `IC` the byte, copy it, `SRL 6,4` for the high nibble, `N 5,=F'15'` for the low nibble, then `IC 7,HEXDIGIT(n)` and `STC` the character. `HEXDIGIT` holds the characters 0 to F.

## Common Failures

| Symptom | Cause | Fix |
|---|---|---|
| ASMA068S on a large `DC` | Type C longer than 256 bytes | Use `DS`, or split the constant |
| Value shorter than expected | Constant longer than its length modifier | Check the modifier against the text |
| Last digit prints as a letter | Sign C or D in the zone of the last zoned byte | Force zone F with `OI` |
| Wrong number read from a field | Instruction reads the bytes as another type | Match the instruction to the `DC` type |
| Address value differs between runs | `A(label)` holds a load address | Do not compare it with a fixed value |
