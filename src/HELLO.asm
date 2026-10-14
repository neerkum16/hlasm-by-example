*********************************************************************
* Hello World - Basic Assembler Program for z/OS                    *
* Purpose: Display "Hello World" to SYSOUT                          *
*********************************************************************
HELLO    CSECT
         STM   14,12,12(13)            * Save Caller's registers
         LR    12,15                   * Load base register
         USING HELLO,12                * Establish Addressability
         ST    13,SAVEAREA+4           * Chain savearea (backward)
         LA    13,SAVEAREA             * Load address of savearea

* Open SYSOUT file for output
         OPEN  (SYSOUT,(OUTPUT))

* Write the message
         PUT   SYSOUT,MESSAGE

* Close SYSOUT file and return
         CLOSE (SYSOUT)

* Restore registers and return
         L     13,SAVEAREA+4           * Restore caller's savearea
         LM    14,12,12(13)            * Restore caller's registers
         SR    15,15                   * Set return code to 0
         BR    14                      * Return to caller

* Data areas
SAVEAREA DS    18F
MESSAGE  DC    CL80'Hello World from ASM!'

* DCB for SYSOUT
SYSOUT   DCB   DSORG=PS,MACRF=PM,DDNAME=SYSOUT,
               RECFM=FB,LRECL=80,BLKSIZE=0

         END   HELLO
