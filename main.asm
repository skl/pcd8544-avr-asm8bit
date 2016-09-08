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
.equ	DD_STATUS	= DDD7
.equ	PIN_LCDLED	= 2
.equ	PIN_LCDRST	= 3
.equ	PIN_LCDSCE	= 4
.equ	PIN_LCDDC	= 5
.equ	PIN_STATUS	= 7

; Variables
.def	SpiTmp		= r16
.def	TimerR		= r18
.def	Count		= r19

.org 0
	rjmp	RESET

RESET:
	; Setup timer
	ldi		TimerR, 0b0000_0101 ; [2:0] 001 = FCPU; 010 = FPU/8; 101 = FPU/64
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
	ldi		SpiTmp, 0x21 ; Tell LCD extended commands follow
	rcall	LCD_WRITE_CMD
	ldi		SpiTmp, 0xB0 ; Set LCD Vop (Contrast)
	rcall	LCD_WRITE_CMD
	ldi		SpiTmp, 0x04 ; Set Temp coefficent
	rcall	LCD_WRITE_CMD
	ldi		SpiTmp, 0x13 ; LCD bias mode 1:48 (try 0x13)
	rcall	LCD_WRITE_CMD
	ldi		SpiTmp, 0x20 ; We must send 0x20 before modifying the display control mode
	rcall	LCD_WRITE_CMD
	ldi		SpiTmp, 0x0C ; Set display control, 0C normal mode, 0D inverse
	rcall	LCD_WRITE_CMD

	rcall	LCD_CLEAR
	rcall	ADC_Init
	;rjmp	LCD_Loop

MAIN_LOOP:
	rcall	LCD_TEXT_A
	rcall	LCD_TEXT_0
	rcall	LCD_TEXT_COLON
	rcall	LCD_TEXT_SPACE

	ldi		r17, (1<<REFS0) | 0 ; ADC0
	sts		ADMUX, r17

	; Enable ADC with a clock division factor of 128 (125kHz?)
	ldi		r17, (1<<ADEN) | (1<<ADSC); | (1<<ADPS2) | (1<<ADPS1) | (1<<ADPS0)
	sts		ADCSRA, r17

	ADC_Wait:
		lds		r17, ADCSRA
		sbrc	r17, ADSC
		rjmp	ADC_Wait
		;lds		SpiTmp, ADCH
		;rcall	LCD_WRITE_DATA
		lds		r21, ADCL
		lds		r22, ADCH

	ldi		Count, 0
	ldi		r20, 0x07
	BIT_LOOP0:
		ror		r21 ; rotate bit 0 into carry
		brcs	TEXT_ELSE0 ; branch if carry bit is high
			rcall	LCD_TEXT_0
			rjmp	TEXT_ENDIF0
		TEXT_ELSE0:
			rcall	LCD_TEXT_1
		TEXT_ENDIF0:
		inc		Count
		cp		r20, Count
		brge	BIT_LOOP0

	ldi		Count, 0
	ldi		r20, 0x01
	BIT_LOOP1:
		ror		r22 ; rotate bit 0 into carry
		brcs	TEXT_ELSE1 ; branch if carry bit is high
			rcall	LCD_TEXT_0
			rjmp	TEXT_ENDIF1
		TEXT_ELSE1:
			rcall	LCD_TEXT_1
		TEXT_ENDIF1:
		inc		Count
		cp		r20, Count
		brge	BIT_LOOP1

	ldi		Count, 0
	ldi		r20, 0x04
	PAUSE_LOOP:
		rcall	PAUSE
		inc		Count
		cp		r20, Count
		brge	PAUSE_LOOP

	rcall	LCD_CLEAR
	rjmp	MAIN_LOOP

LCD_TEXT_0:
	ldi		SpiTmp, 0b0011_1111
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0010_0001
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0010_0001
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0011_1111
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WRITE_DATA
	ret

LCD_TEXT_1:
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0000_0010
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0011_1111
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WRITE_DATA
	ret

LCD_TEXT_2:
	ldi		SpiTmp, 0b0011_0001
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0010_1001
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0010_0010
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WRITE_DATA
	ret

LCD_TEXT_3:
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0001_1010
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WRITE_DATA
	ret

LCD_TEXT_4:
	ldi		SpiTmp, 0b0000_0111
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0000_0100
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0000_0100
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0011_1111
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WRITE_DATA
	ret

LCD_TEXT_5:
	ldi		SpiTmp, 0b0010_0111
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0001_1001
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WRITE_DATA
	ret

LCD_TEXT_6:
	ldi		SpiTmp, 0b0001_1110
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0001_1001
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WRITE_DATA
	ret

LCD_TEXT_7:
	ldi		SpiTmp, 0b0010_0001
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0001_0001
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0000_1001
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0000_0111
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WRITE_DATA
	ret

LCD_TEXT_8:
	ldi		SpiTmp, 0b0001_1010
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0001_1010
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WRITE_DATA
	ret

LCD_TEXT_9:
	ldi		SpiTmp, 0b0010_0111
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0011_1111
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WRITE_DATA
	ret

LCD_TEXT_A:
	ldi		SpiTmp, 0b0011_1110
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0000_1001
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0000_1001
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0011_1110
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WRITE_DATA
	ret

LCD_TEXT_B:
	ldi		SpiTmp, 0b0011_1111
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0001_1010
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WRITE_DATA
	ret

LCD_TEXT_C:
	ldi		SpiTmp, 0b0001_1110
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0010_0001
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0010_0001
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0001_0010
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WRITE_DATA
	ret

LCD_TEXT_COLON:
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0001_0100
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WRITE_DATA
	ret

LCD_TEXT_SPACE:
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WRITE_DATA
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WRITE_DATA
	ret

LCD_Loop:
	rcall	LCD_TEXT_0
	rcall	LCD_TEXT_1
	rcall	LCD_TEXT_2
	rcall	LCD_TEXT_3
	rcall	LCD_TEXT_4
	rcall	LCD_TEXT_5
	rcall	LCD_TEXT_6
	rcall	LCD_TEXT_7
	rcall	LCD_TEXT_8
	rcall	LCD_TEXT_9
	rcall	LCD_TEXT_A
	rcall	LCD_TEXT_B
	rcall	LCD_TEXT_C
	rcall	PAUSE
	rcall	LCD_CLEAR
	rjmp	LCD_Loop


LCD_CONTRAST:
	mov		r0, SpiTmp
	ldi		SpiTmp, 0x21
	rcall	LCD_WRITE_CMD
	mov		SpiTmp, R0
	ori		SpiTmp, 0x80
	rcall	LCD_WRITE_CMD
	ldi		SpiTmp, 0x20
	rcall	LCD_WRITE_CMD
	ret

LCD_WRITE_DATA:
	sbi		PORT_LCD, PIN_LCDDC ; DC = 1 for Data
	cbi		PORT_LCD, PIN_LCDSCE
	rcall	SPI_MasterTransmit
	sbi		PORT_LCD, PIN_LCDSCE
	ret

LCD_WRITE_CMD:
	cbi		PORT_LCD, PIN_LCDDC ; DC = 0 for Command
	cbi		PORT_LCD, PIN_LCDSCE
	rcall	SPI_MasterTransmit
	sbi		PORT_LCD, PIN_LCDSCE
	ret

LCD_GOTO_XY:
	ldi		SpiTmp, 0x80 ; column
	rcall	LCD_WRITE_CMD
	ldi		SpiTmp, 0x40 ; row
	rcall	LCD_WRITE_CMD
	ret

LCD_CLEAR:
	ldi		SpiTmp, 0x0C
	rcall	LCD_WRITE_CMD
	ldi		SpiTmp, 0x80
	rcall	LCD_WRITE_CMD

	ldi		YL, low(504)
	ldi		YH, high(504)
LCD_CL:
	clr		SpiTmp
	rcall	LCD_WRITE_DATA
	sbiw	YL, 1
	brne	LCD_CL
	rcall	LCD_GOTO_XY
	ret

ADC_Init:
	; Use Vcc (5V) as reference voltage and left-adjust
	ldi		r17, (1<<REFS0) | (1<<ADLAR)
	sts		ADMUX, r17 ; out of range for OUT
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
