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