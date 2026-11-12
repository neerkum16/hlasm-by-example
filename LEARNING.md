# Learning Notes

Consolidated notes while learning HLASM on z/OS. Each program has its own write-up in `docs/<PROGRAM>.md`; this file maps topics to programs and keeps the short instruction notes. Concept articles in `docs/concepts/` explain one idea across several programs.

## How to Use This File

- One section per topic, in roadmap order.
- Record what each instruction does, the registers it uses, and mistakes made.
- Add a row to the topic map when a program is added.
- Add a row to the test data table when a program has files in `data/`.
- Add a row to the run JCL table when a program has its own JCL in `jcl/`.
- Add a row to the concept article table when an article is written.
- Add an entry to "Mistakes and Fixes" whenever something fails to assemble or runs wrong.

## Topic and Program Map

| Topic | Program | Source | Doc | SYSOUT |
|---|---|---|---|---|
| 01 Basics | HELLO | `src/HELLO.asm` | `docs/HELLO.md` | `output/HELLO_SYSOUT.svg` |
| 01 Basics | DT01TYPE | `src/DT01TYPE.asm` | `docs/DT01TYPE.md` | `output/DT01TYPE_SYSOUT.svg` |
| 02 Registers and arithmetic | REGCALC | `src/REGCALC.asm` | `docs/REGCALC.md` | `output/REGCALC_SYSOUT.svg` |
| 03 Branching and looping | BR01CMP | `src/BR01CMP.asm` | `docs/BR01CMP.md` | `output/BR01CMP_SYSOUT.svg` |
| 03 Branching and looping | BR02MASK | `src/BR02MASK.asm` | `docs/BR02MASK.md` | `output/BR02MASK_SYSOUT.svg` |
| 03 Branching and looping | BR03LOOP | `src/BR03LOOP.asm` | `docs/BR03LOOP.md` | `output/BR03LOOP_SYSOUT.svg` |
| 03 Branching and looping | BR04BXLE | `src/BR04BXLE.asm` | `docs/BR04BXLE.md` | `output/BR04BXLE_SYSOUT.svg` |
| 03 Branching and looping | BR05TABL | `src/BR05TABL.asm` | `docs/BR05TABL.md` | `output/BR05TABL_SYSOUT.svg` |
| 03 Branching and looping | BR06NEST | `src/BR06NEST.asm` | `docs/BR06NEST.md` | `output/BR06NEST_SYSOUT.svg` |
| 03 Branching and looping | BR07CASE | `src/BR07CASE.asm` | `docs/BR07CASE.md` | `output/BR07CASE_SYSOUT.svg` |
| 03 Branching and looping | BR08SRCH | `src/BR08SRCH.asm` | `docs/BR08SRCH.md` | `output/BR08SRCH_SYSOUT.svg` |
| 03 Branching and looping, 07 File I/O, 08 DSECTs | BR09MTCH | `src/BR09MTCH.asm` | `docs/BR09MTCH.md` | `output/BR09MTCH_SYSOUT.svg` |
| 05 Packed decimal | DT02ARTH | `src/DT02ARTH.asm` | `docs/DT02ARTH.md` | `output/DT02ARTH_SYSOUT.svg` |
| 05 Packed decimal, 06 Editing | DT03CONV | `src/DT03CONV.asm` | `docs/DT03CONV.md` | `output/DT03CONV_SYSOUT.svg` |
| 07 File I/O, 08 DSECTs | QSAMPROC | `src/QSAMPROC.asm` | `docs/QSAMPROC.md` | `output/QSAMPROC_SYSOUT.svg` |
| 08 DSECTs | DS01DSCT | `src/DS01DSCT.asm` | `docs/DS01DSCT.md` | `output/DS01DSCT_SYSOUT.svg` |
| 07 File I/O, 08 DSECTs | DS02BILD | `src/DS02BILD.asm` | `docs/DS02BILD.md` | `output/DS02BILD_SYSOUT.svg` (ISPF Browse of the output file, not SDSF) |
| 07 File I/O, 08 DSECTs | DS02DSCT | `src/DS02DSCT.asm` | `docs/DS02DSCT.md` | `output/DS02DSCT_SYSOUT.svg` |
| 07 File I/O, 08 DSECTs | VB01BILD | `src/VB01BILD.asm` | `docs/VB01BILD.md` | `output/VB01BILD_SYSOUT.svg` (ISPF Browse of the output file, not SDSF) |
| 07 File I/O, 08 DSECTs | VB01LOC | `src/VB01LOC.asm` | `docs/VB01LOC.md` | `output/VB01LOC_SYSOUT.svg` |
| 04 Subroutines | SB01CALL | `src/SB01CALL.asm` | `docs/SB01CALL.md` | `output/SB01CALL_SYSOUT.svg` |
| 04 Subroutines | SB02SUBR | `src/SB02SUBR.asm` | `docs/SB02SUBR.md` | none: result is in `output/SB01CALL_SYSOUT.svg` |
| 05 Packed decimal, 06 Editing | ED01EDMK | `src/ED01EDMK.asm` | `docs/ED01EDMK.md` | `output/ED01EDMK_SYSOUT.svg` |
| 10 Macros, 07 File I/O | MC01MACR | `src/MC01MACR.asm` | `docs/MC01MACR.md` | `output/MC01MACR_SYSOUT.svg` |
| 09 Tables, 03 Branching and looping, 07 File I/O | TB01TABL | `src/TB01TABL.asm` | `docs/TB01TABL.md` | `output/TB01TABL_SYSOUT.svg` |

## Test Data

Programs that read or write files keep their test files in `data/`, named `<PROGRAM>_<DDNAME>.txt`. Each line is one fixed-length record with trailing blanks kept; upload as text.

| Program | DD | File | Records | Content |
|---|---|---|---|---|
| QSAMPROC | AMHFIN | `data/QSAMPROC_AMHFIN.txt` | 6 x 559 | 3 groups: 85008 / D0A0V901 (ADM F, BR F), 85008 / D0A0W301 (ADM F), 85100 / W0A07001 (ADM F, CIT F, BR F) |
| QSAMPROC | AMHFOUT | `data/QSAMPROC_AMHFOUT.txt` | 4 x 559 | Output of the run: header line and 3 detail records, all `SYSTEM ADMINISTRATOR` |
| DS02BILD | PARTFILE | none | 5 x 40 | Created by the program, not stored in `data/`: columns 31-35 are packed decimal and would be damaged by a text upload. Contents are in `docs/DS02BILD.md` |
| DS02DSCT | PARTFILE | none | 5 x 40 | Input: the file DS02BILD creates. See the DS02BILD row |
| VB01BILD | OUTFILE | none | 5 variable, 17 to 37 bytes with RDW | Created by the program, not stored in `data/`: each record starts with a binary RDW and has a packed amount, so a text file cannot hold it. Contents are in `docs/VB01BILD.md` |
| VB01LOC | INFILE | none | 5 variable, 17 to 37 bytes with RDW | Input: the file VB01BILD creates. See the VB01BILD row |
| VB01LOC | OUTFILE | none | 5 variable, written by the program | Created by the program, not stored in `data/`. Not browsed, so its contents are not recorded |
| MC01MACR | INFILE | `data/MC01MACR_INFILE.txt` | 4 x 80 | Input: the output of BR08SRCH (`TABLE SEARCH RESULTS`, CHARLIE 00000300, ALPHA 00000100, ECHO not found). Value in column 51 |
| MC01MACR | OUTFILE | `data/MC01MACR_OUTFILE.txt` | 4 x 80 | Output of the run: a copy of the input, same four lines |
| TB01TABL | TABFILE | `data/TB01TABL_TABFILE.txt` | 8 x 12 | Input, sorted ascending: ALPHA 0100, BRAVO 0200, CHARLIE 0300, DELTA 0400, ECHO 0500, MIKE 0600, SIERRA 0700, ZEBRA 0800 (key `CL8`, value `CL4`). The JCL builds it from inline data, so the dataset is temporary (`&&TABFILE`) |

BR09MTCH has no files in `data/` yet: its input and output files were not supplied (see Open Questions).

DS01DSCT has no files in `data/`: its two records are `DC` constants in the source, and it runs with the generic `jcl/ASMCLRUN.jcl`.

SB01CALL and SB02SUBR have no files in `data/`: the values are constants in the source.

ED01EDMK has no files in `data/`: its amounts are `DC` constants in the source, and it runs with the generic `jcl/ASMCLRUN.jcl`.

## Run JCL

Generic assemble, link and go is `jcl/ASMCLRUN.jcl`. A program that needs its own files has its own member, `jcl/<PROGRAM>.jcl`. Each has three steps: `ASMA90` (assemble), `HEWL` (link) and the program step, with `COND` on the earlier steps. Only `PGMNAME` and the program step DDs differ. The exception is `jcl/SB01CALL.jcl`, which has four steps because two programs are assembled and link-edited into one load module.

| Program | JCL | Program step DDs |
|---|---|---|
| QSAMPROC | `jcl/QSAMPROC.jcl` | `AMHFIN` `DISP=SHR`; `AMHFOUT` `NEW,CATLG,DELETE`, `FB`, `LRECL=559`; `SYSPRINT`, `SYSOUT`, `SYSUDUMP` to `SYSOUT=*` |
| BR09MTCH | `jcl/BR09MTCH.jcl` | Two inputs and three outputs |
| DS02BILD | `jcl/DS02BILD.jcl` | `PARTFILE` `NEW,CATLG,DELETE`, `FB`, `LRECL=40`; `SYSOUT`, `SYSPRINT`, `SYSUDUMP` to `SYSOUT=*`. Dataset names use the masked qualifiers `HLQ.MLQ` |
| DS02DSCT | `jcl/DS02DSCT.jcl` | `PARTFILE` `DISP=SHR` (the file DS02BILD created); `SYSOUT`, `SYSPRINT`, `SYSUDUMP` to `SYSOUT=*`. Output is on `SYSPRINT` |
| VB01BILD | `jcl/VB01BILD.jcl` | `OUTFILE` `NEW,CATLG,DELETE`, `SPACE=(TRK,(10,20),RLSE)`, `RECFM=VB`, `LRECL=37`, `BLKSIZE=0`; `SYSOUT`, `SYSPRINT`, `SYSUDUMP` to `SYSOUT=*`. Dataset names use the masked qualifiers `HLQ.MLQ`; job name masked as `MLQM` |
| VB01LOC | `jcl/VB01LOC.jcl` | `INFILE` is `HLQ.MLQ.VB01BILD.OUTFILE` `DISP=SHR`; `OUTFILE` is `HLQ.MLQ.VB01LOC.OUTFILE` `NEW,CATLG,DELETE`, `SPACE=(TRK,(10,20),RLSE)`, `RECFM=VB`, `LRECL=37`, `BLKSIZE=0`; `SYSOUT`, `SYSPRINT`, `SYSUDUMP` to `SYSOUT=*`. The screenshot of the submitted job showed an ACF2 comment line (`$ACFJ219 ACF2 ACTIVE`) added by the system; it is not in the member and not in the file. Masked as for VB01BILD (`HLQ.MLQ`, job name `MLQM`) |
| SB01CALL, SB02SUBR | `jcl/SB01CALL.jcl` | `STEP01` assembles SB01CALL (`&&OBJ1`), `STEP02` assembles SB02SUBR (`&&OBJ2`), `STEP03` link-edits both (`SYSLIN` concatenation) into `LOAD(SB01CALL)`, `STEP04` runs `SB01CALL`; `SYSOUT`, `SYSPRINT`, `SYSUDUMP` to `SYSOUT=*`. No `PGMNAME` symbol, member names are coded in each step. `SET SOURCE` and `SET LOAD` use the masked qualifiers `HLQ.MLQ`; job name masked as `MLQM`. Both `COND` lists test the earlier steps for return code 8 or more. No dataset is created or cataloged, so it can be rerun as is |
| MC01MACR | `jcl/MC01MACR.jcl` | `INFILE` is `HLQ.MLQ.BR08SRCH.OUTFILE` `DISP=SHR`; `OUTFILE` is `HLQ.MLQ.MC01MACR.OUTFILE` `NEW,CATLG,DELETE`, `SPACE=(TRK,(1,2),RLSE)`, `RECFM=FB`, `LRECL=80`, `BLKSIZE=0`; `STEPLIB`, `SYSOUT`, `SYSPRINT`, `SYSUDUMP`. Masked `HLQ.MLQ`; job name `MLQA`. The `SET` banner reads `SET PRORGAM NAME, SOURCE & LOAD LIBRARY`, kept as in the screenshot. In step 3 each DD has one blank after `DD` (operands in column 15), unlike steps 1 and 2 |
| TB01TABL | `jcl/TB01TABL.jcl` | Four steps: `STEP01` assembles (`ASMA90`), `STEP02` link-edits (`HEWL`), `STEP03` runs `IEBGENER` (`SYSIN DD DUMMY`, `SYSUT1 DD *` with the 8 records, `SYSUT2` `&&TABFILE`, `DISP=(NEW,PASS)`, `SPACE=(TRK,(1,1))`, `RECFM=FB`, `LRECL=12`, `BLKSIZE=0`), `STEP04` runs the program with `TABFILE` `DSN=&&TABFILE,DISP=(OLD,DELETE)`; `STEPLIB`, `SYSOUT`, `SYSPRINT`, `SYSUDUMP`. Masked `HLQ.MLQ`; job name `MLQM`. No dataset is cataloged, so it can be rerun as is. The `SET` banner reads `SET PRORGAM NAME`, kept as in the screenshot. The screenshots show the `STEP03` and `STEP04` DD statements with one blank after `DD`, except `TABFILE`, which has two |

`AMHFOUT` is cataloged on a normal end, so delete the dataset (`APXT.TAQ8656.AMH.OUTPUT`) before a rerun or the step fails on allocation. The same applies to `HLQ.MLQ.TEST.PARTFILE` of DS02BILD `HLQ.MLQ.VB01BILD.OUTFILE` of VB01BILD and `HLQ.MLQ.VB01LOC.OUTFILE` of VB01LOC. `HLQ.MLQ.MC01MACR.OUTFILE` of MC01MACR is cataloged the same way.

`jcl/DS02DSCT.jcl` has the same three steps as `jcl/DS02BILD.jcl`; only `PGMNAME` and the `PARTFILE` DD differ (`DISP=SHR`, nothing is created). Run DS02BILD first.

## Concept Articles

Each article starts with a Scope line that states what the programs exercise.

| Article | Topics | Programs | File |
|---|---|---|---|
| Program linkage and addressability | 01 | All programs, QSAMPROC, DT01TYPE, DT02ARTH | `docs/concepts/LINKAGE.md` |
| Data types and storage | 01 | DT01TYPE | `docs/concepts/DATA-TYPES.md` |
| Even-odd register pairs | 02, 03 | REGCALC, BR04BXLE, BR06NEST | `docs/concepts/REGISTER-PAIRS.md` |
| Condition code and branch masks | 03 | BR01CMP, BR02MASK, QSAMPROC | `docs/concepts/CONDITION-CODE.md` |
| Loop control | 03 | BR03LOOP, BR04BXLE, BR06NEST | `docs/concepts/LOOP-CONTROL.md` |
| Tables and indexed addressing | 03 | BR05TABL, BR08SRCH, QSAMPROC | `docs/concepts/TABLES.md` |
| Multi-way decisions | 03 | BR07CASE | `docs/concepts/MULTIWAY-DECISIONS.md` |
| Packed decimal arithmetic | 05 | DT02ARTH | `docs/concepts/PACKED-ARITHMETIC.md` |
| Data conversions and editing | 02, 05, 06 | REGCALC, DT02ARTH, DT03CONV | `docs/concepts/DATA-CONVERSIONS.md` |
| QSAM processing and control break | 07 | QSAMPROC | `docs/concepts/QSAM-CONTROL-BREAK.md` |
| DSECTs, `USING` and `DROP` | 08 | DS01DSCT, DS02DSCT, QSAMPROC, BR09MTCH, VB01BILD, VB01LOC | `docs/concepts/DSECTS.md` |
| Record layouts: `DS 0CLn`, `ORG` and REDEFINES | 08 | QSAMPROC, DS01DSCT, DS02BILD, DS02DSCT, VB01BILD, VB01LOC | `docs/concepts/RECORD-LAYOUTS.md` |
| Packed data validity, initialisation and test files | 05, 07 | DS02DSCT, DS02BILD, DS01DSCT, BR09MTCH, QSAMPROC, VB01BILD | `docs/concepts/PACKED-VALIDITY.md` |
| Internal subroutines with `BAL` | 04 (partial) | DS02DSCT, BR09MTCH, QSAMPROC, DT01TYPE, DT02ARTH, VB01LOC | `docs/concepts/SUBROUTINES.md` |
| Match-merge of two sorted files | 03, 07 | BR09MTCH | `docs/concepts/MATCH-MERGE.md` |
| Operand lengths: implied and explicit | 03, 07, 08 | DS01DSCT, DS02BILD, DS02DSCT, BR09MTCH, QSAMPROC, VB01BILD, VB01LOC | `docs/concepts/OPERAND-LENGTHS.md` |
| Locate-mode I/O (GL and PL) | 07, 08 | VB01LOC, VB01BILD | `docs/concepts/LOCATE-MODE.md` |
| Variable-length records and the RDW | 07, 08 | VB01BILD, VB01LOC | `docs/concepts/VARIABLE-RECORDS.md` |
| `EX`: operand length at run time | 07 | VB01LOC | `docs/concepts/EXECUTE.md` |
| Boundary cases and storage overruns | 03, 07, 08 | VB01LOC, DS01DSCT, VB01BILD, DS02DSCT | `docs/concepts/STORAGE-OVERRUNS.md` |

Topic 04 is In progress: `SUBROUTINES.md` covers the internal `BAL` routines, and SB01CALL / SB02SUBR add the first separate subprogram, a `CALL` macro and a hand-built `BALR` call (`LINK` is only in a comment). Existing articles still to update for the newer programs: `SUBROUTINES.md` and `LINKAGE.md` (external call, parameter list, return code in R15, SB01CALL and SB02SUBR) and `CONDITION-CODE.md` (new source programs). `DSECTS.md`, `RECORD-LAYOUTS.md`, `OPERAND-LENGTHS.md`, `PACKED-VALIDITY.md`, `SUBROUTINES.md` and `QSAM-CONTROL-BREAK.md` were updated for VB01BILD and VB01LOC. `DATA-CONVERSIONS.md` still has to be updated for `EDMK` (ED01EDMK). Topic 10 has its first program, MC01MACR; a `docs/concepts/MACROS.md` article (macro definition, parameters, `&SYSNDX`, `AIF`, sequence symbols, macro versus subroutine) is still to be written. `docs/concepts/TABLES.md` still has to be updated for TB01TABL (run-time table, `BXLE` over a loaded table, binary search).

## Register Conventions

| Register | Use |
|---|---|
| R0, R1 | Parameter and work registers; clobbered by system services |
| R12 | Base register (by convention in these programs) |
| R13 | Address of save area |
| R14 | Return address |
| R15 | Entry-point address on entry; return code on exit |

## 01 Basics (HELLO)

Concept articles: `docs/concepts/LINKAGE.md`, `docs/concepts/DATA-TYPES.md`, `docs/concepts/OPERAND-LENGTHS.md`.

- Entry linkage: `STM 14,12,12(13)`, `LR 12,15`, `USING name,12`, `ST 13,SAVEAREA+4`, `LA 13,SAVEAREA`.
- Exit linkage: `L 13,SAVEAREA+4`, `LM 14,12,12(13)`, `SR 15,15`, `BR 14`.
- QSAM output: `OPEN (dcb,(OUTPUT))`, `PUT dcb,area`, `CLOSE (dcb)`.
- `DCB DSORG=PS,MACRF=PM,DDNAME=SYSOUT,RECFM=FB,LRECL=80,BLKSIZE=0`; the DD name must exist in the JCL.
- `DC CL80'text'` pads to the record length with blanks.

### DT01TYPE: data types and their hex content

| Type | Example | Stored bytes | Notes |
|---|---|---|---|
| C | `CL10'ABC123'` | C1C2C3F1F2F3 40404040 | One byte per character; short values padded on the right with X'40' |
| X | `XL4'0001ABCD'` | 0001ABCD | Two hex digits per byte; short values padded on the left with zeros |
| B | `B'10110011'` | B3 | Written as bits, stored as whole bytes |
| F | `F'-1234'` | FFFFFB2E | 4 bytes, twos complement, fullword aligned |
| H | `H'-25'` | FFE7 | 2 bytes, halfword aligned |
| P | `PL4'-1234'` | 0001234D | Two digits per byte; sign in the low nibble of the last byte (C positive, D negative, F unsigned) |
| Z | `ZL6'-1234'` | F0F0F1F2F3D4 | One digit per byte; zone F except the last byte, whose zone carries the sign |
| A | `A(DT01TYPE)` | 00008000 | 4 byte address, fullword aligned |
| E | `E'1.5'` | 41180000 | Short floating point: sign and exponent byte, then fraction |

Notes:

- The type only decides how an instruction reads the bytes. `X'F1F2F3F4'` is `1234` as characters and -235736076 as a signed fullword.
- Positive zoned decimal with sign C prints its last digit as a letter (`ZL6'1234'` prints `00123D`); only sign F prints as a digit.
- `LTORG` places literals such as `=F'15'` in the pool.
- `BAL 11,routine` calls an internal routine and `BR 11` returns. Parameters are passed in registers (R2 address, R3 length, R10 output address in `HEXDISP`).
- Hex conversion of one byte: `IC` the byte, copy it, `SRL 6,4` for the high nibble, `N 5,=F'15'` for the low nibble, then `IC 7,HEXDIGIT(n)` and `STC` the character.
- `UNPK` into an 8 byte field keeps only 8 digits; a 9 digit number loses its leftmost digit and the sign.
- A `CL18` literal longer than 18 characters is cut to 18.

## 02 Registers and Arithmetic (REGCALC)

Concept articles: `docs/concepts/REGISTER-PAIRS.md`, `docs/concepts/DATA-CONVERSIONS.md`.

- `L` loads a fullword. `LA r,n` loads the value n (0 to 4095) with no storage reference.
- `AR` adds and `SR` subtracts, register to register.
- `MR even,reg`: the multiplicand is the odd register of the pair; the product fills the pair.
- `D even,storage`: the dividend is the even-odd pair; the quotient lands in the odd register and the remainder in the even register. Clear the even register first.
- Printing a binary number: `CVD` (binary to packed), `UNPK` (packed to zoned), `OI last-byte,X'F0'` (fix sign nibble), `MVC` into the output line.
- Clear the output line with `MVC OUT(80),BLANKS` before building each message.

## 03 Branching and Looping

Concept articles: `docs/concepts/CONDITION-CODE.md`, `docs/concepts/LOOP-CONTROL.md`, `docs/concepts/TABLES.md`, `docs/concepts/MULTIWAY-DECISIONS.md`, `docs/concepts/REGISTER-PAIRS.md`, `docs/concepts/MATCH-MERGE.md`.

### BR01CMP: compare instructions and conditional branches

Compare instructions set the condition code (CC). A branch instruction then tests the CC.

| CC | After compare | After LTR |
|---|---|---|
| 0 | Operands equal | Zero |
| 1 | First operand low | Negative |
| 2 | First operand high | Positive |
| 3 | Not used by compares | Not used |

Compare instructions used:

| Instruction | Compares | Arithmetic |
|---|---|---|
| `CR r1,r2` | Register to register | Signed |
| `C r,storage` | Register to fullword in storage | Signed |
| `CLC a(len),b` | Storage to storage, left to right, up to 256 bytes | Logical (unsigned, EBCDIC collating sequence) |
| `CLI storage,imm` | One storage byte to an immediate byte | Logical |
| `LTR r1,r2` | Loads r2 into r1 and sets CC from the value (zero, negative, positive) | Signed |

Extended branch mnemonics used, with the mask they assemble to (`BC mask,target`):

| Mnemonic | Branches when | Mask |
|---|---|---|
| `BE` / `BZ` | CC 0 (equal, zero) | 8 |
| `BL` / `BM` | CC 1 (low, negative) | 4 |
| `BH` / `BP` | CC 2 (high, positive) | 2 |
| `BNE` | CC not 0 | 7 |
| `BNH` | CC not 2 | 13 |
| `B` | Always | 15 |

Notes:

- The mask is 4 bits, one per CC value: 8 for CC0, 4 for CC1, 2 for CC2, 1 for CC3. A branch is taken when the bit for the current CC is on.
- If/else pattern: test, branch to the "else" label, run the "then" code, then `B` to a shared join label (`EXnPUT`) so the "else" code is skipped.
- Three-way pattern (Example 1): `BE`, `BL`, then an unconditional `B` for the remaining case.
- `CR` and `C` are signed, so -25 is less than 50. `CLC` and `CLI` are logical, so `SMITH` is higher than `JONES` because `S` (X'E2') is greater than `J` (X'D1') in EBCDIC.
- `LTR 5,5` tests a register without a second operand or a compare constant.
- The branch must come immediately after the instruction that sets the CC. Any instruction between them that changes the CC changes the result. `MVC` and `L` do not change it.
- Every message constant is `CL50`, so every `MVC OUTMSG(50),msg` uses the same length.
- Test data and results:

| Test | Values | Result |
|---|---|---|
| `CR` | NUMA 100, NUMB 50 | NUMA is high |
| `C` | NUMB 50, NUMC 50 | Equal |
| `CLC` | NAME1 `SMITH`, NAME2 `JONES` | NAME1 collates high |
| `CLI` | FLAG `Y` | Flag byte is Y |
| `LTR` | NUMD -25 | Negative |

### BR02MASK: branch masks

- Every extended mnemonic is `BC mask,target` (or `BCR mask,reg`). `BE`/`BZ` = 8, `BL`/`BM` = 4, `BH`/`BP` = 2, `BO` = 1, `BNE`/`BNZ` = 7, `BNL`/`BNM` = 11, `BNH`/`BNP` = 13, `BNO` = 14, `B` = 15, `NOP` = 0.
- Add mask bits to branch on several CC values: `BC 12` is 8 + 4, equal or low.
- `BNH` is `BC 13` and includes CC 3. After a compare CC 3 never occurs, so `BC 12` and `BNH` behave the same. After arithmetic CC 3 is overflow and they differ.
- Arithmetic sets the CC (0 zero, 1 negative, 2 positive, 3 overflow), so `AR` then `BZ` needs no compare.
- `BCR 15,14` is `BR 14`. If the register field of `BCR` is 0, it never branches.

### BR03LOOP: loop shapes

| Shape | Pattern | Runs at least once |
|---|---|---|
| Counted | `L r,count` ... `BCT r,top` | Yes |
| Top-tested (DO WHILE) | test and branch out at the top, `B top` at the bottom | No |
| Bottom-tested (DO UNTIL) | body, then test and branch back | Yes |

- `BCT r,label` subtracts 1 and branches if the result is not zero. It does not set the CC. A count of 0 on entry becomes -1 and runs about 4 billion times, so guard a count that may be zero with `LTR` and `BZ`.
- `BCTR r,0` subtracts 1 with no branch. `LA r,1(,r)` adds 1.
- `SRL r,1` halves a non-negative value and does not set the CC. Follow it with `LTR` before a conditional branch.
- `LABEL DS 0H` defines a label with no storage, used as a loop exit target.

### BR04BXLE: index loops

- `BXLE r1,r3,target`: r1 is the index, r3 the increment, r3+1 the limit. The index is incremented first and then compared. `BXLE` branches while index <= limit, `BXH` while index > limit. Neither changes the CC.
- r3 must be the even register of a pair, so the limit is the next odd register.
- Table walk: increment = entry length, limit = address of the last entry (not one past it).
- Countdown: increment -1 with `BXH` and limit 0 gives 5, 4, 3, 2, 1.
- `LM 8,9,INCLIM` loads increment and limit from two adjacent fullwords.
- The test is at the bottom, so the body runs at least once.

### BR05TABL: indexed tables

- `LA 4,TABLE(5)` builds the address of `TABLE` plus the index in R5 without reading storage.
- SS instructions (`MVC`, `CLC`) have no index field, so use the computed address in a base register: `MVC OUTMSG+2(8),0(4)`.
- Step the index with `LA 5,ENTLEN(,5)`. Name the entry length with `EQU`. `TABLE DS 0F` aligns the fullword values.
- `L 3,8(,4)` reads a field at a fixed displacement inside an entry.
- Keep the entry count (`ENTRIES`) beside the table and change it when entries change.

### BR06NEST: nested loops

- One counter register per loop level. Reload the inner counter, the column number and the output pointer inside the outer loop.
- If the inner counter is loaded before the outer label, the second pass starts with 0, `BCT` makes it -1, and the loop runs about 4 billion times.
- `MR 8,5`: multiplicand in the odd register (R9), product in R8:R9. `MR` replaces R8, so clearing it first is not required.
- `MVC 0(8,11),ZONE` is the explicit `D(L,B)` form. Advance the pointer R11 with `LA 11,10(,11)`.
- Write the record (`PUT`) after the inner loop, once per row.

### BR07CASE: multi-way decisions

- Ladder: `CLI x,C'A'` with `BE` for each case, an ELSE path after the last test, and a join label. Compares grow with the number of cases.
- Branch table: range check first (`C` with `BL` and `BH` to the default), then `BCTR 3,0` (zero based), `SLL 3,2` (times 4), `B BRTAB(3)`. Each slot is one 4-byte `B` instruction.
- A computed branch with a bad index jumps to arbitrary storage. Always check the range.
- Keep the original code if it is needed later, because R3 becomes the offset.
- `=F'1'` literals go into the literal pool. `LTORG` places the pool within reach of the base register.

### BR08SRCH: serial search

- Found / not-found: `CLC key,entry`, `BE FOUND` leaves the loop early, `BCT` falling through means no match.
- `CLC` and `MVC` take a base register and displacement, not an index. Keep a pointer in a register (R7) and step it with `LA 7,ENTLEN(,7)`.
- The pointer is still valid at `FOUND`, so `L 3,8(,7)` reads the value from the matching entry.
- After a failed search the pointer is past the last entry and must not be used.
- Copy the search argument to a work key (`MVC SRCHKEY(8),0(10)`) so the compare has a fixed first operand.
- Output columns: key at `OUTMSG(8)`, message at `OUTMSG+10(40)`, value at `OUTMSG+50(8)`.

### BR09MTCH: match-merge of two sorted files

Also listed under 07 File I/O and 08 DSECTs. The file handling is in the 07 section below.

- Decision on two current keys: `CLC KEY1,KEY2`, then `BE MATCHED`, `BL FLUSH1`, `B FLUSH2`. Equal writes the key once to `OUTCOMM` and reads both files; low writes file 1's key to `OUT1ONLY` and reads file 1; high does the same for file 2.
- Check the EOF switches before the `CLC` (`CLI EOF1,C'Y'`, `CLI EOF2,C'Y'`). When one file has ended, the other is drained through `FLUSH1` or `FLUSH2`. `CHECK2` ends the loop only when both switches are `Y`.
- Read only the file whose record was dealt with. After `FLUSH1` the record in `KEY2` is still unprocessed.
- `HIVALUE DC 10X'FF'` in the key at end of file compares higher than any printable key. Here it is only a safety net, because the EOF switches are tested first.
- Every path loops back with `B MAINLOOP`; the program ends only at `ALLDONE`.
- Both files must be sorted ascending on the key. Repeated keys inside one file are not paired: the first occurrence matches, the repeat ends in an "only" file.
- Run result: 5 records read from each file, 4 file-1-only, 4 file-2-only, 1 common (4 + 1 = 5 per file).

### Patterns used in every program

- Output line: `MVC OUTMSG(80),BLANKS`, `MVC OUTMSG(50),msg`, then `CVD`, `UNPK ZONE,DOUBLE`, `OI ZONE+7,X'F0'`, `MVC OUTMSG+50(8),ZONE`, `PUT`.
- A count-controlled `BCT` loop with a count that may be 0 needs a guard.
- Comments start at column 40 and the line ends at column 71.

## 04 Subroutines

DS02DSCT already uses two call levels and a parameter list in R1; see its notes under 08 DSECTs. Level 1 calls use `BAL 10` / `BR 10`, the call from inside a level 1 routine uses `BAL 9` / `BR 9`.

Concept article: `docs/concepts/SUBROUTINES.md` (internal `BAL` routines; not yet updated for SB01CALL and SB02SUBR).

### SB01CALL and SB02SUBR: a separate subprogram with standard linkage

Source: `src/SB01CALL.asm` (main) and `src/SB02SUBR.asm` (called). Run with `jcl/SB01CALL.jcl`. Not assembled or run by Claude; the results are from the owner's run (job J0065847).

| Register | On entry to the called program |
|---|---|
| R1 | Parameter list: fullword addresses, high-order bit on the last one |
| R13 | Save area provided by the caller |
| R14 | Return address |
| R15 | Entry address; on return, the return value |

- A call needs R1 (parameter list), R15 (entry address) and a branch that sets R14: `LA 1,PARMLST1`, `L 15,=V(SB02SUBR)`, `BALR 14,15`. The `CALL` macro generates the same kind of sequence from `CALL SB02SUBR,(TOTAL,AMOUNT)`.
- `=V(name)` is an external reference, resolved by the linkage editor. Both object decks must be in `SYSLIN` (`&&OBJ1` then `&&OBJ2`); the load module is named after the main program.
- `LINK EP=name,PARAM=(...)` is a supervisor call that loads the program at run time. It is only in a comment in SB01CALL and has not been run.
- The parameter list: `DC A(TOTAL)` and `DC X'80',AL3(AMOUNT)`. `AL3` is a 3-byte address; `X'80'` before it sets bit 0 of the word. The `CALL` macro sets that bit only with the `VL` operand, which is not coded here, so the comments in SB01CALL are wrong on that point. SB02SUBR clears the bit with `N 3,=X'7FFFFFFF'` and never tests it.
- The called program saves the caller's registers in the caller's save area (`STM 14,12,12(13)`), chains a private save area both ways (`ST 13,SUBSAVE+4`, `LA 14,SUBSAVE`, `ST 14,8(,13)`, `LR 13,14`) and restores through the backward chain (`L 13,SUBSAVE+4`, `LM 14,12,12(13)`).
- `LM 14,12,12(13)` also reloads R15 and R12. A return code must be in R15 after the `LM`, and anything addressed through R12 after the `LM` is addressed from the caller's base.
- `SHOWRC` saves R15 with `ST 15,SAVERC` before `PUT`, because `PUT` changes R15.
- `SB02SUBR` keeps `SUBSAVE` and `RETCODE` in the CSECT, so it is not reentrant.
- Result of the run: totals 150, 650 and 99350 (the third is -99350 shown without its sign, because `OI ZONE+7,X'F0'` removes it), and `RETURN CODE` 33280 (X'00008200') on every line. Expected 0, 0, 4. Cause, inferred from the source and the SYSOUT: `IC 15,RETCODE` after the `LM` is addressed through R12, which `LM` has just set to SB01CALL's base, so the byte read is not `RETCODE`; `IC` changes only the low byte, so the upper three bytes are the entry address restored by `LM`. Untested fix: set the return code before the `LM` (`SR 15,15`, `IC 15,RETCODE`, `L 13,SUBSAVE+4`, `ST 15,16(,13)`, `LM 14,12,12(13)`).
- Source lines 1-29 of SB01CALL were not supplied; the source file holds a placeholder block for them.

## 05 Packed Decimal (DT02ARTH, DT03CONV)

Concept articles: `docs/concepts/PACKED-ARITHMETIC.md`, `docs/concepts/DATA-CONVERSIONS.md`, `docs/concepts/PACKED-VALIDITY.md`.

### DT02ARTH: packed decimal arithmetic

Decimal instructions are SS format and work in storage. They need no general registers for the arithmetic. Operand lengths are coded as `field(length)`.

| Instruction | Operation | Notes |
|---|---|---|
| `ZAP op1,op2` | Zero and add: op1 = op2 | Safe copy or move; clears op1 first, so lengths may differ and the sign is valid |
| `AP op1,op2` | op1 = op1 + op2 | Signed; operand 1 must hold the result or a decimal overflow occurs |
| `SP op1,op2` | op1 = op1 - op2 | `SP x,x` clears a field |
| `CP op1,op2` | Compare, sets CC | 0 equal, 1 first low, 2 first high; `CP field,=P'0'` tests the sign |
| `MP op1,op2` | op1 = op1 * op2 | Op2 at most 8 bytes; L1 greater than L2; high-order L2 bytes of op1 must be zero |
| `DP op1,op2` | op1 = quotient and remainder | Quotient in the first L1-L2 bytes, remainder in the last L2 bytes, sign of the dividend |
| `SRP op1,n,round` | Shift and round | Positive n shifts left; right shift of N is coded 64-N; rounding digit is added to the last digit shifted out (5 rounds half up, 0 truncates); ignored on a left shift |

Notes:

- Use `ZAP`, not `MVC`, to move packed data. `MVC` copies bytes only. `MVC WORKP(4),PACKA` into a zeroed `PL8` leaves the sign nibble in the middle: X'0012345C0000000C'.
- `MVC` is safe for a whole field of equal length (`MVC SAMELEN(4),PACKA`).
- `ZAP` into an 8-byte field before `MP` provides the leading zero bytes `MP` needs.
- `DP DIVD(8),PACKB(4)`: quotient `DIVD(4)`, remainder `DIVD+4(4)`. A quotient too large for L1-L2 bytes causes a decimal divide exception.
- `SRP` right 2 on 12345 gives 123 with rounding 5 and with 0, because the last digit shifted out is 4.
- Signed display: `CP` against `=P'0'` and `MVI` for the sign character, then `UNPK ZONE15(15),WORKP(8)`, `OI ZONE15+14,X'F0'`, `MVC 1(15,10),ZONE15` (16 characters).
- Test values: `PACKA` `PL4'12345'` X'0012345C', `PACKB` `PL4'678'` X'0000678C', `PACKC` `PL3'-250'` X'00250D'.
- Results: 12345 + 678 = 13023; 12345 + (-250) = 12095; 678 - 12345 = -11667; 12345 * 678 = 8369910; 12345 / 678 = 18 remainder 141.
- Internal routines `PKDISP` and `HEXDISP` are called with `BAL 11` and return with `BR 11`; neither can call the other because R11 would be overwritten.

### DT03CONV: data conversions

Conversion chain: character or zoned, `PACK`, packed, `CVB`, binary in a register, `CVD`, packed, `UNPK`, zoned, `OI` or `MVZ`, printable character. `ED` turns packed into a formatted character field.

| Instruction | Conversion | Notes |
|---|---|---|
| `PACK op1,op2` | Zoned or character to packed | Digit nibble of each byte is kept; the zone of the last byte becomes the sign. No validity check |
| `CVB r,dword` | Packed to binary | Source must be a doubleword, valid digits and sign; value must fit in 31 bits |
| `CVD r,dword` | Binary to packed | Target must be a doubleword |
| `UNPK op1,op2` | Packed to zoned | Zone F on every digit except the last byte, whose zone is the sign |
| `OI field,X'F0'` | Force zone F | Makes the last digit printable; the sign is lost |
| `MVZ op1,op2` | Move zone nibbles | Copies only the high nibble of each byte; can move zones between any bytes |
| `ED op1,op2` | Packed to edited character | Pattern in operand 1 is overwritten by the digits |

Notes:

- `PACK` does not check its input. Leading blanks (X'40') pack as zero digits and are harmless. Trailing blanks pack as zero digits, scale the value by a power of ten and leave an invalid sign (4): `CL8'1234    '` gives X'0000000123400004'.
- `PACK` does not understand a trailing minus. Pack only the digits (`PACK DOUBLE(8),CHARSGN(7)`), test the last character with `CLI`, then `NI DOUBLE+7,X'F0'` and `OI DOUBLE+7,X'0D'` set the sign to D.
- `PACK` target length is explicit and the target is zero filled on the left. 8 digit characters fit an 8 byte target as X'000000000012345F'.
- `CVB` and `CVD` need a doubleword-aligned target (`DS D`). `BINDISP` uses a second doubleword (`DBLDISP`) so the packed result in `DOUBLE` is not changed.
- A negative zoned value prints a letter in the last position: `-1234` shows as `00123M` because X'D4' is the letter M. Positive with sign F prints as a digit.
- Save the sign before `OI` or `MVZ` if it matters: `CP PACKWK(5),=P'0'`, then `MVI SIGNCHR,C'-'` or `C'+'`.
- `BINDISP` prints 9 digits from a register: `CVD 3,DBLDISP`, `UNPK ZONE9(9),DBLDISP+3(5)` (the low 5 bytes hold 9 digits), `OI ZONE9+8,X'F0'`, `MVC 0(9,10),ZONE9`. The sign and any digits beyond 9 are lost.
- `HEXDISP` changes R2, R3 and R10. Reload them for every call. It does not use R4.
- Test values and results: `00012345` packs to X'000000000012345F'; `CVB` gives X'00003039' (12345); `A 4,=F'55'` gives 12400; `CVD` gives X'000000000012400C'.

## 06 Editing (ED/EDMK)

Concept article: `docs/concepts/DATA-CONVERSIONS.md`.

### DT03CONV: ED basics

| Pattern byte | Meaning |
|---|---|
| X'40' | Fill character (blank); first byte of the pattern |
| X'20' | Digit selector: replaced by a digit, or the fill while leading zeros are suppressed |
| X'21' | Significance starter: selects a digit and turns zero suppression off for the digits that follow |
| X'4B' | Period, printed as is |
| X'60' | Trailing minus: printed when the value is negative, replaced by the fill when positive |

- Load the pattern into a work area first (`MVC EDWORK(9),EDMASK1`), then `ED EDWORK(9),PACKWK`. `ED` destroys the pattern, so reload it before every use.
- `EDMASK1` X'402020202020202060': 7 digit selectors then a trailing minus. 12345 gives `   12345 `, -12345 gives `   12345-`.
- `EDMASK2` X'4020202020214B202060': 123.45 style. 12345 gives `   123.45 `. The value 7 gives `      .07 `, not `0.07`. The digit selected by X'21' (the one before the period) is zero and is still replaced by the fill; zero suppression is off only for the digits after it.
- To print a leading `0.07` the significance starter must be one digit position earlier in the pattern.
- The packed source must be a valid packed field; `ED` reads the digits two per byte.
### ED01EDMK: EDMK and a floating currency sign

- `EDMK` is `ED` plus one effect: the first time a digit selector becomes significant, R1 receives the address of that pattern byte. Before that R1 is not touched.
- Floating `$`: `EDMK pattern,source`, `BCTR 1,0` (R1 minus 1, the byte before the first digit), `MVI 0(1),C'$'`. `BCTR` with register 0 as second operand never branches.
- `ED` and `EDMK` have one length, that of operand 1. The source is consumed digit by digit; `EDMK PATTERN,0(7)` takes length 11 from `PATTERN`.
- The pattern is overwritten, so copy the master to a work area before every edit (`MVC PATTERN,PATMAST`). The work area decides how many bytes are copied: a master longer than the work area loses its last bytes.
- A pattern for a `PL5` (9 digits): fill byte, nine selectors, last one `X'21'`, so an amount of 0 still prints one digit and sets R1. In ED01EDMK `PATMAST` is read as 12 bytes (fill, ten `X'20'`, `X'21'`) and `PATTERN` is `CL11`; the `X'21'` is not copied, no digit becomes significant for 0, R1 is not set, and `BCTR`/`MVI` store a `$` one byte before the old R1 value, outside the output line.
- Digits d1 to d9 go to pattern bytes 2 to 10. First significant digit and `$` position, loop 1: 7 gives `$` at byte 9, 450 at byte 7, 1234567 at byte 3.
- A comma is a message insertion byte: it prints when a digit to its left was significant and is replaced by the fill when not. In `PATMAST2` it follows six selectors, so 999 loses it and the `$` takes its slot (`       $999`).
- One comma three digits from the right gives `$1234,567` for 1,234,567, not `$1,234,567`.
- `MVC OUTMSG(12),PATTERN` copies 12 bytes from an 11-byte field; byte 12 is the first byte of `AMTTAB` (`X'00'`, shown as a blank). Loop 2 copies 11.
- `UNPK ZONESHOW,0(5,7)` with `ZONESHOW` `CL10` gives 10 digit characters for a `PL5`; `OI ZONESHOW+9,X'F0'` fixes the last one.
- Result: `$7`, `$450`, `$1234567` for loop 1 (the amount 0 prints nothing), `$1234,567`, `$999`, `$1000,000` for loop 2.

## 07 File I/O (QSAMPROC, BR09MTCH, DS02BILD, DS02DSCT, VB01BILD, VB01LOC)

Concept articles: `docs/concepts/QSAM-CONTROL-BREAK.md`, `docs/concepts/LINKAGE.md`, `docs/concepts/MATCH-MERGE.md`, `docs/concepts/SUBROUTINES.md`, `docs/concepts/PACKED-VALIDITY.md`, `docs/concepts/LOCATE-MODE.md`, `docs/concepts/VARIABLE-RECORDS.md`, `docs/concepts/EXECUTE.md`.

### QSAMPROC: QSAM control break

QSAM calls and DCB operands:

| Item | Use |
|---|---|
| `OPEN (dcb,(INPUT))` / `(dcb,(OUTPUT))` | Opens a file; sets no return code to test |
| `GET dcb,area` | Move mode (`MACRF=GM`): copies the next record to `area` |
| `PUT dcb,area` | Move mode (`MACRF=PM`): copies `area` to the buffer |
| `CLOSE (dcb)` | Flushes the last output buffer; skipping it can lose records |
| `EODAD=label` | Control goes to `label` instead of returning from `GET` at end of file |
| `SYNAD=label` | Control goes to `label` on a genuine I/O error |
| `LRECL=559,RECFM=FB,BLKSIZE=0` | Fixed 559-byte records, block size chosen by the system |

Notes:

- At EODAD, R2 to R13 are preserved by QSAM, so the base register and the return register of the caller of `READINP` are intact and `BR 9` works there.
- Open order: SYSPRINT first, because every error path writes to it. Close order: SYSPRINT last, because the counts are printed after the data files close.
- `PUT` to a file that is not open (or closed) branches through a DCB with no write routine: S0C1.
- Control break on a sorted file: priming read, outer loop per group, inner loop that exits on end of file, customer change or connect id change. On exit the input area already holds the first record of the next group.
- Reset group flags and the work areas once per group (`INITGRP`). Flags are only ever switched on inside the record loop.
- A top-tested outer loop produces no output for an empty input.
- Write the header line just before the first detail record, not at `OPEN`, so an empty input gives an empty output.
- Output record built from named `DS` fields (`OUTNAME`, `OUTID`, ..., `OUTC1` to `OUTC17` for the separators), so a field is referred to by name rather than by offset.
- `DC` of type C is limited to 256 bytes; use several `DC` statements or `DS`. `DC` of types Z and P is limited to 16 bytes.
- Clearing 559 bytes: `MVC a(256),BLANK256`, `MVC a+256(256),BLANK256`, `MVC a+512(47),BLANK256`.
- Prefix table search: `LA 2,PFXTAB`, `L 3,PFXCNT`, `CLC INACCTID(4),0(2)`, `BE found`, `LA 2,4(,2)`, `BCT 3,loop`.
- `=CL3'FT'` compares 3 bytes with `FT` and a blank. `=C'FT'` compares 2 bytes and also matches `FTX`.
- Message printing: `LA 1,msg`, `BAL 7,PRTMSG`. `PRTMSG` does `MVC PRTLINE(50),0(1)` and `PUT`. All messages are `CL50`.
- Counters: `PL5`, `ZAP =P'0'`, `AP =P'1'`, `UNPK ZONE9(9),CNT(5)`, `OI ZONE9+8,X'F0'`.
- Linkage registers by calling level: R10 level 1, R9 level 2, R8 level 3, R7 `PRTMSG`. A routine must not use the register that holds its own return address for a further call.
- The three DCBs (AMHFIN, AMHFOUT, SYSPRINT) are at the end of the program, followed by `LTORG` and then `DCBD`. A DCB continuation line carries `X` in column 72.
- Test run with `data/QSAMPROC_AMHFIN.txt`: 6 records read, 3 written. SYSPRINT shows `RECORDS R000000006` and `RECORDS W000000003`. The `R` and `W` come from the count being placed one byte inside the label text.
- Run JCL is `jcl/QSAMPROC.jcl`: assemble (`ASMA90`), link (`HEWL`), run. `AMHFIN` is `DISP=SHR`; `AMHFOUT` is `NEW,CATLG,DELETE` with `RECFM=FB,LRECL=559`, so delete the output dataset before a rerun.
- The test file only covers rule R1, so every group is `SYSTEM ADMINISTRATOR`. Records for R2, R3, `REGULAR USER` and `READ ONLY USER` are still to be added.

### DS02BILD: building a file with packed data

- Output file with `OPEN (PARTFILE,(OUTPUT))`, `PUT PARTFILE,OUTREC` (move mode, `MACRF=PM`), `CLOSE (PARTFILE)`. The DCB has `RECFM=FB,LRECL=40,BLKSIZE=0`; the JCL DD repeats `FB`, `LRECL=40`, `BLKSIZE=0` and uses `NEW,CATLG,DELETE`.
- A file with packed fields cannot be typed in an editor, so a program builds it: `MVC OUTREC,BLANKS40`, `MVC` for the character fields, `ZAP OUTAMT,=P'n'` for the packed field, `PUT`. `ZAP` from a packed literal stores the sign nibble `C`.
- Browse shows packed bytes as characters: X'5C' is `*`, X'50' is `&`, X'99' is `r`, X'9C' is `æ`, the rest `.`. `HEX ON` shows the real bytes.
- The result is checked in ISPF Browse, so `output/DS02BILD_SYSOUT.svg` is a Browse screen and not an SDSF screen. DS02DSCT reads the file.

### DS02DSCT: reading PARTFILE

- Input DCB `PARTFILE DCB DSORG=PS,MACRF=GM,DDNAME=PARTFILE,EODAD=EOFRTN,RECFM=FB,LRECL=40,BLKSIZE=0`. `GET PARTFILE,INAREA` in move mode copies each record into the 40-byte buffer `INAREA`.
- Priming read before the loop, read again at the bottom of each pass, loop ends on `EOFSW` = `Y`. `EOFRTN` sets the switch and returns with `BR 10` (R10 was set by `BAL 10,READREC`).
- Output goes to `SYSPRINT`. Amounts are shown with `UNPK ZONE7,PARTAMT` and `OI ZONE7+6,X'F0'` (7 digits); the total uses `UNPK ZONE11,GRANDTOT` and `OI ZONE11+10,X'F0'` (11 digits).
- The file must be the one DS02BILD built: packed `PARTAMT` at displacement 30. A text-edited copy loses the sign nibbles and `AP` abends with S0C7.
- Result with the DS02BILD data: 5 detail lines and `RUNNING TOTAL - 00000127943` (12345 + 500 + 99999 + 0 + 15099).

### BR09MTCH: two inputs, three outputs

- Five data DCBs plus `SYSPRINT`: `INFILE1` and `INFILE2` (`MACRF=GM`, `EODAD=EOF1RTN` / `EOF2RTN`, `LRECL=10`), `OUT1ONLY`, `OUT2ONLY`, `OUTCOMM` (`MACRF=PM`, `LRECL=10`). Each DCB continuation line carries `X` in column 72.
- Open order: `SYSPRINT` first and checked, then the five data files, each with `LA 2,dcb`, `BAL 10,OPENCHK`, `BNO OPNERRn`. Each `OPNERRn` loads its own `CL50` message and joins `OPNERRX`, which prints it and branches to `ABENDRTN`.
- Close: `CLOSE (INFILE1,,INFILE2,,OUT1ONLY,,OUT2ONLY,,OUTCOMM)` in one macro, then the counts and the end message, then `CLOSE (SYSPRINT)` last.
- `READ1` / `READ2`: `MVC KEY,BLANKS10`, `GET dcb,KEY`, `AP CNT,=P'1'`, `BR 10`. The EODAD routine sets the EOF switch to `Y`, moves `HIVALUE` into the key and does `BR 10`. This works because QSAM preserves R2 to R13 (R10 and R12 intact).
- `GET` in move mode reads straight into the 10-byte key field, because the record is only the key.
- `ABEND 999,DUMP` ends the step with user completion code 999 and requests a dump. It is reached only from open failures.
- Counters `PL4` with `ZONE CL7`: `UNPK ZONE,CNT`, `OI ZONE+6,X'F0'`, `MVC PRTLINE+21(7),ZONE`. Labels are `CL20`, so the number is always at column 22. A count over 9999999 loses its leftmost digit.
- Data layout: all data, constants, DCBs and `LTORG` come after the last `BR`, then `DCBD`, then `END`.

### VB01BILD: variable length records in locate mode

- DCB `OUTFILE DCB DSORG=PS,MACRF=PL,DDNAME=OUTFILE,RECFM=VB,LRECL=37,BLKSIZE=0`. `MACRF=PL` is put in locate mode. For `RECFM=VB`, `LRECL` is the longest record including its 4-byte RDW: 17 fixed bytes plus a 20-byte name = 37.
- Locate mode: `PUT OUTFILE` has no area operand. QSAM returns the address of an empty buffer in R1. `LR 4,1` saves it at once; the next system macro changes R1.
- The record is the RDW (`OUTRDWLL` H, the length of the whole record including the RDW; `OUTRDWFL` H, flags set to zero with `XC`), `OUTCUSTNO` CL8, `OUTAMOUNT` PL5 and the name. Fixed part 17 bytes, so RDW length = name length + 17: 29, 22, 37, 17, 27 for names of 12, 5, 20, 0 and 10 bytes.
- Fields are filled with `MVC OUTRDWLL,=H'n'`, `MVC OUTCUSTNO,=CL8'P10000n'`, `ZAP OUTAMOUNT,=P'n'` and `MVC OUTNAME(len),=CLlen'name'`. The `MVC` length is explicit because the builder knows each name length at assembly time; a reader that learns the length from the RDW at run time needs `EX`.
- A machine `MVC` moves at least one byte. For the empty name (record 4) there is no `MVC`; only the RDW length 17 says the name is absent.
- `PUT` does not clear the buffer. Every byte inside the record length is set by the program.
- A record is complete at the next `PUT` or at `CLOSE`: the fifth record is written by `CLOSE (OUTFILE)`.
- The file is checked in ISPF Browse (`output/VB01BILD_SYSOUT.svg`, name masked `HLQ.MLQ.VB01BILD.OUTFILE`). Browse does not show the RDW, so the longest line is 33 characters (`Col 001 033`), and the packed bytes show as characters (`*`, `&`, `r`, `æ`, `.`). `HEX ON` shows the RDW and the packed bytes.
- Result: 5 records, `P100001` to `P100005`, amounts 12345, 500, 99999, 0 and 15099.

### VB01LOC: reading variable length records in locate mode, and EX

- Input DCB `INFILE DCB DSORG=PS,MACRF=GL,DDNAME=INFILE,EODAD=EOFRTN,RECFM=VB,LRECL=37,BLKSIZE=0`. `MACRF=GL` is get in locate mode: `GET INFILE` has no area operand and R1 returns the address of the record, RDW included. Save it at once (`LR 3,1`).
- The record length is read from the RDW (`LH 5,INRDWLL`). Name length = RDW length - 17 (`S 5,=F'17'`), because the RDW, `INCUSTNO` and `INAMOUNT` take 17 bytes.
- `EX reg,target` takes the SS instruction at `target`, replaces its length byte with the low byte of `reg`, and runs that one instruction. The target is coded with length 1, which assembles to a length byte of zero, so the register value is the length used. The register must hold the length minus 1: `BCTR 5,0`.
- `MVCSHOWN MVC PRTLINE+20(1),INNAME` and `MVCBUILD MVC OUTNAME(1),INNAME` are the two targets. The stored instructions are not changed.
- End of file: `EODAD=EOFRTN` names the routine `GET` branches to; it sets `EOFSW` to `Y`, and `MAINLOOP` tests it with `CLI`. R3 keeps the last record address after the `EODAD` branch.
- Output in locate mode: `PUT OUTFILE`, `LR 4,1`, `USING VBOUTRECD,4`; the RDW length is `NAMELEN` + 17 stored with `STH`, the flag halfword is zeroed with `XC`, the amount is copied with `ZAP`. The record is written by the next `PUT` or by `CLOSE`.
- An empty name is the failure case. `NAMELEN` is 0, `BCTR` gives -1, the low byte is X'FF', and `EX` moves 256 bytes. In `SHOWREC` the source is the start of the next record (RDW, `P100005`, amount, name), shown at column 25 of line 5 of the output; the destination is `PRTLINE+20`, 196 bytes past the end of `PRTLINE` (80 bytes). By the data layout the move covers `ZONE7`, `BLANKS`, `MSGSTRT` and `MSGEND`; the end message is not printed (a blank line appears instead). Check the length before `EX`: zero must skip the move.
- Output of the run (`output/VB01LOC_SYSOUT.svg`): the start message, 5 detail lines (line 5 wrong), a blank line where the end message should be, and `RECORDS READ  : 0000005`.

## 08 DSECTs

Concept articles: `docs/concepts/DSECTS.md`, `docs/concepts/RECORD-LAYOUTS.md`, `docs/concepts/OPERAND-LENGTHS.md`, `docs/concepts/LOCATE-MODE.md`, `docs/concepts/VARIABLE-RECORDS.md`, `docs/concepts/EXECUTE.md`, `docs/concepts/STORAGE-OVERRUNS.md`.

### QSAMPROC: DCB open check

- `DCBD DSORG=PS,DEVD=DA` at the end of the program generates the `IHADCB` DSECT (a map, no storage).
- `DCBD` must be the last statement before `END`: a DSECT ends the current control section, so no real storage can be defined after it. `LTORG` goes before it.
- `LA 2,dcb`, `USING IHADCB,2`, `TM DCBOFLGS,DCBOFOPN`, `DROP 2`, `BNO error`. `TM` tests only the bits that are ones in the mask; `BNO` branches when the tested bit is off.
- A DSECT defined in the program itself, `USING` and `DROP` on it, and `ORG` are in DS01DSCT below. A DSECT over a record read with `GET` and a DSECT for a parameter block passed in R1 are in DS02DSCT below.

### BR09MTCH: DCB open check as a routine

- The same check is now an internal routine `OPENCHK` that takes the DCB address in R2 and returns with `BR 10`. The condition code from `TM` is the result, so the caller does `BAL 10,OPENCHK` and then `BNO OPNERRn` for the file it just opened.
- Between `BAL` and `BNO` nothing may change the condition code; `DROP` and `BR` do not.
- One routine serves all six DCBs because `USING IHADCB,2` maps the dummy section over whichever DCB R2 points at.
- `DCBD DSORG=PS,DEVD=DA` follows `LTORG` and is the last statement before `END`.

### DS01DSCT: a DSECT of our own, USING, DROP and ORG

- A DSECT is a map of names and displacements. It has no storage and no object code; `CUSTD DSECT` ends the CSECT, and assembling it alone gives zero bytes.
- To use it, point a register at real storage and issue `USING`: `LA 3,CUSTREC`, `USING CUSTD,3`. Each name then assembles as register plus displacement: `CUSTNO` is `0(3)`, `CUSTNAME` is `8(3)`, `CUSTBAL` is `28(3)`. `USING` generates no instruction, so `LA` must run before the first use.
- `DROP 3` ends the mapping. `LA 3,CUSTREC2` and `USING CUSTD,3` map the same layout over another record; the names do not change.
- An operand with no length takes it from the `DS`: `UNPK ZONE,CUSTBAL` uses 5 from `PL5`.
- `ORG CUSTBAL` inside the DSECT sets the location counter back to displacement 28, so `CUSTBALC DS CL5` names the same 5 bytes as characters. This is the REDEFINES equivalent. No data is copied; the name used decides how the bytes are read.
- Record length is the sum of the fields: 8 + 20 + 5 = 33. The source comments say 30.
- The DSECT follows `LTORG` and is the last item before `END`, as with `DCBD`.
- A `=C'...'` literal is as long as its text. `MVC OUTMSG(10),=C'CUST NO: '` copies 10 bytes from a 9-byte literal; the tenth byte is the first byte of the next literal in the pool (the pool is in order of first use). The run shows `N`, `B`, `B` and `Ø` in column 10. Use `=CL10'CUST NO:'` or length 9.
- `UNPK ZONE,CUSTBAL` with a 5-byte `ZONE` uses the low 3 bytes of the packed field and shows 5 digits (`12345`). X'000012345C' read as characters shows only `*` (X'5C').
- Output: `CUST NO: N10023456`, `NAME:    BJOHN SMITH`, `CUST NO: N99887766`, `NAME:    BJANE DOE`, `BAL HEX: B12345`, `BAL RAW: Ø    *`. The `BAL HEX:` label is misleading: the line shows decimal digits, not hex.

### DS02BILD: ORG to place a field in a record area

- `OUTREC DS 0CL40` defines the record with length 40 and reserves no bytes. `ORG OUTREC+30` moves the location counter to displacement 30, `OUTAMT DS PL5` is defined there (column 31), and `ORG OUTREC+40` moves the counter to the end of the record.
- This is the same layout as `PARTD` in DS02DSCT, made with `ORG` in a CSECT instead of a DSECT. The two displacements must match; nothing checks it.
- Without the final `ORG` the counter stops at `OUTREC+35` and the DCB that follows is assembled over the end of the record area.
- `MVC OUTREC,BLANKS40` takes length 40 from the `0CL40` label.
- The comment on `ORG OUTREC+40` says "Step back", but the `ORG` moves forward (30 to 40).

### DS02DSCT: a DSECT over a read buffer, and a parameter list DSECT

- `PARTD DSECT` (`PARTNO` CL8 +0, filler CL2, `PARTDESC` CL20 +10, `PARTAMT` PL5 +30, filler CL5) is laid over `INAREA` with `LA 3,INAREA` and `USING PARTD,3`. `INAREA` has no field names; the DSECT supplies them. This is the normal use of a DSECT: a buffer filled by `GET`.
- A second DSECT, `PARMD` (`PARMAMT` PL5 +0, `PARMTOT` PL6 +5), maps the parameter block `PARMAREA DS CL11`. `LA 1,PARMAREA` puts its address in R1, by convention the parameter list register.
- Two `USING`s can be active at once: `MVC PARMAMT,PARTAMT` assembles with base R1 for the target and base R3 for the source.
- `DROP` does not change a register. R1 still holds the block address when `BAL 9,ADDAMT` runs, and `ADDAMT` issues its own `USING PARMD,1`.
- `ADDAMT` uses `PARMAMT` from the block but updates `GRANDTOT` by name. `PARMTOT` is never used.
- Both DSECTs follow `LTORG`, in order, directly before `END`.
- Comments call the record DSECT `PARTREC`; the DSECT is `PARTD`.

### VB01BILD: a DSECT over a locate-mode buffer

- `VBOUTRECD DSECT` has `OUTRDWLL` H (+0), `OUTRDWFL` H (+2), `OUTCUSTNO` CL8 (+4), `OUTAMOUNT` PL5 (+12) and `OUTNAME DS 0CL1` (+17). `OUTNAME` reserves no bytes; it names the displacement where the variable part starts, and each `MVC` gives its own length.
- The register comes from the system, not from `LA`: `PUT OUTFILE` returns the buffer address in R1, `LR 4,1`, `USING VBOUTRECD,4`. `DROP 4` follows each record, because the next `PUT` returns a different address.
- The layout is the same as `VBINRECD` in the reader VB01LOC (H, H, CL8, PL5, 0CL1). Nothing checks that the two agree, so a change in one needs the same change in the other.
- The DSECT follows `LTORG` and is the last item before `END`, as in the other programs.
- A label of 9 characters (`OUTCUSTNO`, `OUTAMOUNT`, `VBOUTRECD`) leaves no blank in column 10, so its opcode starts in column 11; the operand stays in column 16.

### VB01LOC: two DSECTs at once

- `VBINRECD` is mapped on R3 (input record from `GET`) and `VBOUTRECD` on R4 (output buffer from `PUT`); both are active inside `BUILDOUT`. The two DSECTs have the same layout and different field names (`IN...`, `OUT...`), so every reference names one record only.
- Both registers come from R1 of the system macros, so each is saved with `LR` before the next macro. `DROP 3` and `DROP 4` end the mappings after `MVCBUILD`.
- `INNAME DS 0CL1` and `OUTNAME DS 0CL1` reserve nothing; they name displacement 17. The length of the data from there is not in the DSECT: it comes from the RDW.
- `VBINRECD`, `VBOUTRECD` and `DCBD DSORG=PS,DEVD=DA` come after `LTORG` and directly before `END`.

## 09 Tables

Concept article: `docs/concepts/TABLES.md` (serial search and indexed stepping; not yet updated for TB01TABL).

### TB01TABL: a table loaded from a file, BXLE and binary search

Source: `src/TB01TABL.asm`. Run with `jcl/TB01TABL.jcl` (job J0011942). Not assembled or run by Claude; the output is from the owner's run.

| Item | Use |
|---|---|
| `TABLE DS (MAXENT)CL12` | Empty storage for the worst case (200 x 12 = 2400 bytes) |
| `ENTCNT` | The real number of entries; `MAXENT` only says how many fit |
| `GET TABFILE,0(7)` | Read a record straight into the slot R7 points at |
| `BXLE r1,r3,target` | Add the increment (even register of r3) to r1, compare with the limit (odd register), branch while r1 <= limit |
| `TABLEND` | Address of the last loaded entry, the `BXLE` limit |
| LOW, HIGH, MID | Entry numbers (R4, R5, R6), not addresses |

Notes:

- Declare the table as empty `DS`, load it, count the entries as they arrive and keep the count. R8 is intact at the `EODAD` routine because QSAM keeps R2 to R13; `ST 8,ENTCNT` saves it.
- `BXLE` index = address of an entry, increment = `ENTLEN`, limit = address of the last entry (not the address after it). The limit is `TABLE` + (count - 1) x `ENTLEN`: `BCTR 8,0`, `MH 8,=H'12'`, `LA 3,TABLE`, `AR 3,8`. R2 and R3 must be an even-odd pair; R3 is reloaded from `TABLEND` before each `BXLE`.
- `BXLE` tests at the bottom, so the walk body runs at least once. An empty file would give R3 = `TABLE` - 12 and one unfilled line (read from the code, not run).
- Binary search: LOW = 0, HIGH = count - 1. `LR 6,4`, `AR 6,5`, `SRA 6,1` give MID. The byte offset is made only when an entry is touched: `LR 3,6`, `MH 3,=H'12'`, `LA 7,TABLE(3)`. `CLC SRCHKEY,0(7)` then `BE`, `BL`, or fall into LOW = MID + 1. `LA 4,1(,6)` is LOW = MID + 1; `BCTR 6,0` and `LR 5,6` are HIGH = MID - 1. The loop ends when `CR 4,5` shows LOW above HIGH (`BH BSNOTFND`).
- The search needs an ascending key order. Nothing in the program checks it; on unsorted data it would report `NOT FOUND` for keys that are present.
- Result with the 8-entry file: `ALPHA` found in 3 passes (MID 3, 1, 0), `MIKE` in 2 (MID 3, 5), `ZULU` not found after 4 compares (MID 3, 5, 6, 7), because `ZULU` is above `ZEBRA`.
- Output (15 lines): `ENTRIES LOADED: 0000008`, 8 key / value lines (value at column 13), the search lines with the message at column 11 and the value at column 51.
- The `MAXENT` check is after the `GET`: `C 8,=F'200'` and `BNH LOADLOOP` loop back at count 200, so the 201st record is stored 12 bytes past `TABLE` (over the start of the `TABFILE` DCB, which follows) before count 201 falls into `DC H'0'`. Not exercised.
- `C 8,=F'200'`, `MH ...,=H'12'` (twice) and `LA ...,ENTLEN` do not all use the `EQU` names; changing `MAXENT` or `ENTLEN` needs the literals changed as well.
- The items after `TABLE` (DCBs, literal pool) must be within 4096 bytes of the base register R12; a much larger `MAXENT` would need a second base register.
- `PRTHDR` is a local macro defined before the `CSECT`; `PRINT NOGEN` hides its expansions.

## 10 Macros

Concept article: none yet (`docs/concepts/MACROS.md` is planned).

### MC01MACR: source macros, &SYSNDX and AIF

Source: `src/MC01MACR.asm`. Run with `jcl/MC01MACR.jcl` (job J0095373). Not assembled or run by Claude; the output is from the owner's run, and the error history below is from the owner's debugging journal (`MC01MACR.md` on the owner's machine).

| Item | Use |
|---|---|
| `MACRO` ... `MEND` | Define a macro in the source, before the first `CSECT` |
| Prototype | `&LAB CHKOPEN &DCB,&FAILMSG`: label parameter, then positional parameters |
| `&DEST=SYSOUT` | Keyword parameter with a default; order does not matter |
| `&SYSNDX` | 4-digit number, different for every macro instruction in the assembly; used to build `OK&SYSNDX`, a label that is emitted into the object code |
| `AIF (cond).SEQ` | Assembly-time test; skips source up to the sequence symbol |
| `.SEQ ANOP` | Target for `AIF` and `AGO` |
| `.*` comment | Macro comment, not copied to the expansion |
| `PRINT NOGEN` | Hides the generated lines in the listing |

Final `CHKOPEN` body:

```
&LAB     DS    0H
         LA    2,&DCB
         USING IHADCB,2
         TM    DCBOFLGS,DCBOFOPN
         DROP  2
         AIF   ('&FAILMSG' EQ '').NOMSG
         BO    OK&SYSNDX
         PRTMSG &FAILMSG,DEST=SYSPRINT
         ABEND 999,DUMP
OK&SYSNDX DS   0H
.NOMSG   ANOP
```

Concepts:

- A macro is a template the assembler expands in line. The program grows with each use; nothing is called at run time and no return register is used.
- `&SYSNDX` is for ordinary generated symbols (labels that reach the object code). A fixed label inside a macro is defined again by every expansion and fails from the second use.
- `AIF` and `AGO` are decided at assembly time, from the text of the operands. A run-time question ("did the open fail?") needs a machine branch (`BO`, `BNO`, `BE`). An omitted `&FAILMSG` is an empty string, which `AIF` can test.
- `CHKOPEN` keeps the `TM` result in the condition code: `DROP` and `AIF` do not change it, so `BO` still tests the `TM`.
- `CHKOPEN` calls `PRTMSG`; the outer operand is replaced first, then the inner macro expands.
- A parameter declared positionally in the prototype (`&MSG`, no `=`) must be called positionally. `MSG=text` is not a hard error by itself (ASMA017W is a warning); the whole text `MSG=text` becomes the value of `&MSG` and the damage shows up several statements later.
- A default (`&DEST=SYSOUT`) assumes a DCB with that name. This program has only `SYSPRINT`, so every call codes `DEST=SYSPRINT`; the wrong name appears as an undefined symbol inside the nested system macro (`PUT`).
- A message for a failed `SYSPRINT` open cannot be printed to `SYSPRINT`.
- Result: three `CHKOPEN` expansions all branch over the failure block; `RECORDS COPIED: 0000004`.
- Not run: the `.NOMSG` path (no message operand), the failure path with `ABEND 999,DUMP`, and the default `DEST=SYSOUT`.
- Comments in the source still say the internal label is `&LABEL.A&SYSNDX` (`OPNA0007`, `OPNA0008`) and mention `BNO NOGOOD&SYSNDX`; these come from the earlier attempts. The code has `OK&SYSNDX` and `BO`.

Assembly errors in the order they were found and fixed:

| # | Message | Statement | Cause | Fix |
|---|---|---|---|---|
| 1 | ASMA044E Undefined symbol - `SYSOUT` | `OPEN` / `PUT` / `CLOSE` on `SYSOUT` | First seen on SB01CALL, where no `SYSOUT DCB` was coded. The same kind of mistake comes back in error 5 inside a macro expansion | Add the missing `DCB` with label `SYSOUT` |
| 2 | ASMA112S Invalid sequence symbol - `&SYSSNDX` | `AGO .SKIPMSG&SYSSNDX` | Typo: `&SYSSNDX` instead of `&SYSNDX`; not a system variable, so it was not substituted | Correct the spelling everywhere, comments and code |
| 3 | ASMA112S Invalid sequence symbol - `&SYSNDX` | `AGO .SKIPMSG&SYSNDX` and `.SKIPMSG&SYSNDX ANOP` | Same message after the spelling was right. First theory: a sequence symbol is limited to 7 characters after the period, and `.SKIPMSG` plus 4 digits is 11 | Shorten to `.SKP&SYSNDX` |
| 4 | ASMA112S, unchanged | `AGO .SKP&SYSNDX` and `.SKP&SYSNDX ANOP` | The length theory was wrong: at exactly 7 characters it failed the same way. The cause was not established | Drop `&SYSNDX`; use a fixed `.SKIP` |
| 5 | 9 errors from one mistake: ASMA017W (undefined keyword parameter `PRTMS/MSG`), ASMA150E (invalid delimiter in `MVC PRTLINE(50),MSG=MSGOPN0`), ASMA044E (`LA 1,SYSOUT`), ASMA435I (record 73 in `SYS1.MACLIB(IHBINNRA)`) | Repeated for the three `CHKOPEN` calls | `CHKOPEN` called `PRTMSG MSG=&FAILMSG`, but `&MSG` is positional. `MSG=` was not a keyword, so the whole text `MSG=MSGOPN0` became the value of `&MSG` and the model `MVC` broke. `DEST` was not supplied, so it defaulted to `SYSOUT`, which does not exist here, and `PUT SYSOUT,PRTLINE` generated `LA 1,SYSOUT` inside the system `PUT` expansion (nested `IHBINNRA`) | `PRTMSG &FAILMSG,DEST=SYSPRINT`: message positional, destination explicit |
| 6 | ASMA044E Undefined symbol - `NOGOOD0003`, `NOGOOD0006`, `NOGOOD0009` | `BNO NOGOOD&SYSNDX` | The body was `BNO NOGOOD&SYSNDX`, `AGO .SKIP`, `NOGOOD&SYSNDX DS 0H`, `PRTMSG`, `ABEND`, `.SKIP ANOP`. `AGO` has no condition and is always taken at assembly time, so everything down to `.SKIP` was never generated, including the `NOGOOD` label that `BNO` branched to | Replace with `AIF ('&FAILMSG' EQ '').NOMSG`, `BO OK&SYSNDX` over the failure block, the label `OK&SYSNDX DS 0H` and `.NOMSG ANOP`. `.NOMSG` is the only sequence symbol left |

Error 5 produced 9 of the 11 errors reported in that compile.

Takeaways from the journal:

1. `&SYSNDX` is for ordinary generated symbols only. It makes a label unique per expansion and safe to emit more than once; the spelling is `&SYSNDX`.
2. `AGO` is unconditional and is not a substitute for a run-time branch. Use a machine branch for decisions made at run time; use `AGO` and `AIF` only for decisions the assembler can make from the macro's parameters.
3. Positional and keyword parameters are strict. A positional parameter called with keyword syntax is not a hard error and corrupts the value; the symptoms are unrelated-looking errors several statements later.
4. A macro's default can be wrong for the caller. `PRTMSG`'s `&DEST=SYSOUT` assumes a DCB named `SYSOUT`; every call site overrides it when the program's DCB has another name.
5. When a macro expansion produces many errors, start with the first one: here one wrong call site gave 9 of 11 messages. A diagnosis that rests on a guess (the 7-character rule) must be tested; the test failed.

## Mistakes and Fixes

| Date | Program | Symptom | Cause | Fix |
|---|---|---|---|---|
| 2026-10-15 | DT03CONV | Step 15 prints `.07`, comment says `0.07` | The digit selected by `X'21'` is the one before the period; it is zero and is still replaced by the fill | Comment is wrong, code unchanged; move the significance starter one digit earlier to print `0.07` |
| 2026-10-15 | DT03CONV | Trailing blanks pack to X'0000000123400004' | `PACK` takes the low nibble of each blank (X'40') as digit 0 and the zone of the last blank (4) as the sign | Right justify the digits or pack only the digit part before `PACK` |
| 2026-10-16 | QSAMPROC | ASMA068S on the blank constant | A `DC` of type C was coded as `CL349`; the limit for a `DC` of type C is 256 bytes | Use `DS` for the large area, or split the constant (`CL256` plus `CL93`) |
| 2026-10-16 | QSAMPROC | ASMA034E operand beyond active `USING` range | Program longer than 4096 bytes with one base register | `USING QSAMPROC,12,11` with R11 = R12 + 4096 |
| 2026-10-16 | QSAMPROC | S0C1 at run time | `PUT` to SYSPRINT before it was opened | `OPEN` SYSPRINT before the first `PUT`; close it last |
| 2026-10-24 | DS01DSCT | Lines show `N`, `B`, `B`, `Ø` in column 10 (`CUST NO: N10023456`) | `MVC OUTMSG(10),=C'CUST NO: '` copies 10 bytes from a 9-byte literal; the tenth byte is the first byte of the next literal in the pool (the byte after the pool for the last one) | Code unchanged; code the labels as 10 bytes (`=CL10'CUST NO:'`) or copy 9 bytes |
| 2026-10-24 | DS01DSCT | Comments say the records are 30 bytes | `CL8` + `CL20` + `PL5` is 33 bytes | Comment is wrong, code unchanged |
| 2026-10-24 | DS02DSCT | S0C7 at `AP GRANDTOT,PARMAMT` on the first record | `GRANDTOT DS PL6` has no value. `AP` needs valid packed data, and even all zeros has no sign nibble | `ZAP GRANDTOT,=P'0'` before the first `AP` |
| 2026-10-24 | DS02DSCT | `BUILDTOT` would loop at its own `BR 10` once the S0C7 was fixed | `BAL 10,ADDAMT` overwrote R10, the return address to `MAINLOOP` | `BAL 9,ADDAMT` and `BR 9` in `ADDAMT`: one return register per call level |
| 2026-10-24 | DS02DSCT | Comments refer to a `PARTREC` DSECT | The DSECT is named `PARTD` | Comments are wrong, code unchanged |
| 2026-10-24 | DS02BILD | Comment on `ORG OUTREC+40` says "Step back" | The `ORG` moves the counter forward from 30 to 40 | Comment is wrong, code unchanged |
| 2026-10-24 | DS02BILD | Browse shows `....*` in columns 31-35 | Browse displays packed bytes as characters | Not an error; use `HEX ON` to see X'000012345C' |
| 2026-10-27 | VB01BILD | Browse shows `Col 001 033` and no RDW | Browse shows only the data of a `RECFM=VB` record; the longest record is 37 bytes with the 4-byte RDW | Not an error; `HEX ON` shows the RDW |
| 2026-10-27 | VB01LOC | Line 5 of the output shows `P100005` and its data after `P100004`, and the end message is blank | Record 4 has an empty name: R5 = -1 after `BCTR`, `EX` uses X'FF', and the `MVC` moves 256 bytes into an 80-byte `PRTLINE` | Not fixed in the source. Test the length before `EX` and skip the move when it is zero |
| 2026-10-27 | VB01LOC | Comments say a length of 0 in the register is harmless | An empty name gives -1, not 0 | Comment is incomplete, code unchanged |
| 2026-10-27 | VB01LOC | JCL screenshot has a line `//* $ACFJ219 ACF2 ACTIVE TDBK013` | The system adds it to the submitted job | Not part of the member; left out of `jcl/VB01LOC.jcl` |
| 2026-10-30 | SB01CALL | S0C4 after the heading line, on the first call | The hand-built call had `L 15,=V(SB02SUBR)` and `BALR 14,15` but no `LA 1,PARMLST1`; SB02SUBR's `L 2,0(,1)` used the R1 left over from `OPEN` and `PUT` | Add `LA 1,PARMLST1` before `L 15,=V(SB02SUBR)` (applied by the owner) |
| 2026-10-30 | SB02SUBR | `RETURN CODE` is 33280 on every line; the third call should give 4 | `IC 15,RETCODE` runs after `LM 14,12,12(13)`. `LM` sets R12 to SB01CALL's base, so `RETCODE` is read from the wrong place; `IC` replaces only the low byte of R15, so the other three bytes are the entry address restored by `LM` (inferred, not run by Claude) | Not fixed in the source. Untested: `SR 15,15`, `IC 15,RETCODE`, `L 13,SUBSAVE+4`, `ST 15,16(,13)`, `LM 14,12,12(13)` |
| 2026-10-30 | SB01CALL | Comments say the `CALL` macro sets the high bit of the last address | `CALL` sets it only with the `VL` operand; none is coded. SB02SUBR does not test the bit, so the run is the same | Comment is wrong, code unchanged |
| 2026-10-30 | SB01CALL | `TOTAL NOW` shows 00099350 for -99350 | `OI ZONE+7,X'F0'` forces the last zone to F, which drops the sign | Not an error in the arithmetic; the display has no sign. Use a sign character as in `PKDISP` of DT02ARTH |
| 2026-10-30 | SB01CALL | Comment on call 2 says the amount is large enough to push the total over, and that the check is not triggered | 150 + 500 = 650 is positive; the negative check is exercised by call 3 | Comment is muddled, code unchanged |
| 2026-11-04 | ED01EDMK | Amount 0 prints no `$` and no digit; the comment says the forced `X'21'` makes it print | `PATMAST` is read as 12 bytes with `X'21'` last, `PATTERN` is `CL11`; `MVC PATTERN,PATMAST` copies 11 bytes, so `X'21'` is dropped, `EDMK` does not set R1, and `BCTR`/`MVI` store a `$` outside the output line | Code unchanged. Make `PATTERN` as long as `PATMAST`, or move `X'21'` into byte 11; set R1 to a safe address before `EDMK` |
| 2026-11-04 | ED01EDMK | Comment on `PATMAST` says 11 bytes (`fill,8*sel,sel21`); banner says 12 | The listed parts add to 10; the hex string read from the editor is 12 bytes | Comments are wrong, code unchanged |
| 2026-11-04 | ED01EDMK | Comment says `BCTR` also branches on the result | `BCTR 1,0` has register 0 as second operand and never branches | Comment is wrong, code unchanged |
| 2026-11-04 | ED01EDMK | 1,234,567 shows as `$1234,567` | `PATMAST2` has one comma, after the sixth digit | Not an error in the code; add a second comma to the pattern for millions |
| 2026-11-04 | ED01EDMK | `MVC OUTMSG(12),PATTERN` in loop 1 | `PATTERN` is 11 bytes; byte 12 is `X'00'` from `AMTTAB` | Code unchanged; use length 11 |
| 2026-11-05 | SB01CALL | ASMA044E Undefined symbol - `SYSOUT` on `OPEN`, `PUT` and `CLOSE` | The source used `SYSOUT` but had no `SYSOUT DCB` statement (found first on SB01CALL during the MC01MACR work) | Add `SYSOUT DCB DSORG=PS,MACRF=PM,DDNAME=SYSOUT,RECFM=FB,LRECL=80,BLKSIZE=0` |
| 2026-11-05 | MC01MACR | ASMA112S Invalid sequence symbol - `&SYSSNDX` | Typo for `&SYSNDX`; the misspelt name is not a system variable | Correct the spelling in code and comments |
| 2026-11-05 | MC01MACR | ASMA112S on `AGO .SKIPMSG&SYSNDX` after the spelling was fixed; still failing as `.SKP&SYSNDX` at 7 characters | the 7-character length theory was wrong; cause not established | Fixed name `.SKIP`, later `.NOMSG` |
| 2026-11-05 | MC01MACR | 9 errors (ASMA017W, ASMA150E, ASMA044E, ASMA435I) on the three `CHKOPEN` calls | `PRTMSG MSG=&FAILMSG` called a positional parameter with keyword syntax, and the `&DEST=SYSOUT` default named a DCB that does not exist | `PRTMSG &FAILMSG,DEST=SYSPRINT` |
| 2026-11-05 | MC01MACR | ASMA044E Undefined symbol - `NOGOOD0003`, `NOGOOD0006`, `NOGOOD0009` | `AGO .SKIP` is always taken at assembly time, so the `NOGOOD&SYSNDX` label that `BNO` branched to was never generated | `AIF ('&FAILMSG' EQ '').NOMSG`, `BO OK&SYSNDX`, label `OK&SYSNDX DS 0H`, `.NOMSG ANOP` |
| 2026-11-05 | MC01MACR | Macro comments give `OPNA0007` / `OPNA0008` as the generated label and `BNO NOGOOD&SYSNDX` as the failure branch | Left over from the earlier attempts; the code defines `OK&SYSNDX` and uses `BO OK&SYSNDX` | Comments are wrong, code unchanged |
| 2026-11-05 | MC01MACR | `EOFSW` is set to `N` and `Y` and never tested | The loop ends through `EODAD=EOFRTN`, which falls into the following code | Not an error; the switch is unused |
| 2026-11-05 | MC01MACR | JCL comment reads `SET PRORGAM NAME` | Typo in the original JCL | Kept as in the screenshot |
| 2026-11-11 | TB01TABL | `MAXENT` check cannot stop a 201st record before it is stored | `C 8,=F'200'` and `BNH LOADLOOP` run after the `GET` and the `LA`, so at count 200 the loop reads record 201 into slot 201 (12 bytes past `TABLE`) before count 201 reaches `DC H'0'` (read from the code, not run) | Not fixed. The test has to come before the `GET`; untested |
| 2026-11-11 | TB01TABL | Comment says `BINSRCH` works in entry numbers | No label or instruction has that name; the routine is `BSLOOP` | Comment is wrong, code unchanged |
| 2026-11-11 | TB01TABL | Source comments are at column 35 without `*` and up to 35 characters | The editor source does not follow the repo column rules | The repo copy has the comments from column 40 as `* text`, shortened to 30 characters; code unchanged |
| 2026-11-11 | TB01TABL | Empty `TABFILE` would print one unfilled line in the `BXLE` walk | R8 = 0, `BCTR` gives -1, R3 = `TABLE` - 12, and the walk body runs once before `BXLE` tests (read from the code, not run) | Not fixed; guard with `LTR` and `BZ` on `ENTCNT` before the walk |

## Open Questions

- QSAMPROC: test records for rules R2 and R3, `REGULAR USER` and `READ ONLY USER`, a group whose records carry an ACF2 id, and an empty input file.
- BR09MTCH: the contents of `INFILE1`, `INFILE2`, `OUT1ONLY`, `OUT2ONLY` and `OUTCOMM` for the run with 5 / 5 records read, to be added to `data/`. Cases still to test: an empty file 1, an empty file 2, both empty, a repeated key in one file, and an open failure (missing DD).
- VB01LOC: the length check before `EX` (empty name), the contents of `HLQ.MLQ.VB01LOC.OUTFILE` after the run, and whether the overrun changed anything else in storage. The end message is missing in the SYSOUT; the bytes that replaced it are not shown.
- SB01CALL and SB02SUBR: rerun after the return code fix and check that the three lines show 0, 0 and 4; run the `LINK EP=SB02SUBR,PARAM=(TOTAL,AMOUNT)` variant (SB02SUBR would then need to be a member of `LOAD`); list the `CALL` expansion with `PRINT GEN`; code `VL` on a `CALL` and check that the high bit is set; replace the placeholder for SB01CALL lines 1-29.
- ED01EDMK: confirm the digit count of the `X'...'` on line 174 (read from a photo as 24 hex digits, 12 bytes), the byte that the `$` overwrote for the amount 0 (R1 was not set by `EDMK`), and the column of `$999` in loop 2 (column 8 of the line by calculation; the photo is skewed).
- MC01MACR: run with an empty `&FAILMSG` (the `.NOMSG` path), a deliberate open failure (missing `OUTFILE` DD) to see the message and the `ABEND 999,DUMP`, and `PRINT GEN` to list the expansions and the real `&SYSNDX` values. Confirm the data set name behind the masked `HLQ.MLQ.BR08SRCH.OUTFILE`.
- TB01TABL: run with an empty `TABFILE` (expected: `ENTRIES LOADED: 0000000`, one unfilled line in the walk, three not-found lines), with 200 and 201 records (the late `MAXENT` check) and with an unsorted file (wrong `NOT FOUND`). The `SYSPRINT` of the `IEBGENER` step was not supplied: `SYSUT1` is an inline stream (80-byte records) and `SYSUT2` is `LRECL=12`; its return code and message were not checked.
