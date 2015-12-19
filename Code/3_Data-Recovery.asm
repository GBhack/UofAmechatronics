;==========================================================================
;                              MECHATRONIC PROJECT
;==========================================================================
;                                 12/02/2015
;By                       DIAGNE, MARZOUK and LEGLAYE
;With the help of                    BITON
;
;Data recovery program: read all bytes stored on I2C EEPROM module (512 bytes)
;and send them over Serial
;==========================================================================
;                          Configuration of the PIC
 List P=16f877
    #include <p16f877.inc>

    __CONFIG _CP_OFF & _WDT_OFF & _PWRTE_ON & _HS_OSC & _LVP_OFF & _CPD_OFF

;==========================================================================
;                                Reset vector
    org 0x00
    goto Main

;==========================================================================
;                                 EEaddresses

i       equ		0x43				; use for loops in delay
j       equ		0x44				; use for loops in delay
k       equ		0x45				; use for loops in delay

EEBank     equ		0x46 				; 85=>0 to change EEPROM bank
EEtrio     equ		0x47 				; 3 => 0 for X Y Z
EEcontrolW  equ		0x48                ; to store the Write control byte
EEcontrolR  equ		0x49 				; to store the Read control byte
EEaddress    equ 0x40	                ; EEPROM address to access

;==========================================================================

    org 0x10

;==========================================================================
;                         Macros to select the banks

Bank0	MACRO                       ; Select bank 0
	bcf	STATUS,RP0
	ENDM
    
;==========================================================================
;             Macros to control LEDs on PORTB (for debugging)

LEDS_OFF    MACRO
    BANKSEL PORTB
    movlw   .0
    movwf   PORTB
    ENDM

LEDS_ON    MACRO
    BANKSEL PORTB
    movlw   .255
    movwf   PORTB
    ENDM

LED1_ON    MACRO
    BANKSEL PORTB
    bsf  PORTB,0
    ENDM

LED1_OFF    MACRO
    BANKSEL PORTB
    bcf  PORTB,0
    ENDM

LED2_ON    MACRO
    BANKSEL PORTB
    bsf  PORTB,2
    ENDM

LED2_OFF    MACRO
    BANKSEL PORTB
    bcf  PORTB,2
    ENDM

LED3_ON    MACRO
    BANKSEL PORTB
    bsf  PORTB,4
    ENDM

LED3_OFF    MACRO
    BANKSEL PORTB
    bcf  PORTB,4
    ENDM

;==========================================================================
;				Main code
Main:

    ; Setting LEDs outputs
    BANKSEL     PORTB
	clrf        STATUS
	clrf        PORTB
    BANKSEL     TRISB
    movlw       .0
    movwf       TRISB
    LEDS_OFF

;==========================================================================
;			Initialize the TTL transmitter
;==========================================================================

    BANKSEL    TXSTA                ; Bank 1
    movlw      B'00100100'          ; BRGH = 1
    movwf      TXSTA                ; Enable Async Transmission, set brgh
    movlw      D'129'               ; 9600 baud @ 20 Mhz Fosc
    movwf      SPBRG
    BANKSEL    TXSTA                ; Bank 0
    BCF        TXSTA, CSRC          ; External oscillator
    BCF        TXSTA, TX9           ; Selects 8-bit transmission
    BANKSEL    RCSTA                ; Bank 0
    BSF        RCSTA, SPEN          ; Serial port enable
    BCF        RCSTA, RX9           ; Selects 8-bit reception


    call        SetupI2C            ;Initialize I2C
;WaitPC:
;    Bank0
;    movlw .65
;    SUBWF RCREG
;    btfss STATUS,2
;    GOTO WaitPC
Init:
    Bank0
	movlw       .255
	movwf       EEBank             ;Each bank of the 24AA04 is 256 bytes long
    movlw       b'10100000'        ;Control byte is 1010XX[0 for bank 1, 1 for bank 2][0 for reading 1 for writing]
    movwf       EEcontrolR
    movwf       EEcontrolW
    bsf         EEcontrolW,0
	movlw       .3
	movwf       EEtrio              ; We send a preset sequence every three bytes (X,Y,Z,B1,B2,X,Y...)
	movlw       .0
	movwf       EEaddress		    ; We start at the first address of Bank 0
ReadEEPROM:
    call        ReadI2C		        ;Read one byte (at EEaddress), store it into Work
    call        SendW               ;Send the work (byte read) through Serial
    movlw       .1
    call        delay               ;Wait a few ms
    Bank0
    incf        EEaddress,1         ;Increment EEaddress (for next iteration)
    decfsz      EEBank              ;Decrement EEbank. If EEbank=0: time to change bank
    goto        nextStep
    goto        changeBank

nextStep:
    decfsz      EEtrio              ;Decrement EEtrio. If EEtrio=0 : time to send a control sequence (B1,B2)
    goto        ReadEEPROM
    goto        newSet
    
newSet:
    movlw       .3
    movwf       EEtrio              ;Reset EEtrio
    movlw       .65
    call        SendW               ;Send B1
    movlw       .1
    call        delay
    movlw       .66
    call        SendW               ;Send B2
    movlw       .3
    call        delay
    goto        ReadEEPROM          ;Go back

changeBank:
    Bank0
    btfsc       EEcontrolR,1        ;Check if we already changed bank (if so, we read both banks and program is over)
    goto        endOfOperations
    bsf         EEcontrolR,1        ;Change controle bytes to access Bank2
    bsf         EEcontrolW,1
	movlw       .255
	movwf       EEBank              ; We reset EEbank
	movlw       .3
	movwf       EEtrio              ; We reset EEtrio
	movlw       .0
	movwf       EEaddress		    ; EEaddress = 0h
    goto        nextStep


	
;==========================================================================
;                		RS232 Transmit Routine              
;		    Transmits data from the working register   
;                  		Using EUSART Peripheral           
;==========================================================================

SendW:
    ; Check status of transmit bit, wait until set
    BANKSEL     TXSTA
    BTFSS       TXSTA, TRMT
    GOTO $-1
    ; Load working register into TXREG
    BANKSEL    TXREG
    MOVWF    TXREG
    ; Wait until character is sent
    BANKSEL    TXSTA
    BTFSS    TXSTA, TRMT
    GOTO $-1

    RETURN
	
;==========================================================================
;				Delay
;   Produce a work time delay :
;    - Put 1 into work before calling for a 20ms delay
;    - Put 25 into work before calling for a 0.5s delay
;    NEVER call without setting a constant into work
;==========================================================================
delay:
	movwf	i               ; i = w
iloop:
	movlw	.158
	movwf   j               ; j = w
jloop:
	movlw	.158
	movwf	k               ; k = w
kloop:
	decfsz	k,f             ; k = k-1, skip next if zero
	goto 	kloop
	decfsz	j,f             ; j = j-1, skip next if zero
	goto	jloop
	decfsz	i,f             ; i = i-1, skip next if zero
	goto	iloop
	return
	



;============================================================
;============================================================
;                L O C A L    P R O C E D U R E S
;============================================================
;============================================================

;============================================================
;                 I2C EEPROM data procedures
;============================================================
; GPRs used in EEPROM-related code are placed in the common
; RAM area (from 0x70 to 0x7f). This makes the registers
; accessible from any bank.
;============================
;     LIST OF PROCEDURES
;============================
; SetupI2C   ---  Initialize MSSP module for I2C mode
;                 in hardware master mode
;                 Configure I2C lines
;                 Set slew rate for 100kbps
;                 Set baud rate for 10Mhz
; ReadI2C    ---  Read byte from I2C EEPROM device
;                 Address stored in EEaddress
;                 Read data returned in w register
;============================
;     I2C setup procedure
;============================
SetupI2C:
	BANKSEL TRISC
	movlw		b'00011000'
	iorwf		TRISC,f			; OR into TRISC
; Setup MSSP module for Master Mode operation
    BANKSEL SSPCON
	movlw 		B'00101000'; Enables MSSP and uses appropriate
	movwf 		SSPCON 	; This is loaded into SSPCON
; Input levels and slew rate as standard I2C
	BANKSEL SSPSTAT
	movlw 		B'10000000'
	movwf 		SSPSTAT
; Setup Baud Rate
; Baud Rate = Fosc/(4*(SSPADD+1))
;    Fosc = 10Mhz
;    Baud Rate = 49 for 100 kbps
	movlw 		.49		; Value to use
	movwf 		SSPADD 	; Store in SSPADD
	Bank0
	return

;============================
;    I2C read procedure
;============================
; Procedure to read one byte from 24LC04B EEPROM
; Steps:
;		1. Send START
;		2. Send control. Wait for ACK
;		3. Send address. Wait for ACK
;		4. Send RESTART + control. Wait for ACK
;		5. Switch to receive mode. Get data.
;		6. Send NACK
;		7. Send STOP
;               8. Retreive data into w register
; STEP 1:
ReadI2C
; Send RESTART. Wait for ACK
	BANKSEL     SSPCON2
	bsf 		SSPCON2,RSEN ; RESTART Condition
	call 		WaitI2C 	; Wait for I2C operation

; STEP 2:
; Send control byte. Wait for ACK
    Bank0
	movfw 		EEcontrolR ; Control byte
	call 		Send1I2C ; Send Byte
	call 		WaitI2C ; Wait for I2C operation
; Now check to see if I2C EEPROM is ready
	BANKSEL SSPCON2
	btfsc 		SSPCON2,ACKSTAT ; Check ACK Status bit
	goto 		ReadI2C 	; ACK Poll waiting for EEPROM
					; write to complete

; STEP 3:
; Send address. Wait for ACK
	Bank0
	movf 		EEaddress,w 	; Load from address register
	call 		Send1I2C 	; Send Byte
	call 		WaitI2C 	; Wait for I2C operation
	BANKSEL SSPCON2
	btfsc 		SSPCON2,ACKSTAT ; Check ACK Status bit
	goto 		FailI2C 	; failed, skipped if successful

; STEP 4:
; Send RESTART. Wait for ACK
	bsf 		SSPCON2,RSEN ; Generate RESTART Condition
	call 		WaitI2C ; Wait for I2C operation
; Send output control. Wait for ACK
    Bank0
	movfw 		EEcontrolW ; Load CONTROL BYTE (output)
	call 		Send1I2C 	; Send Byte
	call 		WaitI2C 	; Wait for I2C operation
	BANKSEL SSPCON2
	btfsc 		SSPCON2,ACKSTAT ; Check ACK Status bit
	goto 		FailI2C ; failed, skipped if successful

; STEP 5:
; Switch MSSP to I2C Receive mode
	bsf 		SSPCON2,RCEN ; Enable Receive Mode (I2C)
; Get the data. Wait for ACK
	call 		WaitI2C ; Wait for I2C operation

; STEP 6:
; Send NACK to acknowledge
	BANKSEL SSPCON2
	bsf 		SSPCON2,ACKDT ; ACK DATA to send is 1 (NACK)
	bsf 		SSPCON2,ACKEN ; Send ACK DATA now.
; Once ACK or NACK is sent, ACKEN is automatically cleared

; STEP 7:
; Send STOP. Wait for ACK
	bsf 		SSPCON2,PEN ; Send STOP condition
	call 		WaitI2C ; Wait for I2C operation

; STEP 8:
; Read operation has finished
	BANKSEL SSPBUF
	movf 		SSPBUF,W ; Get data from SSPBUF into W
; Procedure has finished and completed successfully.
	return

;============================
;   I2C support procedures
;============================
; I2C Operation failed code sequence
; Procedure hangs up. User should provide error handling.
FailI2C:
	BANKSEL SSPCON2
	bsf 		SSPCON2,PEN         ; Send STOP condition
	call 		WaitI2C             ; Wait for I2C operation
fail:
	goto	fail

; Procedure to transmit one byte
Send1I2C:
	BANKSEL SSPBUF
	movwf 		SSPBUF              ; Value to send to SSPBUF
	return

; Procedure to wait for the last I2C operation to complete.
; Code polls the SSPIF flag in PIR1.
WaitI2C:
	BANKSEL     PIR1
	btfss 		PIR1,SSPIF          ; Check if I2C operation done
	goto        $-1                 ; I2C module is not ready yet
	bcf 		PIR1,SSPIF          ; I2C ready, clear flag
	return

endOfOperations:
success:
    LEDS_ON
    goto success


    END
	
;==========================================================================
;==========================================================================
;==========================================================================
;==========================================================================
;==========================================================================





