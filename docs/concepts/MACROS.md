# Source Macros: MACRO, MEND, &SYSNDX and AIF

Scope: macros defined in the program source and expanded by the assembler, as in MC01MACR (`CHKOPEN` and `PRTMSG`) and TB01TABL (`PRTHDR`): `MACRO` and `MEND`, the prototype statement, positional and keyword parameters with a default, the label parameter, `&SYSNDX` for unique labels, `AIF` with a sequence symbol and `ANOP`, and the difference between assembly-time and run-time decisions. System macros such as `OPEN`, `PUT` and `CALL` are used by many programs but their expansions are not described. Macros in a library (`SYSLIB` or `COPY` members), `SETA`, `SETB`, `SETC`, `AGO` as a working statement and inner macro calls are not used in any program and are not described. `AGO` is covered only as the cause of a failure. The programs were not assembled or run, apart from the run shown in the MC01MACR SYSOUT screen.

Source programs: MC01MACR, TB01TABL (`PRTHDR`).

## Central Idea

A macro is not a subroutine. It is a template that the assembler expands at every place it is invoked, producing a new copy of the instructions each time. At run time nothing is called: there is no `BAL`, no `BR` and no return register. The program grows by one copy per invocation, and the macro is gone when the program runs.

## Subroutine or Macro

| | Subroutine (`BAL` / `BR`) | Macro |
|---|---|---|
| Copies in the program | One | One per invocation |
| Cost at run time | A branch and a return | None |
| Reached by | `BAL 10,OPENCHK` | `CHKOPEN INFILE,MSGOPN1` |
| Decisions made | At run time | At assembly time (parameters, `AIF`), and at run time (the instructions generated) |
| Reuse in another program | Retype the code | Copy the definition |
| Return register | Needed | Not involved |

OPENCHK in DS02DSCT, QSAMPROC, VB01LOC and BR09MTCH exists once and is called. `CHKOPEN` in MC01MACR is generated three times.

## The Definition

```
         MACRO
&LAB     PRTMSG &MSG,&DEST=SYSOUT
&LAB     DS    0H
         MVC   PRTLINE,BLANKS
         MVC   PRTLINE(50),&MSG
         PUT   &DEST,PRTLINE
         MEND
```

- `MACRO` starts the definition and `MEND` ends it. The line after `MACRO` is the prototype statement.
- A macro must be defined before its first use. TB01TABL defines `PRTHDR` before the CSECT. MC01MACR defines both macros ahead of the mainline.
- `&LAB` takes the label coded in front of the macro instruction. `&LAB DS 0H` gives that label to the first generated statement and generates nothing when no label is coded.
- `&MSG` is a positional parameter, `&DEST=SYSOUT` a keyword parameter with a default.
- The body uses `PRTLINE` and `BLANKS` from the program that invokes it. The macro does not define them, so every program that uses it must.

## Positional and Keyword Parameters

```
         PRTMSG MSGSTRT,DEST=SYSPRINT
         CHKOPEN INFILE,MSGOPN1
         PRTHDR MSGHDR1
```

- A positional parameter is supplied in order, without a name. `&MSG` is always the first operand.
- A keyword parameter is written `DEST=value` and can be coded in any position after the positional ones. When it is left out, the default from the prototype is used.
- In MC01MACR the print DCB is named `SYSPRINT`, so every `PRTMSG` call codes `DEST=SYSPRINT`. With the default `SYSOUT`, the generated `PUT SYSOUT,PRTLINE` would name a DCB that the program does not have.
- The message must be a `CL50` field. The body moves 50 bytes, so a longer message is cut and a shorter one reads the bytes after it. `PRTHDR` in TB01TABL does the same.
- A positional parameter cannot be coded as a keyword. Coding `PRTMSG MSG=&FAILMSG` for a positional `&MSG`, and leaving `DEST` at its default, produced 9 errors from one call in MC01MACR.

## &SYSNDX: A Unique Label for Each Expansion

`CHKOPEN` must branch round its failure block. A fixed label such as `OPNBAD` in the body would be defined again at the second invocation, and the assembler reports a duplicate label.

```
         MACRO
&LAB     CHKOPEN &DCB,&FAILMSG
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
         MEND
```

- `&SYSNDX` is set by the assembler, not by the caller. It is a 4-digit number that changes with every macro instruction in the assembly. Joining it to a label (`OK&SYSNDX`) gives each expansion its own label.
- `&SYSNDX` counts all macro instructions, including `OPEN`, `PUT`, `GET` and `PRTMSG`, so the values for `CHKOPEN` do not run 0001, 0002, 0003.
- The three `CHKOPEN` calls (SYSPRINT, INFILE, OUTFILE) assemble without clash because each gets its own `OK` label.
- The `IHADCB` DSECT comes from `DCBD` at the end of the program, so `DCBOFLGS` and `DCBOFOPN` are known to the macro. The DSECT article describes it.
- `LA 2,&DCB` puts the DCB address in R2. The macro uses and drops R2, so a program that keeps a value in R2 loses it.

## AIF and ANOP: Decisions Made While Assembling

```
         AIF   ('&FAILMSG' EQ '').NOMSG
```

- `AIF` compares text, not data. `'&FAILMSG' EQ ''` is true when the caller left the second operand out.
- When it is true the assembler skips the source lines down to the sequence symbol `.NOMSG`, so the failure block is not generated at all.
- `.NOMSG ANOP` is the target. A sequence symbol must start in column 1 with a period, and `ANOP` is a statement that generates nothing and only carries it.
- With no message, `CHKOPEN` ends after the `TM`. The caller must test the condition code itself.
- The result is fixed in the object code. Nothing is tested at run time.

The run-time decision is a machine instruction. After `TM DCBOFLGS,DCBOFOPN`, `BO OK&SYSNDX` branches when the open bit is on. The failure block (`PRTMSG` and `ABEND 999,DUMP`) follows it and runs only when the open failed. `AIF` decides whether that block exists. `BO` decides whether it runs.

## Why AGO Failed

An earlier version used `AGO .SKIP` to jump round the failure block and `BNO NOGOOD&SYSNDX` to decide at run time.

- `AGO` is an unconditional jump in the macro text, taken once, while assembling, in every expansion. It skipped the generation of the failure block, which also removed the label that `BNO NOGOOD&SYSNDX` branched to.
- A conditional assembly statement cannot test the condition code. That is a run-time value.
- The fix is the machine branch `BO OK&SYSNDX`.
- Sequence symbols with `&SYSNDX` appended, such as `.SKIPMSG&SYSNDX` and `.SKP&SYSNDX`, also failed. A sequence symbol is a fixed name: the macro uses `.NOMSG` in every expansion.

## What the Run Shows

MC01MACR opens three files, prints a start message, copies four records from `INFILE` to `OUTFILE`, prints `RECORDS COPIED: 0000004` and the end message. The copy has the same four lines as the input.

- Each of the three `CHKOPEN` calls passes a message, so the `.NOMSG` path was not run.
- No open failed, so the failure block (`PRTMSG` and `ABEND 999,DUMP`) did not run.
- The `PRTMSG` default `DEST=SYSOUT` was not used, because the program has no DCB named `SYSOUT`.
- If `SYSPRINT` itself fails to open, `CHKOPEN` calls `PRTMSG` to `SYSPRINT`, so `MSGOPN0` cannot be printed.
- The macro comments do not match the code in places. They describe a label `&LABEL.A&SYSNDX` and values `OPNA0007` and `OPNA0008`, and mention `BNO NOGOOD&SYSNDX`. The code defines `OK&SYSNDX` and uses `BO`. The code is unchanged.

## Rules

- Define a macro before its first use.
- Build every label inside a macro with `&SYSNDX`.
- Use the macro's own `&LAB` for a label coded by the caller.
- Use `AIF` and `ANOP` for choices that depend on the operands. Use a machine branch for choices that depend on data.
- Do not use `AGO` for a decision that depends on the condition code.
- Keep the prototype, the comments and the calls in step.
- Code positional parameters in order and keyword parameters by name.
- Test every path of the macro: with and without the optional operand, and with the condition that triggers the generated failure code.
- List the registers and storage names that the macro uses, so the invoking program defines them.

## Common Failures

| Symptom | Cause | Fix |
|---|---|---|
| Duplicate label at the second use | Fixed label inside the macro | Append `&SYSNDX` |
| Error on every expansion of one statement | Misspelt `&SYSNDX` (`&SYSSNDX`) | Spell the system variable correctly |
| 9 errors from one call | Positional parameter coded as a keyword, other default left | Code `&MSG` positionally |
| Failure block missing from the object code | `AGO` skipped it at assembly time | Use `AIF` and a machine branch |
| `BNO` label not found | `AGO` removed the block that held it | `BO OK&SYSNDX` round the block |
| Sequence symbol with `&SYSNDX` rejected | Sequence symbols are fixed names | Use `.NOMSG` |
| Message cut or padded oddly | Message not `CL50` | Match the 50-byte length in the macro |
| Macro uses a DCB the program lacks | Default `DEST=SYSOUT` | Code `DEST=` for the program's DCB |
| Register value lost around a macro | The macro uses R2 and drops it | Keep values elsewhere or save R2 |
