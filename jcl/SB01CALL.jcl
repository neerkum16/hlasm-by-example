//MLQM     JOB (4301,020),'RUN HLASM',CLASS=A,MSGCLASS=X,
//      NOTIFY=&SYSUID,PRTY=8
//*
//*********************************************************************
//* SET SOURCE & LOAD LIBRARY                                         *
//*********************************************************************
// SET SOURCE=HLQ.MLQ.SOURCE
// SET LOAD=HLQ.MLQ.LOADLIB
//*********************************************************************
//* STEP01: ASSEMBLE THE MAIN PROGRAM                                 *
//*********************************************************************
//STEP01   EXEC PGM=ASMA90
//SYSLIB   DD  DSN=SYS1.MACLIB,DISP=SHR
//SYSUT1   DD  DSN=&&SYSUT1,SPACE=(4096,(120,120),,,ROUND),UNIT=DISK,
//             DCB=BUFNO=1
//SYSPRINT DD  SYSOUT=*
//SYSLIN   DD  DSN=&&OBJ1,SPACE=(3040,(40,40),,,ROUND),UNIT=DISK,
//             DISP=(MOD,PASS),
//             DCB=(BLKSIZE=3040,LRECL=80,RECFM=FBS,BUFNO=1)
//SYSIN    DD  DSN=&SOURCE(SB01CALL),DISP=SHR
//*********************************************************************
//* STEP02: ASSEMBLE THE SUB PROGRAM                                  *
//*********************************************************************
//STEP02   EXEC PGM=ASMA90
//SYSLIB   DD  DSN=SYS1.MACLIB,DISP=SHR
//SYSUT1   DD  DSN=&&SYSUT1,SPACE=(4096,(120,120),,,ROUND),UNIT=DISK,
//             DCB=BUFNO=1
//SYSPRINT DD  SYSOUT=*
//SYSLIN   DD  DSN=&&OBJ2,SPACE=(3040,(40,40),,,ROUND),UNIT=DISK,
//             DISP=(MOD,PASS),
//             DCB=(BLKSIZE=3040,LRECL=80,RECFM=FBS,BUFNO=1)
//SYSIN    DD  DSN=&SOURCE(SB02SUBR),DISP=SHR
//*********************************************************************
//* STEP03: LINK-EDIT THE PROGRAM                                     *
//*********************************************************************
//STEP03   EXEC PGM=HEWL,PARM='MAP,LET,LIST',
//         COND=((8,LE,STEP01),(8,LE,STEP02))
//SYSLIN   DD  DSN=&&OBJ1,DISP=(OLD,DELETE)
//         DD  DSN=&&OBJ2,DISP=(OLD,DELETE)
//SYSLMOD  DD  DSN=&LOAD(SB01CALL),DISP=SHR
//SYSUT1   DD  DSN=&&SYSUT1,SPACE=(1024,(120,120),,,ROUND),UNIT=DISK,
//             DCB=BUFNO=1
//SYSPRINT DD  SYSOUT=*
//*********************************************************************
//* STEP04: EXECUTE THE PROGRAM                                       *
//*********************************************************************
//STEP04   EXEC PGM=SB01CALL,
//         COND=((8,LE,STEP01),(8,LE,STEP02),(8,LE,STEP03))
//STEPLIB  DD  DSN=&LOAD(SB01CALL),DISP=OLD
//SYSOUT   DD  SYSOUT=*
//SYSPRINT DD  SYSOUT=*
//SYSUDUMP DD  SYSOUT=*
