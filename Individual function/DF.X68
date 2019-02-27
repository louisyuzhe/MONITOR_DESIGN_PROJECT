*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
* Put program code here
 ORG    $1400
DF_MSG      DC.B    'PC=00000000 SR=0000     US=00000000 SS=00000000',$A,$D
            DC.B    'D0=00000000 D1=00000000 D2=00000000 D3=00000000 ',$A,$D
            DC.B    'D4=00000000 D5=00000000 D6=00000000 D7=00000000 ',$A,$D
            DC.B    'A0=00000000 A1=00000000 A2=00000000 A3=00000000 ',$A,$D
            DC.B    'A4=00000000 A5=00000000 A6=00000000 A7=00000000',$0
DF_MSG_END 
    ORG    $900
STACK EQU $2FFC   ; $3000 minus a long word because A7 will be stored first
DF_STACK EQU $2FC0

       ORG    $2200
***HEX to ASCII***
*Convert HEX in (D1) to ASCII starting at A1 - (# of digits * BYTE)
HEXtoASCII: 
          MOVEM.L D3/D4,-(A7) ; Save registers
          MOVE.L  D1, D4       ; Save D1 to D4
HEXtoA2   MOVE.L  D4, D3      ; Duplicate value of D4
          AND.L   #$0F,D3     ; Filter all except last digit
          CMPI.B  #$A,D3      ; Determine Alphabet/Digit
          BLT     DIGITtoA    ; Branch to subroutine DIGITtoA  
ALPHAtoA  ADDI.B  #$37, D3    ; Convert Alphabets in (D3) to ASCII for A to F
          BRA     HEXtoA3     ; Continue to save value to -A1
DIGITtoA  ADDI.B  #$30,D3      ; Convert Digit in (D3) to ASCII for 0 to 9                  
HEXtoA3   MOVE.B  D3,-(A1)    ; Save ASCII to memory
          LSR.L   #4,D4       ; Shift right by 1 Hex digit
          TST.L   D4          ; Test value in D4
          BNE     HEXtoA2     ; Loop if there is digit left
H2A_END   MOVEM.L (A7)+,D3/D4 ; Restore registers
          RTS                 ; Return from Subroutine
          
**Convert 4 bytes in (D1) to ASCII starting at A1 - (4 BYTE)
*For the SR
HEX4toASCII: 
          MOVEM.L D2-D4,-(A7) ; Save registers
          MOVE.L  D1,D4       ; Save D1 to D4
          MOVE.L  #4,D2       ; Count of 4
HEX4toA2  MOVE.L  D4, D3      ; Duplicate value of D4
          AND.L   #$0F,D3     ; Filter all except last digit
          CMPI.B  #$A,D3      ; Determine Alphabet/Digit
          BLT     DIGIT4toA    ; Branch to subroutine DIGITtoA  
ALPHA4toA ADDI.B  #$37, D3    ; Convert Alphabets in (D3) to ASCII for A to F
          BRA     HEX4toA3    ; Continue to save value to -A1
DIGIT4toA ADDI.B  #$30,D3      ; Convert Digit in (D3) to ASCII for 0 to 9      
HEX4toA3  MOVE.B  D3,-(A1)    ; Save ASCII to memory
          LSR.L   #4,D4       ; Shift right by 1 Hex digit
          SUBI.L  #1, D2      ; Decrement D2    
          BNE     HEX4toA2    ; Loop if there is digit left
H42A_END  MOVEM.L (A7)+,D2-D4 ; Restore registers
          RTS                 ; Return from Subroutine
          
**Convert 8 bytes in (D1) to ASCII starting at A1 - (8 BYTE)
*For the 16 registers (A&D)
HEX8toASCII: 
          MOVEM.L D2-D4,-(A7) ; Save registers
          MOVE.L  D1,D4       ; Save D1 to D4
          MOVE.L  #8,D2       ; Count of 8
HEX8toA2  MOVE.L  D4, D3      ; Duplicate value of D4
          AND.L   #$0F,D3     ; Filter all except last digit
          CMPI.B  #$A,D3      ; Determine Alphabet/Digit
          BLT     DIGIT8toA    ; Branch to subroutine DIGITtoA  
ALPHA8toA ADDI.B  #$37, D3    ; Convert Alphabets in (D3) to ASCII for A to F
          BRA     HEX8toA3    ; Continue to save value to -A1
DIGIT8toA ADDI.B #$30,D3      ; Convert Digit in (D3) to ASCII for 0 to 9    
HEX8toA3  MOVE.B  D3,-(A1)    ; Save ASCII to memory
          LSR.L   #4,D4       ; Shift right by 1 Hex digit
          SUBI.L  #1, D2      ; Decerement D2    
          BNE     HEX8toA2    ; Loop if there is digit left
H82A_END  MOVEM.L (A7)+,D2-D4 ; Restore registers
          RTS                 ; Return from Subroutine 
       


             ORG $2300
* DF -- displays formatted registers
DF      LEA     DF_STACK,A7
        MOVEM.L D0-D7/A0-A6,-(A7) ; Save current REGs on stack to Display
        SUBQ.L  #4, A7
        MOVE    USP,A6      ;for use with DF command
        MOVE.L  A6,-(A7)    ;store USP to STACK
        MOVE    SR,-(A7)    ;save Status register for use with DF
        SUBQ.L  #4, A7
        ;MOVE    SS,-(A7)   ;SS = A7   

        MOVEM.L D0/D2-D3/A0-A2,-(A7) ; Save REGs
        LEA     STACK, A2   ;A2 pointing at STACK
        ADDQ.L  #4, A2      ; Go to the end of STACK for A7 value
        MOVE.L  #16, D2     ; D2 as counter for 16 registers
        MOVE.L  #0, D3      ; D3 as counter for 4 lines
        LEA     DF_MSG_END,A1   ;A1 as the end of string
        SUBQ.L  #1, A1      ; Skip Empty space, $0 
DF2     CMP.L   #4, D3      ; Calc(D3-4)
        BNE     DF3         ; If not 4 times, go to DF3
        SUBQ.L  #2, A1      ; Skip Empty space, $A,$D
        CLR.L   D3          ; Reset D3
DF3     MOVE.L  -(A2), D1   ; Save register value in D1 to be converted 
        BSR     HEX8toASCII ; Branch to convert Hex->ASCII
        ADDQ.L  #1, D3      ; Increment D3, 4 REG/Line
        SUBQ.L  #4, A1      ; Skip blank and 'REG[#]='
        SUBQ.B  #1, D2      ; Increment D2, total = 16REGs
        BNE     DF2         ; If not 12 times yet, go back to DF2
        
        *SS*
        SUBQ.L  #1, A1      ; Skip '$A$D and D0='
        MOVE.L  -(A2), D1   ; Save register value in D1 to be converted 
        BSR     HEX8toASCII ; Branch to convert Hex->ASCII
        
        *US*
        SUBQ.L  #4, A1      ; Skip blank and 'SS='
        MOVE.L  -(A2), D1   ; Save register value in D1 to be converted 
        BSR     HEX8toASCII ; Branch to convert Hex->ASCII
        
        *SR*
        SUBQ.L  #8, A1      ; Skip blanks and 'US='
        MOVE.W  -(A2), D1   ; Save register value in D1 to be converted 
        BSR     HEX4toASCII ; Branch to convert Hex->ASCII
        
        *PC*
        SUBQ.L  #4, A1      ; Skip blank and 'SR='
        MOVE.L  -(A2), D1   ; Save register value in D1 to be converted 
        BSR     HEX8toASCII ; Branch to convert Hex->ASCII
        
        LEA     DF_MSG,A1   ; Go to beginning of string
        MOVE.B  #13,D0
        TRAP    #15         ; Display all Registers
        MOVEM.L (A7)+,D0/D2-D3/A0-A2 ;Restore REGs
        RTS
        

   
 ORG    $1000
START:                  ; first instruction of program
        MOVE.L  A7,STACK    ; store original location of stack beforehand
        ;MOVE.L  A7, $2FBC
        ;LEA     $2FB6,A7
        ;PEA     *-$D         ;save PC on Stack for DF
    
        
        JSR DF
    END    START        ; last line of source



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
