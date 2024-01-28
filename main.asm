;-------------------------------------------------INITIALIZATION----------------------------------------------------------

.CSEG
.ORG 0x00
	rjmp init

.ORG PCINT2addr
	rjmp keypad_ISR

;Data memory - we declare a variable that stores later the length of high / low state of a single beep
.DSEG
.ORG 0x100 
	period: .BYTE 1 ;1 byte variable in memory

;program memory continued
.CSEG 
.ORG 0x110

init:
	;stack initialization
	ldi R16, HIGH(RAMEND)
	out SPH, R16
	ldi R16, LOW(RAMEND)
	out SPL, R16

	;initializing port C_0 as an output
	sbi ddrc, 0

	ldi r20, 0x0f
	out ddrd, r20
	;Set rows to high (pull ups) and columns to low
	ldi r20, 0x30
	out portd, r20
	;Select rows as interrupt triggers
	ldi r20, (1<<pcint4)|(1<<pcint5)
	sts pcmsk2, r20
	;Enable pcint1
	ldi r20, (1<<pcie2)
	sts pcicr, r20
	;Reset register for output
	ldi r18, 0x00
	;Global Enable Interrupt
	sei


;--------------------------------------------------MAIN PROGRAM ----------------------------------------------------------
;main program:
stop:
	sleep ;waiting to be interrupted
	jmp stop


;---------- BUTTON DETECTION ----------

keypad_ISR:
	;Set rows as outputs and columns as inputs
	ldi r20, 0x30
	out ddrd, r20
	;Set columns to high (pull ups) and rows to low
	ldi r20, 0x0f
	out portd, r20
	;Read Port C. Columns code in low nibble
	in r16, pind
	;Store columns code to r18 on low nibble
	mov r18, r16
	andi r18, 0x0f
	;Set rows as inputs and columns as outputs
	ldi r20, 0x0f
	out ddrd, r20
	;Set rows to high (pull ups) and columns to low
	ldi r20, 0x30
	out portd, r20
	;Read Port C. Rows code in high nibble
	in r16, pind
	;Merge with previous read
	andi r16, 0x30
	add r18, r16

	mov r16,r18

	; Take the coordinates and compare them with button's coordinates
	ldi r18,0x11 
	cp r18,r16
	breq case1

	ldi r18,0x12
	cp r18,r16
	breq case2

	ldi r18,0x14
	cp r18,r16
	breq case3

	ldi r18,0x18
	cp r18,r16
	breq case4

	ldi r18,0x21
	cp r18,r16
	breq case5

	ldi r18,0x22
	cp r18,r16
	breq case6

	ldi r18,0x24
	cp r18,r16
	breq case7
	
	ldi r18,0x28
	cp r18,r16
	breq case8

	sei
	reti

; Accordingly to the button which we pushed we are deciding to which case will be run
case1:
	call button1
	reti
case2:
	call button2
	reti
case3:
	call button3
	reti
case4:
	call button4
	reti
case5:
	call button5
	reti
case6:
	call button6
	reti
case7:
	call button7
	reti
case8:
	call button8
	reti


;---------- BUTTON OPERATION ----------

button1:
	ldi R20, 210
	sts period, R20 ;loading the period variable - which determines the frequency of the squeaking
	call squeaking
	ret

button2:
	ldi R20, 200
	sts period, R20
	call squeaking
	ret
	
button3:
	ldi R20, 190
	sts period, R20
	call squeaking
	ret

button4:
	ldi R20, 180
	sts period, R20
	call squeaking
	ret

button5:
	ldi R20, 170
	sts period, R20
	call squeaking
	ret


button6:
	ldi R20, 160
	sts period, R20
	call squeaking
	ret

button7:
	ldi R20, 150
	sts period, R20
	call squeaking
	ret

button8:
	ldi R20, 140
	sts period, R20
	call squeaking
	ret

;----------beep----------


;single squeak - high state and then low state of a certain length Thus, We can produce consist of period digital signal wave

beep: 
	push R16			
	push R17			
	push R18			
	sbi portc, 0x00		

	;delay loops:
	lds R16, period     

delay1:										; Delay1 is high state we are waiting amount of time here then go low state
	ldi R17, 5          
delay2:  
	nop               	
	dec R17           	
	brne delay2  		
	dec R16            	
	brne delay1        	 
	cbi portc, 0x00     

	;delay loops:
   	mov R16, R21       	
  
delay11:									; Delay11 is low state also we are waiting here then we return from subroutine
	ldi R17, 4			 
delay22: 
	nop				  	
	dec R17			  	
	brne delay22 	  	
	dec R16           	
	brne delay11      	
	pop R18				
	pop R17				
	pop R16				
	ret                 

;----------squeaking----------
; Basicly changing the period we can produce analog signals from digital signals and thankfuly we can hear some sort of music notes :)
squeaking: ;it makes a single squeal a certain number of times
	push R16
	push R17
	push R18
	push R19
	push R20
	push R21
	push R22
	
	;sand length compensation - when the period is longer, you need to reduce the number of individual squeaks (so that the sounds have the same length):
	ldi R19, 255
	lds R20, period 
	sub R19, R20

	;special mode - set more than 0 to increase t_L during screeching:
	lds R21, period
	ldi R22, 0

	;making a squeal:
	mov R16, R19

delay111:
	ldi R17, 20
	add R21, R22
delay222:
	call beep
	dec R17
	brne delay222
	dec R16
	brne delay111

	pop R22
	pop R21
	pop R20
	pop R19
	pop R18
	pop R17
	pop R16
	ret