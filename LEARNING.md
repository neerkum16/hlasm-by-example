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
| 02 Registers and arithmetic | REGCALC | `src/REGCALC.asm` | `docs/REGCALC.md` | `output/REGCALC_SYSOUT.svg` |
| 03 Branching and looping | BR01CMP | `src/BR01CMP.asm` | `docs/BR01CMP.md` | `output/BR01CMP_SYSOUT.svg` |
| 03 Branching and looping | BR02MASK | `src/BR02MASK.asm` | pending | pending |
| 03 Branching and looping | BR03LOOP | `src/BR03LOOP.asm` | pending | pending |
| 03 Branching and looping | BR04BXLE | `src/BR04BXLE.asm` | pending | pending |
| 03 Branching and looping | BR05TABL | `src/BR05TABL.asm` | pending | pending |
| 03 Branching and looping | BR06NEST | `src/BR06NEST.asm` | pending | pending |
| 03 Branching and looping | BR07CASE | `src/BR07CASE.asm` | pending | pending |
| 03 Branching and looping | BR08SRCH | `src/BR08SRCH.asm` | pending | pending |

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

The remaining branching programs (BR02MASK to BR08SRCH) will be added as they are documented.

## 04 Subroutines

Planned.

## 05 Packed Decimal

Planned.

## 06 Editing (ED/EDMK)

Planned.

## 07 File I/O

Planned.

## 08 DSECTs

Planned.

## 09 Tables

Planned.

## 10 Macros

Planned.

## Mistakes and Fixes

| Date | Program | Symptom | Cause | Fix |
|---|---|---|---|---|
| | | | | |

## Open Questions

-
