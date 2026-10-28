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

BR09MTCH has no files in `data/` yet: its input and output files were not supplied (see Open Questions).

DS01DSCT has no files in `data/`: its two records are `DC` constants in the source, and it runs with the generic `jcl/ASMCLRUN.jcl`.

## Run JCL

Generic assemble, link and go is `jcl/ASMCLRUN.jcl`. A program that needs its own files has its own member, `jcl/<PROGRAM>.jcl`. Each has three steps: `ASMA90` (assemble), `HEWL` (link) and the program step, with `COND` on the earlier steps. Only `PGMNAME` and the program step DDs differ.

| Program | JCL | Program step DDs |
|---|---|---|
| QSAMPROC | `jcl/QSAMPROC.jcl` | `AMHFIN` `DISP=SHR`; `AMHFOUT` `NEW,CATLG,DELETE`, `FB`, `LRECL=559`; `SYSPRINT`, `SYSOUT`, `SYSUDUMP` to `SYSOUT=*` |
| BR09MTCH | `jcl/BR09MTCH.jcl` | Two inputs and three outputs |
| DS02BILD | `jcl/DS02BILD.jcl` | `PARTFILE` `NEW,CATLG,DELETE`, `FB`, `LRECL=40`; `SYSOUT`, `SYSPRINT`, `SYSUDUMP` to `SYSOUT=*`. Dataset names use the masked qualifiers `HLQ.MLQ` |
| DS02DSCT | `jcl/DS02DSCT.jcl` | `PARTFILE` `DISP=SHR` (the file DS02BILD created); `SYSOUT`, `SYSPRINT`, `SYSUDUMP` to `SYSOUT=*`. Output is on `SYSPRINT` |
| VB01BILD | `jcl/VB01BILD.jcl` | `OUTFILE` `NEW,CATLG,DELETE`, `SPACE=(TRK,(10,20),RLSE)`, `RECFM=VB`, `LRECL=37`, `BLKSIZE=0`; `SYSOUT`, `SYSPRINT`, `SYSUDUMP` to `SYSOUT=*`. Dataset names use the masked qualifiers `HLQ.MLQ`; job name masked as `MLQM` |
| VB01LOC | `jcl/VB01LOC.jcl` | `INFILE` is `HLQ.MLQ.VB01BILD.OUTFILE` `DISP=SHR`; `OUTFILE` is `HLQ.MLQ.VB01LOC.OUTFILE` `NEW,CATLG,DELETE`, `SPACE=(TRK,(10,20),RLSE)`, `RECFM=VB`, `LRECL=37`, `BLKSIZE=0`; `SYSOUT`, `SYSPRINT`, `SYSUDUMP` to `SYSOUT=*`. The screenshot of the submitted job showed an ACF2 comment line (`$ACFJ219 ACF2 ACTIVE`) added by the system; it is not in the member and not in the file. Masked as for VB01BILD (`HLQ.MLQ`, job name `MLQM`) |

`AMHFOUT` is cataloged on a normal end, so delete the dataset (`APXT.TAQ8656.AMH.OUTPUT`) before a rerun or the step fails on allocation. The same applies to `HLQ.MLQ.TEST.PARTFILE` of DS02BILD `HLQ.MLQ.VB01BILD.OUTFILE` of VB01BILD and `HLQ.MLQ.VB01LOC.OUTFILE` of VB01LOC.

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

Topic 04 stays Planned: `SUBROUTINES.md` covers the internal `BAL` routines used so far, and no program yet uses `CALL` or `LINK`. Existing articles still to update for the newer programs: `LINKAGE.md` (parameter list in R1 is now used) and `CONDITION-CODE.md` (new source programs). `DSECTS.md`, `RECORD-LAYOUTS.md`, `OPERAND-LENGTHS.md`, `PACKED-VALIDITY.md`, `SUBROUTINES.md` and `QSAM-CONTROL-BREAK.md` were updated for VB01BILD and VB01LOC.

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

Concept article: `docs/concepts/SUBROUTINES.md`. Topic 04 has no dedicated program yet and stays Planned.

Planned.

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
- `EDMK` is not covered yet.

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

Planned. The serial search and indexed stepping used so far are in `docs/concepts/TABLES.md`.

## 10 Macros

Planned.

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

## Open Questions

- QSAMPROC: test records for rules R2 and R3, `REGULAR USER` and `READ ONLY USER`, a group whose records carry an ACF2 id, and an empty input file.
- BR09MTCH: the contents of `INFILE1`, `INFILE2`, `OUT1ONLY`, `OUT2ONLY` and `OUTCOMM` for the run with 5 / 5 records read, to be added to `data/`. Cases still to test: an empty file 1, an empty file 2, both empty, a repeated key in one file, and an open failure (missing DD).
- VB01LOC: the length check before `EX` (empty name), the contents of `HLQ.MLQ.VB01LOC.OUTFILE` after the run, and whether the overrun changed anything else in storage. The end message is missing in the SYSOUT; the bytes that replaced it are not shown.
