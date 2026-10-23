# hlasm-by-example

Hands-on IBM High Level Assembler (HLASM) programs for z/OS: register arithmetic, branching, tables, searches, and SYSOUT I/O, with learning notes.

## Contents

| Path | Purpose |
|---|---|
| `README.md` | Roadmap and index (this file) |
| `LEARNING.md` | Consolidated notes: topic-to-program map, instruction notes, mistakes |
| `docs/` | One write-up per program (`docs/<PROGRAM>.md`) |
| `docs/concepts/` | Concept articles that explain one idea across several programs (`docs/concepts/<ARTICLE>.md`) |
| `src/` | Assembler source, one file per program (`src/<PROGRAM>.asm`) |
| `data/` | Test files for programs that read or write files (`<PROGRAM>_<DDNAME>.txt`) |
| `jcl/` | JCL to assemble, link, and run (`ASMCLRUN.jcl`) |
| `output/` | SDSF SYSOUT screens for each program (`<PROGRAM>_SYSOUT.svg`) |
| `.gitattributes`, `.gitignore` | Line-ending rules and ignored files |

## Roadmap

| # | Topic | Programs | Status |
|---|---|---|---|
| 01 | Basics: linkage, SYSOUT I/O, data types | HELLO, DT01TYPE | Done |
| 02 | Registers and arithmetic | REGCALC | Done |
| 03 | Branching and looping | BR01CMP, BR02MASK, BR03LOOP, BR04BXLE, BR05TABL, BR06NEST, BR07CASE, BR08SRCH, BR09MTCH | Done |
| 04 | Subroutines | | Planned |
| 05 | Packed decimal | DT02ARTH, DT03CONV | Done |
| 06 | Editing (ED/EDMK) | DT03CONV (ED only) | In progress (EDMK pending) |
| 07 | File I/O | QSAMPROC, BR09MTCH | In progress |
| 08 | DSECTs | QSAMPROC, BR09MTCH (`DCBD` only) | In progress |
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
| `BR09MTCH.asm` | 03, 07, 08 | Match-merge of two sorted 10-byte key files: priming read, `CLC` three-way decision, `FLUSH1` / `FLUSH2` / `MATCHED` paths write file-1-only, file-2-only and common keys, drain after end of file, `EODAD` routines with `HIVALUE`, `BAL 10` read routines, `OPENCHK` with `TM DCBOFLGS,DCBOFOPN` through `DCBD`, `ABEND 999,DUMP`, five packed counters printed to `SYSPRINT`. Input file contents not supplied; run counts 5 / 5 read, 4 / 4 / 1 written | Done |
| `DT02ARTH.asm` | 05 | Packed decimal arithmetic in 15 examples: `ZAP`, `AP`, `SP`, `CP`, `MP`, `DP`, `SRP`, and `MVC` on packed data (shows the broken and the safe case); signed display with `PKDISP`, hex dump with `HEXDISP` | Done |
| `DT03CONV.asm` | 05, 06 | Data conversions in 15 steps: `PACK` (clean, zoned, leading and trailing blanks, trailing minus), `CVB`, `CVD`, `UNPK`, `OI` and `MVZ` for printable zones, `ED` with simple and decimal point masks; hex dump with `HEXDISP`, binary display with `BINDISP` | Done |
| `QSAMPROC.asm` | 07, 08 | QSAM control-break program: reads a sorted 559-byte file with `GET`, classifies each group with flag rules and a prefix table search, writes one comma-delimited record per group with `PUT`; EODAD and SYNAD exits, DCB open check through `DCBD`, two base registers, linkage register per calling level, packed counters. Test files: `data/QSAMPROC_AMHFIN.txt` (6 records, 3 groups) and `data/QSAMPROC_AMHFOUT.txt` (header and 3 detail records) | Done |

Add a row for each new program.

## Concept Articles

Each article explains one idea that runs across several programs. It starts with a Scope line that states what the programs exercise. Files are in `docs/concepts/`.

| Article | Topics | Programs | Central idea |
|---|---|---|---|
| `LINKAGE.md` | 01 | All programs, QSAMPROC, DT01TYPE, DT02ARTH | Save area chain, base register, 4096-byte reach, two base registers, `BAL` routines |
| `DATA-TYPES.md` | 01 | DT01TYPE | The `DC` type builds the bytes; the instruction decides how they are read |
| `REGISTER-PAIRS.md` | 02, 03 | REGCALC, BR04BXLE, BR06NEST | `MR`, `D`, `BXLE` and `LM` depend on even-odd pair layout |
| `CONDITION-CODE.md` | 03 | BR01CMP, BR02MASK, QSAMPROC | Which instructions set the CC, mask bits 8/4/2/1, extended mnemonics |
| `LOOP-CONTROL.md` | 03 | BR03LOOP, BR04BXLE, BR06NEST | `BCT`, `BXLE`, `BXH`, loop shapes, the zero-count trap, nesting |
| `TABLES.md` | 03 | BR05TABL, BR08SRCH, QSAMPROC | Indexed addressing, pointer register for SS instructions, serial search |
| `MULTIWAY-DECISIONS.md` | 03 | BR07CASE | `CLI` ladder versus branch table, range check before a computed branch |
| `PACKED-ARITHMETIC.md` | 05 | DT02ARTH | Operand length rules for `ZAP`, `AP`, `MP`, `DP`, `SRP` |
| `DATA-CONVERSIONS.md` | 02, 05, 06 | REGCALC, DT02ARTH, DT03CONV | Conversion map and `ED` pattern rules |
| `QSAM-CONTROL-BREAK.md` | 07 | QSAMPROC | `GET` and `PUT` in move mode, open and close order, priming read, group reset |

Add a row when an article is written.

## Conventions

Source follows fixed-format HLASM columns.

- Label in column 1, opcode in column 10, operands in column 16
- Comments start at column 40
- Nothing past column 71; a continued statement carries a non-blank character in column 72
- Source files are uppercase with an `.asm` extension, for example `BR01CMP.asm`
- File name, CSECT name, and the `END` operand match
- Each program has a doc `docs/<PROGRAM>.md` with five sections: Program Overview, How the Program Works, Concepts Demonstrated, How the Concepts Are Implemented, Key Takeaways
- Each concept article in `docs/concepts/` has a Scope line directly under the title, then Central Idea, the rules, and Common Failures
- Test files in `data/` are named `<PROGRAM>_<DDNAME>.txt`, are plain text with one fixed-length record per line (trailing blanks kept), and are uploaded to the mainframe as text

## Running a Program

1. Copy the source to a partitioned dataset (member name = program name).
2. For a program that reads or writes files, upload the files from `data/` as text to datasets with the record format and length the program expects (QSAMPROC: `RECFM=FB`, `LRECL=559`; BR09MTCH: `INFILE1` and `INFILE2` sorted, `RECFM=FB`, `LRECL=10`, plus output datasets for `OUT1ONLY`, `OUT2ONLY` and `OUTCOMM`) and point the DD names at them in the JCL. Keep trailing blanks.
3. Adjust and submit `jcl/ASMCLRUN.jcl` (assemble, link, go).
4. The program writes to the `SYSOUT` DD (QSAMPROC and BR09MTCH: `SYSPRINT`). View it in SDSF and compare with `output/<PROGRAM>_SYSOUT.svg`. Compare any output file with its file in `data/`.

## Notes

See `LEARNING.md` for the topic-to-program map, the concept article index, notes on instructions and linkage, and mistakes made along the way.
