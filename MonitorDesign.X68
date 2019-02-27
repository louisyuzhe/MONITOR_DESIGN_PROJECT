     *-----------------------------------------------------------
* Title      : ECE441 MONITOR DESIGN PROJECT 
* Written by : Yuzhe Lim
* Date       : 10/22/2018
* Description: This program performs basic debugger functions  
*              and handles exceptions. It is also equipped with 
*              Command Interpreter and User Instruction Manual
*-----------------------------------------------------------

*---------------------System constants Initialization---------------------*
    ORG    $1000
PROMPT      DC.B    'MONITOR441> ',0     ; Prompt definition
USER_INPUT  DS.B    80                    ; User input spaces size residing in memory
END_USER_INPUT DC.B 0

    ORG    $1080
INVALID_COM DC.B    'Invalid command',0 ; Imply user command has no match   
INVALID_ADR DC.B    'Invalid Address',0 ; Imply input address is invalid 
BusAddrErr  DC.B    'The order: SSW BA IR',0 ; Output follows after Bus & Address Error Exception
EXIT_PRMPT  DC.B    'Exited',0          ;Imply termination/exit of monitor program   
 
***COMMAND TABLE***
**Command Names**
COM_TABL    DC.B    'HELP    '    ; String ‘HELP’ stored in memory (ASCII)
            DC.B    'MDSP    ' 
            DC.B    'SORTW   ' 
            DC.B    'MM      '
            DC.B    'MS      '
            DC.B    'BF      '
            DC.B    'BMOV    '
            DC.B    'BTST    '
            DC.B    'BSCH    '
            DC.B    'GO      '
            DC.B    'DF      '
            DC.B    'EXIT    '
            DC.B    'ADD     '
            DC.B    'D2H     '

**Command Addresses**         
COM_ADDR    DC.W    HELP         ;HELP is the address for HELP command subroutine 
            DC.W    MDSP
            DC.W    SORTW
            DC.W    MM
            DC.W    MS
            DC.W    BF
            DC.W    BMOV
            DC.W    BTST
            DC.W    BSCH
            DC.W    GO
            DC.W    DF
            DC.W    EXIT
            DC.W    ADD
            DC.W    D2H
            
***HELP TABLE***
HELP_TABL     DC.B      'All available commands and usage descriptions:',$A,$A,$D
LINE1A        DC.B      'MDSP <address1> <address2> - eg: MDSP $4002 $4016<CR>',$A,$D
LINE1B        DC.B      'MDSP: Outputs Address And Memory Contents <address1> -> <address2>',$A,$D
LINE1C        DC.B      'Default: <address1> -> <address1 + 16bytes>',$A,$A,$D
LINE2A        DC.B      'SORTW <address1> <address2> <;A or ;D> - eg: SORTW $4000 $4008 ;A<CR>',$A,$D
LINE2B        DC.B      ';A - Ascending order, ;D - Decending',$A,$D
LINE2C        DC.B      'SORTW: Sorts Unsigned Words from memory <address1> to <address2>',$A,$D
LINE2D        DC.B      'Default: Descending Order',$A,$A,$D
LINE3A        DC.B      'MM <address><B/W/L> - eg: MM $4000;W<CR>',$A,$D
LINE3B        DC.B      '<B/W/L> specifies the number of bytes displayed for each address.',$A,$D
LINE3C        DC.B      'MM: Display memory, modify data or enter new data',$A,$D
LINE3D        DC.B      ';B - Byte size, ;W - Word size, ;L - Long size'
LINE3E        DC.B      'Default: Displays and enable edits for Byte size content',$A,$A,$D
LINE4A        DC.B      'MS <address> <data> - eg: MS $4000 HELLO WORLD<CR>',$A,$D
LINE4B        DC.B      'MS: Sets <data> (ASCII string/HEX value) into the <address> specified.',$A,$A,$D
LINE5A        DC.B      'BF <address1> <address2> <data> - eg: BF $4000 $4050 1234<CR>' ,$A,$D
LINE5B        DC.B      '<address1> and <address2> must be even.',$A,$D
LINE5C        DC.B      'BF: Fills memory starting with the word boundary <address1> through <address2>.',$A,$D
LINE5D        DC.B      'Only allows word-size (2 bytes) data pattern.',$A,$D
LINE5E        DC.B      'Both <address1> and <address2>  must be even addresses',$A,$D
LINE5F        DC.B      'If less than word size, the pattern is right justified and leading zeros added',$A,$D
LINE5G        DC.B      'eg: BF $4002 $4016 ABCD<CR>',$A,$A,$D
LINE6A        DC.B      'BMOV <address1> <address2> <address3> - eg: BMOV $4000 #4100 $5000<CR>',$A,$D
LINE6B        DC.B      'BMOV: Moves memory from <address1> till <address2> to <address3>(inclusive)',$A,$A,$D
LINE7A        DC.B      'BTST <address1> <address2> - eg: BTST $4000 $400A<CR>',$A,$D
LINE7B        DC.B      'BTST: test memory from <address1> to <address2> ',$A,$A,$D
LINE8A        DC.B      'BSCH <address1> <address2> <data> - eg: BSCH $4000 $4400 STRING<CR>',$A,$D
LINE8B        DC.B      'BSCH: search a literal string in a memory block ',$A,$D
LINE8C        DC.B      'starting at <address1> through <address2>, both inclusive.',$A,$A,$D
LINE9A        DC.B      'GO <address> - eg: GO $3010<CR>',$A,$D
LINE9B        DC.B      'GO:  start execution from <address>',$A,$A,$D
LINE10        DC.B      'DF: display current PC, SR, US, SS and D, A registers - eg: DF<CR>',$A,$A,$D
LINE11        DC.B      'EXIT: terminates/exits Monitor program - eg: EXIT<CR>',$A,$A,$D   
LINE12A       DC.B      'ADD: Add two hex number - eg: ADD $7F $AF<CR>',$A,$D
LINE12B       DC.B      'ADD: Each value limit is $7FFFFFFF, only 0-9 and A-F',$A,$A,$D 
LINE13A       DC.B      'D2H <data>, Convert up to 3 digits decimal number into hexadecimal number',$A,$D
LINE13B       DC.B      'eg: D2H 123<CR>',$A,$D
LINE13C       DC.B      'D2H: Decimal Value limit is: 255',$0

***EXCEPTION TABLE***
BERR_TXT    DC.B    $D,'Bus Error Exception',0
ADDERR_TXT  DC.B    $D,'Address Error Exception',0   
ILLINST_TXT DC.B    $D,'Illegal Instruction Exception',0
PRIVVIO_TXT DC.B    $D,'Privilege Violation Exception ',0
DIVZERO_TXT DC.B    $D,'Divide by Zero Exception',0
CHKINS_TXT  DC.B    $D,'Check Instruction Exception',0
LINEA_TXT   DC.B    $D,'Line A Emulator Exception',0
LINEF_TXT   DC.B    $D,'Line F Emulator Exception',0

***Ouput for DF***
DF_MSG      DC.B    'PC=00000000 SR=0000     US=00000000 SS=00000000',$A,$D
            DC.B    'D0=00000000 D1=00000000 D2=00000000 D3=00000000 ',$A,$D
            DC.B    'D4=00000000 D5=00000000 D6=00000000 D7=00000000 ',$A,$D
            DC.B    'A0=00000000 A1=00000000 A2=00000000 A3=00000000 ',$A,$D
            DC.B    'A4=00000000 A5=00000000 A6=00000000 A7=00000000',$0
DF_MSG_END      

***Block Test Success/Fail Message***
*No error msg    
BTST_NO_ERR DC.B   'No Error Was Detected',0    

*Error MSg indicating the address, the data stored and the data read of the failing memory. 
ERR_ADDR    DC.B   'Memory problems found: $00000000'
E_ERR_ADDR  DC.B   $A,$D 
DTSTORE     DC.B   'The data stored: 00'
E_DTSTORE   DC.B   $A,$D
DTREAD      DC.B   'The data read: 00'
E_DTREAD    DC.B   0

***BSCH Found/Not Found Message***
BSCH_FAIL_MSG        DC.B 'String not found',0
BSCH_FOUND_MSG       DC.B 'String found at $00000000'
END_BSCH_FOUND       DC.B 0         ; To be use by ASCIItoHEX subroutine

***ADD function output Message***
ADD_MSG DC.B    'The sum = ',$0
END_ADD_MSG DC.B    0

***Decimal to HEX function output Message***
D2H_MSG DC.B    'The HEXADECIMAL = 000'
END_D2H_MSG DC.B '',0   


***-----------------------------Main Program-------------------------------***
    ORG    $1D00
START:                  ; first instruction of program
STACK_INI_REG EQU $2FFC   ; A7 will be stored at $3000 - $4
DF_STACK      EQU $2FB8
STACK         EQU $2FBC

        MOVE.L  A7,STACK_INI_REG ; So registers stored at STACK will start at $3000
        LEA     STACK_INI_REG,A7
        MOVEM.L D0-D7/A0-A6,-(A7); Save registers on STACK to enable restore later 
        ;LEA     STACK,A7
        ;ADDQ.W  #4,A7

***Exception Vector table***
        MOVE.L #STACK,    $0 
        MOVE.L #BUS_ERR,  $8 
        MOVE.L #ADS_ERR,  $C 
        MOVE.L #ILL_INST, $10 
        MOVE.L #DIV_ZERO, $14 
        MOVE.L #CHK_INST, $18 
        MOVE.L #PRIV_VIOL, $20 
        MOVE.L #LINE_A,   $28 
        MOVE.L #LINE_F,   $2C
      
***--------------------------- Command Interpreter ----------------------------***
*A1, A4 point to user input
BEGIN     LEA     END_USER_INPUT, A1    ; CR + LF
          MOVE.L  #13,D0                
          TRAP    #15  
          LEA     PROMPT, A1  ; Prompt for user input “MONITOR441>” 
          MOVE.L  #14,D0      ; Display Prompt
          TRAP    #15
          LEA     USER_INPUT, A1   ; When user input, store to reserve user input space
          MOVE.L  #2,D0       ; Read input ans return to (A1)
          TRAP    #15
          
          LEA     COM_TABL,A2  ; Load Command Table, pointer on the command names. 
          LEA     COM_ADDR,A3  ; Load Command ADDR, pointer on the addr of the subroutines
          CLR.L   D2           ; Command Counter
LOOKUP    MOVEA.L A1,A4        ; Point to user input       
          MOVE.L  #9, D4       ; Each command in command table has 8 characters
CMP_Char  SUBI.B  #1, D4
          CMPM.B  (A2)+, (A4)+ ; Compare byte (input) vs (CMD table)
          BEQ     CMP_Char     ; If same, keep comparing
          CMPI.B  #$20, -(A2)  ; Check if reach blank space 
          BEQ     Run_CMD      ; If 0, means btoh strings are same, select command
NEXTCMD   ADDA.L  #1, A2       ; Loop thru the rest of blank spaces
          SUBI.B  #1, D4
          BNE     NEXTCMD      ; 
          ADDQ.L  #2,D2        ; Else, point to next cmd address
          CMPA.L  A2,A3        ; Check if reach end of COM_TABL
          BGE     LOOKUP       ; Else, keep looking up command         
          BSR     CMD_INVALID  ; Prompt Invalid command
          BRA     BEGIN        ; Start prompt again
                
Run_CMD   ADDA.L  D2,A3        ; point to the cmd adr in COM_ADDR 
          MOVEA.L #0,A5        ; clear A5, used for subroutine call
          MOVEA.W (A3),A5      ; move that command's address to register
          JSR     (A5)        ; jump to that command's subroutine (below)
          BRA     BEGIN        ; Prompt for new command
          
          
***--------------------------- Debugger Commands -----------------------------***
***HELP***
HELP:
        MOVEM.L D0/A1,-(A7)   ; Save register to A7(Stack)
        LEA     HELP_TABL,A1  ; Load HELP TABLE's addr
        MOVE.B  #13,D0      
        TRAP    #15           ; Display HELP TABLE
        MOVEM.L (A7)+,D0/A1   ; restore registers
        RTS
        
***Memory Display***        
*MDSP - outputs the address and memory contents <address1> to <address2>
*Default: outputs the address and memory contents <address1> to <address1 + 16bytes>
MDSP:
       MOVEM.L D0/A1/A5-A6,-(A7)     
       *Store address1 in A5
       SUBA.L  #1, A4       ; Point to first byte of user input address 
       MOVE.B  (A4)+,D1     ; First byte data from user input(A4 pointer)
       CMPI.B  #$24,D1      ; #$24 is '$', test if user input a valid address sign
       BNE     ERR_MDSP     ; INVALID Address for BTST
       BSR     ASCIItoHEX   ; D1 has 1st address(ASCII) 
       MOVEA.L D1, A5       ; 1st HEX addr in A5 
       
       *Check If there's a second address, if yes, store address2 in A6
       MOVE.B  (A4)+,D1     ; Store the next byte in D1 to check blank space
       CMPI.B  #$20,D1      ; Check if user input blank space before Next address
       BNE     NO_ADDR2     ; INVALID Command format for BTST  
       MOVE.B  (A4)+,D1     ; One byte data from user input(A4 pointer)
       CMPI.B  #$24,D1      ; #$24 is '$', test if user input a valid address sign
       BNE     ERR_MDSP     ; INVALID Address for BTST
       BSR     ASCIItoHEX   ; D1 has 2nd address(ASCII)         
       MOVEA.L D1,A6        ; 2nd HEX addr in A6 
       BRA     MDSP2
       
         *If no input addre2, addr2 = addr1 + 16 bytes
NO_ADDR2 MOVEA.L A5,A6      ; make a copy of addr1
         ADDA.L  #15,A6     ; Add 16 bytes to addr1(first byte is counted)
       *Outputs the address and memory contents from A5 to A6
MDSP2  CMPA.L  A5, A6       ; Compare if A5 is at A6 (A6-A5), 
       BLT     END_MDSP     ; If A5 is at A6, go to to next loop
       LEA     STACK, A1    ; Use STACK to store byte to be printed out
       SUBA.L  #$50,A1      ; Skip spaces to prevent stack overflow
       MOVE.B  #$00,-(A1)   ; Null terminator
       CLR.L   D1           ; Clear to store byte data
       MOVE.B  (A5),D1      ; Memory content to be converted
       BSR     HEX2toASCII 
       MOVE.B  #$20,-(A1)   ; Blank space
       MOVE.B  #$20,-(A1)   ; Blank space 
       MOVE.W  A5, D1       ; Address to be converted
       BSR     HEXtoASCII   ; Convert Address to ASCII
       MOVE.B  #13,D0       ; Display the address and memory contents
       TRAP    #15             
       ADDQ.L  #1, A5       ; Go to next byte addr 
       BRA     MDSP2        ; Continue Loop
       
ERR_MDSP JSR    CMD_INVALID  ; Go to invalid command subroutine       
END_MDSP MOVEM.L (A7)+,D0/A1/A5-A6 ;Restore used Register
         RTS
     
         
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
       BNE     ERR_SORTW    ; INVALID Address for SORTW
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

***Memory Modify***        
*MM -  display memory and, as required, modify data or enter new data
* The size (B,W,L) controls the number of bytes displayed for each address.
MM:
        MOVEM.L D0-D1/A1/A5,-(A7)
        
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
        BSR     HEX2toASCII  ; Store the converted byte into output
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
         ;BGT     ERR_MM     ; Prompt Invalid input?   
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
        BSR     HEX4toASCII  ; Store the converted word  into output
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
        BSR     HEX8toASCII  ; Store the converted long into output
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
         BSR     ASCtoHEX_MM ; convert user input into HEX        
         MOVE.L  D1,(A5)+    ; Replace it with HEX LONG user input 
         BRA     LONG_MM     ; Proceed to next LONG data

ERR_MM  JSR    CMD_INVALID        ; Go to invalid command subroutine
END_MM  MOVEM.L (A7)+,D0-D1/A1/A5 ; Restore REGs
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
        CMPI.B  #0,(A4)     ; check if input ended
        BEQ     NULL_MS     ; If yes, end the memory setting
        BRA     ASC_MS      ; Else, keep looping
NULL_MS MOVE.B  #$00,(A5)    ; Null terminator
        BRA     END_MS
        
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


***Block Fill***        
*BF - fills memory starting with the word boundary <address1> through <address2>
BF:     
      MOVEM.L D1/D3/D4/D6/A1/A5-A6,-(A7)
      SUBA.L  #1, A4       ; Point to first byte of user input address        
      MOVE.B  (A4)+,D1     ; First byte data from user input(A4 pointer)
      CMPI.B  #$24,D1      ; #$24 is '$', test if user input a valid address sign
      BNE     ERR_BF       ; INVALID Address for BF
      BSR     ASCIItoHEX   ; D1 has 1st address(ASCII)to be converted
      BTST    #0,D1        ; Check to see if last bit is 0(even addr)
      BNE     ERR_BF       ; Invalid command, addr is odd
      MOVEA.L D1,A5        ; 1st Address(HEX) stored in A5
      
      MOVE.B  (A4)+,D1     ; Blank space before next $address
      CMPI.B  #$20,D1      ; Check if it's a blank space 
      BNE     ERR_BF         
      CLR.L   D1           ; Clear D1    
      MOVE.B  (A4)+,D1     ; second byte of input address
      CMPI.B  #$24,D1      ; #$24 is '$', test if user input a valid address sign
      BNE     ERR_BF       ; If not equal $, there is no 2nd address
      BSR     ASCIItoHEX   ; D1 has 2nd address(ASCII) to be converted
      BTST    #0,D1        ; Check to see if last bit is 0(even addr)
      BNE     ERR_BF       ; Invalid command, addr is odd
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

***Block Move***        
*BMOV -  Moves A Block Of Memory To Another Area
*BMOV <Addr1> <Addr2> <Addr3> eg: BMOV $ $ $<CR>
*Loop is not need for only 3 addr as the ' ' between addr have to be taken account
BMOV:   
         MOVEM.L D1/A2/A5-A6,-(A7)
         SUBA.L  #1, A4    ; Point to first byte of user input address     
        
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
         BSR     ASCIItoHEX   ; D1 has 2nd address(ASCII) to be converted0
         MOVE.L  D1,A2        ; 2nd HEX addr in A2

LOOPBMOV CMPA.L  A5,A6        ; Compare if A5 is at A6 (A6-A5), 
                              ; Compare first, incase user input same addresses
         BLE     END_BMOV     ; If not, keep looping
         MOVE.B  (A5)+,(A2)+  ; Moves A Block Of Memory, (A5) To (A2)
         BRA     LOOPBMOV        
ERR_BMOV BSR     CMD_INVALID ; Display invalid command error msg    
END_BMOV MOVEM.L (A7)+,D1/A2/A5-A6
         RTS    

***Block Test***      *Have to move the mem location to even*  
*BTST -  test memory from  <address1> to <address2>
* If completed w/o errors, display no error msg
* Else display error msg w/ address, the data stored & the data read of the failing memory.  
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
             
       *Fill all of the memory to be tested with $AA and run read operation (1010)
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

        *Fill all of the memory to be tested with $55 and run read operation (0101)
BTST2   MOVEA.L A2, A5        ; Restore A5 initial value
        CLR.L   D1            ; Clear D1 for storing byte data from memory
LOOP_BTST2:                 
        CMPA.L  A5,A6         ; Compare if A5 is at A6 (A6-A5), 
        BLE     NoErr_BTST      ; If A5 is at A6, go to to next loop
        MOVE.B  #$55,(A5)     ; Fill each byte of memory with $55
        MOVE.B  (A5)+,D1      ; Read the byte of memory
        CMPI.B  #$55,D1       ; Check if the contents is be $AA. 
        BEQ     LOOP_BTST2    ; If correct, continue loop for next byte
        
        *Display failing msg with address, data stored, data read of the failing memory.  
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
        

***Block Search***        
*BSCH -  search a literal string from <address1> through <address2> both inclusive
*BSCH <Adr1> <Adr2> "literal string"
* If Found,  the data and address(s) must be displayed. 
BSCH:   
        MOVEM.L D1-D2/A1,-(A7)
        LEA     BSCH_FAIL_MSG ,A1 ; Initialize message
        
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
        CMPI.B  #$20,D1      ; Check if user input blank space before input string
        BNE     ERR_BSCH     ; INVALID Command format for BMOV         
        MOVE.B  (A4),D1      ; Store the next byte in D1 to check blank space
        CMPI.B  #$00,D1      ; Check if user input empty string ''
        BEQ     ERR_BSCH     ; INVALID literal string
        CLR.L   D2           ; flag for checking if anything is found

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

ERR_BSCH   BSR     CMD_INVALID  ; Display invalid command error msg  
           BRA     END_BSCH
            
BSCH_FOUND SUBA.L  #1,A5      ; Point to the first character of string found
           MOVE.L  A5,D1       
           LEA     END_BSCH_FOUND,A1    ; Point to the end end of found addr msg
           BSR     HEX8toASCII          ; Change to the address found
           LEA     BSCH_FOUND_MSG,A1
           MOVE.B  #13,D0               ; Print found message
           TRAP    #15   
           ADDA.L  #1,A5                ; Point to next byte to check
           ADD.L   #1, D2               ; increase string found count
           BRA     LOOPBSCH
           
MSG_BSCH   CMPI.L  #0, D2            ; If D2 isn't zero, at least 1 string is found
           BNE     END_BSCH          ; End the block search
           LEA     BSCH_FAIL_MSG ,A1 ; Load nothing found message
           MOVE.B  #13,D0            ; Display message
           TRAP    #15     
END_BSCH   MOVEM.L (A7)+,D1-D2/A1
           RTS

***Execute Program***        
*GO -  start execution from a given address
GO      MOVEM.L D0-D7/A0-A7,-(A7) ; Save all registers
        SUBA.L  #1, A4       ; Point to first byte of user inout address        
        MOVE.B  (A4)+,D1     ; Cope byte address from user input(A4 pointer)
        CMPI.B  #$24,D1      ; #$24 is '$', test if user input a valid address sign
        BNE     ERR_GO       ; INVALID Address for GO
        BSR     ASCIItoHEX   ; Convert mem addr to be run
        MOVEA.L D1,A6        ; Store user input addr in A6
        JSR     (A6)         ; Start execution from (A6)
        BRA     END_GO       ; End GO subroutine
ERR_GO  BSR     CMD_INVALID  ; Display invalid command error msg       
END_GO  MOVEM.L (A7)+,D0-D7/A0-A7 ; Restore Resgisters
        RTS

   
***Display Formatted Registers***        
* DF - display current PC, SR, US, SS and D, A register
DF:    
        MOVE.L  A7,DF_STACK ; So registers stored at STACK will start at $3000
        LEA     DF_STACK,A7 ;All other Df values store on DF_STACK
        MOVEM.L D0-D7/A0-A6,-(A7) ; Save current REGs on stack to Display
        LEA     DF_STACK,A7 ; To Store SS which is A7 
        MOVE.L (A7),$2F78   
        MOVEA.L  #$2F78, A7
        MOVE    USP,A6      ;for use with DF command
        MOVE.L  A6,-(A7)    ;store USP to STACK
        MOVE    SR,-(A7)    ;save Status register for use with DF
        LEA     STACK,A5
        MOVE.L  (A5),-(A7)
       
        MOVEM.L D0/D2-D3/A0-A2,-(A7) ; Save REGs
        LEA     DF_STACK, A2   ;A2 pointing at STACK
        ADDQ.L  #4, A2      ; Go to the end of STACK for A7 value
        MOVE.L  #16, D2     ; D2 as counter for 16 registers
        MOVE.L  #0, D3      ; D3 as counter for 4 lines
        LEA     DF_MSG_END,A1   ;A1 as the end of string
        SUBQ.L  #1, A1      ; Skip Empty space, $0 
DF2     CMP.L   #4, D3      ; Calc(D3-4)
        BNE     DF3         ; If not 4 times, go to DF3
        SUBQ.L  #2, A1      ; Skip Empty space, $A,$D
        CLR.L   D3          ; Reset D3
DF3     MOVE.L  -(A2), D1   ; Save register value in D1 to be converted 
        BSR     HEX8toASCII ; Branch to convert Hex->ASCII
        ADDQ.L  #1, D3      ; Increment D3, 4 REG/Line
        SUBQ.L  #4, A1      ; Skip blank and 'REG[#]='
        SUBQ.B  #1, D2      ; Increment D2, total = 16REGs
        BNE     DF2         ; If not 12 times yet, go back to DF2
        
        *SS*
        SUBQ.L  #1, A1      ; Skip '$A$D and D0='
        MOVE.L  -(A2), D1   ; Save register value in D1 to be converted 
        BSR     HEX8toASCII ; Branch to convert Hex->ASCII
        
        *US*
        SUBQ.L  #4, A1      ; Skip blank and 'SS='
        MOVE.L  -(A2), D1   ; Save register value in D1 to be converted 
        BSR     HEX8toASCII ; Branch to convert Hex->ASCII
        
        *SR*
        SUBQ.L  #8, A1      ; Skip blanks and 'US='
        MOVE.W  -(A2), D1   ; Save register value in D1 to be converted 
        BSR     HEX4toASCII ; Branch to convert Hex->ASCII
        
        *PC*
        SUBQ.L  #4, A1      ; Skip blank and 'SR='
        MOVE.L  -(A2), D1   ; Save register value in D1 to be converted 
        BSR     HEX8toASCII ; Branch to convert Hex->ASCII
        
        LEA     DF_MSG,A1   ; Go to beginning of string
        MOVE.B  #13,D0
        TRAP    #15         ; Display all Registers
        MOVEM.L (A7)+,D0/D2-D3/A0-A2 ;Restore REGs
        RTS
       

***Exit Monitor Program***        
*EXIT - erminates/exits Monitor program
EXIT    LEA     EXIT_PRMPT ,A1    ; Display exiting msg
        MOVE.B  #13,D0
        TRAP    #15             
        MOVE.L  #$2FC0,A7         ; Start of initial registers 
       ;ADDA.L  INPUT_SIZE,A7     ; Skip stack spaces prepare for User Input
        MOVEM.L (A7)+,D0-D7/A0-A6 ; Restore Registers saved at beginning of program
        MOVEA.L STACK,A7
        BRA     END               ; Terminate Monitor Program  


***--------------------------------Extra Commands-----------------------------------***
***Addition***
*ADD - Sums up two hex number and display
*ADD $A23 $123, each value is limited to max of $7FFFFFFF  
ADD:
    MOVEM.L   ,-(A7)   ; Save Registers
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
    ADD.L   D4, D5      ; Sum both value up in D5
    LEA     ADD_MSG,A1  ; Go to beginning of ADD output message
    MOVE.B  #14,D0
    TRAP    #15         ; Display sum message
    MOVE.L  #16, D2     ; To display output in base 16
    MOVE.L D5,D1
    MOVE.B  #15, D0 
    TRAP    #15         ; Display SUM of the 2 hex number
    LEA     END_ADD_MSG,A1 ; Display CR + LF
    MOVE.B  #13,D0
    TRAP    #15     
    BRA     END_ADD     ; End the ADD function
    
ERR_ADD     JSR    CMD_INVALID  ; Go to invalid command subroutine    
END_ADD:    
    MOVEM.L (A7)+,D0/D2/D4-D5/A1 ;Restore REGs
    RTS

    
***3 Decimal to Hexadecimal***
*D2H - Convert up to 3 digits decimal number into hexadecimal number
*E.G: D2H 123 , number limit is 255
D2H:
    MOVEM.L  D2-D5/A1,-(A7) ; Save registers
    SUBA.L  #1, A4          ; Point to first byte of user input address 
    CLR.L   D1              ; To be used for storing data 
    CLR.L   D3              ; Empty D3 incase of 0 value
    CLR.L   D4              ; Empty D4 incase of less than 3 digits 
    CLR.L   D5              ; Empty D5 incase of less than 3 digits
    
    *Check 1st number
    MOVE.B  (A4)+,D1    ; First byte data from user input(A4 pointer)
    CMPI.B  #$00,D1     ; #$00 Check if there's a number
    BEQ     ERR_D2H     ; Invalid data to be convert
    MOVE.L  D1,D3       ; 1st number in D3 (ASCII)
    SUBI.B  #$30,D3     ; 1st number in D3 (DEC)
    
    *Check 2nd number
    MOVE.B  (A4)+,D1    ; Second byte data from user input(A4 pointer)
    CMPI.B  #$00,D1     ; #$00  Check if there's a number
    BEQ     ONE_D2H     ; If no, go to one digits decimal function
    MOVE.L  D1,D4       ; 2nd number in D4 (ASCII)
    SUBI.B  #$30,D4     ; 2nd number in D4 (DEC)

    *Check 3rd number
    MOVE.B  (A4)+,D1    ; First byte data from user input(A4 pointer)
    CMPI.B  #$00,D1     ; #$00  Check if there's a number
    BEQ     TWO_D2H     ; If no, go to two digits decimal function
    MOVE.B  (A4)+,D2    ; Check if it's only 3 digits
    CMPI.B  #$00,D2     ; 
    BNE     ERR_D2H     ; If not, return error
    MOVE.L  D1,D5       ; 3rd number in D5 (ASCII)
    SUBI.B  #$30,D5     ; 3rd number in D5 (DEC)
    BRA     D2H2

ONE_D2H MOVE.L  D3,D5   ; Place the only digit at 1's
        CLR.L D3        ; Empty D3 because only 1 digit
        BRA     D2H2    ; Go to Dec to Hex conversion

TWO_D2H MOVE.L  D4,D5   ; Place the 2nd digit at 1's
        MOVE.L  D3,D4   ; Place the 1st digit at 10's
        CLR.L D3        ; Empty D3 because only 1 digit
        BRA     D2H2    ; Go to Dec to Hex conversion

*Convert DEC to HEX and store after output string
D2H2: 
    MULU    #$64, D3        ; 1st digit * 100    
    MULU    #$0A, D4        ; 2nd digit * 10
    ADD.W   D3,D4           ; Sums up 3 digits
    ADD.W   D4,D5      
    CMPI.L  #255,D5         ; Max value 255
    BGT     ERR_D2H
    LEA     END_D2H_MSG,A1  ; To save converted HEX after output
    CLR.L   D3
    MOVE.W  D5,D3           ; Save a copy of D5 to be reuse
    ANDI.W  #$0F00,D3       ; To obtain first hex value
    LSR.W   #8, D3          ; Make other byte 0, and shift it to lowest byte -> D3
    CLR.L   D4
    MOVE.W  D5,D4
    ANDI.W  #$00F0,D4       ; To obtain second hex value
    LSR.W   #4, D4          ; Make other byte 0, and shift it to lowest byte -> D3
    ANDI.B  #$0F, D5        ; To obtain last hex value       
    MOVE.L  D5,D1           ; Store 1's HEX value to be displayed
    BSR     HEXtoASCII
    MOVE.L  D4,D1           ; Store 10's HEX value to be displayed
    BSR     HEXtoASCII     
    MOVE.L  D3,D1           ; Store 100's HEX value to be displayed
    BSR     HEXtoASCII     
PRINT   LEA     D2H_MSG,A1  ; Go to beginning of string
        MOVE.B  #13,D0
        TRAP    #15         ; Display converted HEX
        BRA     END_D2H
    
ERR_D2H     JSR    CMD_INVALID  ; Go to invalid command subroutine    
END_D2H:    
    MOVEM.L (A7)+,D2-D5/A1 ;Restore REGs
    RTS


***---------------------------Conversion Subroutines-----------------------------***
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

**Convert 2 HEX characters in (D1) to ASCII starting at A1 - (4 BYTE)
*For MDSP
HEX2toASCII: 
          MOVEM.L D2-D4,-(A7) ; Save registers
          MOVE.L  D1,D4       ; Save D1 to D4
          MOVE.L  #2,D2       ; Count of 2
HEX2toA2  MOVE.L  D4, D3      ; Duplicate value of D4
          AND.L   #$0F,D3     ; Filter all except last digit
          CMPI.B  #$A,D3      ; Determine Alphabet/Digit
          BLT     DIGIT2toA   ; Branch to subroutine DIGITtoA  
ALPHA2toA ADDI.B  #$37, D3    ; Convert Alphabets in (D3) to ASCII for A to F
          BRA     HEX2toA3    ; Continue to save value to -A1
DIGIT2toA ADDI.B  #$30,D3     ; Convert Digit in (D3) to ASCII for 0 to 9      
HEX2toA3  MOVE.B  D3,-(A1)    ; Save ASCII to memory
          LSR.L   #4,D4       ; Shift right by 1 Hex digit
          SUBI.L  #1, D2      ; Decrement D2    
          BNE     HEX2toA2    ; Loop if there is digit left
H22A_END  MOVEM.L (A7)+,D2-D4 ; Restore registers
          RTS                 ; Return from Subroutine
          
**Convert 4 HEX characters in (D1) to ASCII starting at A1 - (4 BYTE)
*For the SR
HEX4toASCII: 
          MOVEM.L D2-D4,-(A7) ; Save registers
          MOVE.L  D1,D4       ; Save D1 to D4
          MOVE.L  #4,D2       ; Count of 4
HEX4toA2  MOVE.L  D4, D3      ; Duplicate value of D4
          AND.L   #$0F,D3     ; Filter all except last digit
          CMPI.B  #$A,D3      ; Determine Alphabet/Digit
          BLT     DIGIT4toA   ; Branch to subroutine DIGITtoA  
ALPHA4toA ADDI.B  #$37, D3    ; Convert Alphabets in (D3) to ASCII for A to F
          BRA     HEX4toA3    ; Continue to save value to -A1
DIGIT4toA ADDI.B  #$30,D3     ; Convert Digit in (D3) to ASCII for 0 to 9      
HEX4toA3  MOVE.B  D3,-(A1)    ; Save ASCII to memory
          LSR.L   #4,D4       ; Shift right by 1 Hex digit
          SUBI.L  #1, D2      ; Decrement D2    
          BNE     HEX4toA2    ; Loop if there is digit left
H42A_END  MOVEM.L (A7)+,D2-D4 ; Restore registers
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

     
***--------------------------- Exception Handlers  -----------------------------***
BUS_ERR:
        MOVEM.L A1/D0,-(A7)     ; Registers for Error Messages
        MOVEM.L D1/A2,-(A7)     ; Registers for SSW, BA, IR subroutine
        LEA     BERR_TXT, A1    ; Bus Error Msg
        BRA     BUS_ADS_EXCPTN

ADS_ERR:
        MOVEM.L A1/D0,-(A7)     ; Registers for Error Messages
        MOVEM.L D1/A2,-(A7)     ; Registers for SSW, BA, IR subroutine
        LEA     ADDERR_TXT, A1  ; Address Error Msg
        BRA     BUS_ADS_EXCPTN      
 
**--For bus error and address error routines--**  
*Read the content of A7, display the content of the Supervisor Status Word, 
*Bus Address and Instruction register all in a single line with spaces between them.   
BUS_ADS_EXCPTN:
        MOVE.L  #13,D0      ; Display error exception message
        TRAP    #15
        MOVEA.L A7,A2       ; A2 as Stack Pointer
        ADDA.L  #24,A2      ; A2 now point to the end of IR      
        LEA     END_USER_INPUT,A1 ; Prepare blank space to write SSW, BA, IR
        MOVE.B  #0,-(A1)    ; Null terminator (end of SSW, BA, IR)
        CLR.L   D1          ; To store word
        MOVE.W  -(A2),D1    ; SSW in D1
        BSR     HEX4toASCII ; ASCII IR stored in -4(A1)
        MOVE.B  #$20,-(A1)  ; Blank space
        MOVE.L  -(A2),D1    ; BA in D1 
        BSR     HEX8toASCII ; ASCII BA stored in -8(A1)
        MOVE.B  #$20,-(A1)  ; Blank space
        CLR.L   D1          ; To store word 
        MOVE.W  -(A2),D1    ; IR in D1
        BSR     HEX4toASCII ; ASCII SSW stored in -4(A1)
        MOVEM.L (A7)+,D1/A2 ; Restore registers
        BRA EXCEPTION       ; To display SSW, BA, IR
        
ILL_INST:
       MOVEM.L A1/D0,-(A7)
       LEA ILLINST_TXT, A1  ; Error msg
       BRA  EXCEPTION       ; Branch to display error msg

DIV_ZERO:
       MOVEM.L A1/D0,-(A7)
       LEA DIVZERO_TXT, A1
       BRA  EXCEPTION 

CHK_INST:
       MOVEM.L A1/D0,-(A7)
       LEA CHKINS_TXT, A1
       BRA  EXCEPTION 

PRIV_VIOL:
       MOVEM.L A1/D0,-(A7)
       LEA PRIVVIO_TXT, A1
       BRA  EXCEPTION       
       
LINE_A:
       MOVEM.L A1/D0,-(A7)
       LEA LINEA_TXT, A1
       BRA  EXCEPTION 
       
LINE_F:
       MOVEM.L A1/D0,-(A7)
       LEA LINEF_TXT, A1
       BRA  EXCEPTION     

*Display error message and display the value of the registers    
EXCEPTION: 
        MOVE.B  #13,D0      ; Print our error exceptionn msg
        TRAP    #15         
        BSR     DF          ; Call subroutine DF
        MOVEM.L (A7)+,D0/A1 ; Restore REGs
        LEA     STACK,A7    ; A7 point to Stack
        ADDA.L  #4,A0       ; User input store on stack right after A7

        BRA     BEGIN       ; Restart program

***------------------------ Invalid Message Subroutine --------------------------***  
*Prompt user when address is invalid
ADDR_INVALID:
       MOVEM.L D0/A1, -(A7)    ; Save REGs
       LEA     INVALID_ADR, A1 ; Display error message
       MOVE.B  #13,D0
       TRAP    #15
       MOVEM.L (A7)+,D0/A1     ; Restore REGs
       RTS

*Prompt user when command is invalid
CMD_INVALID:
       MOVEM.L D0/A1, -(A7)    ; Save REGs
       LEA     INVALID_COM, A1 ; Display error message
       MOVE.B  #13,D0
       TRAP    #15
       MOVEM.L (A7)+,D0/A1     ; Restore REGs
       RTS
   
    ORG $5000   
    MOVE.L  $5001, D0   ;Addr Error - Access long word at odd addr
    
    ORG $5100
    MOVE.B  $FFFFF,D0   ;BUS ERROR - access invalid addr
    
    ORG $5200
    ILLEGAL             ;ILLEGAL INSTR- Call illegal instruction $4AFC
    
    ORG $5300
    MOVE    #0,SR       ;Privilege Violation - Use provilege(supervisor) function
    MOVE    USP,A1
    
    ORG $5400
    DIVU    #0,D0       ;Divide by Zero
    
    ORG $5500
    MOVE.B  #10,D0       ;Check Instruction  - Check if D0<0 or D0 > 5
    CHK     #5,D0        ; Prompt CHK Error Exception if yes\
        
    ORG $5600
    ;LINE A and LINE F, Store $A000 and $F000 here using MM
    
END:
    END    START        ; last line of source


















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
