# Multi-way Decisions

Scope: choosing one path out of several, with a `CLI` ladder (IF / ELSE IF) and a branch table with a computed branch, as in BR07CASE. Code blocks are layouts for illustration, not copies of the program. The program was not assembled or run.

Source programs: BR07CASE.

## Central Idea

A ladder tests the cases one after another. A branch table turns the case number into an offset and jumps straight to the right slot. The ladder is simple and works with any test. The table is fast and fixed in cost, but it needs a small whole-number code and a range check.

## Ladder

```
         CLI   CODE,C'A'               * Case A?
         BE    CASEA
         CLI   CODE,C'B'               * Case B?
         BE    CASEB
         ...                           * ELSE path
         B     JOIN
CASEA    ...
         B     JOIN
CASEB    ...
JOIN     DS    0H                      * All paths meet here
```

- Each case is a `CLI` and a `BE`. The ELSE path follows the last test.
- Every path ends with a branch to the join label so the later cases are skipped.
- The number of compares grows with the number of cases. A code that matches late runs every earlier test.

## Branch Table

```
         L     3,CODE                  * Case number
         C     3,=F'1'
         BL    DEFAULT                 * Below range
         C     3,=F'4'
         BH    DEFAULT                 * Above range
         BCTR  3,0                     * Zero based
         SLL   3,2                     * Times 4
         B     BRTAB(3)                * Computed branch
BRTAB    B     CASE1                   * Slot 0
         B     CASE2                   * Slot 1
         B     CASE3                   * Slot 2
         B     CASE4                   * Slot 3
```

Steps:

1. Range check first: `C` with `BL` and `BH` to the default path.
2. `BCTR 3,0` converts a 1-based code to a 0-based index.
3. `SLL 3,2` multiplies by 4, because each slot is one 4-byte `B` instruction.
4. `B BRTAB(3)` branches to the table start plus the offset. The index register is allowed here because `B` is a register-storage instruction, unlike `MVC` and `CLC`.

Hand-computed: code 3 becomes 2 after `BCTR`, then 8 after `SLL`, so the branch goes to the third slot, which holds `B CASE3`.

## Rules

- A computed branch with a bad index jumps to arbitrary storage. Always check the range first.
- R3 becomes the offset. Keep the original code in another register or in storage if it is needed later.
- Slots must be fixed length. All slots here are `B` instructions of 4 bytes.
- `=F'1'` style literals go into the literal pool. `LTORG` places the pool within reach of the base register.

## Choosing

| Condition | Use |
|---|---|
| Few cases, or tests on characters | Ladder |
| Many cases with a dense 1 to N code | Branch table |
| Cases tested on ranges or text | Ladder |
| Same decision made many times | Branch table, for the constant cost |

## Common Failures

| Symptom | Cause | Fix |
|---|---|---|
| Program jumps to random storage | Code out of range, no range check | Check both ends before the branch |
| Wrong case reached | Code is 1 based but the table is 0 based | `BCTR 3,0` before `SLL` |
| Branch lands inside a slot | Offset not a multiple of the slot size | `SLL 3,2` for 4-byte slots |
| Code is lost after the branch | R3 now holds the offset | Keep a copy |
| Assembly error on a literal | Pool out of base register reach | `LTORG` closer to the code |
