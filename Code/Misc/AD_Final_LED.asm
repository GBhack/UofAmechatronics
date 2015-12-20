;  A/D Converter (Group 5)
;SALLABERRY Camille / BOULARD Alan / BALZAC Vincent / MARQUES Ronan / FROMONTEIL Pierre

;-------------------------------------------------------------------------------
  
;Configuration of the process    
;    Clock FOSC/32 [1.6 µs for 1 TAD] (ADCON0 "10xx xxxx")
;    Config PORT Analog RE0, RE1, RE2 (TRISE "xxxx x111" & ADCON1 "xxxx 1000")
;    Right justified (ADCON1 "1xxx xxxx")
;    Converter turn ON (ADCON0 "xxxx xxx1")
;    Config Led (TRISB "0000 0000") as output
    
;Three Steps for the process: 
;    Configuration of the PIC
;    Conversion: Choice of channel(ADCON0) + Time Loop(sample time) + Conversion process(ADCON0 "xxxx x1xx)
;    Storage from ADRESL & ADRESH to result registers (X,Y,Z) -> From data of 10 bits to 8 bits

;Test Led process
;    Test Led using substraction: the value of the result register - value chosen (in workspace)
    
;-------------------------------------------------------------------------------
    
    processor 16f877
    include <p16f877.inc>
    __CONFIG _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _CP_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _WRT_ON
    
; Variables in PIC ===========================================================

j equ 0x21   
storage2 equ 0x22
resultX equ 0x23
resultY equ 0x24
resultZ equ 0x25
	
;===============================================================================

    org 0x00
    goto Initialisation

; Configuration ================================================================
    
    org 0x05
Initialisation:
    BANKSEL INTCON ; clear interrupt
    CLRF    INTCON
    BANKSEL OPTION_REG ; clear pull-up
    CLRF    OPTION_REG
    BSF	OPTION_REG, 7
    BANKSEL TRISE
    CLRF    TRISE
    BANKSEL TRISB
    CLRF    TRISB
    BANKSEL TRISC
    CLRF    TRISC
    BANKSEL PORTA
    CLRF    PORTA
    BANKSEL PORTB
    CLRF    PORTB
    BANKSEL PORTE
    CLRF    PORTE
    BANKSEL ADCON0
    CLRF    ADCON0
    BANKSEL ADCON1
    CLRF    ADCON1
    BANKSEL ADRESL
    CLRF    ADRESL
    CLRF    ADRESH
    BANKSEL Trigger
    BCF	    Trigger, 0
    
;A/D config
    BANKSEL TRISE
    BSF	    TRISE, 0
    BSF	    TRISE, 1	; Set bit 3,4,5 to use AN7 for X
    BSF	    TRISE, 2
    BANKSEL ADCON1
    BSF	    ADCON1,3	; Config right justified & A/D PORT bits
    BSF	    ADCON1,7
    BANKSEL ADCON0
    MOVLW   B'10000001'	    ; Config A/D clock Fosc/32 + Conversion turn ON
    MOVWF   ADCON0
    
; Main process =================================================================
    CALL Trigger
Start:
    CALL CH1
    CALL LEDX
    CALL CH2
    CALL LEDY
    CALL CH3
    CALL LEDZ
    goto Start
    
;===============================================================================    
;				ANALOG CHANNEL AN5  "Z" Trigger
;===============================================================================
Trigger:

    BANKSEL ADCON0
    BSF	    ADCON0, 3
    BCF	    ADCON0, 4	; Set bit 3,4,5 to use AN5 for Z
    BSF	    ADCON0, 5
    CALL    Acq
    
; STORAGE ZT ====================================================================
    BANKSEL ADRESL
    MOVF    ADRESL, 0	; Transfer results in workspace
    BANKSEL resultZ
    CLRF    0x25
    MOVWF   0x25	; store in result register
    RRF	    resultZ, 1	; shift the code to the right to keep the six last bits
    BCF	    STATUS, 0	; Clear Carry bit STATUS
    BCF	    resultZ, 7	; BCF to clear the bits we don't need
    RRF	    resultZ, 1
    BCF	    STATUS, 0
    BCF	    resultZ, 7
    BANKSEL ADRESH
    MOVF    ADRESH, 0
    BANKSEL storage2
    MOVWF   storage2
    CLRW
    BCF	    STATUS, 0
    RRF	    storage2, 1	; shift the last two bits to the left + clear what we don't need
    BCF	    storage2, 1
    RRF	    storage2, 1 
    BCF	    storage2, 1
    RRF	    storage2, 0
    BCF	    W, 0		; Store in W
    ADDWF   resultZ, 1	; we add the bits from ADRESH to bits from ADRESL in resultZ
   
;Trigger========================================================================

    movlw   B'01000000'		;TriggerValue to W
    subwf   resultZ, 0		;do substraction (resultZ - W), store result in W
    btfss   STATUS, 0		;bit test - skip if carry bit is set
    goto    Trigger		;go back to Converter
    return
	
;===============================================================================    
;				ANALOG CHANNEL AN7  "X"
;===============================================================================    
CH1:
    BANKSEL PORTB
    bsf	    PORTB, 4
    BANKSEL ADCON0
    BSF	    ADCON0, 3
    BSF	    ADCON0, 4	; Set bit 3,4,5 to use AN7 for X
    BSF	    ADCON0, 5
    CALL    Acq
    
; STORAGE X ====================================================================

    BANKSEL ADRESL
    MOVF    ADRESL, 0 ; Transfer results in workspace
    BANKSEL resultX
    MOVWF   0x23 ; store in result register
    RRF	    resultX, 1  ; shift the code to the right to keep the six last bits
    BCF	    STATUS, 0   ; Clear Carry bit STATUS
    BCF	    resultX, 7  ; BCF to clear the bits we don't need
    RRF	    resultX, 1
    BCF	    STATUS, 0
    BCF	    resultX, 7
    BANKSEL ADRESH
    MOVF    ADRESH, 0
    BANKSEL storage2
    MOVWF   storage2
    CLRW
    BCF	    STATUS, 0
    RRF	    storage2, 1 ; shift the last two bits to the left + clear what we don't need
    BCF	    storage2, 1
    RRF	    storage2, 1 
    BCF	    storage2, 1
    RRF	    storage2, 0
    BCF	    W, 0 ; Store in W
    ADDWF   resultX, 1 ; we add the bits from ADRESH to bits from ADRESL in resultX
    return
    
;===============================================================================    
;				Test Led X
;===============================================================================      

LEDX:
    BANKSEL resultX
    BCF	    STATUS, 0	
    movlw   B'10101010'		
    subwf   resultX, 0	;do substraction (resultX - W), store result in W
    btfss   STATUS, 0	;bit test - skip if carry bit is set
    goto    LEDOFF
LED:
    BANKSEL PORTB
    bsf	PORTB, 5
    return
LEDOFF:
    BANKSEL PORTB
    BCF	PORTB, 5
    return
    
;===============================================================================    
;				ANALOG CHANNEL AN6  "Y"
;===============================================================================  
CH2:
    BANKSEL ADCON0
    BCF ADCON0, 3
    BSF ADCON0, 4	; Set bit 3,4,5 to use AN6 for Y
    BSF ADCON0, 5
    CALL Acq
    
; STORAGE Y ====================================================================
  
    BANKSEL ADRESL
    MOVF    ADRESL, 0	; Transfer results in workspace  
    BANKSEL resultY
    MOVWF   0x24	; store in result register
    RRF	resultY, 1	; shift the code to the right to keep the six last bits
    BCF	STATUS, 0	; Clear Carry bit STATUS
    BCF	resultY, 7	; BCF to clear the bits we don't need
    RRF	resultY, 1
    BCF	STATUS, 0
    BCF	resultY, 7
    BANKSEL ADRESH
    MOVF    ADRESH, 0
    BANKSEL storage2
    MOVWF   storage2
    CLRW
    BCF	STATUS, 0
    RRF storage2, 1	; shift the last two bits to the left + clear what we don't need
    BCF storage2, 1
    RRF storage2, 1 
    BCF storage2, 1
    RRF storage2, 0
    BCF W, 0		; Store in W
    ADDWF resultY, 1	; We add the bits from ADRESH to bits from ADRESL and store the result in resultY
    return

;===============================================================================    
;				Test Led Y
;===============================================================================      

LEDY:
    BANKSEL resultY
    BCF STATUS, 0	
    movlw   B'10101010'		
    subwf   resultY, 0	;do substraction (resultX - W), store result in W
    btfss   STATUS, 0	;bit test - skip if carry bit is set
    goto    LEDOFF2
LED2:
    BANKSEL PORTB
    bsf	PORTB, 6
    return
LEDOFF2:
    BANKSEL PORTB
    BCF	PORTB, 6
    return
    
;===============================================================================    
;				ANALOG CHANNEL AN5  "Z"
;===============================================================================

CH3:
    BANKSEL ADCON0
    BSF ADCON0, 3
    BCF ADCON0, 4	; Set bit 3,4,5 to use AN5 for Z
    BSF ADCON0, 5
    CALL Acq
    
; STORAGE Z ====================================================================
   
    BANKSEL ADRESL
    MOVF    ADRESL, 0	; Transfer results in workspace
    BANKSEL resultZ
    CLRF    0x25
    MOVWF   0x25	; store in result register
    RRF	resultZ, 1	; shift the code to the right to keep the six last bits
    BCF	STATUS, 0	; Clear Carry bit STATUS
    BCF	resultZ, 7	; BCF to clear the bits we don't need
    RRF	resultZ, 1
    BCF	STATUS, 0
    BCF	resultZ, 7
    BANKSEL ADRESH
    MOVF    ADRESH, 0
    BANKSEL storage2
    MOVWF   storage2
    CLRW
    BCF	STATUS, 0
    RRF storage2, 1	; shift the last two bits to the left + clear what we don't need
    BCF storage2, 1
    RRF storage2, 1 
    BCF storage2, 1
    RRF storage2, 0
    BCF W, 0		; Store in W
    ADDWF resultZ, 1	; we add the bits from ADRESH to bits from ADRESL in resultZ
    return
    
;===============================================================================    
;				Test Led Z
;===============================================================================      

LEDZ:
    BANKSEL resultZ
    BCF STATUS, 0	
    movlw   B'10101010'		
    subwf   resultZ, 0	;do substraction (resultX - W), store result in W
    btfss   STATUS, 0	;bit test - skip if carry bit is set
    goto    LEDOFF3
LED3:
    BANKSEL PORTB
    bsf	PORTB, 7
    return
LEDOFF3:
    BANKSEL PORTB
    BCF	PORTB, 7
    return
    
;===============================================================================
;				Acquisition
;===============================================================================
Acq:   
; Time Loop(??? µs of sample time) =============================================
    MOVLW   .250	; W = 250 decimal
    MOVWF   j		; j = W
jloopT:
    decfsz  j,f		; j = j-1, skip nextif zero
    goto    jloopT 
; Beginning of the Process =====================================================
    BANKSEL ADCON0
    BSF ADCON0, 2	; beginning of the conversion process
LprocessT: 
    BTFSC ADCON0, 2	; Waiting for the end of the process (bit 1 auto clear when process completed)
    GOTO LprocessT
    return

    END