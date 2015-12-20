;===============================================================================    
;				ANALOG CHANNEL AN6  "Y"
;===============================================================================  
CH2:
    BANKSEL ADCON0
    
    ; Channel AN6
    
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