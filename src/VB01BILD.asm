***********************************************************************
* VB01BILD - Builder: Create Sample Variable Length PARTFILE Records  *
* Purpose: VB01LOC reads records whose RDW (Record Descriptor Word)   *
*          and packed amount field cannot be typed in with an ordinary*
*          text editor - this tiny program builds a handful of valid  *
*          variable length records, with correctly built RDWs, and    *
*          writes them out ready for VB01LOC to read.                 *
*                                                                     *
* This program writes in LOCATE MODE too - PUT with no area operand - *
* so it doubles as a second, simpler worked example of building a     *
* variable length record from scratch, before VB01LOC combines that   *
* with reading one at the same time.                                  *
***********************************************************************
         PRINT NOGEN
VB01BILD CSECT
***********************************************************************
* A000-MAINLINE                                                       *
***********************************************************************
         STM   14,12,12(13)            * Save caller's registers
         LR    12,15                   * Load base register
         USING VB01BILD,12             * Establish addressability
         ST    13,SAVEAREA+4           * Chain savearea (backward)
         LA    13,SAVEAREA             * Load address of savearea

         OPEN  (OUTFILE,(OUTPUT))

***********************************************************************
* Five sample records, each with a DIFFERENT length name field, to    *
* prove VB01LOC really does handle variable length - not just one     *
* fixed length that happens to look variable.  Every record follows   *
* the same four step pattern:                                         *
*                                                                     *
*    1. PUT OUTFILE (locate mode) - R1 = address of an empty buffer   *
*    2. USING VBOUTRECD,4 over that address                           *
*    3. Set the RDW length (name length + 17 fixed bytes), the RDW    *
*       flag half word (zero), the customer number, the packed amount,*
*       and MVC the name in - using an ORDINARY FIXED LENGTH MVC here,*
*       not EX, because THIS program knows each name's length at      *
*       ASSEMBLY TIME (it is typing the names in itself).  EX only    *
*       becomes necessary once the length is not known until run time,*
*       which is exactly VB01LOC's situation when IT reads these same *
*       records back.                                                 *
*    4. DROP 4                                                        *
***********************************************************************
         PUT   OUTFILE
         LR    4,1
         USING VBOUTRECD,4
         MVC   OUTRDWLL,=H'29'         * 17 fixed + 12 byte name = 29
         XC    OUTRDWFL,OUTRDWFL
         MVC   OUTCUSTNO,=CL8'P100001'
         ZAP   OUTAMOUNT,=P'12345'
         MVC   OUTNAME(12),=CL12'BOLT 10MM'
         DROP  4

         PUT   OUTFILE
         LR    4,1
         USING VBOUTRECD,4
         MVC   OUTRDWLL,=H'22'         * 17 fixed +  5 byte name = 22
         XC    OUTRDWFL,OUTRDWFL
         MVC   OUTCUSTNO,=CL8'P100002'
         ZAP   OUTAMOUNT,=P'500'
         MVC   OUTNAME(5),=CL5'WASH '
         DROP  4

         PUT   OUTFILE
         LR    4,1
         USING VBOUTRECD,4
         MVC   OUTRDWLL,=H'37'         * 17 fixed + 20 byte name = 37
*                                      * the LONGEST record file allows
         XC    OUTRDWFL,OUTRDWFL
         MVC   OUTCUSTNO,=CL8'P100003'
         ZAP   OUTAMOUNT,=P'99999'
         MVC   OUTNAME(20),=CL20'HEX NUT STAINLESS   '
         DROP  4

         PUT   OUTFILE
         LR    4,1
         USING VBOUTRECD,4
         MVC   OUTRDWLL,=H'17'         * 17 fixed +  0 byte name = 17
*                                      * SHORTEST record here can be -
*                                      * proves an EMPTY variable field
*                                      * (length 0) works correctly too
         XC    OUTRDWFL,OUTRDWFL
         MVC   OUTCUSTNO,=CL8'P100004'
         ZAP   OUTAMOUNT,=P'0'
*                                      * no MVC - zero bytes to move
         DROP  4

         PUT   OUTFILE
         LR    4,1
         USING VBOUTRECD,4
         MVC   OUTRDWLL,=H'27'         * 17 fixed + 10 byte name = 27
         XC    OUTRDWFL,OUTRDWFL
         MVC   OUTCUSTNO,=CL8'P100005'
         ZAP   OUTAMOUNT,=P'15099'
         MVC   OUTNAME(10),=CL10'COTTER PIN'
         DROP  4

***********************************************************************
* Close, restore registers, and return                                *
***********************************************************************
         CLOSE (OUTFILE)
         L     13,SAVEAREA+4
         LM    14,12,12(13)
         SR    15,15
         BR    14

***********************************************************************
* Data areas                                                          *
***********************************************************************
SAVEAREA DS    18F

OUTFILE  DCB   DSORG=PS,MACRF=PL,DDNAME=OUTFILE,                       X
               RECFM=VB,LRECL=37,BLKSIZE=0

         LTORG

***********************************************************************
* VBOUTRECD - IDENTICAL layout to the one in VB01LOC.  It has to match*
* exactly, byte for byte, because this program is building the very   *
* file VB01LOC will later read - if the two DSECTs ever drifted apart,*
* VB01LOC would read the wrong bytes out of a record that is, from the*
* file system's point of view, perfectly valid.                       *
***********************************************************************
VBOUTRECD DSECT
OUTRDWLL DS    H
OUTRDWFL DS    H
OUTCUSTNO DS   CL8
OUTAMOUNT DS   PL5
OUTNAME  DS    0CL1

         END   VB01BILD
