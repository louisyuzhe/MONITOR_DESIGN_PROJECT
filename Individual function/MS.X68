*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000

INVALID_COM DC.B    'Invalid command',0 ; Imply user command has no match 
USER_INPUT  DS.B    80                    ; User input spaces size residing in memory
END_USER_INPUT DC.B 0
     
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
 
*Convert ASCII in (A4) to HEX in (D1) for MM, ends when detected ';'
ASCIItoHEX_MM:
           MOVEM.L D3,-(A7)     ; Save register
           CLR.L   D1           ; Clear register
           CLR.L   D3
           MOVE.B  (A4)+,D3     ; Save a byte from A4 to D3
           CMPI.B  #$30,D3      ; Check if it is ASCII
           BLT     A2H_END_MM   ; Done if there isn't ASCII
AtoHEX2_MM BSR     ALPHAorDIGIT ; Determine alpha/digit
AtoHEX3_MM ADD.B   D3,D1        ; Store converted HEX in D1
           MOVE.B  (A4)+,D3     ; Save a byte from A4 to D3
           CMPI.B  #';',D3      ; Check if it is ';'
           BEQ     A2H_END_MM   ; Done if it meets ';'
           CMPI.B  #$30,D3      ; Check if it is ASCII
           BLT     A2H_END_MM   ; Done if there isn't ASCII
           ASL.L   #4,D1        ; Shift left to store more HEX
           BRA     AtoHEX2_MM   ; LOOP the conversion
A2H_END_MM SUBA.L  #1,A4        ; leave A6 pointing at byte immediately after last number
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
          
*------------------------------------ Main Program ------------------------------          
***Memory Set***        
*MS -  alters memory by setting data into the address specified
* Data can take the form of ASCII string or hexadecimal data. 
* Input> long, only last long size data will be stored 
 
MS:
        MOVEM.L D1/A5,-(A7)
        
        *Store address at A5
        SUBA.L  #1, A4      ; Point to first byte of user input address 
        MOVEA.L A4,A5       ; A1 points to User Input for Writing
        MOVE.B  (A4)+,D1    ; First byte data from user input(A4 pointer)
        CMPI.B  #$24,D1     ; #$24 is '$', test if user input a valid address sign
        BNE     ERR_MS      ; INVALID Address for MS
        BSR     ASCIItoHEX  ; D1 has 1st address(ASCII) 
        MOVEA.L D1, A5      ; 1st HEX addr in A5 
        MOVE.B  (A4)+,D1    ; Store the next byte in D1 to check blank space
        CMPI.B  #$20,D1     ; Check if user input blank space before data
        BNE     ERR_MS      ; INVALID Command format for MS 
        
        *Determine if it is empty, ASCII or HEX
CHK_MS  MOVE.B  (A4)+,D1    ; Store the next byte in D1 to check HEX sign
        CMPI.B  #$00,D1     ; Check if nothing is input
        BEQ     END_MS      ; If yes, Run MS as HEX
        CMPI.B  #$24,D1     ; #$24 is '$', test if user input hex value
        BEQ     HEX_MS      ; If yes, Run MS as HEX
        SUBA.L  #1,A4       ; Else, point to the beginning of string

ASC_MS  MOVE.B  (A4)+,(A5)+ ; Store one byte of data from input to memory
        CMPI.B  #0,(A4)     ; check if end and increment A4 to match A5
        BEQ     END_MS      ; If yes, end the memory setting
        BRA     ASC_MS      ; Else, keep looping
        
HEX_MS  BSR     ASCIItoHEX  ; D1 has input value (HEX)
        CMPI.L  #$FFFF,D1   ; D1 - $FFFF
        BHI     LONG_MS     ; If ans > 0, its a long
        CMPI.L  #$FF,D1     ; Else, try D1 - $FFFF
        BHI     WORD_MS     ; If ans > 0, its a word

*Store byte size data into (A5)        
BYTE_MS MOVE.B  D1,(A5)    ; Store a byte value
        BRA     CHK_MS      ; End memory setting  

*Store word size data into (A5) 
WORD_MS ADDA.L  #2,A5       ; Skips a word size to save a word data
        MOVE.W  D1,-(A5)    ; Store a word value
        BRA     CHK_MS      ; End memory setting  

*Store long size data into (A5) 
LONG_MS ADDA.L  #4,A5       ; Skips a long size to save a long data
        MOVE.L  D1,-(A5)    ; Store a long value
        BRA     CHK_MS      ; End memory setting  

ERR_MS  JSR    CMD_INVALID  ; Go to invalid command subroutine
END_MS  MOVEM.L (A7)+,D1/A5 ; Restore REGs
        RTS      


*-----------------------------------Default----------------------------------       
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
;TEST1 DC.B    '$2400 ABCDEF',0 ; Store testcase in input space;
TEST1 DC.B    '$2400 HELLO WORLD',0 ; Store testcase in input space;
;TEST1 DC.B    '$2400 $12',0 ; Test Hex byte
;TEST1 DC.B    '$2400 $1234',0 ;  Test Hex word
;TEST1 DC.B    '$2400 $12345678',0 ;  Test Hex long
;TEST1 DC.B    '$2400 $1234567891',0 ;  Test more than hex long (long + byte)

STACK   EQU $2FFC       ; A7 will be stored at $3000 - $4

    ORG $2400
TEST1A   DC.B    '0501040203',0

    ORG $2000
START:                  ; first instruction of program
    MOVEA.L #$2301, A4
    BRA     MS 
    ;MOVEA.L #$2601, A4
    ;BRA     MDSP   
    END    START        ; last line of source

















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
