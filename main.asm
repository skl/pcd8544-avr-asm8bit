;
; EECS X497.2
; Final Project: Oscillscope
;
; With a 48x84 pixel Nokia LCD, we can clearly see sine waves up to around 4Hz.
; We can draw much faster than this but it becomes indiscernible on this screen.
;
; Target: Ardiuno UNO R3
; Created: 2016/08/28
; Author : Stephen Lang
;

; SPI port
.equ	DDR_SPI		= DDRB		; All SPI pins are on Port B of the ATmega

; SPI pins
.equ	DD_SS		= DDB2		; Not used but _must_ be set to output regardless
.equ	DD_MOSI		= DDB3		; _Must_ use this pin for hardware SPI output
.equ	DD_SCK		= DDB5		; _Must_ use this pin for hardware SPI clock

; LCD port
.equ	DDR_LCD		= DDRD		; All LCD pins are kept to Port D for simplicity
.equ	PORT_LCD	= PORTD

; LCD pins
.equ	DD_LCDRST	= DDD3		; Reset
.equ	DD_LCDSCE	= DDD4		; Enable
.equ	DD_LCDDC	= DDD5		; Data/Command select
.equ	DD_LCDLED	= DDD6		; LED Backlight
.equ	PIN_LCDRST	= 3
.equ	PIN_LCDSCE	= 4
.equ	PIN_LCDDC	= 5
.equ	PIN_LCDLED	= 6

; Variables
.def	SpiTmp		= r16

.org 0
	rjmp	RESET

RESET:
	rcall	PWM_Init			; Pulse-Width Modulation (backlight dimming)
	rcall	SPI_MasterInit		; Serial Peripheral Interface (for LCD comms)
	rcall	LCD_Init			; Liquid Crystal Display (Nokia 5110)
	rcall	ADC_Init			; Analogue-to-Digital Converter (for the scope probe input)
	;rcall	LCD_BootMessages	; Print intro text to LCD (over SPI)
	rcall	PWM_FadeIn

MAIN:
	;rjmp	LCD_ADCBitStream
	
	rcall	LCD_Clear

	; In vertical addressing mode, we draw a column at a time.
	; Unlike horizontal addressing where we would draw a row (e.g. text)
	rcall	LCD_Vertical

	MAIN_Loop:
		rcall	PAUSE_Short		; Slow down our draw, the LCD can't cope with it (ghosting)
		rcall	ADC_Read		; Grab an 8-bit left-aligned conversion result into r22

		; Screen is 84 pixels high
		; Input voltage range is 0 - 5V
		; y=0  at 5V (when r22 is 0xFF)
		; y=83 at 0V (when r22 is 0x00)

		; We write one column at a time, always a pixel in each column,
		; the LCD deals with wrap-around so we don't have to.

		; Take r22 (ADCH) and work out which row to draw on:
		;
		; Row  | Values   | Range
		; -----------------------  
		; 0x40   213 - 255   42
		; 0x41   170 - 212   42
		; 0x42   127 - 169   42
		; 0x43    84 - 126   42
		; 0x44    42 - 83    41
		; 0x45     0 - 41    41
		;
		cpi		r22, 213		; if r21 >= 213
		brsh	DataInRow0
		cpi		r22, 170		; else if r21 >= 170
		brsh	DataInRow1
		cpi		r22, 127		; else if r21 >= 127
		brsh	DataInRow2
		cpi		r22, 84			; else if r21 >= 84
		brsh	DataInRow3
		cpi		r22, 42			; else if r21 >= 42
		brsh	DataInRow4
		rjmp	DataInRow5		; else

		DataInRow0:
			ldi		SpiTmp, 0b1111_1111	; Draw pixel
			rcall	LCD_WriteData

			; Clear other rows
			ldi		SpiTmp, 0
			rcall	LCD_WriteData
			ldi		SpiTmp, 0
			rcall	LCD_WriteData
			ldi		SpiTmp, 0
			rcall	LCD_WriteData
			ldi		SpiTmp, 0
			rcall	LCD_WriteData
			ldi		SpiTmp, 0
			rcall	LCD_WriteData
			
			rjmp	Main_Loop

		DataInRow1:
			; Clear other rows
			ldi		SpiTmp, 0
			rcall	LCD_WriteData

			ldi		SpiTmp, 0b1111_1111 ; Draw pixel
			rcall	LCD_WriteData

			; Clear other rows
			ldi		SpiTmp, 0
			rcall	LCD_WriteData
			ldi		SpiTmp, 0
			rcall	LCD_WriteData
			ldi		SpiTmp, 0
			rcall	LCD_WriteData
			ldi		SpiTmp, 0
			rcall	LCD_WriteData
			
			rjmp	Main_Loop

		DataInRow2:
			; Clear other rows
			ldi		SpiTmp, 0
			rcall	LCD_WriteData
			ldi		SpiTmp, 0
			rcall	LCD_WriteData

			ldi		SpiTmp, 0b1111_1111 ; Draw pixel
			rcall	LCD_WriteData

			; Clear other rows
			ldi		SpiTmp, 0
			rcall	LCD_WriteData
			ldi		SpiTmp, 0
			rcall	LCD_WriteData
			ldi		SpiTmp, 0
			rcall	LCD_WriteData
			
			rjmp	Main_Loop

		DataInRow3:
			; Clear other rows
			ldi		SpiTmp, 0
			rcall	LCD_WriteData
			ldi		SpiTmp, 0
			rcall	LCD_WriteData
			ldi		SpiTmp, 0
			rcall	LCD_WriteData

			ldi		SpiTmp, 0b1111_1111 ; Draw pixel
			rcall	LCD_WriteData

			; Clear other rows
			ldi		SpiTmp, 0
			rcall	LCD_WriteData
			ldi		SpiTmp, 0
			rcall	LCD_WriteData
			
			rjmp	Main_Loop

		DataInRow4:
			; Clear other rows
			ldi		SpiTmp, 0
			rcall	LCD_WriteData
			ldi		SpiTmp, 0
			rcall	LCD_WriteData
			ldi		SpiTmp, 0
			rcall	LCD_WriteData
			ldi		SpiTmp, 0
			rcall	LCD_WriteData

			ldi		SpiTmp, 0b1111_1111 ; Draw pixel
			rcall	LCD_WriteData

			; Clear other rows
			ldi		SpiTmp, 0
			rcall	LCD_WriteData
			
			rjmp	Main_Loop

		DataInRow5:
			; Clear other rows
			ldi		SpiTmp, 0
			rcall	LCD_WriteData
			ldi		SpiTmp, 0
			rcall	LCD_WriteData
			ldi		SpiTmp, 0
			rcall	LCD_WriteData
			ldi		SpiTmp, 0
			rcall	LCD_WriteData
			ldi		SpiTmp, 0
			rcall	LCD_WriteData

			ldi		SpiTmp, 0b1111_1111 ; Draw pixel
			rcall	LCD_WriteData

			rjmp	Main_Loop
	
; Displays 10-bit binary value from ADC0 using bit-banging.
; Expects right-aligned ADC capture.
;
; @param	r21	ADCL
; @param	r22	ADCH
LCD_ADCBitStream:
	rcall	ADC_Read
	ldi		r19, 0
	ldi		r20, 0x07 ; read bits [0:7]
	BIT_Loop0:
		ror		r21 ; rotate bit 0 into carry from ADCL
		brcs	TEXT_Else0 ; branch if carry bit is high
			rcall	LCD_Text0
			rjmp	TEXT_EndIf0
		TEXT_Else0:
			rcall	LCD_Text1
		TEXT_EndIf0:
		inc		r19
		cp		r20, r19
		brge	BIT_Loop0

	ldi		r19, 0
	ldi		r20, 0x01 ; read bits [0:1]
	BIT_Loop1:
		ror		r22 ; rotate bit 0 into carry from ADCH
		brcs	TEXT_Else1 ; branch if carry bit is high
			rcall	LCD_Text0
			rjmp	TEXT_EndIf1
		TEXT_Else1:
			rcall	LCD_Text1
		TEXT_EndIf1:
		inc		r19
		cp		r20, r19
		brge	BIT_Loop1

	rcall	PAUSE_Short

	rcall	LCD_Clear
	rjmp	LCD_ADCBitStream

; Initialise A/D multiplex register for ADC0
; Use Vcc (5V) as reference voltage
ADC_Init:
	ldi		r17, (1<<REFS0) | (1<<ADLAR)	; left-align bits
	sts		ADMUX, r17						; out of range for OUT, using STS instead
	ret

; Reads ADCL into r21 and ADCH into r22.
; Up to 10-bit ADC, left- or right- aligned as per ADMUX[ADLAR]
ADC_Read:
	; Enable ADC with a clock division factor of 111 = /128 (125 kHz) or 110 = /64 (250kHz)
	ldi		r17, (1<<ADEN) | (1<<ADSC) | (1<<ADPS2) | (1<<ADPS1); | (1<<ADPS0)
	sts		ADCSRA, r17

	ADC_Wait:
		lds		r17, ADCSRA
		sbrc	r17, ADSC
		rjmp	ADC_Wait
		lds		r21, ADCL
		lds		r22, ADCH
	ret

SPI_MasterInit:
	; Set MOSI and SCK output, all others input
	ldi		r17, (1<<DD_MOSI) | (1<<DD_SCK) | (1<<DD_SS)
	out		DDR_SPI, r17
	ldi		r17, (1<<SPE) | (1<<MSTR) | (1<<SPR0) ; Enable SPI, Master, set clock rate fck/16
	out		SPCR, r17 ; SPI Control Register
	ret

; Sends r16 to SPDR (SPI Data Register)
SPI_MasterTransmit:
	out		SPDR, r16	; Start transmission of data
SPI_WaitTransmit:
	; Wait for transmission to complete
	in		r16, SPSR	; SPI Status Register
	sbrs	r16, SPIF	; SPI Transmission Flag
	rjmp	SPI_WaitTransmit
	ret

; Initialise 8 bit Pulse-Width Modulation
PWM_Init:
	; OCR0A - Output Compare Register A
	ldi		r16, 0xFF	; Set initial duty cycle to always HIGH so LCD backlight starts OFF
	out		OCR0A, r16
	
	; TCCR0A - Timer/Counter Control Register A
	ldi		r16, (1<<COM0A1) | (1<<WGM01) | (1<<WGM00) ; Clear OC0A on compare match, Waveform generation mode 3 (Fast PWM)
	out		TCCR0A, r16

	; TCCR0B - Timer/Counter Control Register B
	ldi		r16, (1<<CS02) | (CS01) | (1<<CS00) ; Clock select 001 = CLKIO; 010 = CLKIO/8; 101 = CLKIO/1024 (from prescaler)
	out		TCCR0B, r16
	ret

PWM_FadeIn:
	ldi		r16, 255
PWM_FadeInLoop:
	dec		r16
	out		OCR0A, r16
	ldi		r19, 1
	rcall	PAUSE_Long
	cpi		r16, 0
	brne	PWM_FadeInLoop
		out		OCR0A, r16
		ldi		r19, 32
		rcall	PAUSE_Long
	ret

PWM_FadeOut:
	ldi		r16, 0
PWM_FadeOutLoop:
	inc		r16
	out		OCR0A, r16
	ldi		r19, 1
	rcall	PAUSE_Long
	cpi		r16, 255
	brne	PWM_FadeOutLoop
		out		OCR0A, r16
		ldi		r19, 32
		rcall	PAUSE_Long
	ret

; Simple pause function
; @param r19 Delay multiplier
PAUSE_Long:
	PAUSE0:
		ldi		r20, 255
	PAUSE1:
		ldi		r21, 64
	PAUSE2:
		dec		r21
		brne	PAUSE2
			dec		r20
			brne	PAUSE1
		dec		r19
			brne	PAUSE0
		ret

; Delay depends on the timer clock prescaler value in TCCR0B[CS[02:00]]
PAUSE_Short:
	in		r16, TIFR0 ; Wait for timer interrupt flag
	andi	r16, 0b0000_0010
	breq	PAUSE_Short
	ldi		r16, 0b0000_0010
	out		TIFR0, r16
	ret

LCD_Init:
	; Set LCD control pins as outputs
	ldi		r17, (1<<DD_LCDLED) | (1<<DD_LCDRST) | (1<<DD_LCDSCE) | (1<<DD_LCDDC)
	out		DDR_LCD, r17

	; H/W Reset LCD
	cbi		PORT_LCD, PIN_LCDRST
	nop
	sbi		PORT_LCD, PIN_LCDRST

	; Setup LCD
	ldi		SpiTmp, 0x21	; Tell LCD extended commands follow
	rcall	LCD_WriteCommand
	ldi		SpiTmp, 0xB0	; Set LCD Vop (Contrast)
	rcall	LCD_WriteCommand
	ldi		SpiTmp, 0x04	; Set Temp coefficent
	rcall	LCD_WriteCommand
	ldi		SpiTmp, 0x14	; LCD bias mode 1:48
	rcall	LCD_WriteCommand
	rcall	LCD_Horizontal
	ldi		SpiTmp, 0x0C	; Set display control, 0C normal mode, 0D inverse
	rcall	LCD_WriteCommand

	rcall	LCD_Clear
	ret

LCD_BootMessages:
	rcall	LCD_BootMessage0
	rcall	PWM_FadeIn
	ldi		r19, 0xFF
	rcall	PAUSE_Long
	ldi		r19, 0xFF
	rcall	PAUSE_Long
	ldi		r19, 0xFF
	rcall	PAUSE_Long
	ldi		r19, 0xFF
	rcall	PAUSE_Long
	ldi		r19, 0xFF
	rcall	PAUSE_Long
	ldi		r19, 0xFF
	rcall	PAUSE_Long

	rcall	LCD_Clear
	rcall	PWM_FadeOut

	rcall	LCD_BootMessage1
	rcall	PWM_FadeIn
	ldi		r19, 0xFF
	rcall	PAUSE_Long
	ldi		r19, 0xFF
	rcall	PAUSE_Long
	ldi		r19, 0xFF
	rcall	PAUSE_Long
	ldi		r19, 0xFF
	rcall	PAUSE_Long
	ldi		r19, 0xFF
	rcall	PAUSE_Long
	ldi		r19, 0xFF
	rcall	PAUSE_Long

	rcall	LCD_Clear
	rcall	PWM_FadeOut
	rcall	PWM_FadeIn

	ret

LCD_BootMessage0:
	ldi		SpiTmp, 0x41 ; row
	rcall	LCD_WriteCommand
	ldi		SpiTmp, 0x80 ; column
	rcall	LCD_WriteCommand

	rcall	LCD_TextSpace
	rcall	LCD_TextSpace
	rcall	LCD_TextSpace

	; eecs
	rcall	LCD_TextE
	rcall	LCD_TextE
	rcall	LCD_TextC
	rcall	LCD_TextS

	rcall	LCD_TextSpace

	; x497.2
	rcall	LCD_TextX
	rcall	LCD_Text4
	rcall	LCD_Text9
	rcall	LCD_Text7
	rcall	LCD_TextDot
	rcall	LCD_Text2

	ldi		SpiTmp, 0x42 ; row
	rcall	LCD_WriteCommand
	ldi		SpiTmp, 0x80 ; column
	rcall	LCD_WriteCommand

	rcall	LCD_TextSpace
	rcall	LCD_TextSpace

	; final
	rcall	LCD_TextF
	rcall	LCD_TextI
	rcall	LCD_TextN
	rcall	LCD_TextA
	rcall	LCD_TextL

	rcall	LCD_TextSpace

	; project
	rcall	LCD_TextP
	rcall	LCD_TextR
	rcall	LCD_TextO
	rcall	LCD_TextJ
	rcall	LCD_TextE
	rcall	LCD_TextC
	rcall	LCD_TextT

	ldi		SpiTmp, 0x44 ; row
	rcall	LCD_WriteCommand
	ldi		SpiTmp, 0x80 ; column
	rcall	LCD_WriteCommand

	rcall	LCD_TextSpace

	rcall	LCD_TextB
	rcall	LCD_TextY

	rcall	LCD_TextSpace

	rcall	LCD_TextS
	rcall	LCD_TextT
	rcall	LCD_TextE
	rcall	LCD_TextP
	rcall	LCD_TextH
	rcall	LCD_TextE
	rcall	LCD_TextN

	rcall	LCD_TextSpace

	rcall	LCD_TextL
	rcall	LCD_TextA
	rcall	LCD_TextN
	rcall	LCD_TextG

	ret

LCD_BootMessage1:
	ldi		SpiTmp, 0x41 ; row
	rcall	LCD_WriteCommand
	ldi		SpiTmp, 0x80 ; column
	rcall	LCD_WriteCommand

	rcall	LCD_TextSpace
	rcall	LCD_TextSpace

	; oscilloscope
	rcall	LCD_TextO
	rcall	LCD_TextS
	rcall	LCD_TextC
	rcall	LCD_TextI
	rcall	LCD_TextL
	rcall	LCD_TextL
	rcall	LCD_TextO
	rcall	LCD_TextS
	rcall	LCD_TextC
	rcall	LCD_TextO
	rcall	LCD_TextP
	rcall	LCD_TextE

	ldi		SpiTmp, 0x43 ; row
	rcall	LCD_WriteCommand
	ldi		SpiTmp, 0x80 ; column
	rcall	LCD_WriteCommand

	rcall	LCD_TextW
	rcall	LCD_TextR
	rcall	LCD_TextI
	rcall	LCD_TextT
	rcall	LCD_TextT
	rcall	LCD_TextE
	rcall	LCD_TextN

	rcall	LCD_TextSpace

	rcall	LCD_TextI
	rcall	LCD_TextN

	rcall	LCD_TextSpace

	rcall	LCD_Text8
	rcall	LCD_TextHyphen
	rcall	LCD_TextB
	rcall	LCD_TextI
	rcall	LCD_TextT

	ldi		SpiTmp, 0x44 ; row
	rcall	LCD_WriteCommand
	ldi		SpiTmp, 0x80 ; column
	rcall	LCD_WriteCommand

	rcall	LCD_TextSpace
	rcall	LCD_TextSpace

	rcall	LCD_TextA
	rcall	LCD_TextV
	rcall	LCD_TextR

	rcall	LCD_TextSpace

	rcall	LCD_TextA
	rcall	LCD_TextS
	rcall	LCD_TextS
	rcall	LCD_TextE
	rcall	LCD_TextM
	rcall	LCD_TextB
	rcall	LCD_TextL
	rcall	LCD_TextE
	rcall	LCD_TextR

	ret

LCD_WriteData:
	sbi		PORT_LCD, PIN_LCDDC ; DC = 1 for Data
	cbi		PORT_LCD, PIN_LCDSCE
	rcall	SPI_MasterTransmit
	sbi		PORT_LCD, PIN_LCDSCE
	ret

LCD_WriteCommand:
	cbi		PORT_LCD, PIN_LCDDC ; DC = 0 for Command
	cbi		PORT_LCD, PIN_LCDSCE
	rcall	SPI_MasterTransmit
	sbi		PORT_LCD, PIN_LCDSCE
	ret

LCD_GotoX0Y0:
	ldi		SpiTmp, 0x80 ; column
	rcall	LCD_WriteCommand
	ldi		SpiTmp, 0x40 ; row
	rcall	LCD_WriteCommand
	ret

LCD_Clear:
	ldi		SpiTmp, 0x0C
	rcall	LCD_WriteCommand
	ldi		SpiTmp, 0x80
	rcall	LCD_WriteCommand

	ldi		YL, low(504)
	ldi		YH, high(504)
LCD_ClearWait:
	clr		SpiTmp
	rcall	LCD_WriteData
	sbiw	YL, 1
	brne	LCD_ClearWait
	rcall	LCD_GotoX0Y0
	ret

LCD_Horizontal:
	ldi		SpiTmp, 0x20 ; 20 = horizontal addressing, 22 = vertical addressing
	rcall	LCD_WriteCommand
	ret

LCD_Vertical:
	ldi		SpiTmp, 0x22 ; 20 = horizontal addressing, 22 = vertical addressing
	rcall	LCD_WriteCommand
	ret

LCD_Text0:
	ldi		SpiTmp, 0b0011_1111
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_1001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0011_1111
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret

LCD_Text1:
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0010
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0011_1111
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret

LCD_Text2:
	ldi		SpiTmp, 0b0011_0001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_1001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0010
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret

LCD_Text3:
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0001_1010
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret

LCD_Text4:
	ldi		SpiTmp, 0b0000_0111
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0100
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0100
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0011_1111
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret

LCD_Text5:
	ldi		SpiTmp, 0b0010_0111
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0001_1001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret

LCD_Text6:
	ldi		SpiTmp, 0b0001_1110
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0001_1001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret

LCD_Text7:
	ldi		SpiTmp, 0b0011_0001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_1001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0101
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0011
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret

LCD_Text8:
	ldi		SpiTmp, 0b0001_1010
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0001_1010
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret

LCD_Text9:
	ldi		SpiTmp, 0b0000_0010
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0001_1110
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret

LCD_TextA:
	ldi		SpiTmp, 0b0011_1110
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_1001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_1001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0011_1110
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret

LCD_TextB:
	ldi		SpiTmp, 0b0011_1111
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0001_1010
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret

LCD_TextC:
	ldi		SpiTmp, 0b0001_1110
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0001_0010
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret

LCD_TextD:
	ldi		SpiTmp, 0b0011_1111
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0001_1110
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret

LCD_TextE:
	ldi		SpiTmp, 0b0011_1111
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret

LCD_TextF:
	ldi		SpiTmp, 0b0011_1111
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0101
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0101
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret

LCD_TextG:
	ldi		SpiTmp, 0b0001_1110
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0001_1101
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret

LCD_TextH:
	ldi		SpiTmp, 0b0011_1111
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0100
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0100
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0011_1111
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret

LCD_TextI:
	ldi		SpiTmp, 0b0010_0001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0011_1111
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret

LCD_TextJ:
	ldi		SpiTmp, 0b0001_0001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0001_1111
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret

LCD_TextK:
	ldi		SpiTmp, 0b0011_1111
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0100
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_1010
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0011_0001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret

LCD_TextL:
	ldi		SpiTmp, 0b0011_1111
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0000
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0000
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0000
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret

LCD_TextM:
	ldi		SpiTmp, 0b0011_1111
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0010
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0100
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0010
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0011_1111
	rcall	LCD_WriteData
	ret

LCD_TextN:
	ldi		SpiTmp, 0b0011_1111
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0010
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0100
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0011_1111
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret

LCD_TextO:
	ldi		SpiTmp, 0b0001_1110
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0001_1110
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret

LCD_TextP:
	ldi		SpiTmp, 0b0011_1111
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0101
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0101
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0010
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret

LCD_TextQ:
	ldi		SpiTmp, 0b0001_1110
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_1001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0001_0001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_1110
	rcall	LCD_WriteData
	ret

LCD_TextR:
	ldi		SpiTmp, 0b0011_1111
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0101
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0101
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0011_1010
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret

LCD_TextS:
	ldi		SpiTmp, 0b0010_0010
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0001_1001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret

LCD_TextT:
	ldi		SpiTmp, 0b0000_0001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0011_1111
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0001
	rcall	LCD_WriteData
	ret

LCD_TextU:
	ldi		SpiTmp, 0b0001_1111
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0000
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0000
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0001_1111
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret

LCD_TextV:
	ldi		SpiTmp, 0b0000_1111
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0001_0000
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0000
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0001_0000
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_1111
	rcall	LCD_WriteData
	ret

LCD_TextW:
	ldi		SpiTmp, 0b0001_1111
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0000
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0001_1100
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0000
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0001_1111
	rcall	LCD_WriteData
	ret

LCD_TextX:
	ldi		SpiTmp, 0b0010_0010
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0001_0100
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_1000
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0001_0100
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0010
	rcall	LCD_WriteData
	ret

LCD_TextY:
	ldi		SpiTmp, 0b0000_0011
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0100
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0011_1000
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0100
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0011
	rcall	LCD_WriteData
	ret

LCD_TextZ:
	ldi		SpiTmp, 0b0011_0001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_1001
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0101
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0010_0011
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret

LCD_TextDot:
	ldi		SpiTmp, 0b0010_0000
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret

LCD_TextColon:
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0001_0100
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret

LCD_TextHyphen:
	ldi		SpiTmp, 0b0000_0100
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0100
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0100
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret

LCD_TextSpace:
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ldi		SpiTmp, 0b0000_0000
	rcall	LCD_WriteData
	ret
