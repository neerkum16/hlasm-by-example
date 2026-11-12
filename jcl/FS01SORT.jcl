//MLQA     JOB (4301,020),'RUN HLASM',CLASS=A,MSGCLASS=X,
//      NOTIFY=&SYSUID,PRTY=8
//*
//*********************************************************************
//* SET PRORGAM NAME, SOURCE & LOAD LIBRARY                           *
//*********************************************************************
// SET PGMNAME=FS01SORT
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
//SYSIN    DD DSN=&SOURCE(&PGMNAME),DISP=SHR
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
//* STEP03: LOAD THE FILEA                                            *
//*********************************************************************
//STEP03   EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//SYSUT2   DD DSN=&&FILEA,DISP=(NEW,PASS),
//            SPACE=(TRK,(1,1)),
//            DCB=(RECFM=FB,LRECL=20,BLKSIZE=0)
//SYSUT1   DD *
A001    EAST  001000
A003    EAST  003000
B002    WEST  002500
B004    WEST  004500
C005    NORTH 005000
/*
//*
//*********************************************************************
//* STEP04: LOAD THE FILEB                                            *
//*********************************************************************
//STEP04   EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//SYSUT2   DD DSN=&&FILEB,DISP=(NEW,PASS),
//            SPACE=(TRK,(1,1)),
//            DCB=(RECFM=FB,LRECL=20,BLKSIZE=0)
//SYSUT1   DD *
A002    EAST  002000
B003    WEST  003500
C004    NORTH 004000
C006    NORTH 006000
/*
//*
//*********************************************************************
//* STEP05: EXECUTE THE PROGRAM                                       *
//*********************************************************************
//STEP05   EXEC PGM=&PGMNAME,COND=(4,LT)
//STEPLIB  DD DSN=&LOAD(&PGMNAME),DISP=OLD
//FILEA    DD  DSN=&&FILEA,DISP=(OLD,DELETE)
//FILEB    DD  DSN=&&FILEB,DISP=(OLD,DELETE)
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
