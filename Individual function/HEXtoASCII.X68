*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
**Convert HEX in (D1) to ASCII starting at A1 - (# of digits * BYTE)
HEXtoASCII: 
          MOVEM.L D3/D4,-(A7) ; Save registers
          MOVE.L  D1,D4       ; Save D1 to D4
HEXtoA2   MOVE.L  D4, D3      ; Duplicate value of D4
          AND.L   #$0F,D3     ; Filter all except last digit
          CMPI.B  #$A,D3      ; Determine Alphabet/Digit
          BLT     DIGITtoA    ; Branch to subroutine DIGITtoA  
ALPHAtoA  ADDI.B  #$37, D3    ; Convert Alphabets in (D3) to ASCII for A to F
          BRA     HEXtoA3     ; Continue to save value to -A1
DIGITtoA  ADDI.B #$30,D3      ; Convert Digit in (D3) to ASCII for 0 to 9                  
HEXtoA3   MOVE.B  D3,-(A1)    ; Save ASCII to memory
          LSR.L   #4,D4       ; Shift right by 1 Hex digit
          TST.L   D4          ; Test value in D4
          BNE     HEXtoA2     ; Loop if there is digit left
H2A_END   MOVEM.L (A7)+,D3/D4 ; Restore registers
          RTS                 ; Return from Subroutine

      ORG    $2000
START:                  ; first instruction of program
MAX_IN_LEN  EQU 80  ; to ensure input won't overflow stack
STACK       EQU $2FFC   ; $3000 minus a long word because A7 will be stored first
        MOVE.L  A7,STACK    ; store original location of stack beforehand
        LEA     STACK,A7
        MOVEM.L D0-D7/A0-A6,-(A7)   ; store all registers in stack. Want to be able to restore them
    
    MOVE.L  #$4000,A1
;    MOVE.L  #$123456, D1
    BRA HEXtoASCII


* Put variables and constants here
    END    START        ; last line of source




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
