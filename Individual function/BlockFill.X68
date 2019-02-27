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

    ORG $1200
***Block Fill***        
*BF - fills memory starting with the word boundary <address1> through <address2>
BF:     
      MOVEM.L D1/D3/D4/D6/A1/A5-A6,-(A7)
      SUBA.L  #1, A4       ; Point to first byte of user input address        
      MOVE.B  (A4)+,D1     ; First byte data from user input(A4 pointer)
      CMPI.B  #$24,D1      ; #$24 is '$', test if user input a valid address sign
      BNE     ERR_BF       ; INVALID Address for BF
      BSR     ASCIItoHEX   ; D1 has 1st address(ASCII) to be converted
      MOVEA.L D1,A5        ; 1st Address(HEX) stored in A5
      MOVE.B  (A4)+,D1     ; Blank space before next $address
      CMPI.B  #$20,D1      ; Check if it's a blank space 
      BNE     ERR_BF         
      CLR.L   D1           ; Clear D1    
      MOVE.B  (A4)+,D1     ; second byte of input address
      CMPI.B  #$24,D1      ; #$24 is '$', test if user input a valid address sign
      BNE     ERR_BF       ; If not equal $, there is no 2nd address
      BSR     ASCIItoHEX   ; D1 has 2nd address(ASCII) to be converted
      MOVEA.L D1,A6        ; 2nd Address(HEX) stored in A6
     
      MOVE.L  #4,D4        ; counter for data pattern (4 characters)
      CLR.L   D6           ; D6 to store word-size (2 bytes) data pattern
      MOVE.B  (A4)+,D1     ; Check if user enter any data pattern  
      CMPI.B  #$00,D1      ; Default 0 if any data pattern is not entered
      BEQ     BF3          ; Store leadign zeroes
      CMPI.B  #$20,D1      ; Check if user input blank space before data pattern
      BNE     ERR_BF       ; If not, invalid command is entered
      SUBQ.B  #1, D4       ; point to first data pattern input
              
BF2   CLR.L   D3           
      MOVE.B  (A4)+,D3     ; One byte data from user input(A4 poier)
      TST.B   D3           ; Check if any data pattern is entered
      BEQ     BF3          ; If reaches blank space, add leading zeroes
      ASL.L   #4,D6        ; Shift left by 4, First char on left byte
      BSR     ALPHAorDIGIT ; Convert to HEX character 
      ADD.B   D3,D6        ; Converted character is now on right
      DBF     D4, BF2      ; Debrease D4, Keep looping and check next data pattern
BF3   ;MOVE.W  (A3),D4    ; TEST: if address2 not even, address error is raised

LOOP_BF CMPA.L  A5, A6      ; Check if A5 = A6
        BLE     END_BF      ; if equal, go to the end
        MOVE.W  D6, (A5)+   ; Store data pattern in the boudary
        BRA     LOOP_BF     ; Else, keep looping
ERR_BF  BSR     CMD_INVALID ; Display invalid command error msg            
END_BF  MOVEM.L (A7)+,D1/D3/D4/D6/A1/A5-A6
        RTS    
      
*Prompt user when command is invalid
CMD_INVALID:
       MOVEM.L D0/A1, -(A7)    ; Save REGs
       LEA     INVALID_COM, A1 ; Display error message
       MOVE.B  #13,D0
       TRAP    #15
       MOVEM.L (A7)+,D0/A1     ; Restore REGs
       RTS

    ORG $2300
TEST1 DC.B    '$23A0 $23AF ABCD',0 ; Store testcase in input space
;TEST1 DC.B    '$23A0 $23AF 1234',0 ; Store testcase in input space
;TEST1 DC.B    '$23A0 $23AF 4',0 ; Store testcase in input space  
;TEST1 DC.B    '$23A0 $23AF 123',0 ; Store testcase in input space  
;TEST1 DC.B    '$23A0 $23AF 12',0 ; Store testcase in input space  


* Put variables and constants here
    ORG $2000
START:                  ; first instruction of program
    MOVEA.L #$2301, A4
    BRA      BF 
       
    END    START        ; last line of source








*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
