*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
        ORG $1000
        
PROMPT      DC.B    'MONITOR441> ',0     ; Prompt definition
USER_INPUT  DC.B    0                    ; User input spaces size residing in memory 
   
        ORG $1080
INVALID_COM DC.B    'Invalid command',0 ; Imply user command has no match   
INVALID_ADR DC.B    'Invalid Address',0 ; Imply input address is invalid 
BusAddrErr  DC.B    'The order: SSW BA IR',0 ; Output follows after Bus & Address Error Exception
EXIT_PRMPT  DC.B    'Exited',0          ;Imply termination/exit of monitor program  
ONE         DC.B    'HELP',0
TWO         DC.B    'MDSP',0
THREE       DC.B    'SORTW',0

***COMMAND TABLE***
**Command Names**
COM_TABL    DC.B    'HELP    '    ; String ‘HELP’ stored in memory (ASCII)
            DC.B    'MDSP    ' 
            DC.B    'SORTW   ' 
            ;DC.B    'MM      '
            ;DC.B    'MS      '
            ;DC.B    'BF      '
            ;DC.B    'BMOV    '
            ;DC.B    'BTST    '
            ;DC.B    'BSCH    '
            DC.B    'GO      '
            ;DC.B    'DF      '
            DC.B    'EXIT    '
            ;DC.B    'NEWCMD1 '
            ;DC.B    'NEWCMD2 '

**Command Addresses**         
COM_ADDR    DC.W    HELP         ;HELP is the address for HELP command subroutine 
            DC.W    MDSP
            DC.W    SORTW
            ;DC.W    MM
            ;DC.W    MS
            ;DC.W    BF
            ;DC.W    BMOV
            ;DC.W    BTST
            ;DC.W    BSCH
            DC.W    GO
            ;DC.W    DF
            DC.W    EXIT
            ;DC.W    NEWCMD1
            ;DC.W    NEWCMD2

***EXCEPTION TABLE***
BERR_TXT    DC.B    $D,'Bus Error Exception',0
ADDERR_TXT  DC.B    $D,'Address Error Exception',0   
ILLINST_TXT DC.B    $D,'Illegal Instruction Exception',0
PRIVVIO_TXT DC.B    $D,'Privilege Violation Exception ',0
DIVZERO_TXT DC.B    $D,'Divide by Zero Exception',0
CHKINS_TXT  DC.B    $D,'Check Instruction Exception',0
LINEA_TXT   DC.B    $D,'Line A Emulator Exception',0
LINEF_TXT   DC.B    $D,'Line F Emulator Exception',0

***ASCII to HEX***
*Convert ASCII in (A4) to HEX in (D1)
ASCIItoHEX:
        MOVEM.L D3,-(A7)     ; Save register
        CLR.L   D1           ; Clear register
        CLR.L   D3
        MOVE.B  (A4)+,D3     ; Save a byte from A4 to D3
        CMPI.B  #$30,D3      ; Check if it is ASCII
        BLT     A2H_END      ; Done if there isn't ASCII
AtoHEX2 BSR     ALPHAorDIGIT ; Determine alpha/digit
AtoHEX3 ADD.B   D3,D1        ; Store converted HEX in D1
        MOVE.B  (A4)+,D3     ; Save a byte from A4 to D3
        CMPI.B  #$30,D3      ; Check if it is ASCII
        BLT     A2H_END      ; Done if there isn't ASCII
        ASL.L   #4,D1        ; Shift left to store more HEX
        BRA     AtoHEX2      ; LOOP the conversion
A2H_END SUBA.L  #1,A4        ; leave A6 pointing at byte immediately after last number
        MOVEM.L (A7)+,D3     ; restore registers
        RTS
        
ALPHAorDIGIT:
        CMPI.B  #$40,D3      ; Determine alpha/digit
        BLT     AtoDIGIT     ; Branch to subroutine AtoDIGIT        
*Convert ASCII (D3) to Alphabets
AtoALPHA SUBI.B #$7, D3 ; for A to F
*Convert ASCII (D3) to digits
AtoDIGIT SUBI.B #$30,D3 ; for 0 to 9
         RTS  
         
    ORG $2000
START:
STACK       EQU $2FFC   ; $3000 minus a long word because A7 will be stored first4
;MAX_IN_LEN  EQU 80  ; to ensure input won't overflow stack
        MOVE.L  A7,STACK    ; store original location of stack beforehand
        LEA     STACK,A7
        MOVEM.L D0-D7/A0-A6,-(A7)   ; store all registers in stack. Want to be able to restore them
        LEA     STACK,A7
        ADDQ.W  #4,A7
       
***--------------------------- Command Interpreter ----------------------------***

          ;SUBA.L  #MAX_IN_LEN,A7  ; open space in stack for input (do only once)
BEGIN     LEA     PROMPT, A1  ; Prompt for user input “MONITOR441>” 
          MOVE.L  #14,D0      ; Display Prompt
          TRAP    #15
          LEA     USER_INPUT, A1      ; When user input, store to reserve user input space
          MOVE.L  #2,D0       ; Read input ans return to (A1)
          TRAP    #15
          
          LEA     COM_TABL,A2  ; Load Command Table (Start)
          LEA     COM_ADDR,A3  ; Load Command Table (End)
          CLR.L   D2           ; Command Counter
LOOKUP    MOVEA.L A1,A4        ; Point to user input       
          MOVE.L  #9, D4  
CMP_Char  SUBI.B  #1, D4
          CMPM.B  (A2)+, (A4)+ ; Compare byte (input) vs (CMD table)
          BEQ     CMP_Char     ; If same, keep comparing
          CMPI.B  #$20, -(A2)  ; Check if reach blank space 
          BEQ     Run_CMD      ; If 0, means all strings are same, select command
NEXTCMD   ADDA.L  #1, A2       ; Loop thru the rest of blank spaces
          SUBI.B  #1, D4
          BNE     NEXTCMD      ; 
          ADDQ.L  #2,D2        ; Else, point to next cmd address
          ;ADDQ.L  #8,A4        ; Go to next command
          CMPA.L  A2,A3        ; Check if reach end of COM_TABL
          BGE     LOOKUP       ; Else, keep looking up command         
          BSR     CMD_INVALID  ; Prompt Invalid command
          BRA     BEGIN        ; Start prompt again
          
Run_CMD   ADDA.L  D2,A3        ; point to the cmd adr in COM_ADDR 
          MOVEA.L #0,A5        ; clear A5, used for subroutine call
          MOVEA.W (A3),A5      ; move that command's address to register
          JSR     (A5)        ; jump to that command's subroutine (below)
          BRA     BEGIN        ; Prompt for new command

*Prompt user when command is invalid
CMD_INVALID:
       MOVEM.L D0/A1, -(A7)    ; Save REGs
       LEA     INVALID_COM, A1 ; Display error message
       MOVE.B  #13,D0
       TRAP    #15
       MOVEM.L (A7)+,D0/A1     ; Restore REGs
       RTS  
***Execute Program***        
*GO -  start execution from a given address
GO      MOVEM.L D0-D7/A0-A7,-(A7) ; Save all registers
        SUBA.L  #1, A4       ; Point to first byte of user inout address        
        MOVE.B  (A4)+,D1     ; Cope byte address from user input(A4 pointer)
        CMPI.B  #$24,D1      ; #$24 is '$', test if user input a valid address sign
        BNE     ERR_GO       ; INVALID Address for GO
        BSR     ASCIItoHEX   ; Convert mem addr to be run
        MOVEA.L D1,A6        ; Store user input addr in A6
        JSR     (A6)         ; Start execution from (A6)
        BRA     END_GO       ; End GO subroutine
ERR_GO  BSR     CMD_INVALID  ; Display invalid command error msg       
END_GO  MOVEM.L (A7)+,D0-D7/A0-A7 ; Restore Resgisters
        RTS
        
*EXIT - erminates/exits Monitor program
EXIT    LEA     EXIT_PRMPT ,A1    ; Display exiting msg
        MOVE.B  #13,D0
        TRAP    #15             
        ADDA.L  #4,A7             ; Skip PC on stack(4 bytes)
        MOVEM.L (A7)+,D0-D7/A0-A6 ; Restore Registers saved at beginning of program
        MOVEA.L STACK,A7
        BRA     END               ; Terminate Monitor Program  
       
HELP     LEA     ONE ,A1    ; Display exiting msg
        MOVE.B  #13,D0
        TRAP    #15   
            RTS
MDSP        LEA     TWO ,A1    ; Display exiting msg
        MOVE.B  #13,D0
        TRAP    #15
            RTS
SORTW       LEA     THREE ,A1    ; Display exiting msg
        MOVE.B  #13,D0
        TRAP    #15
            RTS
END:        
    END    START        ; last line of source




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
