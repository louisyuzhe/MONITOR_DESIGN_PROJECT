*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000

INVALID_COM DC.B    'Invalid command',0 ; Imply user command has no match 
     
    ORG $1200
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
          
***Block Test***        
*BTST -  test memory from  <address1> to <address2>
* If completed w/o errors, display no error msg
* Else display error msg w/ address, the data stored & the data read of the failing memory.  
   
    
*No error msg    
BTST_NO_ERR DC.B   'No Error Was Detected',0    

*Error MSg indicating the address, the data stored and the data read of the failing memory. 
ERR_ADDR    DC.B   'Memory problems found: $00000000'
E_ERR_ADDR  DC.B   $A,$D 
DTSTORE     DC.B   'The data stored: 00'
E_DTSTORE   DC.B   $A,$D
DTREAD      DC.B   'The data read: 00'
E_DTREAD    DC.B   0
    ORG $1400
BTST:   
       MOVEM.L D0-D1/A1-A2/A5-A6,-(A7)
       *Obtain and store addr1 and addr2 in A5,A2 and A6 respectively
       SUBA.L  #1, A4       ; Point to first byte of user input address 
       MOVE.B  (A4)+,D1     ; First byte data from user input(A4 pointer)
       CMPI.B  #$24,D1      ; #$24 is '$', test if user input a valid address sign
       BNE     ERR_BTST     ; INVALID Address for BTST
       BSR     ASCIItoHEX   ; D1 has 1st address(ASCII)  
       MOVEA.L D1,A5        ; 1st HEX addr in A5 
       MOVEA.L D1,A2        ; 1st HEX addr in A2 (For testing $55)
       MOVE.B  (A4)+,D1     ; Store the next byte in D1 to check blank space
       CMPI.B  #$20,D1      ; Check if user input blank space before Next address
       BNE     ERR_BTST     ; INVALID Command format for BTST       
       MOVE.B  (A4)+,D1     ; One byte data from user input(A4 pointer)
       CMPI.B  #$24,D1      ; #$24 is '$', test if user input a valid address sign
       BNE     ERR_BTST     ; INVALID Address for BTST
       BSR     ASCIItoHEX   ; D1 has 2nd address(ASCII)         
       MOVEA.L D1,A6        ; 2nd HEX addr in A6 
             
       *Fill all of the memory to be tested with $AA, then run read operation
        CLR.L   D1          ; Clear D1 for storing byte data from memory
LOOP_BTST1:                 
        CMPA.L  A5,A6         ; Compare if A5 is at A6 (A6-A5), 
                              ; Compare first, incase user input same addresses
        BLE     BTST2         ; If A5 is at A6, go to to next loop
        MOVE.B  #$AA,(A5)     ; Fill each byte of memory with $55
        MOVE.B  (A5)+,D1      ; Read the byte of memory
        CMPI.B  #$AA,D1       ; Check if the contents is be $AA. 
        BEQ     LOOP_BTST1    ; If correct, continue loop for next byte
        
        *Display failing msg with address, data stored, data read of the failing memory.  
        LEA     E_DTREAD,A1   ; Else,contents not $AA, problem in memory block
        BSR     HEXtoASCII    ; Convert data byte(HEX) read in mem and store it
        LEA     E_DTSTORE, A1 ; Store what system suppose to read
        MOVE.B  #$41, -(A1)   ; Store ASCII 'A'
        MOVE.B  #$41, -(A1)   ; Store ASCII 'A'     
        LEA     E_ERR_ADDR,A1 ; Store address of memory problem found     
        SUBA.L  #1, A5        ; Point to the error byte in memory location
        MOVE.L  A5, D1        ; D1 now has the problem memory addr        
        BSR     HEX8toASCII   ; Convert error addr into ASCII 
        LEA     ERR_ADDR ,A1  ; Display complete BTST error msg    
        MOVE.B  #13, D0         
        TRAP    #15     
        BRA     END_BTST      ; Go to the end of BTST

        *Fill all of the memory to be tested with $55, then run read operation
BTST2   MOVEA.L A2, A5        ; Restore A5 initial value
        CLR.L   D1            ; Clear D1 for storing byte data from memory
LOOP_BTST2:                 
        CMPA.L  A5,A6         ; Compare if A5 is at A6 (A6-A5), 
        BLE     NoErr_BTST      ; If A5 is at A6, go to to next loop
        MOVE.B  #$55,(A5)     ; Fill each byte of memory with $55
        MOVE.B  (A5)+,D1      ; Read the byte of memory
        CMPI.B  #$55,D1       ; Check if the contents is be $AA. 
        BEQ     LOOP_BTST2    ; If correct, continue loop for next byte
        
        * Fill up all the error messages detail and display
        LEA     E_DTREAD,A1   ; Else,contents not $AA, problem in memory block
        BSR     HEXtoASCII    ; Convert data byte(HEX) read in mem and store it
        LEA     E_DTSTORE, A1 ; Store what system suppose to read
        MOVE.B  #$35, -(A1)   ; Store ASCII '5'
        MOVE.B  #$35, -(A1)   ; Store ASCII '5'     
        LEA     E_ERR_ADDR,A1 ; Store address of memory problem found     
        SUBA.L  #1, A5        ; Point to the error byte in memory location
        MOVE.L  A5, D1        ; D1 now has the problem memory addr        
        BSR     HEX8toASCII   ; Convert error addr into ASCII 
        LEA     ERR_ADDR ,A1  ; Display complete BTST error msg    
        MOVE.B  #13, D0         
        TRAP    #15     
        BRA     END_BTST       ; Go to the end of BTST
ERR_BTST   BSR    CMD_INVALID  ; Go to invalid command subroutine
           BRA    END_BTST     ; End the subroutine     
NoErr_BTST LEA  BTST_NO_ERR,A1 ; Display no error found msg
           MOVE.B  #13, D0         
           TRAP    #15 
END_BTST   MOVEM.L (A7)+,D0-D1/A1-A2/A5-A6 ;Restore used Register
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
TEST DC.B    '$2400 $240A ',0 ; Store testcase in input space

    ORG $2000
START:                  ; first instruction of program
    MOVEA.L #$2301, A4
    BRA     BTST 
       
    END    START        ; last line of source













*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
