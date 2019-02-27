*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
 ORG $1100
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
    
***3 Decimal to Hexadecimal***
*D2H - Convert up to 3 digits decimal number into hexadecimal number
*E.G: D2H 123 , number limit is 255
D2H_MSG DC.B    'The HEXADECIMAL = 000'
END_D2H_MSG DC.B '',0   
  
D2H:
    MOVEM.L  D2-D5/A1,-(A7) ; Save registers
    SUBA.L  #1, A4          ; Point to first byte of user input address 
    CLR.L   D1              ; To be used for storing data 
    CLR.L   D3              ; Empty D3 incase of 0 value
    CLR.L   D4              ; Empty D4 incase of less than 3 digits 
    CLR.L   D5              ; Empty D5 incase of less than 3 digits
    
    *Check 1st number
    MOVE.B  (A4)+,D1    ; First byte data from user input(A4 pointer)
    CMPI.B  #$00,D1     ; #$00 Check if there's a number
    BEQ     ERR_D2H     ; Invalid data to be convert
    MOVE.L  D1,D3       ; 1st number in D3 (ASCII)
    SUBI.B  #$30,D3     ; 1st number in D3 (DEC)
    
    *Check 2nd number
    MOVE.B  (A4)+,D1    ; Second byte data from user input(A4 pointer)
    CMPI.B  #$00,D1     ; #$00  Check if there's a number
    BEQ     ONE_D2H     ; If no, go to one digits decimal function
    MOVE.L  D1,D4       ; 2nd number in D4 (ASCII)
    SUBI.B  #$30,D4     ; 2nd number in D4 (DEC)

    *Check 3rd number
    MOVE.B  (A4)+,D1    ; First byte data from user input(A4 pointer)
    CMPI.B  #$00,D1     ; #$00  Check if there's a number
    BEQ     TWO_D2H     ; If no, go to two digits decimal function
    MOVE.B  (A4)+,D2    ; Check if it's only 3 digits
    CMPI.B  #$00,D2     ; 
    BNE     ERR_D2H     ; If not, return error
    MOVE.L  D1,D5       ; 3rd number in D5 (ASCII)
    SUBI.B  #$30,D5     ; 3rd number in D5 (DEC)
    BRA     D2H2

ONE_D2H MOVE.L  D3,D5   ; Place the only digit at 1's
        CLR.L D3        ; Empty D3 because only 1 digit
        BRA     D2H2    ; Go to Dec to Hex conversion

TWO_D2H MOVE.L  D4,D5   ; Place the 2nd digit at 1's
        MOVE.L  D3,D4   ; Place the 1st digit at 10's
        CLR.L D3        ; Empty D3 because only 1 digit
        BRA     D2H2    ; Go to Dec to Hex conversion

*Convert DEC to HEX and store after output string
D2H2: 
    MULU    #$64, D3        ; 1st digit * 100    
    MULU    #$0A, D4        ; 2nd digit * 10
    ADD.W   D3,D4           ; Sums up 3 digits
    ADD.W   D4,D5 
    CMPI.L  #255,D5
    BGT     ERR_D2H     
    LEA     END_D2H_MSG,A1  ; To save converted HEX after output
    CLR.L   D3
    MOVE.W  D5,D3           ; Save a copy of D5 to be reuse
    ANDI.W  #$0F00,D3       ; To obtain first hex value
    LSR.W   #8, D3          ; Make other byte 0, and shift it to lowest byte -> D3
    CLR.L   D4
    MOVE.W  D5,D4
    ANDI.W  #$00F0,D4       ; To obtain second hex value
    LSR.W   #4, D4          ; Make other byte 0, and shift it to lowest byte -> D3
    ANDI.B  #$0F, D5        ; To obtain last hex value       
    MOVE.L  D5,D1           ; Store 1's HEX value to be displayed
    BSR     HEXtoASCII
    MOVE.L  D4,D1           ; Store 10's HEX value to be displayed
    BSR     HEXtoASCII     
    MOVE.L  D3,D1           ; Store 100's HEX value to be displayed
    BSR     HEXtoASCII     
PRINT   LEA     D2H_MSG,A1  ; Go to beginning of string
        MOVE.B  #13,D0
        TRAP    #15         ; Display converted HEX
        BRA     END_D2H
    
ERR_D2H     JSR    CMD_INVALID  ; Go to invalid command subroutine    
END_D2H:    
    MOVEM.L (A7)+,D2-D5/A1 ;Restore REGs
    RTS

*Prompt user when command is invalid
CMD_INVALID:
       MOVEM.L D0/A1, -(A7)    ; Save REGs
       LEA     INVALID_COM, A1 ; Display error message
       MOVE.B  #13,D0
       TRAP    #15
       MOVEM.L (A7)+,D0/A1     ; Restore REGs
       RTS
       
    ORG    $2300
;TEST1 DC.B    '$2400 $2408 ;A',0 ; Store testcase in input space
;TEST1 DC.B    '$2400 $2408 ;D',0 ; Store testcase in input space
;TEST1 DC.B    '123',0 ; Store testcase in input space
TEST1 DC.B    '10',0 ; Store testcase in input space    
    ORG    $1000
INVALID_COM DC.B    'Invalid command',0 ; Imply user command has no match 

START:                  ; first instruction of program

    MOVEA.L #$2301, A4
    BRA     D2H 
       END    START        ; last line of source







*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
