//MLQM     JOB (9999,020),'RUN HLASM',CLASS=A,MSGCLASS=X,
//      NOTIFY=&SYSUID,PRTY=8
//*
//*********************************************************************
//* SET PRORGAM NAME, SOURCE & LOAD LIBRARY                           *
//*********************************************************************
// SET PGMNAME=TB01TABL
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
//* STEP03: LOAD THE TABLE FILE                                       *
//*********************************************************************
//STEP03   EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//SYSUT2   DD DSN=&&TABFILE,DISP=(NEW,PASS),
//            SPACE=(TRK,(1,1)),
//            DCB=(RECFM=FB,LRECL=12,BLKSIZE=0)
//SYSUT1   DD *
ALPHA   0100
BRAVO   0200
CHARLIE 0300
DELTA   0400
ECHO    0500
MIKE    0600
SIERRA  0700
ZEBRA   0800
/*
//*
//*********************************************************************
//* STEP04: EXECUTE THE PROGRAM                                       *
//*********************************************************************
//STEP04   EXEC PGM=&PGMNAME,COND=((8,LE,STEP01),(8,LE,STEP02))
//STEPLIB  DD DSN=&LOAD(&PGMNAME),DISP=OLD
//TABFILE  DD  DSN=&&TABFILE,DISP=(OLD,DELETE)
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
