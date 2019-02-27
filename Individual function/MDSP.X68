*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000

INVALID_COM DC.B    'Invalid command',0 ; Imply user command has no match 

     
    ORG $1100
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

***HEX to ASCII***
*Convert HEX in (D1) to ASCII starting at A1 - (# of digits * BYTE)
HEXtoASCII: 
          MOVEM.L D3/D4,-(A7) ; Save registers
          MOVE.L  D1, D4      ; Save D1 to D4
HEXtoA2   MOVE.L  D4, D3      ; Duplicate value of D4
          AND.L   #$0F,D3     ; Filter all except last digit
          CMPI.B  #$A,D3      ; Determine Alphabet/Digit
          BLT     DIGITtoA    ; Branch to subroutine DIGITtoA  
ALPHAtoA  ADDI.B  #$37, D3    ; Convert Alphabets in (D3) to ASCII for A to F
          BRA     HEXtoA3     ; Continue to save value to -A1
DIGITtoA  ADDI.B  #$30,D3     ; Convert Digit in (D3) to ASCII for 0 to 9                  
HEXtoA3   MOVE.B  D3,-(A1)    ; Save ASCII to memory
          LSR.L   #4,D4       ; Shift right by 1 Hex digit
          TST.L   D4          ; Test value in D4
          BNE     HEXtoA2     ; Loop if there is digit left
H2A_END   MOVEM.L (A7)+,D3/D4 ; Restore registers
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
          
**Convert 2 HEX characters in (D1) to ASCII starting at A1 - (4 BYTE)
*For the SR
HEX2toASCII: 
          MOVEM.L D2-D4,-(A7) ; Save registers
          MOVE.L  D1,D4       ; Save D1 to D4
          MOVE.L  #2,D2       ; Count of 4
HEX2toA2  MOVE.L  D4, D3      ; Duplicate value of D4
          AND.L   #$0F,D3     ; Filter all except last digit
          CMPI.B  #$A,D3      ; Determine Alphabet/Digit
          BLT     DIGIT2toA   ; Branch to subroutine DIGITtoA  
ALPHA2toA ADDI.B  #$37, D3    ; Convert Alphabets in (D3) to ASCII for A to F
          BRA     HEX2toA3    ; Continue to save value to -A1
DIGIT2toA ADDI.B  #$30,D3     ; Convert Digit in (D3) to ASCII for 0 to 9      
HEX2toA3  MOVE.B  D3,-(A1)    ; Save ASCII to memory
          LSR.L   #4,D4       ; Shift right by 1 Hex digit
          SUBI.L  #1, D2      ; Decrement D2    
          BNE     HEX2toA2    ; Loop if there is digit left
H22A_END  MOVEM.L (A7)+,D2-D4 ; Restore registers
          RTS                 ; Return from Subroutine
          
***Memory Display***        
*MDSP - outputs the address and memory contents <address1> to <address2>
*Default: outputs the address and memory contents <address1> to <address1 + 16bytes>
MDSP:
       MOVEM.L D0/A1/A5-A6,-(A7)     
       *Store addr1 in A5
       SUBA.L  #1, A4       ; Point to first byte of user input address 
       MOVE.B  (A4)+,D1     ; First byte data from user input(A4 pointer)
       CMPI.B  #$24,D1      ; #$24 is '$', test if user input a valid address sign
       BNE     ERR_MDSP     ; INVALID Address for BTST
       BSR     ASCIItoHEX   ; D1 has 1st address(ASCII) 
       MOVEA.L D1, A5       ; 1st HEX addr in A5 
       
       *Check If there's a second address, if yes, store addr2 in A6
       MOVE.B  (A4)+,D1     ; Store the next byte in D1 to check blank space
       CMPI.B  #$20,D1      ; Check if user input blank space before Next address
       BNE     NO_ADDR2     ; INVALID Command format for BTST  
       MOVE.B  (A4)+,D1     ; One byte data from user input(A4 pointer)
       CMPI.B  #$24,D1      ; #$24 is '$', test if user input a valid address sign
       BNE     ERR_MDSP     ; INVALID Address for BTST
       BSR     ASCIItoHEX   ; D1 has 2nd address(ASCII)         
       MOVEA.L D1,A6        ; 2nd HEX addr in A6 
       BRA     MDSP2
       
         *If no input addr2, addr2 = addr1 + 16 bytes
NO_ADDR2 MOVEA.L A5,A6      ; make a copy of addr1
         ADDA.L  #15,A6     ; Add 15 more bytes to addr1(first byte is counted)
       *Outputs the address and memory contents from A5 to A6
MDSP2  CMPA.L  A5, A6       ; Compare if A5 is at A6 (A6-A5), 
       BLT     END_MDSP     ; If A5 is at A6, go to to next loop
       LEA     STACK, A1    ; Use STACK to store byte tobe printed out
       SUBA.L  #$50,A1      ; Skip spaces to prevent stack overflow
       MOVE.B  #$00,-(A1)   ; Null terminator
       CLR.L   D1           ; Clear to store byte data
       MOVE.B  (A5), D1     ; Memory content to be converted
       BSR     HEX2toASCII 
       MOVE.B  #$20,-(A1)   ; Blank space
       MOVE.B  #$20,-(A1)   ; Blank space 
       MOVE.W  A5, D1       ; Address to be converted
       BSR     HEXtoASCII  ; Convert Address to ASCII
       MOVE.B  #13,D0       ; Display the address and memory contents
       TRAP    #15             
       ADDQ.L  #1, A5       ; Go to next byte addr 
       BRA     MDSP2        ; Continue Loop
       
ERR_MDSP JSR    CMD_INVALID  ; Go to invalid command subroutine       
END_MDSP MOVEM.L (A7)+,D0/A1/A5-A6 ;Restore used Register
         RTS
         
*Prompt user when command is invalid
CMD_INVALID:
       MOVEM.L D0/A1, -(A7)    ; Save REGs
       LEA     INVALID_COM, A1 ; Display error message
       MOVE.B  #13,D0
       TRAP    #15
       MOVEM.L (A7)+,D0/A1     ; Restore REGs
       RTS
     
* Put variables and constants here
    ORG    $2300
TEST1 DC.B    '$2400 $240A ',0 ; Store testcase in input space
STACK   EQU $2FFC       ; A7 will be stored at $3000 - $4
    ORG    $2600
TEST2 DC.B    '$2500',0 ; Store testcase in input space

    ORG $2400
TEST1A   DC.B    'ABCDEFGH',0
    ORG $2500
TEST2A   DC.B    '0001ABC4GHCCCCCC',0

    ORG $2000
START:                  ; first instruction of program
    ;MOVEA.L #$2301, A4
    ;BRA     MDSP 
    MOVEA.L #$2601, A4
    BRA     MDSP   
    END    START        ; last line of source














*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
