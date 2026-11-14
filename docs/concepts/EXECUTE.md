# EX: Operand Length at Run Time

Scope: `EX` used to run an `MVC` whose length is decided at run time (`MVCSHOWN` and `MVCBUILD` in VB01LOC), the length-minus-1 form made with `BCTR`, the effect of an empty variable field, and the check that VB02FIX puts in front of `EX`. `EX` with instructions other than `MVC` is not used in any program and is not described. VB02FIX was run with the VB01BILD data, so only its zero-length path was exercised; the negative and over-256 paths were not run. The programs were not assembled or run, apart from the runs shown in the VB01LOC and VB02FIX SYSOUT screens.

Source programs: VB01LOC (the defect), VB02FIX (the check).

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

## The Check in VB02FIX

VB02FIX is VB01LOC with the length tested in `READREC`, once, where it is computed:

```
         LH    5,INRDWLL               * R5 = record length, RDW included
         S     5,=F'17'                * R5 = name length
         LTR   5,5                     * Test BEFORE trusting it
         BZ    NAMEZERO                * Zero: a legal, empty name
         BM    NAMEBAD                 * Negative: damaged RDW
         C     5,=F'256'               * Over the MVC ceiling?
         BH    NAMEBAD
         ST    5,NAMELEN
         BCTR  5,0                     * Safe: length - 1 for EX
         ST    5,NAMELENM1
         MVI   NAMEOK,C'Y'
         B     RRCOMMON
```

```
         CLI   NAMEOK,C'Y'             * In SHOWREC and BUILDOUT
         BNE   SHOWPUT                 * Skip the EX
         L     5,NAMELENM1
         EX    5,MVCSHOWN
```

- `LTR` sets the condition code once. `BZ` does not change it, so `BM` still sees the result of the `LTR`. The `C` that follows sets a new code for `BH`.
- `BCTR` comes after the tests. It does not set the condition code, so a test placed after it would test nothing.
- The check is made once. `SHOWREC` and `BUILDOUT` test the one-byte flag `NAMEOK` and do not repeat the arithmetic.
- For a rejected length `NAMELEN` is set to 0, so `BUILDOUT` still writes a valid record with an RDW length of 17 and no name bytes.
- A length over 256 can occur only with a damaged RDW, because `LRECL=37` limits the name to 20 bytes.
- Run result (VB02FIX SYSOUT): line 5 is `P100004   0000000` with a blank name, no bytes of record 5 appear on it, the end message `VB02FIX - PROGRAM ENDED NORMALLY` is printed, and `RECORDS READ  : 0000005` is followed by `BAD/EMPTY NAMES:0000001`. The output file browsed after the run shows the same 5 lines as the input: record 4 is `P100004` with no name.
- The program counts the empty name with the rejected ones, although an empty name is a legal record. The source comment says this is for demonstration.
- Only the zero path was exercised. Neither a negative length nor a length over 256 was in the test data.

## Rules

- Never pass `EX` a length computed from data without checking it. Zero, negative and over-256 lengths are the boundary cases; test all three and the flag that carries the result.
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
| Test placed after `BCTR` finds nothing | `BCTR` does not set the condition code | `LTR` before `BCTR` |
| Second `EX` site still moves 256 bytes | Only one site was changed | Test the same flag at every `EX` (`NAMEOK` in VB02FIX) |
