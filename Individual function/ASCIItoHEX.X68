*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $2000
INVALID_ADR MOVE.B  #0, D5 


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
           CMPI.B  #';',D3      ; Check if it is ';'
           BEQ     A2H_END_MM   ; Done if it meets ';'
           CMPI.B  #$30,D3      ; Check if it is ASCII
           BLT     A2H_END_MM      ; Done if there isn't ASCII
AtoHEX2_MM BSR     ALPHAorDIGIT ; Determine alpha/digit
AtoHEX3_MM ADD.B   D3,D1        ; Store converted HEX in D1
           MOVE.B  (A4)+,D3     ; Save a byte from A4 to D3
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
         
        ORG    $1000

START:                  ; first instruction of program
MAX_IN_LEN  EQU 80  ; to ensure input won't overflow stack
STACK       EQU $2FFC   ; $3000 minus a long word because A7 will be stored first
        MOVE.L  A7,STACK    ; store original location of stack beforehand
        LEA     STACK,A7
        MOVEM.L D0-D7/A0-A6,-(A7)   ; store all registers in stack. Want to be able to restore them
    
    MOVE.L  #$4000,A4
    MOVE.B  #$3B,(A4)+
    MOVE.B  #$3A,(A4)+
    MOVE.L  #$4000,A4
    BRA ASCIItoHEX_MM
    END    START        ; last line of source





*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
