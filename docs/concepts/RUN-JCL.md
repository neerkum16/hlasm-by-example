# Running a Program: Assemble, Link-Edit, Execute

Scope: the JCL in `jcl/` that assembles (`ASMA90`), link-edits (`HEWL`) and runs a program: the symbolic parameters, passing the object deck between steps as a temporary data set, `COND` on each step, linking two object decks into one load module (SB01CALL), building test data in the job with `IEBGENER` and temporary data sets (FS01SORT, TB01TABL), permanent output data sets and reruns, `STEPLIB`, and the `SYSOUT`, `SYSPRINT` and `SYSUDUMP` DDs. Data set names are masked as `HLQ.MLQ`. Jobs with procedures (`PROC`), `IF`/`THEN`/`ELSE`, GDGs and tape are not used in any JCL member and are not described. The JCL was not submitted by Claude; run results come from the SYSOUT screens in the program docs.

Source programs: the members of `jcl/`: ASMCLRUN, BR09MTCH, DS02BILD, DS02DSCT, FS01SORT, MC01MACR, QSAMPROC, SB01CALL, TB01TABL, VB01BILD, VB01LOC, VB02FIX.

## Central Idea

One job does the whole cycle: assemble the source, link-edit the object deck into a load module, run the load module. Each step passes its result to the next through a temporary data set, and `COND` stops the later steps when an earlier one failed. The only lines that change from one program to another are the three `SET` statements and the DDs the program opens.

## The Three Steps

```
//  SET PGMNAME=VB01LOC
//  SET SOURCE=HLQ.MLQ.SOURCE
//  SET LOAD=HLQ.MLQ.LOADLIB
//STEP01   EXEC PGM=ASMA90
//SYSLIB   DD  DSN=SYS1.MACLIB,DISP=SHR
//SYSLIN   DD  DSN=&&OBJ,...,DISP=(MOD,PASS),DCB=(BLKSIZE=3040,LRECL=80,RECFM=FBS,BUFNO=1)
//SYSIN    DD  DSN=&SOURCE(&PGMNAME),DISP=SHR
//STEP02   EXEC PGM=HEWL,PARM='MAP,LET,LIST',COND=(8,LE,STEP01)
//SYSLIN   DD  DSN=&&OBJ,DISP=(OLD,DELETE)
//         DD  DDNAME=SYSIN
//SYSLMOD  DD  DSN=&LOAD(&PGMNAME),DISP=SHR
//STEP03   EXEC PGM=&PGMNAME,COND=((8,LE,STEP01),(8,LE,STEP02))
//STEPLIB  DD  DSN=&LOAD(&PGMNAME),DISP=OLD
```

| Step | Program | Reads | Writes |
|---|---|---|---|
| STEP01 | `ASMA90`, the assembler | `SYSIN`: the source member. `SYSLIB`: `SYS1.MACLIB` for system macros | `SYSLIN`: the object deck `&&OBJ`; `SYSPRINT`: the listing |
| STEP02 | `HEWL`, the linkage editor | `SYSLIN`: `&&OBJ`, then `SYSIN` | `SYSLMOD`: member `&PGMNAME` of the load library; `SYSPRINT`: the link map |
| STEP03 | The program itself | `STEPLIB`: the load library member, plus the program's own DDs | `SYSOUT` or `SYSPRINT` and the program's files |

- The three `SET` statements are the only edit between programs: program name, source library and load library. `&PGMNAME`, `&SOURCE` and `&LOAD` are replaced in every step.
- `SYSLIB` points to `SYS1.MACLIB` so that `OPEN`, `PUT`, `GET`, `CLOSE`, `CALL` and the other system macros can be expanded.
- `PARM='MAP,LET,LIST'` passes the options `MAP`, `LET` and `LIST` to the linkage editor.
- `DD DDNAME=SYSIN` in STEP02 is a second `SYSLIN` input, read from the DD named `SYSIN` in the same step. ASMCLRUN has a `SYSIN DD *` there with no link statements. The other members have no `SYSIN` DD in that step, and the jobs run, so the missing DD adds nothing.

## Passing the Object Deck

- `&&OBJ` is a temporary data set. The `&&` name makes the system delete it at the end of the job.
- STEP01 writes it with `DISP=(MOD,PASS)`: `MOD` appends, `PASS` keeps it for a later step.
- STEP02 reads it with `DISP=(OLD,DELETE)`: the link step uses it and deletes it.
- `RECFM=FBS,LRECL=80,BLKSIZE=3040` is the object deck format the assembler writes.
- The assembler listing and the link map go to `SYSPRINT DD SYSOUT=*`. Assembly errors are found there.

## COND: Skipping Steps After a Failure

`COND=(8,LE,STEP01)` bypasses the step when `8 LE return-code-of-STEP01` is true, that is, when STEP01's return code is 8 or higher. A warning (return code 4) lets the job go on.

| Job | Run step condition | The run is skipped when |
|---|---|---|
| ASMCLRUN, VB01BILD, VB01LOC, MC01MACR, DS02DSCT, BR09MTCH and similar | `((8,LE,STEP01),(8,LE,STEP02))` | The assembly or the link-edit ended with 8 or more |
| SB01CALL | `((8,LE,STEP01),(8,LE,STEP02),(8,LE,STEP03))` | Either assembly or the link-edit ended with 8 or more |
| TB01TABL | The run step, STEP04, tests STEP01 and STEP02 | Assembly or link-edit ended with 8 or more |
| FS01SORT | `(4,LT)` with no step name | Any earlier step ended with a return code above 4 |

- A condition list is an OR: one true test bypasses the step.
- In FS01SORT the missing step name makes `COND=(4,LT)` apply to every earlier step, including the two `IEBGENER` steps.
- The `IEBGENER` steps in FS01SORT and TB01TABL have no `COND`, so they run even after a failed assembly. The data they build is deleted at the end of the job.

## Two Programs in One Load Module: SB01CALL

```
//STEP01   EXEC PGM=ASMA90          main program   -> &&OBJ1
//STEP02   EXEC PGM=ASMA90          called program -> &&OBJ2
//STEP03   EXEC PGM=HEWL,PARM='MAP,LET,LIST',
//         COND=((8,LE,STEP01),(8,LE,STEP02))
//SYSLIN   DD  DSN=&&OBJ1,DISP=(OLD,DELETE)
//         DD  DSN=&&OBJ2,DISP=(OLD,DELETE)
//SYSLMOD  DD  DSN=&LOAD(SB01CALL),DISP=SHR
```

- Each program is assembled by its own step into its own deck. The decks must not share a `SYSLIN` data set name.
- The link step concatenates the two decks on `SYSLIN`. The `V`-type constant `=V(SB02SUBR)` in SB01CALL is resolved against the control section named `SB02SUBR` in the second deck.
- `SYSLMOD` names one member, `SB01CALL`, so there is one load module. The first control section is the entry point, so SB01CALL runs.
- The run step then needs only `PGM=SB01CALL` and `STEPLIB`. SB02SUBR is inside the module.

## Test Data Built in the Job: FS01SORT and TB01TABL

```
//STEP03   EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//SYSUT2   DD DSN=&&FILEA,DISP=(NEW,PASS),
//            SPACE=(TRK,(1,1)),
//            DCB=(RECFM=FB,LRECL=20,BLKSIZE=0)
//SYSUT1   DD *
A001    EAST  001000
...
/*
```

- `IEBGENER` copies `SYSUT1` to `SYSUT2`. `SYSUT1` holds the records in the job stream (`DD *`) and `SYSUT2` is a new temporary data set.
- `SYSIN DD DUMMY` means there are no `IEBGENER` control statements: a plain copy.
- The program's own DD reads the temporary data set: `FILEA DD DSN=&&FILEA,DISP=(OLD,DELETE)`. The data set is deleted after the run.
- The record layout is set by the `DCB` on `SYSUT2`: `RECFM=FB`, `LRECL=20`. In-stream data must be typed to the program's column layout. In FS01SORT the key is in columns 1 to 8, the region in 9 to 14 and the amount in 15 to 20.
- The data is in the JCL, so the input is the same on every run and appears in the job with the output. TB01TABL does the same for `TABFILE`, with 12-byte records.
- A packed or binary field cannot be typed this way. VB01BILD builds that kind of file with a program (see the variable-length records article).

## Permanent Output Data Sets and Reruns

```
//OUTFILE  DD  DSN=HLQ.MLQ.VB01LOC.OUTFILE,
//             DISP=(NEW,CATLG,DELETE),
//             SPACE=(TRK,(10,20),RLSE),
//             DCB=(RECFM=VB,LRECL=37,BLKSIZE=0)
```

- `DISP=(NEW,CATLG,DELETE)` creates the data set and catalogs it when the step ends normally. If the step abends, the data set is deleted.
- A second run fails at allocation, because the name is already cataloged. Delete the data set before a rerun. Programs that write permanent files this way include VB01BILD, VB01LOC, BR09MTCH and MC01MACR.
- An input from an earlier program is read with `DISP=SHR`: VB01LOC reads `HLQ.MLQ.VB01BILD.OUTFILE`, and MC01MACR reads `HLQ.MLQ.BR08SRCH.OUTFILE`. That earlier job must have run first.
- `BLKSIZE=0` lets the system choose the best block size. `RLSE` releases unused space at the end.
- `LRECL` on a VB file is the longest record including the 4-byte RDW (37 for the VB programs).
- The `DCB` parameters on the DD and the DCB in the program describe the same file, so keep `RECFM` and `LRECL` the same in both. The VB programs code `RECFM=VB,LRECL=37` in the program and on the DD.

## The Output DDs

| DD | Role in these jobs |
|---|---|
| `SYSOUT` | The print file of programs whose DCB has `DDNAME=SYSOUT` (ED01EDMK, SB01CALL and others) |
| `SYSPRINT` | The print file of programs whose DCB has `DDNAME=SYSPRINT` (MC01MACR, TB01TABL) |
| `SYSUDUMP` | The dump file for an abend |

- Run steps code both `SYSOUT` and `SYSPRINT`, so one JCL fits programs of either style. The one the program does not open stays empty. MC01MACR's output goes to `SYSPRINT`, and its `SYSOUT` DD is not used.
- A DD that the program names but the JCL does not supply makes the `OPEN` of that DCB fail. Programs with an open check (`OPENCHK`, `CHKOPEN`) report it; the others fail at the first `GET` or `PUT`.
- ASMCLRUN, the generic member, ends with `//SYSUPUMP DD SYSOUT=*`. The dump DD in the other members is spelled `SYSUDUMP`. With `SYSUPUMP`, an abend would not find the standard dump DD. It is a likely misspelling, and I did not run the member to check what happens.
- `STEPLIB DD DSN=&LOAD(&PGMNAME),DISP=OLD` names the load library member for the run step. Without it the system searches the standard libraries and does not find the program.

## Rules

- Change only the `SET` statements for a new program, and the program's own DDs.
- Give each object deck its own temporary name, and list all decks on `SYSLIN` of the link step.
- Apply `COND` to the run step for both the assemble and the link-edit step.
- Check that the `DD` name matches the `DDNAME` in the program's DCB.
- Delete a cataloged output data set before a rerun, or use a new name.
- Give a `DD *` data set the exact record layout the program expects.
- Read the assembler listing for errors before reading the program output.
- Keep `SYSUDUMP` spelled correctly in every member.

## Common Failures

| Symptom | Cause | Fix |
|---|---|---|
| Job fails at allocation on a rerun | `OUTFILE` already cataloged | Delete the data set first |
| Run step skipped | Assembly or link ended with 8 or more | Read the `SYSPRINT` listing of STEP01 and STEP02 |
| Program not found at the run step | `STEPLIB` missing or the link step wrote no member | Check `SYSLMOD` and `STEPLIB` |
| Unresolved external reference in the link map | Second object deck missing from `SYSLIN` | Add `&&OBJ2` |
| `OPEN` fails | DD name missing or different from `DDNAME=` | Add or rename the DD |
| Record layout wrong in a program fed from `DD *` | Columns in the job stream differ from the layout | Count the columns against the DSECT |
| IEBGENER steps run after a failed assembly | No `COND` on those steps | Add `COND` or accept it |
| No dump DD on an abend | DD name misspelt (`SYSUPUMP`) | Use `SYSUDUMP` |
