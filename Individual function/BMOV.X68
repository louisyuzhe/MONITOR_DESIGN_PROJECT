*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000

INVALID_COM DC.B    'Invalid command',0 ; Imply user command has no match   
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


***Block Move***        
*BMOV -  Moves A Block Of Memory To Another Area
*BMOV <Addr1> <Addr2> <Addr3> eg: BMOV $ $ $<CR>
*Loop is not need for only 3 addr as the ' ' between addr have to be taken account
BMOV:   
         MOVEM.L D1/A2/A5-A6,-(A7)
         z`    
        
         *Store 1st address in A5 and skip the blank space after it
         MOVE.B  (A4)+,D1     ; First byte data from user input(A4 pointer)
         CMPI.B  #$24,D1      ; #$24 is '$', test if user input a valid address sign
         BNE     ERR_BMOV     ; INVALID Address for BMOV
         BSR     ASCIItoHEX   ; D1 has 1st address(ASCII) to be converted
         MOVEA.L D1,A5        ; 1st HEX addr in A5  
         MOVE.B  (A4)+,D1     ; Store the next byte in D1 to check blank space
         CMPI.B  #$20,D1      ; Check if user input blank space before Next address
         BNE     ERR_BMOV     ; INVALID Command format for BMOV
        
         *Store 2nd address in A6 and skip the blank space after it
         MOVE.B  (A4)+,D1     ; another byte data from user input(A4 pointer)
         CMPI.B  #$24,D1      ; #$24 is '$', test if user input a valid address sign
         BNE     ERR_BMOV     ; INVALID Address for BMOV
         BSR     ASCIItoHEX   ; D1 has 2nd address(ASCII) to be converted
         MOVE.L  D1,A6        ; 2nd HEX addr in A6      
         MOVE.B  (A4)+,D1     ; Store the next byte in D1 to check blank space
         CMPI.B  #$20,D1      ; Check if user input blank space before Next address
         BNE     ERR_BMOV     ; INVALID Command format for BMOV
     
         *Store 3rd address in A2
         MOVE.B  (A4)+,D1     ; another byte data from user input(A4 pointer)
         CMPI.B  #$24,D1      ; #$24 is '$', test if user input a valid address sign
         BNE     ERR_BMOV     ; INVALID Address for BMOV
         BSR     ASCIItoHEX   ; D1 has 2nd address(ASCII) to be converted
         MOVE.L  D1,A2        ; 2nd HEX addr in A2

LOOPBMOV CMPA.L  A5,A6        ; Compare if A5 is at A6 (A6-A5), 
                              ; Compare first, incase user input same addresses
         BLE     END_BMOV     ; If not, keep looping
         MOVE.B  (A5)+,(A2)+  ; Moves A Block Of Memory, (A5) To (A2)
         BRA     LOOPBMOV        
ERR_BMOV BSR     CMD_INVALID ; Display invalid command error msg    
END_BMOV MOVEM.L (A7)+,D1/A2/A5-A6
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
    BSR      BMOV 
       
    END    START        ; last line of source






*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
