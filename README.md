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
| `jcl/` | JCL to assemble, link, and run (`ASMCLRUN.jcl`; `BR09MTCH.jcl` for BR09MTCH with its five data files; `QSAMPROC.jcl` for QSAMPROC with `AMHFIN` and `AMHFOUT`; `DS02BILD.jcl` for DS02BILD with `PARTFILE`; `DS02DSCT.jcl` for DS02DSCT; `VB01BILD.jcl` for VB01BILD with `OUTFILE`; `VB01LOC.jcl` for VB01LOC with `INFILE` and `OUTFILE`) |
| `output/` | SDSF SYSOUT screens for each program (`<PROGRAM>_SYSOUT.svg`); DS02BILD and VB01BILD show an ISPF Browse of their output file instead |
| `.gitattributes`, `.gitignore` | Line-ending rules and ignored files |

## Roadmap

| # | Topic | Programs | Status |
|---|---|---|---|
| 01 | Basics: linkage, SYSOUT I/O, data types | HELLO, DT01TYPE | Done |
| 02 | Registers and arithmetic | REGCALC | Done |
| 03 | Branching and looping | BR01CMP, BR02MASK, BR03LOOP, BR04BXLE, BR05TABL, BR06NEST, BR07CASE, BR08SRCH, BR09MTCH | Done |
| 04 | Subroutines | None yet; internal `BAL` routines are in `docs/concepts/SUBROUTINES.md` | Planned |
| 05 | Packed decimal | DT02ARTH, DT03CONV | Done |
| 06 | Editing (ED/EDMK) | DT03CONV (ED only) | In progress (EDMK pending) |
| 07 | File I/O | QSAMPROC, BR09MTCH, DS02BILD, DS02DSCT, VB01BILD, VB01LOC | In progress |
| 08 | DSECTs | DS01DSCT, DS02DSCT, DS02BILD (`ORG` record layout only), VB01BILD (DSECT over a locate-mode buffer), VB01LOC (input and output DSECTs over locate-mode buffers), QSAMPROC (`DCBD` only), BR09MTCH (`DCBD` only) | In progress |
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
| `QSAMPROC.asm` | 07, 08 | QSAM control-break program: reads a sorted 559-byte file with `GET`, classifies each group with flag rules and a prefix table search, writes one comma-delimited record per group with `PUT`; EODAD and SYNAD exits, DCB open check through `DCBD`, two base registers, linkage register per calling level, packed counters. Test files: `data/QSAMPROC_AMHFIN.txt` (6 records, 3 groups) and `data/QSAMPROC_AMHFOUT.txt` (header and 3 detail records). Run JCL: `jcl/QSAMPROC.jcl` | Done |
| `DS01DSCT.asm` | 08 | A DSECT of our own: `CUSTD` layout (`CUSTNO`, `CUSTNAME`, `CUSTBAL`) at the end of the source with no storage of its own, mapped over two `DC` records with `LA 3,rec` and `USING CUSTD,3`, `DROP`, then `ORG` to name the packed balance a second time as characters (`CUSTBALC`, the REDEFINES equivalent) and `UNPK` of the packed view. Six SYSOUT lines; column 10 of each carries a stray byte (`N`, `B`, `B`, `Ø`) because `MVC OUTMSG(10)` copies 10 bytes from 9-byte literals. No data files; runs with the generic `jcl/ASMCLRUN.jcl` | Done |
| `DS02BILD.asm` | 07, 08 | Builds the 5-record, 40-byte test file `PARTFILE` for the companion program DS02DSCT: `MVC` for part number and description, `ZAP` from packed literals for the `PL5` amount in columns 31-35, `PUT` in move mode, five times with no loop. The record area is `OUTREC DS 0CL40` with `ORG OUTREC+30` for `OUTAMT` and `ORG OUTREC+40` to close the record. No SYSOUT: the result is checked in ISPF Browse (`output/DS02BILD_SYSOUT.svg`, dataset name masked `HLQ.MLQ.TEST.PARTFILE`). The comment on the last `ORG` says "Step back" but the `ORG` moves forward. Run JCL: `jcl/DS02BILD.jcl` | Done |
| `DS02DSCT.asm` | 07, 08 | Reads `PARTFILE` (built by DS02BILD) with `GET` and an `EODAD` exit and maps the 40-byte buffer `INAREA` with a DSECT (`PARTD`, packed `PARTAMT`). A second DSECT (`PARMD`) maps a parameter block built by `BUILDTOT` and passed in R1 to `ADDAMT`, which adds the amount to a packed `GRANDTOT`. Two call levels use R10 and R9. Prints 5 detail lines and the total 127943 to `SYSPRINT`. The first version abended S0C7: `GRANDTOT` was never set with `ZAP`; it also called `ADDAMT` with `BAL 10`, which would loop (final version `BAL 9`). Comments call the DSECT `PARTREC`; it is `PARTD`. Run JCL: `jcl/DS02DSCT.jcl` | Done |
| `VB01BILD.asm` | 07, 08 | Builds the 5-record variable length file `OUTFILE` (`RECFM=VB`, `LRECL=37`) for the companion reader VB01LOC: `PUT` in locate mode (no area operand), R1 returns the buffer address, `LR 4,1` and `USING VBOUTRECD,4` map the DSECT over it, the RDW length (name length + 17) is set with `MVC OUTRDWLL,=H'n'`, `XC` clears the RDW flags, `ZAP` stores the `PL5` amount, `MVC` with an explicit length stores the name (12, 5, 20, 0 and 10 bytes; no `MVC` for the empty name), `DROP 4` after each record, the last record is written by `CLOSE`. RDW lengths 29, 22, 37, 17, 27. No SYSOUT: the result is checked in ISPF Browse (`output/VB01BILD_SYSOUT.svg`, dataset name masked `HLQ.MLQ.VB01BILD.OUTFILE`); Browse does not show the RDW. Its reader is VB01LOC. Run JCL: `jcl/VB01BILD.jcl` | Done |
| `VB01LOC.asm` | 07, 08 | Reads the variable length file VB01BILD built (`RECFM=VB`, `LRECL=37`, `EODAD=EOFRTN`) with `GET` in locate mode (no area operand), `LR 3,1` and `USING VBINRECD,3`; name length = RDW length - 17 (`LH`, `S`), `BCTR` for the length minus 1; `EX 5,MVCSHOWN` runs an `MVC` with a run-time length to print each record on `SYSPRINT`; builds a matching record with `PUT OUTFILE` in locate mode (`LR 4,1`, `USING VBOUTRECD,4`, `STH` for the RDW, `XC`, `ZAP`, `EX 5,MVCBUILD`); `OPENCHK` with `DCBD`. The run prints 5 records and `RECORDS READ  : 0000005`; the empty name of record 4 makes `EX` move 256 bytes, so line 5 shows the next record's data and the end message is lost (see `docs/VB01LOC.md`). Run JCL: `jcl/VB01LOC.jcl` | Done |

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
| `DSECTS.md` | 08 | DS01DSCT, DS02DSCT, QSAMPROC, BR09MTCH, VB01BILD, VB01LOC | A DSECT is a map with no storage; `LA`, `USING` and `DROP` join it to real storage; two maps at once; DSECT over a locate-mode buffer; `DCBD`; placement before `END` |
| `RECORD-LAYOUTS.md` | 08 | QSAMPROC, DS01DSCT, DS02BILD, DS02DSCT, VB01BILD, VB01LOC | `DS 0CLn` records, `ORG` to place a field, `ORG` in a DSECT as REDEFINES, closing `ORG`, `DS 0CL1` marking a variable part |
| `PACKED-VALIDITY.md` | 05, 07 | DS02DSCT, DS02BILD, DS01DSCT, BR09MTCH, QSAMPROC, VB01BILD | A valid sign nibble is needed before `AP`; initialise with `ZAP`; S0C7; building a packed test file; `HEX ON` in Browse |
| `SUBROUTINES.md` | 04 (partial) | DS02DSCT, BR09MTCH, QSAMPROC, DT01TYPE, DT02ARTH, VB01LOC | `BAL` and `BR`, one return register per call level, parameter block in R1, `EODAD` routine as a return path |
| `MATCH-MERGE.md` | 03, 07 | BR09MTCH | Two sorted files, one current record each, `CLC` three-way decision, drain after end of file, `HIVALUE` |
| `OPERAND-LENGTHS.md` | 03, 07, 08 | DS01DSCT, DS02BILD, DS02DSCT, BR09MTCH, QSAMPROC, VB01BILD, VB01LOC | Implied and explicit operand lengths, literal length, fixed `CL50` messages, truncation by `UNPK` zones, run-time length with `EX` |
| `LOCATE-MODE.md` | 07, 08 | VB01LOC, VB01BILD | `GET` and `PUT` in locate mode, buffer address in R1, `LR` at once, DSECT over the buffer, record written at the next `PUT` or `CLOSE` |
| `VARIABLE-RECORDS.md` | 07, 08 | VB01BILD, VB01LOC | `RECFM=VB`, the 4-byte RDW, `LRECL` as the longest record, length arithmetic (+17, -17), `DS 0CL1` variable part, Browse view |
| `EXECUTE.md` | 07 | VB01LOC | `EX` with `MVC`, length minus 1 with `BCTR`, low byte of the register, the empty-name failure and an untested fix |
| `STORAGE-OVERRUNS.md` | 03, 07, 08 | VB01LOC, DS01DSCT, VB01BILD, DS02DSCT | Over-reads and overruns seen in runs, what an overrun overwrites, one fault hiding another, boundary tests |

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
3. Adjust and submit `jcl/ASMCLRUN.jcl` (assemble, link, go). BR09MTCH uses `jcl/BR09MTCH.jcl`: replace `HLQ.MLQ` with your own high and middle level qualifiers; `INFILE1` and `INFILE2` must exist, the three output datasets are created each run (`NEW,CATLG,DELETE`). QSAMPROC uses `jcl/QSAMPROC.jcl`: it assembles, link-edits and runs in three steps; change the `SET` statements (`PGMNAME`, `SOURCE`, `LOAD`) and the `AMHFIN` and `AMHFOUT` dataset names to your own; `AMHFIN` must exist and `AMHFOUT` is `NEW,CATLG,DELETE`, so delete it before a rerun.
4. The program writes to the `SYSOUT` DD (QSAMPROC, BR09MTCH and DS02DSCT: `SYSPRINT`). View it in SDSF and compare with `output/<PROGRAM>_SYSOUT.svg`. Compare any output file with its file in `data/`. DS01DSCT lines carry one extra character in column 10 (`N`, `B`, `B`, `Ø`); it comes from the source, see `docs/DS01DSCT.md`. DS02BILD writes no SYSOUT: it creates `PARTFILE` (`jcl/DS02BILD.jcl`, `NEW,CATLG,DELETE`, delete before a rerun); view it in ISPF Browse and compare with `output/DS02BILD_SYSOUT.svg`. Browse shows the packed bytes in columns 31-35 as characters; `HEX ON` shows the real bytes. DS02DSCT reads that file: run DS02BILD first, then DS02DSCT (`jcl/DS02DSCT.jcl`, `PARTFILE` as `DISP=SHR`), and compare the SYSOUT with `output/DS02DSCT_SYSOUT.svg`. VB01BILD writes no SYSOUT either: it creates `OUTFILE` (`jcl/VB01BILD.jcl`, `RECFM=VB`, `LRECL=37`, `NEW,CATLG,DELETE`, delete before a rerun); view it in ISPF Browse and compare with `output/VB01BILD_SYSOUT.svg`. Browse does not show the 4-byte RDW, so the longest line is 33 characters. VB01LOC reads that file: run VB01BILD first, then VB01LOC (`jcl/VB01LOC.jcl`, `INFILE` as `DISP=SHR`, new `OUTFILE` `NEW,CATLG,DELETE`, delete before a rerun), and compare the `SYSPRINT` with `output/VB01LOC_SYSOUT.svg`.

## Notes

See `LEARNING.md` for the topic-to-program map, the concept article index, notes on instructions and linkage, and mistakes made along the way.
