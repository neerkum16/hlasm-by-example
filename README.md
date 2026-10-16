# hlasm-by-example

Hands-on IBM High Level Assembler (HLASM) programs for z/OS: register arithmetic, branching, tables, searches, and SYSOUT I/O, with learning notes.

## Contents

| Path | Purpose |
|---|---|
| `README.md` | Roadmap and index (this file) |
| `LEARNING.md` | Consolidated notes: topic-to-program map, instruction notes, mistakes |
| `docs/` | One write-up per program (`docs/<PROGRAM>.md`) |
| `src/` | Assembler source, one file per program (`src/<PROGRAM>.asm`) |
| `jcl/` | JCL to assemble, link, and run (`ASMCLRUN.jcl`) |
| `output/` | SDSF SYSOUT screens for each program (`<PROGRAM>_SYSOUT.svg`) |
| `.gitattributes`, `.gitignore` | Line-ending rules and ignored files |

## Roadmap

| # | Topic | Programs | Status |
|---|---|---|---|
| 01 | Basics: linkage, SYSOUT I/O, data types | HELLO, DT01TYPE | Done |
| 02 | Registers and arithmetic | REGCALC | Done |
| 03 | Branching and looping | BR01CMP, BR02MASK, BR03LOOP, BR04BXLE, BR05TABL, BR06NEST, BR07CASE, BR08SRCH | Done |
| 04 | Subroutines | | Planned |
| 05 | Packed decimal | DT02ARTH, DT03CONV | In progress |
| 06 | Editing (ED/EDMK) | DT03CONV (ED only) | In progress |
| 07 | File I/O | | Planned |
| 08 | DSECTs | | Planned |
| 09 | Tables | | Planned |
| 10 | Macros | | Planned |

## Programs

| Program | Topic | Description | Status |
|---|---|---|---|
| `HELLO.asm` | 01 | Writes one record to SYSOUT; standard entry and exit linkage | Done |
| `DT01TYPE.asm` | 01 | Defines one field of each DC type (C, X, B, F, H, P, Z, A, E); prints character and hex views with an internal `BAL` routine; overlays the same four bytes as characters and binary | Done |
| `REGCALC.asm` | 02 | Add, subtract, multiply, divide, and LA; converts binary results to printable digits | Done |
| `BR01CMP.asm` | 03 | Compare instructions (CR, C, CLC, CLI, LTR) set the condition code; extended branch mnemonics (BE, BL, BNE, BNH, BZ, BM) test it | Done |
| `BR02MASK.asm` | 03 | Branch masks: extended mnemonics as `BC mask,target`; `BC 8`, `BC 12`, `BC 15`, `NOP`, `BZ` after arithmetic, `BCR 15,14` | Done |
| `BR03LOOP.asm` | 03 | Loop shapes: counted loop with `BCT`, top-tested (DO WHILE), bottom-tested (DO UNTIL), `BCTR r,0` | Done |
| `BR04BXLE.asm` | 03 | Index loops: `BXLE` over a fullword table by address, `BXH` counting down with a negative increment | Done |
| `BR05TABL.asm` | 03 | Table of 12-byte entries stepped with an index register (`LA TABLE(5)`), `BCT` loop, running total | Done |
| `BR06NEST.asm` | 03 | Nested loops: 4 by 4 multiplication table with `MR`, inner counter reset per row, `MVC` with explicit `D(L,B)` | Done |
| `BR07CASE.asm` | 03 | Multi-way decisions: `CLI` IF / ELSE IF ladder and a branch table with a computed branch (`B BRTAB(3)`) and range check | Done |
| `BR08SRCH.asm` | 03 | Serial search of a keyed table with `CLC`, early exit, found / not-found pattern, pointer register for SS instructions | Done |
| `DT02ARTH.asm` | 05 | Packed decimal arithmetic in 15 examples: `ZAP`, `AP`, `SP`, `CP`, `MP`, `DP`, `SRP`, and `MVC` on packed data (shows the broken and the safe case); signed display with `PKDISP`, hex dump with `HEXDISP` | Done |
| `DT03CONV.asm` | 05, 06 | Data conversions in 15 steps: `PACK` (clean, zoned, leading and trailing blanks, trailing minus), `CVB`, `CVD`, `UNPK`, `OI` and `MVZ` for printable zones, `ED` with simple and decimal point masks; hex dump with `HEXDISP`, binary display with `BINDISP` | Done |

Add a row for each new program.

## Conventions

Source follows fixed-format HLASM columns.

- Label in column 1, opcode in column 10, operands in column 16
- Comments start at column 40
- Nothing past column 71; a continued statement carries a non-blank character in column 72
- Source files are uppercase with an `.asm` extension, for example `BR01CMP.asm`
- File name, CSECT name, and the `END` operand match
- Each program has a doc `docs/<PROGRAM>.md` with five sections: Program Overview, How the Program Works, Concepts Demonstrated, How the Concepts Are Implemented, Key Takeaways

## Running a Program

1. Copy the source to a partitioned dataset (member name = program name).
2. Adjust and submit `jcl/ASMCLRUN.jcl` (assemble, link, go).
3. The program writes to the `SYSOUT` DD. View it in SDSF and compare with `output/<PROGRAM>_SYSOUT.svg`.

## Notes

See `LEARNING.md` for the topic-to-program map, notes on instructions and linkage, and mistakes made along the way.
