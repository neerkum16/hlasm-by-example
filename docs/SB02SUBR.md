# SB02SUBR.asm

## Program Overview

SB02SUBR is the called subprogram of the pair started by SB01CALL. It is a separate CSECT that is never run from JCL on its own. It receives the addresses of two fullwords in a parameter list (R1): the total and an amount. It adds the amount to the total, stores the new total back, and prepares a return code: 0 for a non-negative total, 4 for a negative total. It follows the z/OS standard linkage, so a caller using `CALL`, `LINK` or `BALR` can reach it.

SB02SUBR has no output of its own. Its effect is seen in the SYSOUT of the caller: `docs/SB01CALL.md`. It is assembled in `STEP02` of `jcl/SB01CALL.jcl` and link-edited with SB01CALL into one load module.

Program data:

| Field | Value | Used by |
|---|---|---|
| SUBSAVE | `DS 18F`, private save area | Entry and exit linkage |
| RETCODE | `DS X`, one byte | Set to 0 or 4, loaded into R15 at the end |

Registers used:

| Register | Role |
|---|---|
| R1 | On entry: address of the parameter list (two fullword addresses) |
| R2 | Address of parameter 1, the total |
| R3 | Address of parameter 2, the amount (high bit masked off) |
| R4 | Total, then total plus amount |
| R12 | Base register |
| R13 | On entry: caller's save area; during the body: `SUBSAVE` |
| R14 | Return address on entry; temporary pointer to `SUBSAVE` during the chain |
| R15 | Entry address on entry; return value on exit |

Output: none. The caller's output is in `output/SB01CALL_SYSOUT.svg`:

![SB01CALL SYSOUT](../output/SB01CALL_SYSOUT.svg)

Not assembled or run by Claude.

## How the Program Works

**Entry.**
1. `STM 14,12,12(13)` saves the caller's registers in the caller's save area.
2. `LR 12,15` and `USING SB02SUBR,12` set the base register.
3. `ST 13,SUBSAVE+4` stores the caller's save area address in word 2 of `SUBSAVE` (backward chain).
4. `LA 14,SUBSAVE` and `ST 14,8(,13)` store the address of `SUBSAVE` in word 3 of the caller's save area (forward chain).
5. `LR 13,14` makes R13 point to `SUBSAVE`.

**Body.**
1. `L 2,0(,1)` and `L 3,4(,1)` load the two addresses from the parameter list.
2. `N 3,=X'7FFFFFFF'` clears the high-order flag of the second address.
3. `L 4,0(,2)`, `A 4,0(,3)`, `ST 4,0(,2)` add the amount to the total and store it.
4. `LTR 4,4` sets the condition code from the new total. `BM SUBRBAD` is taken when it is negative.
5. `MVI RETCODE,0` and `B SUBRRET` for a non-negative total; `SUBRBAD MVI RETCODE,4` for a negative one.

**Exit.** `SUBRRET`: `L 13,SUBSAVE+4` (R13 back to the caller's save area), `LM 14,12,12(13)` (restores R14, R15 and R0 to R12), `IC 15,RETCODE`, `BR 14`.

**Execution trace** (values from the SB01CALL run).

| Call | Total before | Amount | R4 after `A` | CC after `LTR` | `BM` | RETCODE set |
|---|---|---|---|---|---|---|
| 1 | 100 | 50 | 150 | positive | not taken | 0 |
| 2 | 150 | 500 | 650 | positive | not taken | 0 |
| 3 | 650 | -100000 | -99350 | negative | taken | 4 |

## Concepts Demonstrated

- The called side of the z/OS standard linkage: R13, R1, R14, R15
- A private save area and the two-way save area chain
- Reading a parameter list of addresses, with the last-address flag in the high bit
- Masking the flag bit before using the address
- Updating the caller's storage through a passed address
- A return code kept in storage and loaded into R15 after `LM`
- A separate CSECT with its own `PRINT NOGEN` and `END`

## How the Concepts Are Implemented

| Concept | Implementation |
|---|---|
| Save area chain | `ST 13,SUBSAVE+4`, `LA 14,SUBSAVE`, `ST 14,8(,13)`, `LR 13,14`. Word 2 points back to the caller's area, word 3 of the caller's area points forward to `SUBSAVE`. |
| Parameter access | `L 2,0(,1)` and `L 3,4(,1)` read word 1 and word 2 of the list; `L 4,0(,2)` and `A 4,0(,3)` read the values through those addresses. |
| Flag bit | `N 3,=X'7FFFFFFF'` clears bit 0 of R3. The bit is never tested, so the routine works for any list of two parameters. |
| Result to caller | `ST 4,0(,2)` writes the total into the caller's `TOTAL` field. |
| Return code | `MVI RETCODE,0` or `4`; `IC 15,RETCODE` after `LM`. `LM` reloads R15, so a value placed in R15 before it would be lost. |
| Literal pool | There is no `LTORG`; the literal `=X'7FFFFFFF'` goes after `END`. |

## Key Takeaways

- `LM 14,12,12(13)` also reloads R15 and R12. Loading R15 after `LM` is correct, but `IC 15,RETCODE` is addressed through R12, and at that point R12 holds the caller's base, not SB02SUBR's. The byte read is not `RETCODE`. In the SB01CALL run the return code is 33280 (X'00008200') on every call, including the third, where 4 is expected. `IC` also changes only the low byte of R15, so the upper three bytes are the entry address that `LM` restored. This is inferred from the source and the SYSOUT; the program was not run by Claude. The source is not changed. An untested fix: `SR 15,15` and `IC 15,RETCODE` before the `LM`, then `L 13,SUBSAVE+4`, `ST 15,16(,13)` and `LM 14,12,12(13)`, so that `LM` restores the return code into R15.
- The program expects R1 to point to a list. A caller that does not load R1 (the first version of SB01CALL, which lacked `LA 1,PARMLST1`) makes `L 2,0(,1)` use a garbage address and abend S0C4.
- The high-order bit of the last address is masked but never tested. A caller that does not set it (the `CALL` macro without `VL`) gets the same result.
- `SUBSAVE` and `RETCODE` are static storage in the CSECT, so SB02SUBR is not reentrant: a recursive or multitasking call would share them.
- The program does not check that R1 holds two addresses; a list with one parameter would read the next word as the second address.
- `LTR 4,4` and `BM` test only the sign: a total of 0 gives return code 0.
- Because the caller prints the return code with `UNPK` and `OI`, the sign and any digits beyond 8 are lost in the display.
- Comments in the header say any caller (`CALL`, `LINK` or `BALR`) can invoke it; only `BALR` and `CALL` have been run (`LINK` is a comment in SB01CALL).
