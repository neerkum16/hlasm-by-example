# Condition Code and Branch Masks

Scope: the condition code as set by the compare instructions `CR`, `C`, `CLC`, `CLI` and `LTR`, by arithmetic, and by `TM` on a single bit, and the extended branch mnemonics as used in BR01CMP, BR02MASK and QSAMPROC. Condition code settings of instructions not used in these programs are not described. Hand-computed items are marked; the programs were not assembled or run.

Source programs: BR01CMP, BR02MASK, QSAMPROC (`TM` open check).

## Central Idea

An instruction sets a 2-bit condition code (CC). A branch instruction then tests it. The branch carries a 4-bit mask, one bit per CC value. The branch is taken when the mask bit for the current CC is on. Every extended mnemonic such as `BE` or `BNH` is `BC` with a fixed mask.

## CC Values

| CC | After compare | After LTR | After arithmetic |
|---|---|---|---|
| 0 | Operands equal | Zero | Zero |
| 1 | First operand low | Negative | Negative |
| 2 | First operand high | Positive | Positive |
| 3 | Not used by compares | Not used | Overflow |

## Compare Instructions

| Instruction | Compares | Arithmetic |
|---|---|---|
| `CR r1,r2` | Register to register | Signed |
| `C r,storage` | Register to fullword in storage | Signed |
| `CLC a(len),b` | Storage to storage, left to right, up to 256 bytes | Logical (unsigned, EBCDIC collating sequence) |
| `CLI storage,imm` | One storage byte to an immediate byte | Logical |
| `LTR r1,r2` | Loads r2 into r1, sets CC from the value | Signed |

- `CR` and `C` are signed, so -25 is less than 50.
- `CLC` and `CLI` are logical, so `SMITH` is higher than `JONES`: `S` (X'E2') is greater than `J` (X'D1') in EBCDIC.
- `LTR 5,5` tests a register without a second operand or a constant.

Test data in BR01CMP:

| Test | Values | Result |
|---|---|---|
| `CR` | NUMA 100, NUMB 50 | NUMA is high |
| `C` | NUMB 50, NUMC 50 | Equal |
| `CLC` | NAME1 `SMITH`, NAME2 `JONES` | NAME1 collates high |
| `CLI` | FLAG `Y` | Flag byte is Y |
| `LTR` | NUMD -25 | Negative |

## Branch Masks

| Mnemonic | Branches when | Mask |
|---|---|---|
| `BE`, `BZ` | CC 0 | 8 |
| `BL`, `BM` | CC 1 | 4 |
| `BH`, `BP` | CC 2 | 2 |
| `BO` | CC 3 | 1 |
| `BNE`, `BNZ` | CC not 0 | 7 |
| `BNL`, `BNM` | CC not 1 | 11 |
| `BNH`, `BNP` | CC not 2 | 13 |
| `BNO` | CC not 3 | 14 |
| `B` | Always | 15 |
| `NOP` | Never | 0 |

The mask bits are 8 for CC 0, 4 for CC 1, 2 for CC 2 and 1 for CC 3. Add bits to branch on several values: `BC 12` is 8 + 4, equal or low. Hand-computed: `BC 10` is 8 + 2, equal or high, with CC 3 excluded.

### BNH and BC 12

`BNH` is `BC 13` and includes CC 3. After a compare CC 3 never occurs, so `BC 12` and `BNH` act the same. After arithmetic, CC 3 means overflow and they differ.

### BCR

`BCR mask,reg` is the register form. `BCR 15,14` is `BR 14`. If the register field of `BCR` is 0, the branch is never taken.

## Patterns

- If / else: test, branch to the else label, run the then code, then `B` to a shared join label so the else code is skipped. BR01CMP names the join labels `EXnPUT`.
- Three-way: `BE`, `BL`, then an unconditional `B` for the remaining case.
- Arithmetic then test: `AR` then `BZ` needs no compare.

## TM and the Open Check

QSAMPROC tests whether a DCB is open with `TM DCBOFLGS,DCBOFOPN`, followed by `BNO error`. `TM` tests only the bits that are ones in the mask. With a single bit tested, the CC is 0 when the bit is off and 3 when it is on, so `BNO` (CC not 3) branches when the bit is off.

## Rules

- The branch must come immediately after the instruction that sets the CC. An instruction in between that changes the CC changes the result.
- `MVC` and `L` do not change the CC. `BCT`, `BXLE`, `BXH` and `SRL` do not either; follow `SRL` with `LTR` before a conditional branch.
- Choose signed or logical compare to match the data: numbers use `CR` or `C`, text uses `CLC` or `CLI`.

## Common Failures

| Symptom | Cause | Fix |
|---|---|---|
| Branch tests the wrong result | An instruction between the compare and the branch changed the CC | Put the branch next to the compare |
| Negative number sorts as large | Logical compare of a binary number | Use `C` or `CR` |
| `BNH` and `BC 12` differ | CC 3 after arithmetic | Choose the mask for the CC values that can occur |
| Branch after `SRL` always goes one way | `SRL` leaves the CC unchanged | `LTR` first |
| `BCR 0,reg` never branches | A register field of 0 suppresses the branch | Use a nonzero register |
