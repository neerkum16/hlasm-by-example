//MLQM     JOB (4301,020),'RUN HLASM',CLASS=A,MSGCLASS=X,
//      NOTIFY=&SYSUID,PRTY=8
//*
//*********************************************************************
//* SET PRORGAM NAME, SOURCE & LOAD LIBRARY                           *
//*********************************************************************
// SET PGMNAME=VB02FIX
// SET SOURCE=HLQ.MLQ.SOURCE
// SET LOAD=HLQ.MLQ.LOADLIB
//*********************************************************************
//* STEP01: ASSEMBLE THE PROGRAM                                      *
//*********************************************************************
//STEP01   EXEC PGM=ASMA90
//SYSLIB   DD  DSN=SYS1.MACLIB,DISP=SHR
//SYSUT1   DD  DSN=&&SYSUT1,SPACE=(4096,(120,120),,,ROUND),UNIT=DISK,
//             DCB=BUFNO=1
//SYSPRINT DD  SYSOUT=*
//SYSLIN   DD  DSN=&&OBJ,SPACE=(3040,(40,40),,,ROUND),UNIT=DISK,
//             DISP=(MOD,PASS),
//             DCB=(BLKSIZE=3040,LRECL=80,RECFM=FBS,BUFNO=1)
//SYSIN    DD  DSN=&SOURCE(&PGMNAME),DISP=SHR
//*********************************************************************
//* STEP02: LINK-EDIT THE PROGRAM                                     *
//*********************************************************************
//STEP02   EXEC PGM=HEWL,PARM='MAP,LET,LIST',COND=(8,LE,STEP01)
//SYSLIN   DD  DSN=&&OBJ,DISP=(OLD,DELETE)
//         DD  DDNAME=SYSIN
//SYSLMOD  DD  DSN=&LOAD(&PGMNAME),DISP=SHR
//SYSUT1   DD  DSN=&&SYSUT1,SPACE=(1024,(120,120),,,ROUND),UNIT=DISK,
//             DCB=BUFNO=1
//SYSPRINT DD  SYSOUT=*
//*********************************************************************
//* STEP03: EXECUTE THE PROGRAM                                       *
//*********************************************************************
//STEP03   EXEC PGM=&PGMNAME,COND=((8,LE,STEP01),(8,LE,STEP02))
//STEPLIB  DD  DSN=&LOAD(&PGMNAME),DISP=OLD
//*
//INFILE   DD  DSN=HLQ.MLQ.VB01.INFILE,DISP=SHR
//*
//OUTFILE  DD  DSN=HLQ.MLQ.VB02.OUTFILE,
//             DISP=(NEW,CATLG,DELETE),
//             SPACE=(TRK,(10,20),RLSE),
//             DCB=(RECFM=VB,LRECL=37,BLKSIZE=0)
//*
//SYSOUT   DD  SYSOUT=*
//SYSPRINT DD  SYSOUT=*
//SYSUDUMP DD  SYSOUT=*
