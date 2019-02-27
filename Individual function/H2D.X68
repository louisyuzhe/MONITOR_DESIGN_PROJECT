*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
 ORG $1100
***ASCII to HEX***
*Convert a byte of ASCII in (A4) to HEX in (D1)
AtoH_BYTE:
          MOVEM.L D3,-(A7)     ; Save register
          CLR.L   D1           ; Clear register
          CLR.L   D3
          MOVE.B  (A4)+,D3     ; Save a byte from A4 to D3
          CMPI.B  #$30,D3      ; Check if it is ASCII
          BLT     A2H_END_B    ; Done if there isn't ASCII
          BSR     ALPorDIG     ; Determine alpha/digit
          ADD.B   D3,D1        ; Store converted HEX in D1
A2H_END_B MOVEM.L (A7)+,D3     ; restore registers
          RTS

ALPorDIG:
         CMPI.B  #$40,D3      ; Determine alpha/digit
         BLT     AtoDIG     ; Branch to subroutine AtoDIGIT        
*Convert ASCII (D3) to DEC (Alphabets) 
AtoALP SUBI.B #$31, D3 ; for A to F
         RTS
*Convert ASCII (D3) to DEC (digits)
AtoDIG SUBI.B #$30,D3 ; for 0 to 9
         RTS

    
***Addition***
*H2D - Add two hex number and display
*H2D $7FF, Hex value is limited to max of $7FFF
H2D_MSG DC.B    'The decimal = ',$0
END_H2D_MSG DC.B '',0   
    
    ORG $2000
H2D:
    MOVEM.L  D0/D2/D4-D5/A1,-(A7)
    SUBA.L  #1, A4       ; Point to first byte of user input address 
    CLR.L   D1           ; To be used for stroing data
    CLR.L   D3
    
    *Store 1st hex value in D4
    MOVE.B  (A4)+,D1    ; First byte data from user input(A4 pointer)
    CMPI.B  #$24,D1     ; #$24 is '$', test if user input a valid hex number
    BNE     ERR_H2D     ; INVALID value for H2D
    BSR     AtoH_BYTE   ; D1 has the hex value
    MOVE.L  D1, D4      ; D4 now has the hex value

    *Test if there's a second character
    MOVE.B  (A4),D1    ; First byte data from user input(A4 pointer)
    LEA     END_H2D_MSG ; For storing ASCII encoded decimal
    CMPI.B  #$00,D1     ; #$24 is '$', test if user input a valid hex number
    BEQ     ONE_CHAR    ; INVALID value for h2D

    *If there's 2 character
    MULU    #16, D4     ; First char * 16 
    
    
   ; SUBA.L  #1,A4       ; point A4 to the second hex character
    BSR     AtoH_BYTE   ; D1 has the 2nd hex value
    MOVE.L  D1, D5      ; D5 now has the 2nd hex value

    
H2D_LOOP    SUBI.L  #1,D4   ; First character * 16 + 2nd char
            BLT     PRINT
            ADDI.L   #16,D5
            BRA     H2D_LOOP
    
ONE_CHAR  MOVE.L D4, D5    
    
PRINT   LEA     H2D_MSG,A1   ; Go to beginning of string
        MOVE.B  #14,D0
        TRAP    #15         ; Display sum message
        MOVE.L  #10, D2     ; Set output as base 16
        MOVE.L D5,D1
        MOVE.B  #3, D0 
        TRAP    #15         ; Display sum message
        LEA     END_H2D_MSG,A1  ; Print CR+LF
        MOVE.B  #13,D0
        TRAP    #15   
        BRA     END_H2D
    
ERR_H2D     JSR    CMD_INVALID  ; Go to invalid command subroutine    
END_H2D:    
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
TEST1 DC.B    '$2A',0 ; Store testcase in input space
    
    ORG    $1000
INVALID_COM DC.B    'Invalid command',0 ; Imply user command has no match 

START:                  ; first instruction of program

    MOVEA.L #$2301, A4
    BRA     H2D 
       END    START        ; last line of source


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
