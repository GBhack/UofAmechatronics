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