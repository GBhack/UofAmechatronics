;===============================================================================    
;				Test Led X
;===============================================================================      

LEDX:
    
    BANKSEL resultX
    BCF STATUS, 0	
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