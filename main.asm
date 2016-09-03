;
; AssemblerApplication1.asm
;
; Created: 28/08/2016 10:33:57
; Author : skl
;

; SPI port
.equ	DDR_SPI		= DDRB

; SPI pins
.equ	DD_SS		= DDB2
.equ	DD_MOSI		= DDB3
.equ	DD_SCK		= DDB5

; LCD port
.equ	DDR_LCD		= DDRD
.equ	PORT_LCD	= PORTD

; LCD pins
.equ	DD_LCDLED	= DDD2
.equ	DD_LCDRST	= DDD3
.equ	DD_LCDSCE	= DDD4
.equ	DD_LCDDC	= DDD5
.equ	PIN_LCDLED	= 2
.equ	PIN_LCDRST	= 3
.equ	PIN_LCDSCE	= 4
.equ	PIN_LCDDC	= 5

; Variables
.def	SpiTmp		= r16
.def	TimerR		= r18

.org 0
	rjmp	RESET

RESET:
	; Setup timer
	ldi		TimerR, 0b0000_0001 ; [2:0] 001 = FCPU; 010 = FPU/8
	out		TCCR0B, TimerR

	rcall	SPI_MasterInit

	; Set LCD control pins as outputs
	ldi		r17, (1<<DD_LCDLED) | (1<<DD_LCDRST) | (1<<DD_LCDSCE) | (1<<DD_LCDDC)
	out		DDR_LCD, r17

	; H/W Reset LCD
	cbi		PORT_LCD, PIN_LCDRST
	nop
	sbi		PORT_LCD, PIN_LCDRST

	; Turn on backlight
	cbi		PORT_LCD, PIN_LCDLED

	; Setup LCD
	ldi SpiTmp, 0x21 ; Tell LCD extended commands follow
	rcall LCD_WRITE_CMD
	ldi SpiTmp, 0xB0 ; Set LCD Vop (Contrast)
	rcall LCD_WRITE_CMD
	ldi SpiTmp, 0x04 ; Set Temp coefficent
	rcall LCD_WRITE_CMD
	ldi SpiTmp, 0x13 ; LCD bias mode 1:48 (try 0x13)
	rcall LCD_WRITE_CMD
	ldi SpiTmp, 0x20 ; We must send 0x20 before modifying the display control mode
	rcall LCD_WRITE_CMD
	ldi SpiTmp, 0x0D ; Set display control, 0C normal mode, 0D inverse
	rcall LCD_WRITE_CMD

	rcall LCD_CLEAR

MAIN_LOOP:
	rjmp MAIN_LOOP

LCD_CONTRAST:
	mov r0, SpiTmp
	ldi SpiTmp, 0x21
	rcall LCD_WRITE_CMD
	mov SpiTmp, R0
	ori SpiTmp, 0x80
	rcall LCD_WRITE_CMD
	ldi SpiTmp, 0x20
	rcall LCD_WRITE_CMD
	ret

LCD_WRITE_DATA:
	sbi PORT_LCD, PIN_LCDDC ; DC = 1 for Data
	cbi PORT_LCD, PIN_LCDSCE
	rcall SPI_MasterTransmit
	sbi PORT_LCD, PIN_LCDSCE
	ret

LCD_WRITE_CMD:
	cbi PORT_LCD, PIN_LCDDC ; DC = 0 for Command
	cbi PORT_LCD, PIN_LCDSCE
	rcall SPI_MasterTransmit
	sbi PORT_LCD, PIN_LCDSCE
	ret

LCD_GOTO_XY:
	ldi SpiTmp, 0x80 ; column
	rcall LCD_WRITE_CMD
	ldi SpiTmp, 0x40 ; row
	rcall LCD_WRITE_CMD
	ret

LCD_CLEAR:
	ldi SpiTmp, 0x0D
	rcall LCD_WRITE_CMD
	ldi SpiTmp, 0x80
	rcall LCD_WRITE_CMD

	ldi YL, low(504)
	ldi YH, high(504)
LCD_CL:
	clr SpiTmp
	rcall LCD_WRITE_DATA
	sbiw YL, 1
	brne LCD_CL
	rcall LCD_GOTO_XY
	ret

SPI_MasterInit:
	; Set MOSI and SCK output, all others input
	ldi		r17, (1<<DD_MOSI) | (1<<DD_SCK) | (1<<DD_SS)
	out		DDR_SPI, r17
	; Optionally revert SS pin to GPO port
	; sbi SS_PORT, SS
	; Enable SPI, Master, set clock rate fck/16
	ldi		r17, (1<<SPE) | (1<<MSTR) | (1<<SPR0)
	out		SPCR, r17
	ret

SPI_MasterTransmit:
	; Start transmission of data (r16)
	out		SPDR, r16
SPI_WaitTransmit:
	; Wait for transmission to complete
	in		r16, SPSR
	sbrs	r16, SPIF
	rjmp	SPI_WaitTransmit
	ret

PAUSE:
PLUPE:
	in		TimerR, TIFR0			; Wait for timer
	andi	TimerR, 0b0000_0010
	breq	PLUPE
	ldi		TimerR, 0b0000_0010
	out		TIFR0, TimerR
	ret
