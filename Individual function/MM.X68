*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000

INVALID_COM DC.B    'Invalid command',0 ; Imply user command has no match 
USER_INPUT  DS.B    90                    ; User input spaces size residing in memory
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

    ORG $2600          
*------------------------------------ Main Program ------------------------------          
***Memory Modify***        
*MM -  display memory and, as required, modify data or enter new data
* The size (B,W,L) controls the number of bytes displayed for each address.
MM:
        MOVEM.L D0-D2/A1/A5,-(A7)
        
        *Store address to MM at A5
        SUBA.L  #1, A4      ; Point to first byte of user input address 
        MOVEA.L A4,A1       ; A1 points to User Input for Writing
        MOVE.B  (A4)+,D1    ; First byte data from user input(A4 pointer)
        CMPI.B  #$24,D1     ; #$24 is '$', test if user input a valid address sign
        BNE     ERR_MM      ; INVALID Address for MM
        BSR     ASCIItoHEX_MM ; D1 has 1st address(ASCII) 
        MOVEA.L D1, A5      ; 1st HEX addr in A5 
        
        *Determine between byte(DEFAULT), word or long size
        MOVE.B  (A4)+,D1    ; Store the next byte in D1 to check size
        CMPI.B  #$00,D1     ; Check if there is any size input
        BEQ     BYTE_MM     ; Use byte size MM (DEFAULT)
        CMPI.B  #';',D1     ; Check if user input semi-colon before sorting order
        BNE     ERR_MM      ; INVALID command format for MM       
        MOVE.B  (A4),D1    ; Store the next byte in D1 to check size
        CMPI.B  #$42,D1     ; Check if it's 'B'
        BEQ     BYTE_MM     ; Use byte size MM 
        CMPI.B  #$57,D1     ; Check if it's 'W'
        BEQ     WORD_MM     ; Use word size MM
        CMPI.B  #$4C,D1     ; Check if it's 'L'
        BEQ     LONG_MM     ; Use long size MM 
        BRA     ERR_MM      ; Invalid command for MM
        
        *Display BYTE memory addressing mode
BYTE_MM LEA     END_USER_INPUT, A1  ; Empty space to store display memory and data
        MOVE.B  #$0,-(A1)   ; Null terminator
        MOVE.B  #$3F,-(A1)  ; Prompt for user input with '?'
        MOVE.B  #$20,-(A1)  ; similiar to SANPER
        CLR.L   D1          ; Clear to store byte data
        MOVE.B  (A5),D1     ; D1 has a byte data
        BSR     HEXtoASCII  ; Store the converted byte into output
        MOVE.B  #$20,-(A1)   ; 4 empty spaces
        MOVE.B  #$20,-(A1)   ; 
        MOVE.B  #$20,-(A1)   ;
        MOVE.B  #$20,-(A1)   ;
        MOVE.L  A5,D1       ; HEX addr in A5 
        BSR     HEX8toASCII ; Store ASCII addr in output
        MOVE.B  #$24,-(A1)  ; Store '$' hex addr sign in output
        MOVE.B  #14,D0      ; Display memory addr and data
        TRAP    #15           
        MOVE.B  #2,D0       ; Read input ans return to (A1)
        TRAP    #15         
        CMPI.B  #$0,(A1)    ; Check if user input(null terminated) nothing
        BNE     BYTE_MM2    ; If user input smtg, intpret input       
        ADDA.L  #1,A5       ; Point to next byte data
        BRA     BYTE_MM     ; Proceed to next byte data
        
         *Read user input and terminate/ store input data
BYTE_MM2 CMPI.B  #$2E,(A1)   ; Check if user enter '.' to terminate
         BEQ     END_MM      ; if yes, end MM
         MOVEA.L A1,A4       ; Else, point A4 to current byte data 
         BSR     ASCIItoHEX  ; convert user input into HEX
         CMPI.L  #$FF,D1     ; Check if user input more than a byte
         ;BGT     ERR_MM      
         BGT     BYTE_MM     ; If yes, prompt user again  
         MOVE.B  D1,(A5)+    ; Replace it with HEX byte user input 
         BRA     BYTE_MM     ; Proceed to next byte data

 *Display WORD memory addressing mode
WORD_MM LEA     END_USER_INPUT, A1  ; Empty space to store display memory and data
        MOVE.B  #$0,-(A1)   ; Null terminator
        MOVE.B  #$3F,-(A1)  ; Prompt for user input with '?'
        MOVE.B  #$20,-(A1)  ; similiar to SANPER
        CLR.L   D1          ; Clear to store byte data
        MOVE.W  (A5),D1     ; D1 has a WORD data
        BSR     HEXtoASCII  ; Store the converted word  into output
        MOVE.B  #$20,-(A1)   ; 4 empty spaces
        MOVE.B  #$20,-(A1)   ; 
        MOVE.B  #$20,-(A1)   ;
        MOVE.B  #$20,-(A1)   ;
        MOVE.L  A5,D1       ; HEX addr in A5 
        BSR     HEX8toASCII ; Store ASCII addr in output
        MOVE.B  #$24,-(A1)  ; Store '$' hex addr sign in output
        MOVE.B  #14,D0      ; Display memory addr and data
        TRAP    #15           
        MOVE.B  #2,D0       ; Read input ans return to (A1)
        TRAP    #15         
        CMPI.B  #$0,(A1)    ; Check if user input(null terminated) nothing
        BNE     WORD_MM2    ; If user input smtg, intepret input       
        ADDA.L  #2,A5       ; Point to next word data
        BRA     WORD_MM     ; Proceed to next word  data
        
         *Read user input and terminate/ store input data
WORD_MM2 CMPI.B  #$2E,(A1)   ; Check if user enter '.' to terminate
         BEQ     END_MM      ; if yes, end MM
         MOVEA.L A1,A4       ; Else, point A4 to current byte data 
         BSR     ASCIItoHEX  ; convert user input into HEX
         CMPI.L  #$FFFF,D1   ; Check if user input more than a word   
         BGT     WORD_MM     ; If yes, prompt user again  
         MOVE.W  D1,(A5)+    ; Replace it with HEX word user input 
         BRA     WORD_MM     ; Proceed to next word data

*Display LONG memory addressing mode
LONG_MM LEA     END_USER_INPUT, A1  ; Empty space to store display memory and data
        MOVE.B  #$0,-(A1)   ; Null terminator
        MOVE.B  #$3F,-(A1)  ; Prompt for user input with '?'
        MOVE.B  #$20,-(A1)  ; similiar to SANPER
        MOVE.L  (A5),D1     ; D1 has a LONG data
        BSR     HEXtoASCII  ; Store the converted long into output
        MOVE.B  #$20,-(A1)   ; 4 empty spaces
        MOVE.B  #$20,-(A1)   ; 
        MOVE.B  #$20,-(A1)   ;
        MOVE.B  #$20,-(A1)   ;
        MOVE.L  A5,D1       ; HEX addr in A5 
        BSR     HEX8toASCII ; Store ASCII addr in output
        MOVE.B  #$24,-(A1)  ; Store '$' hex addr sign in output
        MOVE.B  #14,D0      ; Display memory addr and data
        TRAP    #15           
        MOVE.B  #2,D0       ; Read input ans return to (A1)
        TRAP    #15         
        CMPI.B  #$0,(A1)    ; Check if user input(null terminated) nothing
        BNE     LONG_MM2    ; If user input smtg, interpret input       
        ADDA.L  #4,A5       ; Point to next LONGd data
        BRA     LONG_MM     ; Proceed to next LONG data
        
         *Read user input and terminate/ store input data
LONG_MM2 CMPI.B  #$2E,(A1)   ; Check if user enter '.' to terminate
         BEQ     END_MM      ; if yes, end MM
         MOVEA.L A1,A4       ; Else, point A4 to current LONG data 
         BSR     ASCtoHEX_MM  ; convert user input into HEX
        
         ;MOVE.L  #$FFFFFFFF,D2 ; To be used for checking user input   
         ;CMP.L   D1,D2       ; Check if user input more than a long   
         ;BGT     LONG_MM     ; If yes, prompt user again 
         
         MOVE.L  D1,(A5)+    ; Replace it with HEX LONG user input 
         BRA     LONG_MM     ; Proceed to next LONG data

ERR_MM  JSR    CMD_INVALID        ; Go to invalid command subroutine
END_MM  MOVEM.L (A7)+,D0-D2/A1/A5 ; Restore REGs
        RTS      

***ASCII to HEX for MM***
*Convert ASCII in (A4) to HEX in (D1)
*Prompt user again if if user input more than a long 
ASCtoHEX_MM:
        MOVEM.L D3,-(A7)     ; Save register
        CLR.L   D1           ; Clear register
        CLR.L   D3
        CLR.L   D2           ; count 8 times
        MOVE.B  (A4)+,D3     ; Save a byte from A4 to D3
        CMPI.B  #$30,D3      ; Check if it is ASCII
        BLT     AM2H_END     ; Done if there isn't ASCII
AMtoHEX2 BSR     ALPHAorDIGIT ; Determine alpha/digit
AMtoHEX3 CMPI.L  #8,D2       ; Check if user input more than a long   
        BEQ     LONG_MM      ; prompt user again 
        ADD.B   D3,D1        ; Store converted HEX in D1
        MOVE.B  (A4)+,D3     ; Save a byte from A4 to D3
        CMPI.B  #$30,D3      ; Check if it is ASCII
        BLT     AM2H_END     ; Done if there isn't ASCII
        ASL.L   #4,D1        ; Shift left to store more HEX
        ADDQ.B  #1,D2        ; Count the amount of HEX
        BRA     AMtoHEX2     ; LOOP the conversion
AM2H_END SUBA.L  #1,A4       ; leave A6 pointing at byte immediately after last number
        MOVEM.L (A7)+,D3     ; restore registers
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
;TEST1 DC.B    '$2400',0 ; Store testcase in input space
;TEST1 DC.B    '$2400;B',0 ; Store testcase in input space
;TEST1 DC.B    '$2400;W',0 ; Store testcase in input space
TEST1 DC.B    '$2400;L',0 ; Store testcase in input space


STACK   EQU $2FFC       ; A7 will be stored at $3000 - $4

    ORG $2400
TEST1A   DC.B    '0000000100000002',0

    ORG $2000
START:                  ; first instruction of program
    MOVEA.L #$2301, A4
    BRA     MM 
    ;MOVEA.L #$2601, A4
    ;BRA     MDSP   
    END    START        ; last line of source



















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
