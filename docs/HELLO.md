# hello.asm

## Program Overview

A minimal HLASM program for z/OS that writes one 80-byte record, `Hello World from ASM!`, to the SYSOUT DD and returns to its caller with return code 0. It is the baseline template for the other programs: standard entry linkage, QSAM file I/O, standard exit linkage, then data and the DCB.

## How the Program Works

1. **Entry linkage.**
   - `STM 14,12,12(13)` saves the caller's registers R14 through R12 into the caller's save area, starting at offset 12.
   - `LR 12,15` copies the entry-point address, which z/OS passes in R15, into R12 as the base register.
   - `USING HELLO,12` tells the assembler that R12 holds the address of the start of CSECT HELLO.
   - `ST 13,SAVEAREA+4` stores the caller's save-area address (still in R13) into word 2 of this program's save area. This is the backward chain.
   - `LA 13,SAVEAREA` makes R13 point to this program's own save area.
2. **Open.** `OPEN (SYSOUT,(OUTPUT))` opens the DCB named SYSOUT for output.
3. **Write.** `PUT SYSOUT,MESSAGE` moves the 80-byte field MESSAGE into the QSAM buffer and queues it as one record.
4. **Close.** `CLOSE (SYSOUT)` flushes the buffer and closes the file.
5. **Exit linkage.**
   - `L 13,SAVEAREA+4` reloads the caller's save-area address into R13.
   - `LM 14,12,12(13)` restores the caller's registers.
   - `SR 15,15` zeroes R15, which is the return code.
   - `BR 14` branches back to the caller.
6. **Data.**
   - `SAVEAREA DS 18F` is 72 bytes for the standard save area.
   - `MESSAGE DC CL80'Hello World from ASM!'` is the output record, padded with blanks to 80 bytes.
   - The DCB declares the file attributes.
7. `END HELLO` ends the assembly and names HELLO as the entry point.

## Concepts Demonstrated

- CSECT and the base register
- OS standard linkage (save area, register save and restore)
- QSAM sequential output with OPEN, PUT and CLOSE
- Fixed-length character constants
- Return codes
- The DCB macro

## How the Concepts Are Implemented

| Concept | Implementation |
|---|---|
| Base register addressing | `LR 12,15` plus `USING HELLO,12`. Every storage reference after this is assembled as displacement(base). |
| Save area linkage | `STM`/`LM` preserve the caller's registers. `ST 13,SAVEAREA+4` and `LA 13,SAVEAREA` set up the chain. System services such as OPEN and PUT require R13 to point to a valid save area. |
| QSAM output | `DCB DSORG=PS,MACRF=PM,DDNAME=SYSOUT` declares a physical-sequential file in put-move mode, so PUT copies the record from your field into the buffer. |
| Record format | `RECFM=FB,LRECL=80` gives fixed-blocked 80-byte records. `BLKSIZE=0` lets the system choose the block size. |
| Fixed-length constant | `CL80'...'` allocates exactly 80 bytes and pads the text with blanks, matching LRECL. |
| Return code | `SR 15,15` zeroes R15, so the step ends with RC=0. |

## Key Takeaways

- Every assembler program that calls system services needs the entry/exit linkage pattern. Reuse this skeleton as a template.
- R15 holds the entry address on entry and the return code on exit. R13 is the save area, R14 is the return address, and R12 is the conventional base.
- The DD name in the DCB (`SYSOUT`) must exist in the JCL, for example `//SYSOUT DD SYSOUT=*`.
- The record you PUT must match LRECL. Defining the message as `CL80` makes this automatic.
- This version stores only the backward chain. It does not set the forward chain (the caller's save area word 3), which is acceptable for simple programs but weaker for dump tracing.
- The save area is inside the CSECT, so the program is not reentrant.
