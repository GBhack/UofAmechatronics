; Program by Hugo SELLA, Arnaud DARBAS and Maxime CADE
;
;Data Storage: read three bytes in GPR and write them on an
;I2C EEPROM module (512 bytes) until it is full.

;===========================================================
;                      DEFINITION OF THE PROCESSOR
;===========================================================

    processor 	16f877		; Define processor
    #include	<p16f877.inc>
    __CONFIG _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_ON & _HS_OSC & _LVP_OFF & _CPD_OFF

    org 0x00

    Goto    Initialization

    org 0x04

i		    equ	0x20        ;For timer counters
j		    equ	0x21        ;For timer counters
k		    equ	0x22        ;For timer counters

EEByte1		equ	0x23        ; 1st byte to store
EEByte2		equ	0x24        ; 2nd byte to store
EEByte3		equ	0x25        ; 3rd byte to store
EEChangeMem	equ	0x79        ; 85=>0 to change EEPROM bank when first is full
EEComptByte	equ	0x7A        ; 3 => 0 for keeping track of 1st, 2nd and 3rd bytes
EEMemAdd	equ	0x7B        ; Memory Address on the EEPROM to write at
EEControl	equ	0x7F        ; Control Byte for addressing EEPROM over I2C

;============================================================
;                          M A C R O S
;============================================================
; Macros to select the register banks


Bank0	MACRO			; Select RAM bank 0
		bcf	STATUS,RP0
		bcf	STATUS,RP1
		ENDM

Bank1	MACRO			; Select RAM bank 1
		bsf	STATUS,RP0
		bcf	STATUS,RP1
		ENDM

Bank2	MACRO			; Select RAM bank 2
		bcf	STATUS,RP0
		bsf	STATUS,RP1
		ENDM

Bank3	MACRO			; Select RAM bank 3
		bsf	STATUS,RP0
		bsf	STATUS,RP1
		ENDM

;======================================================
;                  I2C write procedure
;======================================================


; Write three byte per cycle to I2C EEPROM 24LC04A
; Steps:

; 1. Send START
; 2. Send control. Wait for ACK
; 3. Send address. Wait for ACK
; 4. Send data. Wait for ACK (3 times)
; 5. Send STOP

;Executed only once, to write the first 3 bytes
Initialization:
    call    INITI2C         ;MSSP module initalization
	Bank0
	movlw 0x00
	movwf PORTB             ;PortB as an output (for LED debugging)
	movlw .85
	movwf EEChangeMem       ;We change bank after writing 3*85=255 bytes
	movlw .3
	movwf EEComptByte       ;We store 3 bytes at a time
	movlw .0
	movwf EEMemAdd          ;We start at first address of bank 1
	movlw .65
	movwf EEByte1
	movlw .66
	movwf EEByte2
	movlw .67               ;For testing purpose we store ASCII 'A', 'B', 'C' 170 times on EEPROM
	movwf EEByte3
	movlw b'10100000'       ;Control byte = 1010XX[bank number]0 for write operations
	movwf EEControl
	goto WriteI2C           ;We write the first 3 bytes. WriteI2C go to main when over

;Main "loop", executed 169 times
Main:
	Bank0
    movlw   .1
    call delay
    movlw .3
    addwf EEMemAdd,1        ;We add 3 to the current address (to start writing next 3 bytes 3 blocks later)
	decfsz EEChangeMem      ;We keep track of were we are in the current bank
	goto WriteI2C
	btfsc EEControl, 1      ;If we wrote 255 bytes on current bank, we check if we already switched bank
	goto EndStorage	        ;If yes the programm is over and goes to an infinite loop (both banks are full)
	movlw b'10100010'       ;If not, we change bank
	movwf EEControl         
	movlw .0       
	movwf EEMemAdd          ;We start from address 0 in bank 2      
	movlw .85
	movwf EEChangeMem       ;We reset the counter to know when bank 2 is full too
; STEP 1:


WriteI2C:
	Bank1            ;  Contain SSPCON2
	bsf SSPCON2,SEN  ;  Produce START Condition
	call WaitI2C     ;  Wait for I2C to complete

; STEP 2:

; Send control byte. Wait for ACK

	movf EEControl, w ; Control byte
	call Send1I2C ; Send Byte
	call WaitI2C ; Wait for I2C to complete
	Bank1
	btfsc SSPCON2,ACKSTAT ; Check ACK bit to see if I2C failed, skip if not
	goto FailI2C

; STEP 3:

; Send address. Wait for ACK
	Bank0
	movf EEMemAdd,w ; Load Address Byte
	call Send1I2C ; Send Byte
	call WaitI2C ; Wait for I2C operation to complete
	Bank1
	btfsc SSPCON2,ACKSTAT ; Check ACK Status bit to see if I2C failed, skip if not
	goto FailI2C

; STEP 4:
; Send data. Wait for ACK
	
	movlw 0x23
	movwf FSR           ;We use indirect addressing to send bytes 1, 2 and 3 successivly
	
Quelconque:
    Bank0
	movf INDF,w         ;Load one of the Data Bytes
	call Send1I2C       ;Send Byte
	call WaitI2C        ;Wait for I2C operation to complete
	Bank1
	btfsc SSPCON2,ACKSTAT ; Check ACK Status bit to see if I2C failed, skip if not
	goto FailI2C
	incf FSR            ;Increment data byte address
	Bank0
	decfsz EEComptByte, f ;Check if we have sent all 3 bytes
	goto Quelconque	      ;if not, send a new byte
	movlw .3	          ;If yes, let's stop here and reset the counter
	movwf EEComptByte
	Bank1
; STEP 5:

; Send STOP. Wait for ACK
	bsf SSPCON2,PEN ; Send STOP condition
	call WaitI2C ; Wait for I2C operation to complete

    ;Blink a LED on port B to inform user that one set of bytes have been stored and set a small delay between two operations
    Bank0
	movlw b'00010000'
	movwf PORTB
    movlw .1
    call delay
	movlw b'00000000'
	movwf PORTB
    movlw .1
    call delay

; WRITE operation has completed successfully.
	Bank0
	goto Main


;==============================================
;            I2C support procedures
;==============================================

; I2C Operation failed code sequence
; Procedure hangs up. User should provide error handling.


FailI2C:
	Bank1
	bsf SSPCON2,PEN ; Send STOP condition
	call WaitI2C ; Wait for I2C operation

fail:
	Bank0
	movlw b'00000100'       ;Light a LED to inform that operation failed
	movwf PORTB

	goto fail               ;Stay here forever

; Procedure to transmit one byte

Send1I2C:
;	Data EEPROM Programming 491
	Bank0
	movwf SSPBUF            ;Work is simply moved to the MSSP buffer. The MSSP takes care of sending it
	return

; Procedure to wait for the last I2C operation to complete.
; Code polls the SSPIF flag in PIR1.

WaitI2C:
	Banksel PIR1
	btfss PIR1,SSPIF ; Check if I2C operation done
	goto $-1 ; I2C module is not ready yet
	bcf PIR1,SSPIF ; I2C ready, clear flag
	return
EndStorage:
	Bank0
	movlw b'00000001'       ;Light a LED to inform that the program worked
	movwf PORTB
			 ; We could set a PORT to light a LED here 
	goto EndStorage  ; to alert the user that the memory is full

;===========================================================
;                  INITIALIZATION OF I2C MODE
;===========================================================
INITI2C:
    Bank1
    movlw b'00011000'
	iorwf TRISC,f ; OR into TRISC  ; setup SLC and SDA
	movlw b'00000000'
	movwf TRISB
    movlw b'00011000'
	iorwf TRISC,f ; OR into TRISC


; Setup MSSP module for Master Mode operation
    Bank0   ; Contain SSPCON
	movlw B'00101000'  ; Enables MSSP and uses appropriate

; 0 0 1 0 1 0 0 0 Value to install
; 7 6 5 4 3 2 1 0 <== SSPCON bits in this operation
; | | | | |__|__|__|___     Serial port select bits
; | | | | 		    1000 = I2C master mode
; | | | | 		    Clock = Fosc/(4*(SSPAD+1))
; | | | |_______________    UNUSED IN MASTER MODE
; | | |__________________   SSP Enable
; | | 			    1 = SDA and SCL pins as serial
; | |_____________________  Receive 0verflow indicator
; | 			    0 = no overflow
; |________________________ Write collision detect
;                           0 = no collision detected

	movwf SSPCON ; Loaded into SSPCON

; Input levels and slew rate as standard I2C

	Bank1             ; Contain SSPSTAT
	movlw B'10000000'

; 1 0 0 0 0 0 0 0 Value to install
; 7 6 5 4 3 2 1 0 <== SSPSTAT bits in this operation
; | | | | | | | |___ Buffer full status bit READ ONLY
; | | | | | | |______ UNUSED in present application
; | | | | | |_________ Read/write information READ ONLY
; | | | | |____________ UNUSED IN MASTER MODE
; | | | |_______________ STOP bit READ ONLY
; | | |__________________ Data address READ ONLY
; | |_____________________ SMP bus select
; | 0 = use normal I2C specs
; |________________________ Slew rate control
; 0 = disabled
;
	movwf SSPSTAT

;Now the SCL and SDA are enabled
;The I2C mode is now configured

; Setup Baud Rate
; Baud Rate = Fosc/(4*(SSPADD+1))
; Fosc = 20Mhz
; Baud Rate = 49 for 100 kbps
	movlw .49 ; Value to use
	movwf SSPADD ; Store in SSPADD
	Bank0
    return


;==========================================================================
;				Delay
;   Produce a work time 20ms delay :
;    - Put 1 into work before calling for a 20ms delay
;    - Put 50 into work before calling for a 1s delay
;    - ...
;    NEVER call without setting a constant into work

delay:
	movwf	i		    ; i = w
iloop:
	movlw	.255
	movwf   j		    ; j = w
jloop:
	movlw	.255
	movwf	k		    ; k = w
kloop:
	decfsz	k,f		    ; k = k-1, skip next if zero
	goto 	kloop
	decfsz	j,f		    ; j = j-1, skip next if zero
	goto	jloop
	decfsz	i,f		    ; i = i-1, skip next if zero
	goto	iloop
	return


    END

;==========================================================================
;==========================================================================
;==========================================================================
;==========================================================================
;==========================================================================





