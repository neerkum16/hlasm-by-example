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
| 03 Branching and looping | BR02MASK | `src/BR02MASK.asm` | `docs/BR02MASK.md` | `output/BR02MASK_SYSOUT.svg` |
| 03 Branching and looping | BR03LOOP | `src/BR03LOOP.asm` | `docs/BR03LOOP.md` | `output/BR03LOOP_SYSOUT.svg` |
| 03 Branching and looping | BR04BXLE | `src/BR04BXLE.asm` | `docs/BR04BXLE.md` | `output/BR04BXLE_SYSOUT.svg` |
| 03 Branching and looping | BR05TABL | `src/BR05TABL.asm` | `docs/BR05TABL.md` | `output/BR05TABL_SYSOUT.svg` |
| 03 Branching and looping | BR06NEST | `src/BR06NEST.asm` | `docs/BR06NEST.md` | `output/BR06NEST_SYSOUT.svg` |
| 03 Branching and looping | BR07CASE | `src/BR07CASE.asm` | `docs/BR07CASE.md` | `output/BR07CASE_SYSOUT.svg` |
| 03 Branching and looping | BR08SRCH | `src/BR08SRCH.asm` | `docs/BR08SRCH.md` | `output/BR08SRCH_SYSOUT.svg` |

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
