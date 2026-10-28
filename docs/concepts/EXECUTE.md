# EX: Operand Length at Run Time

Scope: `EX` used to run an `MVC` whose length is decided at run time (`MVCSHOWN` and `MVCBUILD` in VB01LOC), the length-minus-1 form made with `BCTR`, and the effect of an empty variable field. `EX` with instructions other than `MVC` is not used in any program and is not described. The fix for the empty-name case is described but was not run. The programs were not assembled or run, apart from the run shown in the VB01LOC SYSOUT screen.

Source programs: VB01LOC.

## Central Idea

`MVC` and `CLC` carry their length in the instruction, as one byte holding the length minus 1. The assembler fills it in, so every other `MVC` in the repo has a length known at assembly time. When the length depends on the data, `EX` runs one copy of a target instruction with its length byte replaced by a register value.

## Mechanism

```
         LH    5,INRDWLL               * R5 = record length, RDW included
         S     5,=F'17'                * R5 = name length
         ST    5,NAMELEN
         BCTR  5,0                     * R5 = name length - 1
         ST    5,NAMELENM1
         ...
         L     5,NAMELENM1
         EX    5,MVCSHOWN              * Run the MVC with R5 as its length
         ...
MVCSHOWN MVC   PRTLINE+20(1),INNAME    * Target, coded with length 1
```

- `EX reg,target` takes the instruction at `target`, ORs the low byte of `reg` into its length byte, and executes that one instruction.
- The instruction in storage is not changed. Only this execution behaves differently.
- The target is coded with length 1. That assembles to a length byte of zero, so the OR gives exactly the register's value.
- The register must hold the length minus 1. `BCTR 5,0` makes it.
- Only the low byte is used, so the length is 1 to 256.
- VB01LOC has two targets: `MVCSHOWN` (name to the print line, column 21) and `MVCBUILD` (name to the output record). Both take the length from `NAMELENM1`.
- The target sits in the program after the routine's `BR 10` and inside the `USING` range of R3 (and R4 for `MVCBUILD`). The `DROP`s follow it.

## Trace

| Record | LL | NAMELEN | R5 (length - 1) | Length byte used | Bytes moved |
|---|---|---|---|---|---|
| 1 | 29 | 12 | 11 | X'0B' | 12 |
| 2 | 22 | 5 | 4 | X'04' | 5 |
| 3 | 37 | 20 | 19 | X'13' | 20 |
| 4 | 17 | 0 | -1 | X'FF' | 256 |
| 5 | 27 | 10 | 9 | X'09' | 10 |

## The Empty Name

An empty name is the case that fails.

- A move of 0 bytes does not exist, because the length byte holds the length minus 1.
- `BCTR` on a name length of 0 gives -1, X'FFFFFFFF'. The low byte is X'FF'.
- `EX` runs `MVC PRTLINE+20(256),INNAME`.

What the run shows (VB01LOC.md and the SYSOUT screen):

- Line 5, for `P100004`, has the start of the next record at column 25: RDW, `P100005`, amount and `COTTER PIN`. The 256 source bytes run into the next record in the same buffer.
- The target is 196 bytes longer than `PRTLINE`, which is 80 bytes. By the data layout in the source the move covers `ZONE7`, `BLANKS`, `MSGSTRT` and all of `MSGEND`. The end message does not appear. A blank line is printed in its place.
- `BUILDOUT` uses the same -1. The output RDW is correct (17, from `NAMELEN`) but the 256-byte move writes past the end of the record in the buffer. `OUTFILE` was not browsed, so its content is not recorded.

The source comments say that a length of 0 is a harmless one-byte move and that production code checks the length. The check is left out. The empty-name case gives -1, not 0, so the comment is incomplete.

## Fix (not run)

Test the name length once, where it is computed, and skip the move when it is zero:

```
         S     5,=F'17'                * R5 = name length
         ST    5,NAMELEN
         LTR   5,5                     * Empty name?
         BZ    EMPTY                   * Yes: no BCTR, no EX
         BCTR  5,0
```

- Both `EX` sites, `SHOWREC` and `BUILDOUT`, need the same decision. One way is to store a switch, or to test `NAMELEN` before each `EX`.
- `LTR` sets the condition code that `BZ` tests. `BCTR` does not set it, so the test goes before `BCTR`.
- A name length above 256 would wrap, because only the low byte is used. A length computed from a corrupt RDW needs an upper limit as well as the zero test.

## Rules

- Never pass `EX` a length computed from data without checking it. Zero and negative lengths are the boundary cases.
- Code the target with length 1 so the length byte starts at zero.
- Produce the register value with `BCTR` after checking for zero, not before.
- Keep the target next to the `EX` and name it for what it moves (`MVCSHOWN`, `MVCBUILD`).
- Test the shortest and the longest record.

## Common Failures

| Symptom | Cause | Fix |
|---|---|---|
| 256 bytes moved for an empty field | `BCTR` of 0 gives -1, low byte X'FF' | Test for zero before `BCTR` |
| Data from the next record appears | The move is longer than the field | Validate the length |
| End message missing | The overrun covered storage after the target | Validate the length |
| Move one byte too long | Register holds the length, not length - 1 | `BCTR` before `EX` |
| Length wrong after `EX` | Target coded with a length above 1 | Code length 1 |
| Fewer bytes moved than expected for a length above 256 | Only the low byte of the register is used | Limit the length |
