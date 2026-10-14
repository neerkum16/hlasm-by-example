# regcalc.asm

## Program Overview

REGCALC demonstrates register arithmetic in HLASM and how to display binary results. It runs five examples (add, subtract, multiply, divide, add using LA) and writes one formatted line per example to SYSOUT.

Input values are fullword constants: NUM1=100, NUM2=50, NUM3=15, NUM4=5.

Expected output (8-digit zero-padded numbers):

```
ADDITION: 00000100  + 00000050  = 00000150
SUBTRACTION: 00000100 - 00000050 = 00000050
MULTIPLICATION: 00000015 * 00000005 = 00000075
DIVISION: 00000100 / 00000015 = 00000006 REM=00000010
LOAD ADDRESS: 00000025 + 00000075 = 00000100
```

## How the Program Works

**Linkage and I/O.** The entry linkage, save area, OPEN, CLOSE and exit linkage are the same pattern as hello.asm. The DCB for SYSOUT is 80-byte fixed-blocked output.

**Common pattern for each example.**
1. Load operands into registers with `L` (or `LA` in example 5).
2. Clear the 80-byte output buffer: `MVC OUTMSG(80),BLANKS`.
3. Place a label such as `ADDITION: ` at the start of OUTMSG.
4. Convert each operand for display (the four-instruction sequence below) and place it at a fixed offset in OUTMSG, with operator and `=` text between the numbers.
5. Perform the arithmetic in registers.
6. Convert the result the same way, place it in OUTMSG, and `PUT SYSOUT,OUTMSG`.

**The conversion sequence.** A binary register value cannot be printed directly, so each number goes through:
1. `CVD reg,DOUBLE` converts binary to packed decimal in an 8-byte doubleword.
2. `UNPK ZONE,DOUBLE` unpacks it into 8 zoned-decimal bytes.
3. `OI ZONE+7,X'F0'` replaces the sign nibble in the last byte with F so the last digit is printable.
4. `MVC OUTMSG+n(8),ZONE` copies the 8 digits into the message at offset n.

**The five examples.**

| Example | Registers | Instruction | Result |
|---|---|---|---|
| 1 Addition | R3=NUM1, R4=NUM2 | `AR 3,4` | R3 = 150 |
| 2 Subtraction | R5=NUM1, R6=NUM2 | `SR 5,6` | R5 = 50 |
| 3 Multiplication | R7=NUM3, R8=NUM4 | `MR 6,8` | R6:R7 pair = 75 (low order in R7) |
| 4 Division | R8:R9 = 0:100 | `D 8,NUM3` | quotient R9 = 6, remainder R8 = 10 |
| 5 LA | R10=25, R11=75 | `AR 10,11` | R10 = 100 |

## Concepts Demonstrated

- Loading registers from storage (`L`) and with immediate values (`LA`)
- Fixed-point arithmetic: `AR`, `SR`, `MR`, `D`
- Even-odd register pairs for multiply and divide
- Binary to packed to zoned decimal conversion (`CVD`, `UNPK`, `OI`)
- Building an output record with `MVC` at computed offsets
- Literals (`=C'...'`) and the literal pool
- Work areas defined with `DS` and constants defined with `DC`
- Buffer clearing from a blank constant

## How the Concepts Are Implemented

| Concept | Implementation |
|---|---|
| Register arithmetic | `AR 3,4` adds R4 to R3 and leaves the sum in R3. `SR 5,6` subtracts R6 from R5. Both are register-to-register and use 32-bit signed values. |
| Multiplication with a pair | `MR 6,8` names the even register R6 of the pair. The implied multiplicand is R7, the multiplier is R8, and the 64-bit product ends up in R6:R7. The small result fits in R7, so `CVD 7` is used. |
| Division with a pair | `L 9,NUM1` and `SR 8,8` form the 64-bit dividend R8:R9 = 0:100. `D 8,NUM3` divides it by a fullword in storage. The quotient goes to R9 (odd) and the remainder to R8 (even). |
| LA as load immediate | `LA 10,25` computes the address 0+25 with no base or index, which loads 25 into R10. Valid for values 0 to 4095. |
| Numeric display | `DOUBLE DS D` is the 8-byte target for CVD (doubleword aligned). `ZONE DS CL8` is the UNPK target. Offset 7 in `OI ZONE+7,X'F0'` is the last byte, which carries the sign nibble. |
| Message layout | Offsets such as `OUTMSG+10(8)` and `OUTMSG+19(3)` place each field. Because `OUTMSG(80),BLANKS` clears the line first, the one-byte gaps between fields stay blank. |
| Literals | `=C' + '` creates an anonymous constant in the literal pool, which the assembler places at the end of the program, since no LTORG is coded. MVC copies it into the buffer. |
| Output | `OUTMSG DS CL80` matches LRECL=80, so each `PUT` writes one full line. |

## Key Takeaways

- Registers hold binary values. Anything you print must be converted to character form first, and CVD, UNPK, OI is the standard idiom.
- `OI ZONE+7,X'F0'` removes the sign, so negative results print as positive. The program is only correct for non-negative values. Handle negatives explicitly if needed.
- Each number displays as exactly 8 digits with leading zeros. Larger values would not be shown fully.
- MR and D need an even-odd register pair. MR's first operand is the even register and the odd register is implied. D's dividend is the even-odd pair and the quotient lands in the odd register.
- Set R8 (the high half of the dividend) before D. If R8 holds garbage, the result is wrong or a divide exception occurs.
- Offsets in MVC statements must be computed by hand and must match the text lengths. An off-by-one shifts every later field.
- The explicit length on `MVC OUTMSG+43(6),=C' REM='` is 6 while the literal as transcribed is 5 characters. MVC copies the explicit length, so one extra byte comes from whatever follows the literal in the pool. Check this line in your source and change the length to 5 (or the literal to 6 characters) if it matches.
- Some comments are copy-paste leftovers (for example "Perform Subtraction" above `MR`, "Minus Sign" on `*`, "NUM1 = 10" on NUM3). Update comments when copying code blocks.
