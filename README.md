# hlasm-learning

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
| 01 | Basics: linkage, SYSOUT I/O | HELLO | Done |
| 02 | Registers and arithmetic | REGCALC | Done |
| 03 | Branching and looping | BR01CMP, BR02MASK, BR03LOOP, BR04BXLE, BR05TABL, BR06NEST, BR07CASE, BR08SRCH | In progress (BR01CMP done) |
| 04 | Subroutines | | Planned |
| 05 | Packed decimal | | Planned |
| 06 | Editing (ED/EDMK) | | Planned |
| 07 | File I/O | | Planned |
| 08 | DSECTs | | Planned |
| 09 | Tables | | Planned |
| 10 | Macros | | Planned |

## Programs

| Program | Topic | Description | Status |
|---|---|---|---|
| `HELLO.asm` | 01 | Writes one record to SYSOUT; standard entry and exit linkage | Done |
| `REGCALC.asm` | 02 | Add, subtract, multiply, divide, and LA; converts binary results to printable digits | Done |
| `BR01CMP.asm` | 03 | Compare instructions (CR, C, CLC, CLI, LTR) set the condition code; extended branch mnemonics (BE, BL, BNE, BNH, BZ, BM) test it | Done |
| `BR02MASK.asm` | 03 | Branch on condition code using masks | To be documented |
| `BR03LOOP.asm` | 03 | Looping | To be documented |
| `BR04BXLE.asm` | 03 | Index loops with BXLE | To be documented |
| `BR05TABL.asm` | 03 | Table processing | To be documented |
| `BR06NEST.asm` | 03 | Nested loops and branches | To be documented |
| `BR07CASE.asm` | 03 | Case selection | To be documented |
| `BR08SRCH.asm` | 03 | Searching | To be documented |

Add a row for each new program. Descriptions marked "To be documented" are inferred from the file names and will be replaced when each program is written up.

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
