# Even-Odd Register Pairs

Scope: the register pair rules for `MR`, `D`, `BXLE` / `BXH` and `LM` as used in REGCALC, BR04BXLE and BR06NEST. Other pair instructions are not used in any program and are not described. The numeric example is an illustration, not taken from REGCALC. The programs were not assembled or run.

Source programs: REGCALC, BR04BXLE, BR06NEST.

## Central Idea

Some instructions name one register and use the next one too. The named register is the even one of an even-odd pair. Where an operand and a result land depends on that layout, so the code looks odd until the layout is known.

## Pairs by Instruction

| Instruction | Named register | Pair use |
|---|---|---|
| `MR even,reg` | Even register | Multiplicand in the odd register; product fills the pair |
| `D even,storage` | Even register | Dividend is the pair; quotient lands in the odd register, remainder in the even register |
| `BXLE r1,r3,target` | r3 (even) | r3 is the increment, r3+1 the limit; r1 is the index and is not part of the pair |
| `LM r1,r3,storage` | r1 to r3 | Loads consecutive registers from consecutive fullwords |

## Multiply

`MR 8,5` from BR06NEST:

- The multiplicand is in R9, the odd register of the pair named by 8.
- The multiplier is R5.
- The product fills R8:R9. The product low word is in R9.
- `MR` replaces R8, so clearing it first is not required.

## Divide

`D 4,field`:

- The dividend is the 64-bit value in R4:R5.
- The quotient lands in R5 and the remainder in R4.
- Clear the even register first, so the dividend equals the odd register.

Hand-computed illustration: R4 = 0 and R5 = 12345, `D 4,=F'678'` gives R5 = 18 and R4 = 141.

## BXLE and BXH

```
         LM    8,9,INCLIM              * R8 = increment, R9 = limit
         ...
         BXLE  6,8,LOOP                * R6 index, R8:R9 pair
```

- r3 must be the even register so the limit is the next odd register.
- `LM 8,9,INCLIM` loads the increment and the limit from two adjacent fullwords. The pair is loaded with one instruction because the registers are consecutive.

## Rules

- The named register of `MR` and `D` is the even register. An odd register in that position is a specification exception.
- Do not use R8 or R9 for other data in the middle of a `MR 8,5` sequence.
- For `D`, set the even register before the divide. A dividend of 12345 in the odd register with a dirty even register gives a wrong quotient or a divide exception.
- The remainder is in the even register, so move it before the next use of the pair.

## Common Failures

| Symptom | Cause | Fix |
|---|---|---|
| Specification exception | Odd register named in `MR`, `D` or as `BXLE` r3 | Name the even register |
| Wrong quotient or divide exception | Even register not cleared before `D` | `SR` the even register first |
| Product read from the wrong register | Low word is in the odd register | Use R9 for a small product in `MR 8,5` |
| `BXLE` loops wrongly | Limit not in the register after r3 | Load increment and limit together with `LM` |
| Pair overwritten | R8 or R9 used between `LM` and `BXLE` | Keep the pair free for the loop |
