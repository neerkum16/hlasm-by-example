# Loop Control

Scope: counted loops with `BCT`, top-tested and bottom-tested loops, index loops with `BXLE` and `BXH`, and nested loops, as used in BR03LOOP, BR04BXLE and BR06NEST. Table stepping with `LA` and `BCT` is covered in the tables article. Code blocks are layouts for illustration, not copies of the programs. The programs were not assembled or run.

Source programs: BR03LOOP, BR04BXLE, BR06NEST.

## Central Idea

A loop is a counter or index that changes, a test, and a branch back. The instruction chosen decides where the test is, what changes and whether the condition code is touched. Where the test sits decides whether the body can run zero times.

## Loop Shapes

| Shape | Pattern | Runs at least once |
|---|---|---|
| Counted | `L r,count` ... `BCT r,top` | Yes |
| Top-tested (DO WHILE) | Test and branch out at the top, `B top` at the bottom | No |
| Bottom-tested (DO UNTIL) | Body, then test and branch back | Yes |
| Index (`BXLE`, `BXH`) | Index, increment and limit in registers | Yes |

## BCT

```
         L     6,COUNT                 * Count in R6
LOOP     ...                           * Loop body
         BCT   6,LOOP                  * R6 - 1, branch if not 0
```

- `BCT r,label` subtracts 1 from the register and branches if the result is not zero. It does not set the CC.
- The test is at the bottom, so the body always runs once.
- A count of 0 on entry becomes -1, which is not zero, and the loop runs about 4 billion times. Guard a count that may be zero:

```
         L     6,COUNT
         LTR   6,6                     * Test the count
         BZ    SKIP                    * Zero: skip the loop
```

- `BCTR r,0` subtracts 1 and never branches (a second register of 0 means no branch). `LA r,1(,r)` adds 1.
- `SRL r,1` halves a non-negative value and does not set the CC. Follow it with `LTR` before a conditional branch.
- `LABEL DS 0H` defines a label with no storage, used as a loop exit target.

## BXLE and BXH

`BXLE r1,r3,target`:

- r1 is the index, r3 the increment and r3+1 the limit.
- The increment is added to the index first, then the index is compared with the limit.
- `BXLE` branches while index <= limit. `BXH` branches while index > limit. Neither changes the CC.
- r3 must be the even register of a pair, so the limit sits in the next odd register.

Table walk: the index holds an address.

```
         LA    6,TABLE                 * R6 = index = first entry
         LM    8,9,INCLIM              * R8 = step, R9 = limit
LOOP     ...                           * Use the entry at R6
         BXLE  6,8,LOOP                * Step, compare, branch
```

The increment is the entry length. The limit is the address of the last entry, not one past it. `LM 8,9,INCLIM` loads increment and limit from two adjacent fullwords.

Countdown: increment -1 with `BXH` and limit 0 gives 5, 4, 3, 2, 1. After the pass for 1 the index becomes 0, which is not greater than 0, so the loop ends.

The test is at the bottom, so the body runs at least once.

## Top-tested Loop

```
TOP      LTR   6,6                     * Test before the body
         BZ    DONE                    * Leave when zero
         ...                           * Loop body
         BCTR  6,0                     * Count down, no branch
         B     TOP                     * Back to the test
DONE     DS    0H
```

This shape handles a zero count with no separate guard.

## Nested Loops

BR06NEST prints a 4 by 4 multiplication table.

- Each loop level has its own counter register.
- The inner counter, the column number and the output pointer are reloaded inside the outer loop. If the inner counter is loaded before the outer label, the second pass starts with 0, `BCT` makes it -1 and the inner loop runs about 4 billion times.
- `MVC 0(8,11),ZONE` uses the explicit `D(L,B)` form. The pointer R11 advances with `LA 11,10(,11)`.
- `PUT` is outside the inner loop, once per row.

```
         L     6,ROWS                  * Outer count
ROWLOOP  L     7,COLS                  * Reload inner count
COLLOOP  ...                           * One cell
         BCT   7,COLLOOP               * Inner loop
         PUT   SYSOUT,OUTMSG           * One line per row
         BCT   6,ROWLOOP               * Outer loop
```

## Choosing

| Need | Use |
|---|---|
| Fixed count | `BCT` |
| Count that may be zero | `BCT` with an `LTR`/`BZ` guard, or a top-tested loop |
| Stepping through a table by address | `BXLE` |
| Counting down to a limit | `BXH` with a negative increment |
| Rows and columns | One `BCT` counter per level |

## Common Failures

| Symptom | Cause | Fix |
|---|---|---|
| Loop runs about 4 billion times | `BCT` count of 0 on entry, or inner count not reloaded | Guard the count; reload the inner count in the outer loop |
| `BXLE` stops one entry early or late | Limit is one past the last entry, or the first entry | Use the address of the last entry |
| Wrong register used as limit | r3 is not the even register of the pair | Put the increment in an even register |
| Branch after `SRL` or `BCT` misbehaves | They leave the CC unchanged | `LTR` first |
