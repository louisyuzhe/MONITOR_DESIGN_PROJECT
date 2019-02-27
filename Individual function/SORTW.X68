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
          
***Sort in Word***        
*SORTW -  sorts <address1> to <address2> in word size data
*(A or D) specifies whether the list is sorted in Ascending or Descending order
SORTW:
       MOVEM.L D1-D2/A1-A2/A5-A6,-(A7)
        
       *Store addr1 in A5
       SUBA.L  #1, A4       ; Point to first byte of user input address 
       MOVE.B  (A4)+,D1     ; First byte data from user input(A4 pointer)
       CMPI.B  #$24,D1      ; #$24 is '$', test if user input a valid address sign
       BNE     ERR_SORTW    ; INVALID Address for BTST
       BSR     ASCIItoHEX   ; D1 has 1st address(ASCII) 
       MOVEA.L D1, A5       ; 1st HEX addr in A5 
       
       *Store addr2 in A6
       MOVE.B  (A4)+,D1     ; Store the next byte in D1 to check blank space
       CMPI.B  #$20,D1      ; Check if user input blank space before Next address
       BNE     ERR_SORTW    ; INVALID Command format for BTST  
       MOVE.B  (A4)+,D1     ; One byte data from user input(A4 pointer)
       CMPI.B  #$24,D1      ; #$24 is '$', test if user input a valid address sign
       BNE     ERR_SORTW    ; INVALID Address for BTST
       BSR     ASCIItoHEX_MM ; D1 has 2nd address(ASCII)         
       MOVEA.L D1,A6        ; 2nd HEX addr in A6 
        
       MOVE.B  (A4)+,D1     ; Store the next byte in D1 to check blank space
       CMPI.B  #$20,D1      ; Check if user input blank space before sorting order
       BEQ     CHK_AD       ; Check if A or D is input  
       CMPI.B  #';',D1      ; Check if user input blank space before semicolon
       BEQ     ERR_SORTW    ; If yes, invalid command format  
       CMPI.B  #$00,D1      ; Check if there is any size input
       BEQ     DEF_SORTW    ; use default: descending (D1=0)

CHK_AD MOVE.B  (A4)+,D1     ; Store the next byte in D1 to check semi-colon
       CMPI.B  #';',D1      ; Check if user input semi-colon before sorting order
       BNE     ERR_SORTW    ; INVALID command format for SORTW
       MOVE.B  (A4)+,D1     ; Store the next byte in D1 to check sorting order
       CMPI.B  #$41, D1     ; Check if it's 'A'
       BEQ     A_SORTW      ; Go to sort in Ascending
       CMPI.B  #$44, D1     ; Check if it's 'D'
       BNE     ERR_SORTW    ; INVALID command format for SORTW

*Descending Sorting (DEFAULT)
DEF_SORTW  MOVEA.L A5,A2       ; Backup first addr to run nested loop               
DSORT_LOOP CMP.W   (A2)+,(A2)+ ; compare next two numbers
           BHI     D_SWAPW     ; If next > prev word data         
           SUBQ.L  #2,A2       ; Point back to the last word
           CMP.L   A2,A6       ; Check if A2 reaches A6
           BNE     DSORT_LOOP  ; If not, go back to comparing
           BRA     END_SORTW   ; Else, end the sorting
D_SWAPW    MOVE.L  -(A2),D2     ; Store the 2 words being compared
           SWAP.W  D2           ; Exchange Upper and lower word
           MOVE.L  D2,(A2)      ; Store back in memory
           BRA     DEF_SORTW    ; Continue next 2 comparisons
        
*Ascending Sorting
A_SORTW    MOVEA.L A5,A2       ; Backup first addr to run nested loop               
ASORT_LOOP CMP.W   (A2)+,(A2)+ ; compare next two numbers
           BCS     A_SWAPW     ; If prev > next word data         
           SUBQ.L  #2,A2       ; Point back to the last word
           CMP.L   A2,A6       ; Check if A2 reaches A6
           BNE     ASORT_LOOP  ; If not, go back to comparing
           BRA     END_SORTW   ; Else, end the sorting       
A_SWAPW    MOVE.L  -(A2),D2     ; Store the 2 words being compared
           SWAP.W  D2           ; Exchange Upper and lower word
           MOVE.L  D2,(A2)      ; Store back in memory
           BRA     A_SORTW      ; Continue next 2 comparisons
     
ERR_SORTW  JSR    CMD_INVALID  ; Go to invalid command subroutine
END_SORTW  MOVEM.L (A7)+,D1-D2/A1-A2/A5-A6 ;Restore used Register
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
TEST1 DC.B    '$2400 $2408 ;A',0 ; Store testcase in input space
;TEST1 DC.B    '$2400 $2408 ;D',0 ; Store testcase in input space
;TEST1 DC.B    '$2400 $2408',0 ; Store testcase in input space
;TEST1 DC.B    '$2400 $2408;D',0 ; Store testcase in input space

STACK   EQU $2FFC       ; A7 will be stored at $3000 - $4

    ORG $2400
TEST1A   DC.B    '0501040203',0

    ORG $2000
START:                  ; first instruction of program
    MOVEA.L #$2301, A4
    BRA     SORTW 
    ;MOVEA.L #$2601, A4
    ;BRA     MDSP   
    END    START        ; last line of source















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
