*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000

INVALID_COM DC.B    'Invalid command',0 ; Imply user command has no match  
ERR_ADDR    DC.B   'Memory problems found: $00000000'
E_ERR_ADDR  DC.B   $A,$D 
DTSTORE     DC.B   'The data stored: 00'
E_DTSTORE   DC.B   $A,$D
DTREAD      DC.B   'The data read: 00'
E_DTREAD    DC.B   0 

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

***Block Search***        
*BSCH -  search a literal string from <address1> through <address2> both inclusive
*BSCH <Adr1> <Adr2> "literal string"
* If Found,  the data and address(es) must be displayed. 
BSCH_FAIL_MSG        DC.B 'String not found',0
BSCH_FOUND_MSG       DC.B 'String found at $00000000'
END_BSCH_FOUND       DC.B 0         ; To be use by ASCIItoHEX subroutine
   
BSCH:   
        MOVEM.L D1/A1,-(A7)
        LEA     BSCH_FAIL_MSG ,A1 ; will change if found
        
        SUBA.L  #1, A4       ; Point to first byte of user input address 
        MOVE.B  (A4)+,D1     ; First byte data from user input(A4 pointer)
        CMPI.B  #$24,D1      ; #$24 is '$', test if user input a valid address sign
        BNE     ERR_BSCH     ; INVALID Address for BSCH
        BSR     ASCIItoHEX   ; D1 has 1st address(ASCII)  
        MOVEA.L D1,A5        ; 1st HEX addr in A5  
        MOVE.B  (A4)+,D1     ; Store the next byte in D1 to check blank space
        CMPI.B  #$20,D1      ; Check if user input blank space before Next address
        BNE     ERR_BSCH     ; INVALID Command format for BMOV       
        MOVE.B  (A4)+,D1     ; One byte data from user input(A4 pointer)
        CMPI.B  #$24,D1      ; #$24 is '$', test if user input a valid address sign
        BNE     ERR_BSCH     ; INVALID Address for BSCH
        BSR     ASCIItoHEX   ; D1 has 2nd address(ASCII)         
        MOVEA.L D1,A6        ; 2nd HEX addr in A6  
        MOVE.B  (A4)+,D1     ; Store the next byte in D1 to check blank space
        CMPI.B  #$20,D1      ; Check if user input blank space before Next address
        BNE     ERR_BSCH     ; INVALID Command format for BMOV
       
LOOPBSCH CMPA.L  A5,A6        ; Compare if A5 is at A6 (A6-A5), 
                              ; Compare first, incase user input same addresses
        BEQ     MSG_BSCH      ; Quit loop of A5 is at A6
        MOVEA.L A4, A2        ; A2 point to user input
        CMP.B   (A5)+,(A2)+   ; Compare one byte of character
        BNE     LOOPBSCH      ; Keep looping if doesnt equal
        MOVE.L  A5,A3         ; Save my A5 in A3, if found A5 will point to the String

BSCH2   CMPI.B  #0,(A2)       ; Check if string ended
        BEQ     BSCH_FOUND    ; If ended, same string found
        CMP.B   (A3)+,(A2)+   ; Compare one byte of character
        BNE     LOOPBSCH      ; IF not equal, check next literal string
        BRA     BSCH2         ; else, compare the next character

ERR_BSCH   BSR     CMD_INVALID
           BRA     END_BSCH
            
BSCH_FOUND SUBA.L  #1,A5      ; Point to the first character of string found
           MOVE.L  A5,D1      ; Point to the first character of string found
           LEA     END_BSCH_FOUND,A1    ; Point to the end end of found addr msg
           BSR     HEX8toASCII          ; Change to the address found
           LEA     BSCH_FOUND_MSG,A1
MSG_BSCH   MOVE.B  #13,D0               ; Print end result message
           TRAP    #15     
END_BSCH   MOVEM.L (A7)+,D1/A1
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
    ORG $2000
START:                  ; first instruction of program
    MOVEA.L #$2301, A4
    BSR      BSCH 
       
    END    START        ; last line of source









*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
