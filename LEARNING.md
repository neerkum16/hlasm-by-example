# Learning Notes

Consolidated notes while learning HLASM on z/OS. Each program has its own write-up in `docs/<PROGRAM>.md`; this file maps topics to programs and keeps the short instruction notes.

## How to Use This File

- One section per topic, in roadmap order.
- Record what each instruction does, the registers it uses, and mistakes made.
- Add a row to the topic map when a program is added.
- Add an entry to "Mistakes and Fixes" whenever something fails to assemble or runs wrong.

## Topic and Program Map

| Topic | Program | Source | Doc | SYSOUT |
|---|---|---|---|---|
| 01 Basics | HELLO | `src/HELLO.asm` | `docs/HELLO.md` | `output/HELLO_SYSOUT.svg` |
| 01 Basics | DT01TYPE | `src/DT01TYPE.asm` | `docs/DT01TYPE.md` | `output/DT01TYPE_SYSOUT.svg` |
| 02 Registers and arithmetic | REGCALC | `src/REGCALC.asm` | `docs/REGCALC.md` | `output/REGCALC_SYSOUT.svg` |
| 03 Branching and looping | BR01CMP | `src/BR01CMP.asm` | `docs/BR01CMP.md` | `output/BR01CMP_SYSOUT.svg` |
| 03 Branching and looping | BR02MASK | `src/BR02MASK.asm` | `docs/BR02MASK.md` | `output/BR02MASK_SYSOUT.svg` |
| 03 Branching and looping | BR03LOOP | `src/BR03LOOP.asm` | `docs/BR03LOOP.md` | `output/BR03LOOP_SYSOUT.svg` |
| 03 Branching and looping | BR04BXLE | `src/BR04BXLE.asm` | `docs/BR04BXLE.md` | `output/BR04BXLE_SYSOUT.svg` |
| 03 Branching and looping | BR05TABL | `src/BR05TABL.asm` | `docs/BR05TABL.md` | `output/BR05TABL_SYSOUT.svg` |
| 03 Branching and looping | BR06NEST | `src/BR06NEST.asm` | `docs/BR06NEST.md` | `output/BR06NEST_SYSOUT.svg` |
| 03 Branching and looping | BR07CASE | `src/BR07CASE.asm` | `docs/BR07CASE.md` | `output/BR07CASE_SYSOUT.svg` |
| 03 Branching and looping | BR08SRCH | `src/BR08SRCH.asm` | `docs/BR08SRCH.md` | `output/BR08SRCH_SYSOUT.svg` |
| 05 Packed decimal | DT02ARTH | `src/DT02ARTH.asm` | `docs/DT02ARTH.md` | `output/DT02ARTH_SYSOUT.svg` |
| 05 Packed decimal, 06 Editing | DT03CONV | `src/DT03CONV.asm` | `docs/DT03CONV.md` | `output/DT03CONV_SYSOUT.svg` |
| 07 File I/O, 08 DSECTs | QSAMPROC | `src/QSAMPROC.asm` | `docs/QSAMPROC.md` | `output/QSAMPROC_SYSOUT.svg` |

## Register Conventions

| Register | Use |
|---|---|
| R0, R1 | Parameter and work registers; clobbered by system services |
| R12 | Base register (by convention in these programs) |
| R13 | Address of save area |
| R14 | Return address |
| R15 | Entry-point address on entry; return code on exit |

## 01 Basics (HELLO)

- Entry linkage: `STM 14,12,12(13)`, `LR 12,15`, `USING name,12`, `ST 13,SAVEAREA+4`, `LA 13,SAVEAREA`.
- Exit linkage: `L 13,SAVEAREA+4`, `LM 14,12,12(13)`, `SR 15,15`, `BR 14`.
- QSAM output: `OPEN (dcb,(OUTPUT))`, `PUT dcb,area`, `CLOSE (dcb)`.
- `DCB DSORG=PS,MACRF=PM,DDNAME=SYSOUT,RECFM=FB,LRECL=80,BLKSIZE=0`; the DD name must exist in the JCL.
- `DC CL80'text'` pads to the record length with blanks.

### DT01TYPE: data types and their hex content

| Type | Example | Stored bytes | Notes |
|---|---|---|---|
| C | `CL10'ABC123'` | C1C2C3F1F2F3 40404040 | One byte per character; short values padded on the right with X'40' |
| X | `XL4'0001ABCD'` | 0001ABCD | Two hex digits per byte; short values padded on the left with zeros |
| B | `B'10110011'` | B3 | Written as bits, stored as whole bytes |
| F | `F'-1234'` | FFFFFB2E | 4 bytes, twos complement, fullword aligned |
| H | `H'-25'` | FFE7 | 2 bytes, halfword aligned |
| P | `PL4'-1234'` | 0001234D | Two digits per byte; sign in the low nibble of the last byte (C positive, D negative, F unsigned) |
| Z | `ZL6'-1234'` | F0F0F1F2F3D4 | One digit per byte; zone F except the last byte, whose zone carries the sign |
| A | `A(DT01TYPE)` | 00008000 | 4 byte address, fullword aligned |
| E | `E'1.5'` | 41180000 | Short floating point: sign and exponent byte, then fraction |

Notes:

- The type only decides how an instruction reads the bytes. `X'F1F2F3F4'` is `1234` as characters and -235736076 as a signed fullword.
- Positive zoned decimal with sign C prints its last digit as a letter (`ZL6'1234'` prints `00123D`); only sign F prints as a digit.
- `LTORG` places literals such as `=F'15'` in the pool.
- `BAL 11,routine` calls an internal routine and `BR 11` returns. Parameters are passed in registers (R2 address, R3 length, R10 output address in `HEXDISP`).
- Hex conversion of one byte: `IC` the byte, copy it, `SRL 6,4` for the high nibble, `N 5,=F'15'` for the low nibble, then `IC 7,HEXDIGIT(n)` and `STC` the character.
- `UNPK` into an 8 byte field keeps only 8 digits; a 9 digit number loses its leftmost digit and the sign.
- A `CL18` literal longer than 18 characters is cut to 18.

## 02 Registers and Arithmetic (REGCALC)

- `L` loads a fullword. `LA r,n` loads the value n (0 to 4095) with no storage reference.
- `AR` adds and `SR` subtracts, register to register.
- `MR even,reg`: the multiplicand is the odd register of the pair; the product fills the pair.
- `D even,storage`: the dividend is the even-odd pair; the quotient lands in the odd register and the remainder in the even register. Clear the even register first.
- Printing a binary number: `CVD` (binary to packed), `UNPK` (packed to zoned), `OI last-byte,X'F0'` (fix sign nibble), `MVC` into the output line.
- Clear the output line with `MVC OUT(80),BLANKS` before building each message.

## 03 Branching and Looping

### BR01CMP: compare instructions and conditional branches

Compare instructions set the condition code (CC). A branch instruction then tests the CC.

| CC | After compare | After LTR |
|---|---|---|
| 0 | Operands equal | Zero |
| 1 | First operand low | Negative |
| 2 | First operand high | Positive |
| 3 | Not used by compares | Not used |

Compare instructions used:

| Instruction | Compares | Arithmetic |
|---|---|---|
| `CR r1,r2` | Register to register | Signed |
| `C r,storage` | Register to fullword in storage | Signed |
| `CLC a(len),b` | Storage to storage, left to right, up to 256 bytes | Logical (unsigned, EBCDIC collating sequence) |
| `CLI storage,imm` | One storage byte to an immediate byte | Logical |
| `LTR r1,r2` | Loads r2 into r1 and sets CC from the value (zero, negative, positive) | Signed |

Extended branch mnemonics used, with the mask they assemble to (`BC mask,target`):

| Mnemonic | Branches when | Mask |
|---|---|---|
| `BE` / `BZ` | CC 0 (equal, zero) | 8 |
| `BL` / `BM` | CC 1 (low, negative) | 4 |
| `BH` / `BP` | CC 2 (high, positive) | 2 |
| `BNE` | CC not 0 | 7 |
| `BNH` | CC not 2 | 13 |
| `B` | Always | 15 |

Notes:

- The mask is 4 bits, one per CC value: 8 for CC0, 4 for CC1, 2 for CC2, 1 for CC3. A branch is taken when the bit for the current CC is on.
- If/else pattern: test, branch to the "else" label, run the "then" code, then `B` to a shared join label (`EXnPUT`) so the "else" code is skipped.
- Three-way pattern (Example 1): `BE`, `BL`, then an unconditional `B` for the remaining case.
- `CR` and `C` are signed, so -25 is less than 50. `CLC` and `CLI` are logical, so `SMITH` is higher than `JONES` because `S` (X'E2') is greater than `J` (X'D1') in EBCDIC.
- `LTR 5,5` tests a register without a second operand or a compare constant.
- The branch must come immediately after the instruction that sets the CC. Any instruction between them that changes the CC changes the result. `MVC` and `L` do not change it.
- Every message constant is `CL50`, so every `MVC OUTMSG(50),msg` uses the same length.
- Test data and results:

| Test | Values | Result |
|---|---|---|
| `CR` | NUMA 100, NUMB 50 | NUMA is high |
| `C` | NUMB 50, NUMC 50 | Equal |
| `CLC` | NAME1 `SMITH`, NAME2 `JONES` | NAME1 collates high |
| `CLI` | FLAG `Y` | Flag byte is Y |
| `LTR` | NUMD -25 | Negative |

### BR02MASK: branch masks

- Every extended mnemonic is `BC mask,target` (or `BCR mask,reg`). `BE`/`BZ` = 8, `BL`/`BM` = 4, `BH`/`BP` = 2, `BO` = 1, `BNE`/`BNZ` = 7, `BNL`/`BNM` = 11, `BNH`/`BNP` = 13, `BNO` = 14, `B` = 15, `NOP` = 0.
- Add mask bits to branch on several CC values: `BC 12` is 8 + 4, equal or low.
- `BNH` is `BC 13` and includes CC 3. After a compare CC 3 never occurs, so `BC 12` and `BNH` behave the same. After arithmetic CC 3 is overflow and they differ.
- Arithmetic sets the CC (0 zero, 1 negative, 2 positive, 3 overflow), so `AR` then `BZ` needs no compare.
- `BCR 15,14` is `BR 14`. If the register field of `BCR` is 0, it never branches.

### BR03LOOP: loop shapes

| Shape | Pattern | Runs at least once |
|---|---|---|
| Counted | `L r,count` ... `BCT r,top` | Yes |
| Top-tested (DO WHILE) | test and branch out at the top, `B top` at the bottom | No |
| Bottom-tested (DO UNTIL) | body, then test and branch back | Yes |

- `BCT r,label` subtracts 1 and branches if the result is not zero. It does not set the CC. A count of 0 on entry becomes -1 and runs about 4 billion times, so guard a count that may be zero with `LTR` and `BZ`.
- `BCTR r,0` subtracts 1 with no branch. `LA r,1(,r)` adds 1.
- `SRL r,1` halves a non-negative value and does not set the CC. Follow it with `LTR` before a conditional branch.
- `LABEL DS 0H` defines a label with no storage, used as a loop exit target.

### BR04BXLE: index loops

- `BXLE r1,r3,target`: r1 is the index, r3 the increment, r3+1 the limit. The index is incremented first and then compared. `BXLE` branches while index <= limit, `BXH` while index > limit. Neither changes the CC.
- r3 must be the even register of a pair, so the limit is the next odd register.
- Table walk: increment = entry length, limit = address of the last entry (not one past it).
- Countdown: increment -1 with `BXH` and limit 0 gives 5, 4, 3, 2, 1.
- `LM 8,9,INCLIM` loads increment and limit from two adjacent fullwords.
- The test is at the bottom, so the body runs at least once.

### BR05TABL: indexed tables

- `LA 4,TABLE(5)` builds the address of `TABLE` plus the index in R5 without reading storage.
- SS instructions (`MVC`, `CLC`) have no index field, so use the computed address in a base register: `MVC OUTMSG+2(8),0(4)`.
- Step the index with `LA 5,ENTLEN(,5)`. Name the entry length with `EQU`. `TABLE DS 0F` aligns the fullword values.
- `L 3,8(,4)` reads a field at a fixed displacement inside an entry.
- Keep the entry count (`ENTRIES`) beside the table and change it when entries change.

### BR06NEST: nested loops

- One counter register per loop level. Reload the inner counter, the column number and the output pointer inside the outer loop.
- If the inner counter is loaded before the outer label, the second pass starts with 0, `BCT` makes it -1, and the loop runs about 4 billion times.
- `MR 8,5`: multiplicand in the odd register (R9), product in R8:R9. `MR` replaces R8, so clearing it first is not required.
- `MVC 0(8,11),ZONE` is the explicit `D(L,B)` form. Advance the pointer R11 with `LA 11,10(,11)`.
- Write the record (`PUT`) after the inner loop, once per row.

### BR07CASE: multi-way decisions

- Ladder: `CLI x,C'A'` with `BE` for each case, an ELSE path after the last test, and a join label. Compares grow with the number of cases.
- Branch table: range check first (`C` with `BL` and `BH` to the default), then `BCTR 3,0` (zero based), `SLL 3,2` (times 4), `B BRTAB(3)`. Each slot is one 4-byte `B` instruction.
- A computed branch with a bad index jumps to arbitrary storage. Always check the range.
- Keep the original code if it is needed later, because R3 becomes the offset.
- `=F'1'` literals go into the literal pool. `LTORG` places the pool within reach of the base register.

### BR08SRCH: serial search

- Found / not-found: `CLC key,entry`, `BE FOUND` leaves the loop early, `BCT` falling through means no match.
- `CLC` and `MVC` take a base register and displacement, not an index. Keep a pointer in a register (R7) and step it with `LA 7,ENTLEN(,7)`.
- The pointer is still valid at `FOUND`, so `L 3,8(,7)` reads the value from the matching entry.
- After a failed search the pointer is past the last entry and must not be used.
- Copy the search argument to a work key (`MVC SRCHKEY(8),0(10)`) so the compare has a fixed first operand.
- Output columns: key at `OUTMSG(8)`, message at `OUTMSG+10(40)`, value at `OUTMSG+50(8)`.

### Patterns used in every program

- Output line: `MVC OUTMSG(80),BLANKS`, `MVC OUTMSG(50),msg`, then `CVD`, `UNPK ZONE,DOUBLE`, `OI ZONE+7,X'F0'`, `MVC OUTMSG+50(8),ZONE`, `PUT`.
- A count-controlled `BCT` loop with a count that may be 0 needs a guard.
- Comments start at column 40 and the line ends at column 71.

## 04 Subroutines

Planned.

## 05 Packed Decimal (DT02ARTH, DT03CONV)

### DT02ARTH: packed decimal arithmetic

Decimal instructions are SS format and work in storage. They need no general registers for the arithmetic. Operand lengths are coded as `field(length)`.

| Instruction | Operation | Notes |
|---|---|---|
| `ZAP op1,op2` | Zero and add: op1 = op2 | Safe copy or move; clears op1 first, so lengths may differ and the sign is valid |
| `AP op1,op2` | op1 = op1 + op2 | Signed; operand 1 must hold the result or a decimal overflow occurs |
| `SP op1,op2` | op1 = op1 - op2 | `SP x,x` clears a field |
| `CP op1,op2` | Compare, sets CC | 0 equal, 1 first low, 2 first high; `CP field,=P'0'` tests the sign |
| `MP op1,op2` | op1 = op1 * op2 | Op2 at most 8 bytes; L1 greater than L2; high-order L2 bytes of op1 must be zero |
| `DP op1,op2` | op1 = quotient and remainder | Quotient in the first L1-L2 bytes, remainder in the last L2 bytes, sign of the dividend |
| `SRP op1,n,round` | Shift and round | Positive n shifts left; right shift of N is coded 64-N; rounding digit is added to the last digit shifted out (5 rounds half up, 0 truncates); ignored on a left shift |

Notes:

- Use `ZAP`, not `MVC`, to move packed data. `MVC` copies bytes only. `MVC WORKP(4),PACKA` into a zeroed `PL8` leaves the sign nibble in the middle: X'0012345C0000000C'.
- `MVC` is safe for a whole field of equal length (`MVC SAMELEN(4),PACKA`).
- `ZAP` into an 8-byte field before `MP` provides the leading zero bytes `MP` needs.
- `DP DIVD(8),PACKB(4)`: quotient `DIVD(4)`, remainder `DIVD+4(4)`. A quotient too large for L1-L2 bytes causes a decimal divide exception.
- `SRP` right 2 on 12345 gives 123 with rounding 5 and with 0, because the last digit shifted out is 4.
- Signed display: `CP` against `=P'0'` and `MVI` for the sign character, then `UNPK ZONE15(15),WORKP(8)`, `OI ZONE15+14,X'F0'`, `MVC 1(15,10),ZONE15` (16 characters).
- Test values: `PACKA` `PL4'12345'` X'0012345C', `PACKB` `PL4'678'` X'0000678C', `PACKC` `PL3'-250'` X'00250D'.
- Results: 12345 + 678 = 13023; 12345 + (-250) = 12095; 678 - 12345 = -11667; 12345 * 678 = 8369910; 12345 / 678 = 18 remainder 141.
- Internal routines `PKDISP` and `HEXDISP` are called with `BAL 11` and return with `BR 11`; neither can call the other because R11 would be overwritten.

### DT03CONV: data conversions

Conversion chain: character or zoned, `PACK`, packed, `CVB`, binary in a register, `CVD`, packed, `UNPK`, zoned, `OI` or `MVZ`, printable character. `ED` turns packed into a formatted character field.

| Instruction | Conversion | Notes |
|---|---|---|
| `PACK op1,op2` | Zoned or character to packed | Digit nibble of each byte is kept; the zone of the last byte becomes the sign. No validity check |
| `CVB r,dword` | Packed to binary | Source must be a doubleword, valid digits and sign; value must fit in 31 bits |
| `CVD r,dword` | Binary to packed | Target must be a doubleword |
| `UNPK op1,op2` | Packed to zoned | Zone F on every digit except the last byte, whose zone is the sign |
| `OI field,X'F0'` | Force zone F | Makes the last digit printable; the sign is lost |
| `MVZ op1,op2` | Move zone nibbles | Copies only the high nibble of each byte; can move zones between any bytes |
| `ED op1,op2` | Packed to edited character | Pattern in operand 1 is overwritten by the digits |

Notes:

- `PACK` does not check its input. Leading blanks (X'40') pack as zero digits and are harmless. Trailing blanks pack as zero digits, scale the value by a power of ten and leave an invalid sign (4): `CL8'1234    '` gives X'0000000123400004'.
- `PACK` does not understand a trailing minus. Pack only the digits (`PACK DOUBLE(8),CHARSGN(7)`), test the last character with `CLI`, then `NI DOUBLE+7,X'F0'` and `OI DOUBLE+7,X'0D'` set the sign to D.
- `PACK` target length is explicit and the target is zero filled on the left. 8 digit characters fit an 8 byte target as X'000000000012345F'.
- `CVB` and `CVD` need a doubleword-aligned target (`DS D`). `BINDISP` uses a second doubleword (`DBLDISP`) so the packed result in `DOUBLE` is not changed.
- A negative zoned value prints a letter in the last position: `-1234` shows as `00123M` because X'D4' is the letter M. Positive with sign F prints as a digit.
- Save the sign before `OI` or `MVZ` if it matters: `CP PACKWK(5),=P'0'`, then `MVI SIGNCHR,C'-'` or `C'+'`.
- `BINDISP` prints 9 digits from a register: `CVD 3,DBLDISP`, `UNPK ZONE9(9),DBLDISP+3(5)` (the low 5 bytes hold 9 digits), `OI ZONE9+8,X'F0'`, `MVC 0(9,10),ZONE9`. The sign and any digits beyond 9 are lost.
- `HEXDISP` changes R2, R3 and R10. Reload them for every call. It does not use R4.
- Test values and results: `00012345` packs to X'000000000012345F'; `CVB` gives X'00003039' (12345); `A 4,=F'55'` gives 12400; `CVD` gives X'000000000012400C'.

## 06 Editing (ED/EDMK)

### DT03CONV: ED basics

| Pattern byte | Meaning |
|---|---|
| X'40' | Fill character (blank); first byte of the pattern |
| X'20' | Digit selector: replaced by a digit, or the fill while leading zeros are suppressed |
| X'21' | Significance starter: selects a digit and turns zero suppression off for the digits that follow |
| X'4B' | Period, printed as is |
| X'60' | Trailing minus: printed when the value is negative, replaced by the fill when positive |

- Load the pattern into a work area first (`MVC EDWORK(9),EDMASK1`), then `ED EDWORK(9),PACKWK`. `ED` destroys the pattern, so reload it before every use.
- `EDMASK1` X'402020202020202060': 7 digit selectors then a trailing minus. 12345 gives `   12345 `, -12345 gives `   12345-`.
- `EDMASK2` X'4020202020214B202060': 123.45 style. 12345 gives `   123.45 `. The value 7 gives `      .07 `, not `0.07`. The digit selected by X'21' (the one before the period) is zero and is still replaced by the fill; zero suppression is off only for the digits after it.
- To print a leading `0.07` the significance starter must be one digit position earlier in the pattern.
- The packed source must be a valid packed field; `ED` reads the digits two per byte.
- `EDMK` is not covered yet.

## 07 File I/O (QSAMPROC)

### QSAMPROC: QSAM control break

QSAM calls and DCB operands:

| Item | Use |
|---|---|
| `OPEN (dcb,(INPUT))` / `(dcb,(OUTPUT))` | Opens a file; sets no return code to test |
| `GET dcb,area` | Move mode (`MACRF=GM`): copies the next record to `area` |
| `PUT dcb,area` | Move mode (`MACRF=PM`): copies `area` to the buffer |
| `CLOSE (dcb)` | Flushes the last output buffer; skipping it can lose records |
| `EODAD=label` | Control goes to `label` instead of returning from `GET` at end of file |
| `SYNAD=label` | Control goes to `label` on a genuine I/O error |
| `LRECL=559,RECFM=FB,BLKSIZE=0` | Fixed 559-byte records, block size chosen by the system |

Notes:

- At EODAD, R2 to R13 are preserved by QSAM, so the base register and the return register of the caller of `READINP` are intact and `BR 9` works there.
- Open order: SYSPRINT first, because every error path writes to it. Close order: SYSPRINT last, because the counts are printed after the data files close.
- `PUT` to a file that is not open (or closed) branches through a DCB with no write routine: S0C1.
- Control break on a sorted file: priming read, outer loop per group, inner loop that exits on end of file, customer change or connect id change. On exit the input area already holds the first record of the next group.
- Reset group flags and the work areas once per group (`INITGRP`). Flags are only ever switched on inside the record loop.
- A top-tested outer loop produces no output for an empty input.
- Write the header line just before the first detail record, not at `OPEN`, so an empty input gives an empty output.
- Output record built from named `DS` fields (`OUTNAME`, `OUTID`, ..., `OUTC1` to `OUTC17` for the separators), so a field is referred to by name rather than by offset.
- `DC` of type C is limited to 256 bytes; use several `DC` statements or `DS`. `DC` of types Z and P is limited to 16 bytes.
- Clearing 559 bytes: `MVC a(256),BLANK256`, `MVC a+256(256),BLANK256`, `MVC a+512(47),BLANK256`.
- Prefix table search: `LA 2,PFXTAB`, `L 3,PFXCNT`, `CLC INACCTID(4),0(2)`, `BE found`, `LA 2,4(,2)`, `BCT 3,loop`.
- `=CL3'FT'` compares 3 bytes with `FT` and a blank. `=C'FT'` compares 2 bytes and also matches `FTX`.
- Message printing: `LA 1,msg`, `BAL 7,PRTMSG`. `PRTMSG` does `MVC PRTLINE(50),0(1)` and `PUT`. All messages are `CL50`.
- Counters: `PL5`, `ZAP =P'0'`, `AP =P'1'`, `UNPK ZONE9(9),CNT(5)`, `OI ZONE9+8,X'F0'`.
- Linkage registers by calling level: R10 level 1, R9 level 2, R8 level 3, R7 `PRTMSG`. A routine must not use the register that holds its own return address for a further call.

### Two base registers

- A displacement is 12 bits, so one base register reaches 4096 bytes. Storage past that (literal pool, DCBs, data) needs another base register.
- `USING QSAMPROC,12,11`, `LA 11,4095(,12)`, `LA 11,1(,11)`. Two `LA` instructions are used because 4096 does not fit in a 12-bit displacement. The first register named in the `USING` covers the first 4096 bytes.
- R11 is then not available for linkage, which is why `PRTMSG` uses R7.

## 08 DSECTs

### QSAMPROC: DCB open check

- `DCBD DSORG=PS` at the end of the program generates the `IHADCB` DSECT (a map, no storage).
- `LA 2,dcb`, `USING IHADCB,2`, `TM DCBOFLGS,DCBOFOPN`, `DROP 2`, `BNO error`. `TM` tests only the bits that are ones in the mask; `BNO` branches when the tested bit is off.
- Other DSECT topics are not covered yet.

## 09 Tables

Planned.

## 10 Macros

Planned.

## Mistakes and Fixes

| Date | Program | Symptom | Cause | Fix |
|---|---|---|---|---|
| 2026-10-15 | DT03CONV | Step 15 prints `.07`, comment says `0.07` | The digit selected by `X'21'` is the one before the period; it is zero and is still replaced by the fill | Comment is wrong, code unchanged; move the significance starter one digit earlier to print `0.07` |
| 2026-10-15 | DT03CONV | Trailing blanks pack to X'0000000123400004' | `PACK` takes the low nibble of each blank (X'40') as digit 0 and the zone of the last blank (4) as the sign | Right justify the digits or pack only the digit part before `PACK` |
| 2026-10-16 | QSAMPROC | ASMA068S on the blank constant | A `DC` of type C was coded as `CL349`; the limit for a `DC` of type C is 256 bytes | Use `DS` for the large area, or split the constant (`CL256` plus `CL93`) |
| 2026-10-16 | QSAMPROC | ASMA034E operand beyond active `USING` range | Program longer than 4096 bytes with one base register | `USING QSAMPROC,12,11` with R11 = R12 + 4096 |
| 2026-10-16 | QSAMPROC | S0C1 at run time | `PUT` to SYSPRINT before it was opened | `OPEN` SYSPRINT before the first `PUT`; close it last |

## Open Questions

- QSAMPROC: the source lines after the EODAD banner comment (DCBs, `LTORG`, `DCBD`, `END`) were rebuilt, not taken from the screenshots. Compare with the real source.
