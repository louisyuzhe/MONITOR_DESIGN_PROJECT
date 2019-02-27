*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
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

    
***Addition***
*ADD - Sums up two hex number and display
*ADD $A23 $123, each value is limited to max of $7FFFFFFF
ADD_MSG DC.B    'The sum = ',$0
    
    ORG $2000
ADD:
    MOVEM.L  D0/D2/D4-D5/A1,-(A7)   ; Save Registers
    SUBA.L  #1, A4       ; Point to first byte of user input address 
    CLR.L   D1           ; To be used for storing data
    
    *Store 1st hex value in D4
    MOVE.B  (A4)+,D1    ; First byte data from user input(A4 pointer)
    CMPI.B  #$24,D1     ; #$24 is '$', test if user input a valid hex number
    BNE     ERR_ADD     ; INVALID value for ADD
    BSR     ASCIItoHEX  ; D1 has 1st hex value
    MOVE.L  D1, D4      ; D4 now has 1st hex value
    MOVE.B  (A4)+,D1    ; Store the next byte in D1 to check blank space
    CMPI.B  #$20,D1     ; Check if user input blank space before data
    BNE     ERR_ADD     ; INVALID Command format for ADD
    
    *Store 2nd hex value in D5
    MOVE.B  (A4)+,D1    ; Take one byte data from user input(A4 pointer)
    CMPI.B  #$24,D1     ; #$24 is '$', test if user input a valid hex number
    BNE     ERR_ADD     ; INVALID value for ADD
    BSR     ASCIItoHEX  ; D1 has 1st hex value
    MOVE.L  D1, D5      ; D5 now has 2nd hex value

    *Addition
    ADD.L   D4, D5      ; Sum both value up inD5
    LEA     ADD_MSG,A1  ; Go to beginning of ADD output message
    MOVE.B  #14,D0
    TRAP    #15         ; Display sum message
    MOVE.L  #16, D2     ; To display output in base 16
    MOVE.L D5,D1
    MOVE.B  #15, D0 
    TRAP    #15         ; Display SUM of the 2 hex number
    BRA     END_ADD
    
ERR_ADD     JSR    CMD_INVALID  ; Go to invalid command subroutine    
END_ADD:    
    MOVEM.L (A7)+,D0/D2/D4-D5/A1 ;Restore REGs
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
TEST1 DC.B    '$8FFFFFFF $7FFFFFFF',0 ; Store testcase in input space
    
    ORG    $1000
INVALID_COM DC.B    'Invalid command',0 ; Imply user command has no match 

START:                  ; first instruction of program

    MOVEA.L #$2301, A4
    JSR     ADD 
       END    START        ; last line of source


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
