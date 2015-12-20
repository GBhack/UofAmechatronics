;===============================================================================    
;				ANALOG CHANNEL AN7  "X"
;===============================================================================    
CH1:
    BANKSEL PORTB
    bsf	    PORTB, 4
	
    BANKSEL ADCON0
    
    BSF ADCON0, 3
    BSF ADCON0, 4	; Set bit 3,4,5 to use AN7 for X
    BSF ADCON0, 5
    
    CALL Acq
    
; STORAGE X ====================================================================

    BANKSEL ADRESL
    MOVF    ADRESL, 0 ; Transfer results in workspace
    BANKSEL resultX
    MOVWF   0x23 ; store in result register
  
    RRF	resultX, 1  ; shift the code to the right to keep the six last bits
    BCF	STATUS, 0   ; Clear Carry bit STATUS
    BCF	resultX, 7  ; BCF to clear the bits we don't need
    
    RRF	resultX, 1
    BCF	STATUS, 0
    BCF	resultX, 7
    
    BANKSEL ADRESH
    MOVF    ADRESH, 0
    
    BANKSEL storage2
    MOVWF   storage2
    
    CLRW
    BCF	STATUS, 0
    RRF storage2, 1 ; shift the last two bits to the left + clear what we don't need
    BCF storage2, 1
    
    RRF storage2, 1 
    BCF storage2, 1
    
    RRF storage2, 0
    BCF W, 0 ; Store in W
    
    ADDWF resultX, 1 ; we add the bits from ADRESH to bits from ADRESL in resultX
    return