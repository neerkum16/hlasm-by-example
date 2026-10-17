# QSAMPROC.asm

## Program Overview

QSAMPROC reads a sorted sequential file of user entitlement records (`AMHFIN`, fixed length 559) and writes one comma-delimited record (`AMHFOUT`, fixed length 559) for each group of input records. A group is the run of consecutive records with the same customer number and the same connect id. Because the input is sorted on those two fields, a change in either field marks the end of a group (control break). Messages and counts go to `SYSPRINT`.

While a group is read, three flags are set by rules:

| Rule | Condition | Flag |
|---|---|---|
| R1 | Service code `ADM` and access code `F` or `C` | `HASADM` |
| R2 | Service code `CIT`, `EFT` or `WPS` | `HASPAY` |
| R3 | Service code `FT` and first 4 bytes of the account id found in a 32-entry prefix table | `HASFTS` |
| R4 | `HASADM` gives `SYSTEM ADMINISTRATOR`; `HASPAY` or `HASFTS` gives `REGULAR USER`; otherwise `READ ONLY USER` | `FINALCLA` |

Files:

| DD | Direction | Record |
|---|---|---|
| AMHFIN | Input, `MACRF=GM` | 559 bytes, sorted on customer number and connect id |
| AMHFOUT | Output, `MACRF=PM` | 559 bytes, 18 comma-delimited columns, header line first |
| SYSPRINT | Output, `MACRF=PM` | 80 bytes, messages and counts |

Registers used:

| Register | Role |
|---|---|
| R1 | Address of the message passed to `PRTMSG` |
| R2 | Pointer to a DCB (open check) or to the current prefix table entry |
| R3 | Entries left in the prefix table search |
| R7 | Return address of `PRTMSG` |
| R8 | Return address of level 3 routines (`CHKFT`) |
| R9 | Return address of level 2 routines (`READINP`, `CHKREC`, `WRTHDR`) |
| R10 | Return address of level 1 routines |
| R11 | Second base register (program start + 4096) |
| R12 | First base register |
| R13 | Save area |

Output on SYSPRINT (4 lines, job J0077886: 34 records read, 13 groups written):

```
QSAMPROC - PROGRAM STARTED
QSAMPROC - RECORDS R000000034
QSAMPROC - RECORDS W000000013
QSAMPROC - PROGRAM ENDED NORMALLY
```

![QSAMPROC SYSOUT](../output/QSAMPROC_SYSOUT.svg)

## How the Program Works

**Linkage.** Standard entry linkage with two base registers: `USING QSAMPROC,12,11`, then `LA 11,4095(,12)` and `LA 11,1(,11)` make R11 the address 4096 bytes past the start.

**Mainline.** `INITIAL`, `OPENFILE`, start message, `READINP` (priming read), then the group loop. After the loop: `CLOSFILE`, `PRTCNTS`, `CLOSE SYSPRINT`, exit linkage with return code 0.

**Group loop (`GRPLOOP`).** Top tested: if `EOFSW` is `Y` the loop ends. Otherwise `INITGRP`, `SAVEKEY`, `PROCGRP`, `FINALCLS`, `BUILDOUT`, `WRITEOUT`, then `B GRPLOOP`.

**`PROCGRP`.** Inner top-tested loop with three exits: end of file, customer number changed (`CLC INCUSTNO(8),SAVCUST`), connect id changed. The body is `CHKREC` then `READINP`. On exit `INREC` holds the first record of the next group, so the mainline needs no extra read.

**`CHKREC`.** Applies R1, R2 and R3 to one record. A flag is only switched on here; `INITGRP` switches the flags off once per group.

**`CHKFT`.** Serial search: R2 = `PFXTAB`, R3 = 32, `CLC INACCTID(4),0(2)`, `BE FTFOUND`, `LA 2,4(,2)`, `BCT 3,FTLOOP`.

**`FINALCLS`.** Tests `HASADM`, then `HASPAY`, then `HASFTS`; first match wins and moves a 20-byte classification text to `FINALCLA`.

**`BUILDOUT` and `WRITEOUT`.** `BUILDOUT` clears `OUTAREA`, moves the connect id into columns 1 and 2, fixed literals into columns 3 to 6, 8 and 9, the saved correlation id into column 7, the classification into column 18, and 17 commas with `MVI`. `WRITEOUT` writes the header line before the first detail only (`FIRSTSW`), then `PUT` and `AP WRITCNT,=P'1'`.

**End of file and errors.** `READEOF` (EODAD) sets `EOFSW` and prints a message if no record was read. `IOERRIN` and `IOERROUT` (SYNAD) print a message and go to `ABENDRTN` (`ABEND 16,DUMP`). `OPENFILE` opens SYSPRINT first, tests `DCBOFOPN` through the `IHADCB` DSECT after each `OPEN`, and branches to `OPENERR1`, `OPENERR2` or `ABENDRTN`.

**Counts.** `PRTCNTS` copies a message to `MSGREAD`, `UNPK ZONE9(9),READCNT(5)`, `OI ZONE9+8,X'F0'`, moves the digits to `MSGREAD+20(9)`, and prints. The same steps run for `WRITCNT`.

**Execution trace (sample run).**

| Step | Routine | Effect |
|---|---|---|
| 1 | `INITIAL` | Areas cleared, switches set, counters zero |
| 2 | `OPENFILE` | SYSPRINT, AMHFIN, AMHFOUT opened and checked |
| 3 | `PRTMSG` | PROGRAM STARTED |
| 4 | `READINP` | First record read, `READCNT` = 1 |
| 5 | `GRPLOOP` x 13 | Each pass reads one group, sets flags, writes one record; the first pass also writes the header |
| 6 | `READEOF` | 34th `GET` finds no more records, `EOFSW` = `Y` |
| 7 | `GRPLOOP` | `EOFSW` is `Y`, loop ends |
| 8 | `CLOSFILE`, `PRTCNTS` | Data files closed; counts 34 and 13 printed; end marker printed |
| 9 | `CLOSE SYSPRINT`, exit | Return code 0 |

## Concepts Demonstrated

- QSAM `OPEN`, `GET`, `PUT`, `CLOSE` in move mode with EODAD and SYNAD exits
- Control-break processing on a sorted file
- Flag-based rules and a priority decision at the end of a group
- Checking that a file opened through the DCB (`DCBD`, `IHADCB`, `TM`, `DROP`)
- Two base registers for a program larger than 4096 bytes
- Linkage register per calling level
- Table lookup with early exit
- Packed decimal counters printed with `UNPK` and `OI`
- Building a fixed-layout record from named `DS` fields
- Clearing areas larger than 256 bytes in chunks
- Abend on I/O failure

## How the Concepts Are Implemented

| Concept | Implementation |
|---|---|
| EODAD | `DCB ...,EODAD=READEOF`. When `GET` finds no more records, control goes to `READEOF` instead of returning. R9 and R12 are intact, so `BR 9` there returns to the caller of `READINP`. |
| SYNAD | `SYNAD=IOERRIN` and `SYNAD=IOERROUT` route a real I/O error to a message and `ABENDRTN`. |
| Open check | `LA 2,dcb`, `USING IHADCB,2`, `TM DCBOFLGS,DCBOFOPN`, `DROP 2`, `BNO error`. `DCBD DSORG=PS` at the end generates the `IHADCB` map. |
| Open order | SYSPRINT is opened first because every error path writes to it. If SYSPRINT itself fails, the program abends without a message. |
| Control break | `SAVEKEY` copies the key of the first record; `PROCGRP` compares each record with it using `CLC`. |
| Group reset | `INITGRP` sets `HASADM`, `HASPAY`, `HASFTS` to `N` and clears `FINALCLA` and `OUTAREA` before every group. |
| Rule R3 literal | `CLC INSVCCD(3),=CL3'FT'` compares 3 bytes. `=C'FT'` would compare 2 bytes and also match `FTX`. |
| Prefix table | `PFXTAB` is 32 four-byte `DC` entries, `PFXCNT DC F'32'`. `CLC INACCTID(4),0(2)` uses R2 as the base register. |
| Second base | `USING QSAMPROC,12,11` with R11 = R12 + 4096. Without it the literal pool and DCBs past byte 4095 give ASMA034E. |
| Return registers | R10 level 1, R9 level 2, R8 level 3, R7 `PRTMSG`. A routine that calls another never has its own return address overwritten. |
| Counters | `READCNT` and `WRITCNT` are `PL5`. `ZAP` with `=P'0'` clears, `AP` with `=P'1'` adds. |
| Clearing areas | `MVC area(256),BLANK256`, `area+256(256)`, `area+512(47)` for 559 bytes. `BLANK256` is `CL256' '`, the maximum for a `DC` of type C. |
| Header | Built from several `DC C'...'` statements plus `CL256' '` and `CL93' '` pads: 210 + 256 + 93 = 559 bytes. |
| Output record | `OUTAREA` is `0CL559` with named fields and 17 one-byte separator fields set by `MVI OUTCn,C','`. |
| Message print | `PRTMSG` clears `PRTLINE`, `MVC PRTLINE(50),0(1)` copies 50 bytes from the address in R1, and `PUT`. |
| Close order | `CLOSFILE` closes the data files; `CLOSE (SYSPRINT)` is last because `PRTCNTS` still writes to it. |

## Key Takeaways

- Writing to SYSPRINT before it is open, or after it is closed, branches through a DCB without a valid write routine and ends in S0C1. Open it first and close it last.
- A `DC` of type C is limited to 256 bytes. Use `DS` for larger areas, or split a `DC` into several statements. The limit for `ZL` and `PL` in a `DC` is 16 bytes.
- A program longer than 4096 bytes needs a second base register. `LA 11,4095(,12)` followed by `LA 11,1(,11)` is used because 4096 does not fit in a 12-bit displacement. R11 can then not be used for linkage.
- `OPEN` sets no return code to test. Test `DCBOFOPN` in `DCBOFLGS` through the `IHADCB` DSECT.
- Without `INITGRP`, a flag set by one group stays on for the next and groups are misclassified.
- A top-tested group loop produces no output for an empty input file.
- The count is placed at `MSGREAD+20(9)`, one byte after the start of `READ    :`. The `R` of `READ` remains, so the printed text is `RECORDS R000000034`. Placing the number at offset 21 or moving the label text would give a cleaner line. The code was left as it ran.
- The comment in `PRTCNTS` says `PROGRAM QSAMPROC ENDED` while `MSGEND` prints `PROGRAM ENDED NORMALLY`.
- The `WRITEOUT` banner is numbered 7000 and the `CLOSFILE` banner 8000; the notes call the second routine `CLOSEFILE`. The label in the code is `CLOSFILE`.
- Errors met while building the program: ASMA068S (a `CL349` pad longer than the 256-byte limit of `DC`), ASMA034E (operand beyond the active `USING` range), S0C1 (PUT to an unopened SYSPRINT).
- The source lines after the `EODAD` banner comment (DCB macros, `LTORG`, `DCBD`, `END`) were not in the supplied screenshots and are rebuilt from the banner and routine names.
