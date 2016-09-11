;
; EECS X497.2
; Final Project: Oscilloscope
;
; With a 48x84 pixel Nokia LCD, we can clearly see sine and triangle waves up to around 4Hz.
; Horizontal scaling would allow us to see waves up to around fADC/2 or about 125kHz.
;
; Square and sawtooth waves don't work so well as there is no connecting line drawn between
; pixels.
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
	rcall	LCD_BootMessages	; Print intro text to LCD (over SPI)
	;rcall	PWM_FadeIn
	;rcall	LCD_Clear

MAIN:
	;rjmp	LCD_ADCBitStream	; Show raw 10-bit ADC data in binary (for testing)

	; In vertical addressing mode, we draw a column at a time.
	; Unlike horizontal addressing where we would draw a row (e.g. text)
	rcall	LCD_Vertical

	; Screen is 84 pixels high, accessed through 6 rows in the first instance.
	; Input voltage range is 0 - 5V
	; y=0  at 5V (when r22 is 0xFF) to draw at the top of screen
	; y=83 at 0V (when r22 is 0x00) to draw at the bottom

	; We write one column at a time, always a pixel in each column,
	; the LCD deals with wrap-around so we don't have to.
	; Just need to make sure that we clear unused rows.

	; Take r22 (ADCH) and work out which row to access.
	; Then, work out which pixel to draw in that row.

	; I could've used binary division as scaling but those algorithms take many cycles...
	; This is faster but not really scalable to larger screens.

	; Also this is based on the 8-bit ADCH value only and not the two additional
	; bits in ADCL. Two reasons for this:
	; 1) 8-bit ADC mode on the ATmega allows for a higher sample rate
	; 2) Simpler code.
	MAIN_Loop:
		rcall	PAUSE_Short		; Slow down our draw, easy way to avoid horizontal scaling
		rcall	ADC_Read		; Grab an 8-bit left-aligned conversion result into r22

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
		brsh	JumpToDataInRow3
		cpi		r22, 42			; else if r21 >= 42
		brsh	JumpToDataInRow4
		rjmp	DataInRow5		; else

		; These are out of reach for BRSH
		JumpToDataInRow3: rjmp DataInRow3
		JumpToDataInRow4: rjmp DataInRow4

		DataInRow0:
			ldi		r20, 5			; Number of rows to clear

			; Row |  Values  | Range
			; -----------------------  
			;  0   250 - 255    5
			;  1   244 - 249    5
			;  2   239 - 243    4
			;  3   233 - 238    5
			;  4   228 - 232    4
			;  5   223 - 227    4
			;  6   218 - 222    4
			;  7   213 - 217    4
			;
			cpi		r22, 250
			brsh	DataInRow0Bit0
			cpi		r22, 244
			brsh	DataInRow0Bit1
			cpi		r22, 239
			brsh	DataInRow0Bit2
			cpi		r22, 233
			brsh	DataInRow0Bit3
			cpi		r22, 228
			brsh	DataInRow0Bit4
			cpi		r22, 223
			brsh	DataInRow0Bit5
			cpi		r22, 218
			brsh	DataInRow0Bit6
			rjmp	DataInBit7

			DataInRow0Bit0: rjmp DataInBit0
			DataInRow0Bit1: rjmp DataInBit1
			DataInRow0Bit2: rjmp DataInBit2
			DataInRow0Bit3: rjmp DataInBit3
			DataInRow0Bit4: rjmp DataInBit4
			DataInRow0Bit5: rjmp DataInBit5
			DataInRow0Bit6: rjmp DataInBit6

		DataInRow1:
			ldi		SpiTmp, 0
			rcall	LCD_WriteData

			ldi		r20, 4			; Number of rows to clear

			; Row |  Values  | Range
			; -----------------------  
			;  0   207 - 212    5
			;  1   201 - 206    5
			;  2   196 - 200    4
			;  3   190 - 195    5
			;  4   185 - 189    4
			;  5   180 - 184    4
			;  6   175 - 179    4
			;  7   170 - 174    4
			;
			cpi		r22, 207
			brsh	DataInRow1Bit0
			cpi		r22, 201
			brsh	DataInRow1Bit1
			cpi		r22, 196
			brsh	DataInRow1Bit2
			cpi		r22, 190
			brsh	DataInRow1Bit3
			cpi		r22, 185
			brsh	DataInRow1Bit4
			cpi		r22, 180
			brsh	DataInRow1Bit5
			cpi		r22, 175
			brsh	DataInRow1Bit6
			rjmp	DataInBit7

			; RJMP has wider range than BRSH
			DataInRow1Bit0: rjmp DataInBit0
			DataInRow1Bit1: rjmp DataInBit1
			DataInRow1Bit2: rjmp DataInBit2
			DataInRow1Bit3: rjmp DataInBit3
			DataInRow1Bit4: rjmp DataInBit4
			DataInRow1Bit5: rjmp DataInBit5
			DataInRow1Bit6: rjmp DataInBit6

		DataInRow2:
			ldi		SpiTmp, 0
			rcall	LCD_WriteData
			ldi		SpiTmp, 0
			rcall	LCD_WriteData

			ldi		r20, 3			; Number of rows to clear

			; Row |  Values  | Range
			; -----------------------  
			;  0   164 - 169    5
			;  1   158 - 163    5
			;  2   153 - 157    4
			;  3   147 - 152    5
			;  4   142 - 146    4
			;  5   137 - 141    4
			;  6   132 - 136    4
			;  7   127 - 131    4
			;
			cpi		r22, 164
			brsh	DataInRow1Bit0
			cpi		r22, 158
			brsh	DataInRow1Bit1
			cpi		r22, 153
			brsh	DataInRow1Bit2
			cpi		r22, 147
			brsh	DataInRow1Bit3
			cpi		r22, 142
			brsh	DataInRow1Bit4
			cpi		r22, 137
			brsh	DataInRow1Bit5
			cpi		r22, 132
			brsh	DataInRow1Bit6
			rjmp	DataInBit7

			; RJMP has wider range than BRSH
			DataInRow2Bit0: rjmp DataInBit0
			DataInRow2Bit1: rjmp DataInBit1
			DataInRow2Bit2: rjmp DataInBit2
			DataInRow2Bit3: rjmp DataInBit3
			DataInRow2Bit4: rjmp DataInBit4
			DataInRow2Bit5: rjmp DataInBit5
			DataInRow2Bit6: rjmp DataInBit6

		DataInRow3:
			ldi		SpiTmp, 0
			rcall	LCD_WriteData
			ldi		SpiTmp, 0
			rcall	LCD_WriteData
			ldi		SpiTmp, 0
			rcall	LCD_WriteData

			ldi		r20, 2			; Number of rows to clear

			; Row |  Values  | Range
			; -----------------------  
			;  0   121 - 126    5
			;  1   115 - 120    5
			;  2   110 - 114    4
			;  3   104 - 109    5
			;  4    99 - 103    4
			;  5    94 -  98    4
			;  6    89 -  93    4
			;  7    84 -  88    4
			;
			cpi		r22, 121
			brsh	DataInRow3Bit0
			cpi		r22, 115
			brsh	DataInRow3Bit1
			cpi		r22, 110
			brsh	DataInRow3Bit2
			cpi		r22, 104
			brsh	DataInRow3Bit3
			cpi		r22, 99
			brsh	DataInRow3Bit4
			cpi		r22, 94
			brsh	DataInRow3Bit5
			cpi		r22, 89
			brsh	DataInRow3Bit6
			rjmp	DataInBit7

			; RJMP has wider range than BRSH
			DataInRow3Bit0: rjmp DataInBit0
			DataInRow3Bit1: rjmp DataInBit1
			DataInRow3Bit2: rjmp DataInBit2
			DataInRow3Bit3: rjmp DataInBit3
			DataInRow3Bit4: rjmp DataInBit4
			DataInRow3Bit5: rjmp DataInBit5
			DataInRow3Bit6: rjmp DataInBit6

		DataInRow4:
			ldi		SpiTmp, 0
			rcall	LCD_WriteData
			ldi		SpiTmp, 0
			rcall	LCD_WriteData
			ldi		SpiTmp, 0
			rcall	LCD_WriteData
			ldi		SpiTmp, 0
			rcall	LCD_WriteData

			ldi		r20, 1			; Number of rows to clear

			; Row |  Values  | Range
			; -----------------------  
			;  0    78 -  83    5
			;  1    72 -  77    5
			;  2    67 -  71    4
			;  3    64 -  66    4
			;  4    59 -  63    4
			;  5    54 -  58    4
			;  6    49 -  53    4
			;  7    42 -  48    4
			;
			cpi		r22, 78
			brsh	DataInRow4Bit0
			cpi		r22, 72
			brsh	DataInRow4Bit1
			cpi		r22, 67
			brsh	DataInRow4Bit2
			cpi		r22, 64
			brsh	DataInRow4Bit3
			cpi		r22, 59
			brsh	DataInRow4Bit4
			cpi		r22, 54
			brsh	DataInRow4Bit5
			cpi		r22, 49
			brsh	DataInRow4Bit6
			rjmp	DataInBit7

			; RJMP has wider range than BRSH
			DataInRow4Bit0: rjmp DataInBit0
			DataInRow4Bit1: rjmp DataInBit1
			DataInRow4Bit2: rjmp DataInBit2
			DataInRow4Bit3: rjmp DataInBit3
			DataInRow4Bit4: rjmp DataInBit4
			DataInRow4Bit5: rjmp DataInBit5
			DataInRow4Bit6: rjmp DataInBit6

		DataInRow5:
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

			ldi		r20, 0			; Number of rows to clear

			; Row |  Values  | Range
			; -----------------------  
			;  0    36 -  41    5
			;  1    30 -  35    5
			;  2    25 -  29    4
			;  3    20 -  24    4
			;  4    15 -  19    4
			;  5    10 -  14    4
			;  6     5 -   9    4
			;  7     0 -   4    4
			;
			cpi		r22, 36
			brsh	DataInRow5Bit0
			cpi		r22, 30
			brsh	DataInRow5Bit1
			cpi		r22, 25
			brsh	DataInRow5Bit2
			cpi		r22, 20
			brsh	DataInRow5Bit3
			cpi		r22, 15
			brsh	DataInRow5Bit4
			cpi		r22, 10
			brsh	DataInRow5Bit5
			cpi		r22, 5
			brsh	DataInRow5Bit6
			rjmp	DataInBit7

			; RJMP has wider range than BRSH
			DataInRow5Bit0: rjmp DataInBit0
			DataInRow5Bit1: rjmp DataInBit1
			DataInRow5Bit2: rjmp DataInBit2
			DataInRow5Bit3: rjmp DataInBit3
			DataInRow5Bit4: rjmp DataInBit4
			DataInRow5Bit5: rjmp DataInBit5
			DataInRow5Bit6: rjmp DataInBit6

		DataInBit7:
			ldi		SpiTmp, 0b1000_0000	; Draw pixel
			rcall	LCD_WriteData
			rjmp	ClearRows

		DataInBit6:
			ldi		SpiTmp, 0b0100_0000	; Draw pixel
			rcall	LCD_WriteData
			rjmp	ClearRows

		DataInBit5:
			ldi		SpiTmp, 0b0010_0000	; Draw pixel
			rcall	LCD_WriteData
			rjmp	ClearRows

		DataInBit4:
			ldi		SpiTmp, 0b0001_0000	; Draw pixel
			rcall	LCD_WriteData
			rjmp	ClearRows

		DataInBit3:
			ldi		SpiTmp, 0b0000_1000	; Draw pixel
			rcall	LCD_WriteData
			rjmp	ClearRows

		DataInBit2:
			ldi		SpiTmp, 0b0000_0100	; Draw pixel
			rcall	LCD_WriteData
			rjmp	ClearRows

		DataInBit1:
			ldi		SpiTmp, 0b0000_0010	; Draw pixel
			rcall	LCD_WriteData
			rjmp	ClearRows

		DataInBit0:
			ldi		SpiTmp, 0b0000_0001	; Draw pixel
			rcall	LCD_WriteData
			rjmp	ClearRows

		ClearRows:
			cpi		r20, 0	; Special case, no rows to clear
			brne	ActuallyClearRows
			rjmp	MAIN_Loop ; Out of branch range again
			ActuallyClearRows:
				ldi		r19, 0
				ClearRows_Loop:
					ldi		SpiTmp, 0
					rcall	LCD_WriteData
					inc		r19
					cp		r20, r19
					brne	ClearRows_Loop
				rjmp	MAIN_Loop
	
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
	; Set MOSI, SCK and SS to output, all others input
	ldi		r17, (1<<DD_MOSI) | (1<<DD_SCK) | (1<<DD_SS)
	out		DDR_SPI, r17
	
	; SPI Enable, Master, set clock rate fck/16
	ldi		r17, (1<<SPE) | (1<<MSTR) | (1<<SPR0)
	out		SPCR, r17	; SPI Control Register
	ret

; Sends r16 to SPDR (SPI Data Register)
SPI_MasterTransmit:
	out		SPDR, r16	; Start transmission of data
SPI_WaitTransmit:
	in		r16, SPSR	; SPI Status Register
	sbrs	r16, SPIF	; SPI Transmission Flag, wait for it
	rjmp	SPI_WaitTransmit
	ret

; Initialise 8 bit Pulse-Width Modulation
PWM_Init:
	; OCR0A - Output Compare Register A
	ldi		r16, 0xFF	; Set initial duty cycle to always HIGH so LCD backlight starts OFF
	out		OCR0A, r16
	
	; TCCR0A - Timer/Counter Control Register A
	; Clear OC0A on compare match, Waveform generation mode 3 (Fast PWM)
	ldi		r16, (1<<COM0A1) | (1<<WGM01) | (1<<WGM00)
	out		TCCR0A, r16

	; TCCR0B - Timer/Counter Control Register B
	; Clock select 001 = CLKIO; 010 = CLKIO/8; 101 = CLKIO/1024 (from prescaler)
	ldi		r16, (1<<CS02) | (CS01) | (1<<CS00)
	out		TCCR0B, r16
	ret

PWM_FadeIn:
	ldi		r16, 255
PWM_FadeInLoop:
	dec		r16
	out		OCR0A, r16		; Vary the duty cycle
	ldi		r19, 1
	rcall	PAUSE_Long
	cpi		r16, 0
	brne	PWM_FadeInLoop
		out		OCR0A, r16	; Final value
		ldi		r19, 32
		rcall	PAUSE_Long
	ret

PWM_FadeOut:
	ldi		r16, 0
PWM_FadeOutLoop:
	inc		r16
	out		OCR0A, r16		; Vary the duty cycle
	ldi		r19, 1
	rcall	PAUSE_Long
	cpi		r16, 255
	brne	PWM_FadeOutLoop
		out		OCR0A, r16	; Final value
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
	ldi		SpiTmp, 0x41 ; row 1
	rcall	LCD_WriteCommand
	ldi		SpiTmp, 0x80 ; column 0
	rcall	LCD_WriteCommand

	; Spaces help center text, like websites from the 90's
	rcall	LCD_TextSpace
	rcall	LCD_TextSpace
	rcall	LCD_TextSpace

	; EECS
	rcall	LCD_TextE
	rcall	LCD_TextE
	rcall	LCD_TextC
	rcall	LCD_TextS

	rcall	LCD_TextSpace

	; X497.2
	rcall	LCD_TextX
	rcall	LCD_Text4
	rcall	LCD_Text9
	rcall	LCD_Text7
	rcall	LCD_TextDot
	rcall	LCD_Text2

	ldi		SpiTmp, 0x42 ; row 2
	rcall	LCD_WriteCommand
	ldi		SpiTmp, 0x80 ; column 0
	rcall	LCD_WriteCommand

	rcall	LCD_TextSpace
	rcall	LCD_TextSpace

	; FINAL
	rcall	LCD_TextF
	rcall	LCD_TextI
	rcall	LCD_TextN
	rcall	LCD_TextA
	rcall	LCD_TextL

	rcall	LCD_TextSpace

	; PROJECT
	rcall	LCD_TextP
	rcall	LCD_TextR
	rcall	LCD_TextO
	rcall	LCD_TextJ
	rcall	LCD_TextE
	rcall	LCD_TextC
	rcall	LCD_TextT

	ldi		SpiTmp, 0x44 ; row 4
	rcall	LCD_WriteCommand
	ldi		SpiTmp, 0x80 ; column 0
	rcall	LCD_WriteCommand

	rcall	LCD_TextSpace

	; BY
	rcall	LCD_TextB
	rcall	LCD_TextY

	rcall	LCD_TextSpace

	; STEPHEN
	rcall	LCD_TextS
	rcall	LCD_TextT
	rcall	LCD_TextE
	rcall	LCD_TextP
	rcall	LCD_TextH
	rcall	LCD_TextE
	rcall	LCD_TextN

	rcall	LCD_TextSpace

	; LANG
	rcall	LCD_TextL
	rcall	LCD_TextA
	rcall	LCD_TextN
	rcall	LCD_TextG

	ret

LCD_BootMessage1:
	ldi		SpiTmp, 0x41 ; row 1
	rcall	LCD_WriteCommand
	ldi		SpiTmp, 0x80 ; column 0
	rcall	LCD_WriteCommand

	rcall	LCD_TextSpace
	rcall	LCD_TextSpace

	; OSCILLOSCOPE
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

	ldi		SpiTmp, 0x43 ; row 3
	rcall	LCD_WriteCommand
	ldi		SpiTmp, 0x80 ; column 0
	rcall	LCD_WriteCommand

	; WRITTEN
	rcall	LCD_TextW
	rcall	LCD_TextR
	rcall	LCD_TextI
	rcall	LCD_TextT
	rcall	LCD_TextT
	rcall	LCD_TextE
	rcall	LCD_TextN

	rcall	LCD_TextSpace

	; IN
	rcall	LCD_TextI
	rcall	LCD_TextN

	rcall	LCD_TextSpace

	; 8-BIT
	rcall	LCD_Text8
	rcall	LCD_TextHyphen
	rcall	LCD_TextB
	rcall	LCD_TextI
	rcall	LCD_TextT

	ldi		SpiTmp, 0x44 ; row 4
	rcall	LCD_WriteCommand
	ldi		SpiTmp, 0x80 ; column 0
	rcall	LCD_WriteCommand

	rcall	LCD_TextSpace
	rcall	LCD_TextSpace

	; AVR
	rcall	LCD_TextA
	rcall	LCD_TextV
	rcall	LCD_TextR

	rcall	LCD_TextSpace

	; ASSEMBLER
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
	sbi		PORT_LCD, PIN_LCDDC		; D/C = 1 for Data
	cbi		PORT_LCD, PIN_LCDSCE	; Set enable (active LOW)
	rcall	SPI_MasterTransmit
	sbi		PORT_LCD, PIN_LCDSCE	; Clear disable
	ret

LCD_WriteCommand:
	cbi		PORT_LCD, PIN_LCDDC		; D/C = 0 for Command
	cbi		PORT_LCD, PIN_LCDSCE	; Set enable (active LOW)
	rcall	SPI_MasterTransmit
	sbi		PORT_LCD, PIN_LCDSCE	; Clear disable
	ret

LCD_GotoX0Y0: ; YOLO, XOYO YOLO (tounge twister)
	ldi		SpiTmp, 0x80 ; column 0
	rcall	LCD_WriteCommand
	ldi		SpiTmp, 0x40 ; row 0
	rcall	LCD_WriteCommand
	ret

LCD_Clear: ; All your pixels are belong to us
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
	ldi		SpiTmp, 0x20 ; 0x20 = horizontal addressing
	rcall	LCD_WriteCommand
	ret

LCD_Vertical:
	ldi		SpiTmp, 0x22 ; 0x22 = vertical addressing
	rcall	LCD_WriteCommand
	ret

; Pixel font loosely based on Pixeled by OmegaPC777
; http://www.dafont.com/pixeled.font
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
