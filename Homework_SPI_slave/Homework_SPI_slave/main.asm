;
; Homework_SPI_slave.asm
;
; Created: 11/18/2023 2:45:23 PM
; Author : minhk
;


; Replace with your application code
.EQU SS=4 ; SS pin 
.EQU MISO=6 ;
.ORG 0
RJMP MAIN
MAIN: 
	LDI R29,0X30
	LDI R16,0XFF
	OUT DDRA,R16; for displaying output
	SBI DDRD,2
	CBI PORTD,2
	LDI R16,0X00
	OUT PORTA,R16 ;
	LDI R16,(1<<MISO) ;
	OUT DDRB,R16
	LDI R16,(1<<SPE0) ;SPI ENBALE; SPI MODE 0
	OUT SPCR0,R16
START: 
	CBI PORTD,2
	CALL keypad_scan
	mov r17,r24 //OUTPUT TO MASTER
	CPI R17,0xff
	breq start
	ADD R17,R29
	SBI PORTD,2
SPI_SS: 
	SBIC PINB,SS ; CHECK SS FLAG 
	RJMP SPI_SS
	RCALL SPI_TRANSACTION ; 
	OUT PORTA,R18;hi?n th? k? t? thu t? SPI
	CBI PORTD,2
	RJMP START ;
;SPI_TRANS truy?n data SPI gi?a Master và Slaver
;Input: R17 ch?a data ghi ra Slaver
;Output: R18 ch?a data ð?c t? Slaver S? d?ng R16
SPI_TRANSACTION:
	OUT SPDR0,R17 ;  FROM SLAVE TO MASTER 
CHECK_FLAG:
	IN R16,SPSR0 ;
	SBRS R16,SPIF0 ;CHECK FLAG SPIF0
	RJMP CHECK_FLAG ;
	IN R18,SPDR0 ;  FROM MASTER TO SLAVE
	RET

keypad_scan: 
	ldi r20, 0b00001111 ; set upper 4 bits of PORTD as input with pull-up, lower 4 bits as output 
	out DDRC, r20 
	ldi r20, 0b11111111 ; enable pull up resistor 
	out PORTC, r20
	ldi r22, 0b11110111 ; initial col mask 
	ldi r24, 0 ; initial pressed row value 
		ldi r23,3 ;scanning col index
	call DELAY
keypad_scan_loop: 
	out PORTC, r22 ; scan current col 
		nop ;need to have 1us delay to stablize 
	call DELAY
	sbic PINC, 4 ; check row 0 
	rjmp keypad_scan_check_col2 
	rjmp keypad_scan_found ; row 0 is pressed 
keypad_scan_check_col2:
	call DELAY
	sbic PINC, 5 ; check row 1 
	rjmp keypad_scan_check_col3 
	ldi r24, 1 ; row1 is pressed 
	rjmp keypad_scan_found 
keypad_scan_check_col3:
	call DELAY
	sbic PINC, 6 ; check row 2 
	rjmp keypad_scan_check_col4 
	call DELAY
	ldi r24, 2 ; row 2 is pressed 
	rjmp keypad_scan_found 
keypad_scan_check_col4:
	call DELAY
	sbic PINC, 7 ; check row 3 
	rjmp keypad_scan_next_row 
	call DELAY
	ldi r24, 3 ; row 3 is pressed 
	rjmp keypad_scan_found
keypad_scan_next_row: 
	; check if all rows have been scanned 
	call DELAY
	cpi r23,0 
	breq keypad_scan_not_found
	; shift row mask to scan next row 
	ror r22 
		dec r23 ;increase row index 
	call DELAY
	rjmp keypad_scan_loop
keypad_scan_found: 
	; combine row and column to get key value (0-15) 
		;key code = row*4 + col 
	call DELAY
	lsl r24 ; shift row value 4 bits to the left 
		lsl r24 
	add r24, r23 ; add row value to column value 
	call DELAY
	ret
keypad_scan_not_found: 
	ldi r24, 0xFF ; no key pressed 
	call DELAY
	ret

DELAY:
LDI R21,105 ;1MC
L1: LDI R20,250 ;1MC
L2: DEC R20 ;1MC
NOP ;1MC
BRNE L2 ;2/1MC
DEC R21 ;1MC
BRNE L1 ;2/1MC
RET ;4MC

