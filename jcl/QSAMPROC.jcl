//MLQM JOB (9999,000),'RUN HLASM',CLASS=A,MSGCLASS=X,
//         NOTIFY=&SYSUID,PRTY=8
//*
//*********************************************************************
//* SET PROGRAM NAME, SOURCE & LOAD LIBRARY
//*********************************************************************
//   SET PGMNAME=QSAMPROC
//   SET SOURCE=HLQ.MLQ.SOURCE
//   SET LOAD=HLQ.MLQ.LOADLIB
//*********************************************************************
//* STEP01: ASSEMBLE THE PROGRAM
//*********************************************************************
//STEP01    EXEC PGM=ASMA90
//SYSLIB    DD   DSN=SYS1.MACLIB,DISP=SHR
//SYSUT1    DD   DSN=&&SYSUT1,SPACE=(4096,(120,120),,,ROUND),UNIT=DISK,
//               DCB=BUFNO=1
//SYSPRINT  DD   SYSOUT=*
//SYSLIN    DD   DSN=&&OBJ,SPACE=(3040,(40,40),,,ROUND),UNIT=DISK,
//               DISP=(MOD,PASS),
//               DCB=(BLKSIZE=3040,LRECL=80,RECFM=FBS,BUFNO=1)
//SYSIN     DD   DSN=&SOURCE(&PGMNAME),DISP=SHR
//*********************************************************************
//* STEP02: LINK-EDIT THE PROGRAM
//*********************************************************************
//STEP02    EXEC PGM=HEWL,PARM='MAP,LET,LIST',COND=(8,LE,STEP01)
//SYSLIN    DD   DSN=&&OBJ,DISP=(OLD,DELETE)
//          DD   DDNAME=SYSIN
//SYSLMOD   DD   DSN=&LOAD(&PGMNAME),DISP=SHR
//SYSUT1    DD   DSN=&&SYSUT1,SPACE=(1024,(120,120),,,ROUND),UNIT=DISK,
//               DCB=BUFNO=1
//SYSPRINT  DD   SYSOUT=*
//*********************************************************************
//* STEP03: EXECUTE THE PROGRAM
//*********************************************************************
//STEP03    EXEC PGM=&PGMNAME,COND=((8,LE,STEP01),(8,LE,STEP02))
//STEPLIB   DD   DSN=&LOAD(&PGMNAME),DISP=OLD
//*
//AMHFIN    DD   DSN=HLQ.MLQ.AMH.INPUT,DISP=SHR
//*
//AMHFOUT   DD   DSN=HLQ.MLQ.AMH.OUTPUT,
//               DISP=(NEW,CATLG,DELETE),
//               SPACE=(CYL,(100,20),RLSE),
//               DCB=(RECFM=FB,LRECL=559)
//*
//SYSOUT    DD   SYSOUT=*
//SYSPRINT  DD   SYSOUT=*
//SYSUDUMP  DD   SYSOUT=*
