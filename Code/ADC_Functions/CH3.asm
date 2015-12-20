;===============================================================================    
;				ANALOG CHANNEL AN5  "Z"
;===============================================================================

CH3:
    BANKSEL ADCON0
    
    ; Channel AN5
    
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