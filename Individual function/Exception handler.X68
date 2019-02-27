*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
        ORG $1000
        
PROMPT      DC.B    'MONITOR441> ',0     ; Prompt definition
USER_INPUT  DS.B    80                    ; User input spaces size residing in memory    
END_USER_INPUT

        ORG $1080
INVALID_COM DC.B    'Invalid command',0 ; Imply user command has no match   
INVALID_ADR DC.B    'Invalid Address',0 ; Imply input address is invalid 
BusAddrErr  DC.B    'The order: SSW BA IR',0 ; Output follows after Bus & Address Error Exception
EXIT_PRMPT  DC.B    'Exited',0          ;Imply termination/exit of monitor program  
ONE         DC.B    'HELP',0
TWO         DC.B    'MDSP',0
THREE       DC.B    'SORTW',0

***EXCEPTION TABLE***
BERR_TXT    DC.B    $D,'Bus Error Exception',0
ADDERR_TXT  DC.B    $D,'Address Error Exception',0   

            ORG $1200
***COMMAND TABLE***
**Command Names**
COM_TABL    ;DC.B    'HELP    '    ; String ‘HELP’ stored in memory (ASCII)
            ;DC.B    'MDSP    '  ; number specifies length of word 
           ; DC.B    'SORTW   ' ; used for LOOPUP (not input)
            ;DC.B    'EXIT    ' ; used for LOOPUP (not input)
            DC.B    'GO      '
            
**Command Addresses**         
COM_ADDR    ;DC.W    HELP         ;HELP is the address for HELP command subroutine 
            ;DC.W    MDSP
            ;DC.W    SORTW
            ;DC.W    EXIT    
            DC.W    GO

          
**Convert 4 HEX characters in (D1) to ASCII starting at A1 - (4 BYTE)
*For the SR
HEX4toASCII: 
          MOVEM.L D2-D4,-(A7) ; Save registers
          MOVE.L  D1,D4       ; Save D1 to D4
          MOVE.L  #4,D2       ; Count of 4
HEX4toA2  MOVE.L  D4, D3      ; Duplicate value of D4
          AND.L   #$0F,D3     ; Filter all except last digit
          CMPI.B  #$A,D3      ; Determine Alphabet/Digit
          BLT     DIGIT4toA   ; Branch to subroutine DIGITtoA  
ALPHA4toA ADDI.B  #$37, D3    ; Convert Alphabets in (D3) to ASCII for A to F
          BRA     HEX4toA3    ; Continue to save value to -A1
DIGIT4toA ADDI.B  #$30,D3     ; Convert Digit in (D3) to ASCII for 0 to 9      
HEX4toA3  MOVE.B  D3,-(A1)    ; Save ASCII to memory
          LSR.L   #4,D4       ; Shift right by 1 Hex digit
          SUBI.L  #1, D2      ; Decrement D2    
          BNE     HEX4toA2    ; Loop if there is digit left
H42A_END  MOVEM.L (A7)+,D2-D4 ; Restore registers
          RTS                 ; Return from Subroutine
          
**Convert 8 HEX characters in (D1) to ASCII starting at A1 - (8 BYTE)
*For the 16 registers (A, D), SSW, BA, IR
HEX8toASCII: 
          MOVEM.L D2-D4,-(A7) ; Save registers
          MOVE.L  D1,D4       ; Save D1 to D4
          MOVE.L  #8,D2       ; Count of 8
HEX8toA2  MOVE.L  D4, D3      ; Duplicate value of D4
          AND.L   #$0F,D3     ; Filter all except last digit
          CMPI.B  #$A,D3      ; Determine Alphabet/Digit
          BLT     DIGIT8toA   ; Branch to subroutine DIGITtoA  
ALPHA8toA ADDI.B  #$37, D3    ; Convert Alphabets in (D3) to ASCII for A to F
          BRA     HEX8toA3    ; Continue to save value to -A1
DIGIT8toA ADDI.B #$30,D3      ; Convert Digit in (D3) to ASCII for 0 to 9    
HEX8toA3  MOVE.B  D3,-(A1)    ; Save ASCII to memory
          LSR.L   #4,D4       ; Shift right by 1 Hex digit
          SUBI.L  #1, D2      ; Decerement D2    
          BNE     HEX8toA2    ; Loop if there is digit left
H82A_END  MOVEM.L (A7)+,D2-D4 ; Restore registers
          RTS                 ; Return from Subroutine 


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
;STACK       EQU $2FFC   ; $3000 minus a long word because A7 will be stored first4
STACK_INI_REG EQU $2FFC   ; A7 will be stored at $3000 - $4
DF_STACK      EQU $2FB8
STACK         EQU $2FBC

        MOVE.L  A7,STACK_INI_REG ; So registers stored at STACK will start at $3000
        LEA     STACK_INI_REG,A7
        MOVEM.L D0-D7/A0-A6,-(A7); Save registers on STACK to enable restore later 

    ***Exception Vector table***
        MOVE.L #STACK,    $0 
        MOVE.L #BUS_ERR,  $8 
        MOVE.L #ADS_ERR,  $C
        
    BRA ERR_BUS
***--------------------------- Command Interpreter ----------------------------***

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
        
    
***--------------------------- Exception Handlers  -----------------------------***
BUS_ERR:
        MOVEM.L A1/D0,-(A7)     ; Registers for Error Messages
        MOVEM.L D1/A2,-(A7)     ; Registers for SSW, BA, IR subroutine
        LEA     BERR_TXT, A1    ; Bus Error Msg
        BRA     BUS_ADS_EXCPTN

ADS_ERR:
        MOVEM.L A1/D0,-(A7)     ; Registers for Error Messages
        MOVEM.L D1/A2,-(A7)     ; Registers for SSW, BA, IR subroutine
        LEA     ADDERR_TXT, A1  ; Address Error Msg
        BRA     BUS_ADS_EXCPTN      
 
**--For bus error and address error routines--**  
*Read the content of A7, display the content of the Supervisor Status Word, 
*Bus Address and Instruction register all in a single line with spaces between them.   
BUS_ADS_EXCPTN:
        MOVE.L  #13,D0      ; Display error exceptionn message
        TRAP    #15
        LEA     DF_STACK,A2 ; A2 as Stack Pointer
        ADDA.L  #2,A2       ; A now point to the end of IR
        
        LEA     END_USER_INPUT,A1 ; Prepare blank space to write SSW, BA, IR
        ;SUBA.L  #60,A1      ; Empty spaces for the HEXtoASCII result
        MOVE.B  #0,-(A1)    ; Null terminator (end of SSW, BA, IR)
        CLR.L   D1          ; D1 carries byte to be converted
        MOVE.W  -(A2),D1    ; SSW to be converted to ASCII
        BSR     HEX8toASCII ; SSW stored in -8(A1)
        ADDQ.L  #4,A1       ; Convert SSW LONG > WORD
        MOVE.B  #$20,-(A1)  ; A single line with spaces between them
        MOVE.L  -(A2),D1    ; BA to be converted to ASCII
        BSR     HEX8toASCII ; BA stored in -8(A1)
        MOVE.B  #$20,-(A1)  ; A single line with spaces between them.
        CLR.L   D1          ; 
        MOVE.W  -(A2),D1    ; IR to be converted to ASCII
        BSR     HEX8toASCII ; IR stored in -8(A1)
        ADDQ.L  #4,A1       ; IR is WORD size
        MOVEM.L (A7)+,D1/A2 ; Restore registers for pointer and conversion
        BRA EXCEPTION       ; To display SSW, BA, IR


*Display error message and display the value of the registers    
EXCEPTION: 
        MOVE.B  #13,D0      ; Print our error exceptionn msg
        TRAP    #15         
        ;BSR     DF          ; Call subroutine DF
        MOVEM.L (A7)+,D0/A1 ; Restore REGs
        LEA     STACK,A7    ; A7 point to Stack
        ADDA.L  #4,A0       ; User input store on stack right after A7
        BRA     BEGIN       ; Restart program

    ORG $5000
ERR_BUS MOVE.L  $5001,D0

END:        
    END    START        ; last line of source









*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
