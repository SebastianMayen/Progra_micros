;Archivo:	Proyecto_1.s
;Dispositivo:	PIC16F887
;Autor:		Sebastian Mayén Dávila
;Copilador:	pic-as (v2.40),MPLABX v6.05
;
;Progra:	...
;Hardware:	...
; 
; Creado:	28 de febrero, 2023
; Ultima modificacion: 28 de febrero, 2023
    
PROCESSOR 16F887
#include <xc.inc>
    
; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT  ; Oscillator Selection bits (INTOSC oscillator: CLKOUT function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF             ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)


;-----------------Macros----------------
reset_tmr0 macro 
    banksel PORTA	    ;banco 00
    movf valor_timer0, W    ;mover contador de timer0 a W
    movwf TMR0		    ;Se carga el valor inicial al TMR0
    bcf T0IF		    ;Se apaga la bandera de interrupción del timer0
    endm
    
reset_tmr1 macro 
    banksel PORTA	    ;banco 00
    movlw 255		    ;mover contador de timer0 a W
    movwf TMR1H		    ;Se carga el valor inicial al TMR0
    movlw 0		    ;mover contador de timer0 a W
    movwf TMR1L		    ;Se carga el valor inicial al TMR0
    bcf PIR1, 0		    ;Se apaga la bandera de interrupción del timer0
    endm

    
mostrar_valor_frec_HzCuadrada_HzSenosoidal macro cen_HzC, dece_HzC, uni_HzC, valor_t, cen_HzS, dece_HzS, uni_HzS ;macro para mostrar frecuecia de la señal cuadrada y senoidal 
    btfss   PORTD, 6	    ;test de bit del la led de señal cuadrada
    goto    $+11	    ;si es 0 seguir hasta la linia 11 donde estan la variables para la senoidal
    movlw   cen_HzC	    ; mover el valor de a la tabla para mostrar en los displays
    call    tabla	    ;llamar a la tabla para combertir el valor en la representacion de displays 
    movwf   display_Frec
    movlw   dece_HzC
    call    tabla	    ;llamar a la tabla para combertir el valor en la representacion de displays
    movwf   display_Frec+1         
    movlw   uni_HzC	    ;mover 
    call    tabla	    ;llamar a la tabla para combertir el valor en la representacion de displays
    movwf   display_Frec+2    
    retlw   valor_t
    
    movlw   cen_HzS	    ;mostrar el valor en los displays (centena)
    call    tabla	    ;llamar a la tabla para combertir el valor en la representacion de displays
    movwf   display_Frec
    movlw   dece_HzS
    call    tabla	    ;llamar a la tabla para combertir el valor en la representacion de displays
    movwf   display_Frec+1
    movlw   uni_HzS
    call    tabla	    ;llamar a la tabla para combertir el valor en la representacion de displays
    movwf   display_Frec+2
    retlw   valor_t
    endm
    
mostrar_valor_frec_Khcuadrada_Hztriangular macro cen_KHzC, dece_KHzC, uni_KHzC, valor_t, cen_HzT, dece_HzT, uni_HzT ;macro para mostrar los valores  
    btfss   PORTD, 6
    goto    $+11
    movlw   cen_KHzC
    call    tabla	    ;llamar a la tabla para combertir el valor en la representacion de displays
    movwf   display_Frec
    movlw   dece_KHzC
    call    tabla	    ;llamar a la tabla para combertir el valor en la representacion de displays
    movwf   display_Frec+1
    movlw   uni_KHzC
    call    tabla	    ;llamar a la tabla para combertir el valor en la representacion de displays
    movwf   display_Frec+2
    retlw   valor_t
    
    movlw   cen_HzT
    call    tabla	    ;llamar a la tabla para combertir el valor en la representacion de displays
    movwf   display_Frec
    movlw   dece_HzT
    call    tabla	    ;llamar a la tabla para combertir el valor en la representacion de displays
    movwf   display_Frec+1
    movlw   uni_HzT
    call    tabla	    ;llamar a la tabla para combertir el valor en la representacion de displays
    movwf   display_Frec+2
    retlw   valor_t
    endm
    

;-----------------Variables--------------
PSECT udata_shr
  W_TEMP:	    DS 1    ;Variable reservada para guardar el W Temporal
  STATUS_TEMP:	    DS 1    ;Variable reservada para guardar el STATUS Temporal
  valor_timer0:	    DS 1    ;Variable que se mueve al TMR0
  cont_principal:   DS 1    ;contador principal de 0 a 20	
  cont_triangular:  DS 1    ;Variable para mapear la onda senoidal
  bandera_timer0:   DS 1    ;bandera para que cada vez que se active la señal cuadrada suba o baje. 
  banderas:	    DS 1    ;bandera para el multiplexado
  display_Frec:	    DS 3    ;valores para mostar en los displays 
    
;--------------Vector Reset-------------   
PSECT VectorReset, class=CODE, abs, delta=2
ORG 00h	 
VectorReset:
    PAGESEL  main 
    goto     main
    
;-------------Vector de Interrupción---------
ORG 04h			    ;posicionamiento para las interrupciones.
push:
    movwf   W_TEMP	    ;guardado temporal de STATUS y W
    swapf   STATUS, W	    ;cambiar valor de nibbles	
    movwf   STATUS_TEMP	    ;guardar en status temporal
isr:
    btfsc   RBIF	    ;revision de la bandera de interrupcion on-change del PORTB
    call    int_button	    ;llamar la subrutina de interrupcion			    
    btfsc   T0IF	    ;revision de la bandera de interrupcion por el TMR0
    call    int_TMR0	    ;llamar la subrutina de interrupcion	
    btfsc   PIR1, 0
    call    int_TMR1
pop:			    
    swapf   STATUS_TEMP, W  ;volver a W el orden de los nibbles
    movwf   STATUS	    ;volver al registro status el valor original
    swapf   W_TEMP, F	    
    swapf   W_TEMP, W
    retfie
    
;------------Subrutinas de interrupciones------------
int_button:
    banksel PORTA
    btfsc   PORTB, 0	    
    goto    dec_cont		;1
inc_cont:			;0
    incf    cont_principal
    call    verificacion
    bcf	    RBIF
    return
dec_cont:
    btfsc   PORTB, 1	    ;si es 1 salta, 0 continua (estan en pull ups)
    goto    cambio_KHz ;1
    decf    cont_principal  ;0
    call    verificacion
    bcf	    RBIF	    ;apagar bandera de interrupcion
    return
verificacion:
    movf    cont_principal, W
    sublw   20
    btfsc   STATUS, 0
    return		    ;1	cont < 20
    movlw   20		    ;0  cont > 20
    movwf   cont_principal
    return
cambio_KHz:
    btfsc   PORTB, 2
    goto    cambio_triangular	;1
    btfss   PORTD, 7
    btfsc   PORTE, 0  
    goto    rest_led_Hz
    btfss   PORTD, 4	    ;0
    goto    rest_led_Hz
    bcf	    PORTD, 4	    ;1
    bsf	    PORTD, 5
    bcf	    RBIF	    ;apagar bandera de interrupcion
    return
cambio_triangular:
    btfsc   PORTB, 4
    goto    $+11	;1
    btfsc   PORTD, 6
    goto    $+4			;1 cuadrada
    btfss   PORTD, 7		;0 caudrada
    goto    rest_led_modOnda	;0 triangular
    goto    cambio_senoidal	;1 triangular
    bcf	    PORTD, 5		;1
    bcf	    PORTE, 0
    bsf	    PORTD, 4
    bcf	    PORTD, 6	    ;1
    bsf	    PORTD, 7
    bcf	    RBIF	    ;apagar bandera de interrupcion
    return
cambio_senoidal:
    bcf	    PORTD, 5		;apago kh
    bcf	    PORTD, 7		;apago triangular 
    bsf	    PORTD, 4		;enciedo Hz
    bcf	    PORTD, 6	    ; apago cuadrada
    bsf	    PORTE, 0	; enciendo senoidal
    bcf	    RBIF	    ;apagar bandera de interrupcion
    return
rest_led_Hz:
    bcf	    PORTD, 5	    ;1
    bsf	    PORTD, 4
    bcf	    RBIF	    ;apagar bandera de interrupcion
    return
rest_led_modOnda:
    bcf	    PORTE, 0	
    bcf	    PORTD, 7	    ;1
    bsf	    PORTD, 6
    bcf	    RBIF	    ;apagar bandera de interrupcion
    return    

;---------------interupcion de TMR0-------------    
int_TMR0:
    banksel PORTA
    btfsc   PORTE, 0		;revisar si la led de senoidal esta prendida
    goto    signal_senoidal	; ira a subrutina para hacer onda senoidal
    btfss   PORTD, 7		;revisar si la led de triangular esta encendida
    goto    signal_cuadrada	;ir a subrutina para hacer onda cuadrada
signal_triangular:
    btfsc   bandera_timer0, 0	;revisar bondera de estado
    goto    dec_contTriangular	;si la bandera esta encendida ir a decremento de la onda triangualr
inc_contTriangular:		;si esta apagado incrementar la onda triangualr
    movf    PORTA, W		; revisar que el puerto A no haga overflow
    sublw   254
    btfsc   STATUS, 2		; cuando llegue a 255 el port A empezar decremento activando la bandera
    bsf	    bandera_timer0, 0	;
    incf    PORTA	;0
    reset_tmr0			;resetear el valor del TMR0
    return
dec_contTriangular:
    decf    PORTA		; decrementar el puerto A hasta llegar a 0 y comenzar de nuevo
    btfsc   STATUS, 2
    bcf	    bandera_timer0, 0	;1
    reset_tmr0			;resetear el valor del TMR0
    return
signal_cuadrada:		; si la señal cuadra esta activa
    btfsc   bandera_timer0, 0	;revisar la bandera de la interrupcion 
    goto full_porta		;si esta prendida hacer subrutina de prender todo el puerto A
zero_porta:			;Si esta apagado apagar todo el puerto A
    bsf	    bandera_timer0, 0
    clrf    PORTA		;apagar el pueto A
    reset_tmr0			;resetear el valor del TMR0
    return
full_porta:			;subrutina para prender todo el puerto A
    bcf	    bandera_timer0, 0	;1 
    movlw   255
    movwf   PORTA
    reset_tmr0			;resetear el valor del TMR0
    return
signal_senoidal:
    movf    cont_triangular, W	;revisat que el contador llegue hasta 127 no mas 
    sublw   127
    btfsc   STATUS, 0	    ;revisar el zero
    goto    $+3		    ;1	cont < 20
    movlw   0		    ;0  cont > 20
    movwf   cont_triangular     
    movf    cont_triangular, W
    call    tabla_senoidal	;llamar a la tabla de mapeo
    movwf   PORTA		;mover el valor correspondiente al puerto A
    incf    cont_triangular	;incrementar el contador de mapeo
    reset_tmr0			;resetear el valor del TMR0
    return

;---------------interupcion de TMR1------------- 
int_TMR1:
    call seleccion_display  ;llamar a subrutina 
    reset_tmr1		    ;llamar a macro
    return    
seleccion_display:
    bcf	    PORTD, 0		;limpiar el puerto de seleccion cada vez que se active la interrupción
    bcf	    PORTD, 1
    bcf	    PORTD, 2
    bcf	    PORTD, 3
    btfsc   banderas, 0		;revisar la bandera
    goto    display_0		;si la vandera esta prendida ir al display 0
    btfsc   banderas, 1		;si la vandera esta apagada revisar el bit 1 de la bandera
    goto    display_1		;si el bit 1 de la bandera esta prendido ir al display 1
    goto    display_2		;si el bit 1 de la bandera esta apagado ir al display 2
display_0:			;prender el display de unidades  
    movf    display_Frec+2, W	;mover el valor modificado al puerto C
    movwf   PORTC
    bsf	    PORTD, 0		;prender el display 0
    bcf	    banderas, 0		;apagar el bit 0 de bandeta
    bsf	    banderas, 1		;prender el bit 1 de bandera 
    return
display_1:			;prender el display de decenas
    movf    display_Frec+1, W	;mover el valor modificado al puerto C
    movwf   PORTC
    bsf	    PORTD, 1		;prender el display 1
    bcf	    banderas, 1		;apagar el bit 1 de la bandera
    bsf	    banderas, 2		;prender el bir 1 de la bandera
    return
display_2:			;prender el display de centenas
    movf    display_Frec, W	;mover el valor modificado al puerto C
    movwf   PORTC
    bsf	    PORTD, 2		;prender el display 2
    bcf	    banderas, 2		;apagar el bit 2 de la bandera    
    bsf	    banderas, 0		;prender el bit 0 de la bandera
    return

    
;--------------Codigo principal--------------
PSECT code, delta=2, abs

 ORG 100h
tabla:				;------tabla para mostrar en displays---------
    clrf    PCLATH
    bsf	    PCLATH, 0
    bcf	    PCLATH, 1
    addwf   PCL
    retlw   00111111B  ;0
    retlw   00000110B  ;1
    retlw   01011011B  ;2
    retlw   01001111B  ;3
    retlw   01100110B  ;4          
    retlw   01101101B  ;5
    retlw   01111101B  ;6
    retlw   00000111B  ;7
    retlw   01111111B  ;8
    retlw   01101111B  ;9 
    retlw   10111111B  ;0.
    retlw   10000110B  ;1.
    retlw   11011011B  ;2.
    retlw   11001111B  ;3.
    retlw   11100110B  ;4.         
    retlw   11101101B  ;5.
    retlw   11111101B  ;6.
    retlw   10000111B  ;7.
    retlw   11111111B  ;8.
    retlw   11101111B  ;9. 
 
tabla_timer0_Hz:	    ;---------tabla para mostar valores en Hz en cuadrada y Hz en senoidal---------
    clrf    PCLATH
    bsf	    PCLATH, 0
    bcf	    PCLATH, 1
    addwf   PCL
    goto    valor_0Hz  
    goto    valor_1Hz
    goto    valor_2Hz
    goto    valor_3Hz
    goto    valor_4Hz
    goto    valor_5Hz
    goto    valor_6Hz
    goto    valor_7Hz
    goto    valor_8Hz
    goto    valor_9Hz
    goto    valor_10Hz
    goto    valor_11Hz
    goto    valor_12Hz
    goto    valor_13Hz
    goto    valor_14Hz
    goto    valor_15Hz
    goto    valor_16Hz
    goto    valor_17Hz
    goto    valor_18Hz
    goto    valor_19Hz
    goto    valor_20Hz
    valor_0Hz:
    mostrar_valor_frec_HzCuadrada_HzSenosoidal 0, 1, 5, 0, 0, 10, 3 
    valor_1Hz:
    mostrar_valor_frec_HzCuadrada_HzSenosoidal 0, 5, 0, 178, 0, 11, 1
    valor_2Hz:
    mostrar_valor_frec_HzCuadrada_HzSenosoidal 1, 0, 0, 217, 0, 12, 1
    valor_3Hz:
    mostrar_valor_frec_HzCuadrada_HzSenosoidal 1, 5, 0, 230, 0, 12, 3
    valor_4Hz:
    mostrar_valor_frec_HzCuadrada_HzSenosoidal 1, 9, 4, 236, 0, 13, 0
    valor_5Hz:
    mostrar_valor_frec_HzCuadrada_HzSenosoidal 2, 5, 0, 225, 0, 13, 9
    valor_6Hz:
    mostrar_valor_frec_HzCuadrada_HzSenosoidal 3, 0, 0, 230, 0, 14, 6
    valor_7Hz:
    mostrar_valor_frec_HzCuadrada_HzSenosoidal 3, 5, 0, 234, 0, 15, 5 
    valor_8Hz:
    mostrar_valor_frec_HzCuadrada_HzSenosoidal 3, 8, 8, 236, 0, 16, 2
    valor_9Hz:
    mostrar_valor_frec_HzCuadrada_HzSenosoidal 4, 5, 4, 239, 0, 0, 7
    valor_10Hz:
    mostrar_valor_frec_HzCuadrada_HzSenosoidal 5, 1, 4, 241, 0, 17, 9
    valor_11Hz:
    mostrar_valor_frec_HzCuadrada_HzSenosoidal 5, 5, 0, 242, 0, 18, 5
    valor_12Hz:
    mostrar_valor_frec_HzCuadrada_HzSenosoidal 5, 9, 2, 230, 0, 19, 2
    valor_13Hz:
    mostrar_valor_frec_HzCuadrada_HzSenosoidal 6, 4, 0, 232, 0, 19, 9
    valor_14Hz:
    mostrar_valor_frec_HzCuadrada_HzSenosoidal 7, 0, 0, 234, 1, 10, 7
    valor_15Hz:
    mostrar_valor_frec_HzCuadrada_HzSenosoidal 7, 4, 7, 215, 1, 11, 6
    valor_16Hz:
    mostrar_valor_frec_HzCuadrada_HzSenosoidal 7, 8, 5, 217, 1, 12, 2
    valor_17Hz:
    mostrar_valor_frec_HzCuadrada_HzSenosoidal 8, 2, 7, 219, 1, 12, 8
    valor_18Hz:
    mostrar_valor_frec_HzCuadrada_HzSenosoidal 8, 9, 7, 222, 1, 13, 9
    valor_19Hz:
    mostrar_valor_frec_HzCuadrada_HzSenosoidal 9, 2, 5, 223, 1, 14, 3
    valor_20Hz:
    mostrar_valor_frec_HzCuadrada_HzSenosoidal 9, 8, 3, 225, 1, 15, 2

ORG 300h
tabla_timer0_KHz:	;------------tabla para mostar valores en Khz en onda cuadrada y Hz en triengular-----------
    clrf    PCLATH
    bsf	    PCLATH, 0
    bsf	    PCLATH, 1
    addwf   PCL
    goto    valor_0KHz  
    goto    valor_1KHz 
    goto    valor_2KHz 
    goto    valor_3KHz 
    goto    valor_4KHz 
    goto    valor_5KHz 
    goto    valor_6KHz 
    goto    valor_7KHz 
    goto    valor_8KHz 
    goto    valor_9KHz 
    goto    valor_10KHz 
    goto    valor_11KHz 
    goto    valor_12KHz 
    goto    valor_13KHz 
    goto    valor_14KHz 
    goto    valor_15KHz 
    goto    valor_16KHz 
    goto    valor_17KHz 
    goto    valor_18KHz 
    goto    valor_19KHz 
    goto    valor_20KHz 
    valor_0KHz:
    mostrar_valor_frec_Khcuadrada_Hztriangular 0, 11, 8, 6, 0, 17, 4;2
    valor_1KHz:
    mostrar_valor_frec_Khcuadrada_Hztriangular 0, 13, 6, 131, 1, 14, 1;4
    valor_2KHz:
    mostrar_valor_frec_Khcuadrada_Hztriangular 0, 15, 1, 173, 2, 10, 1;6
    valor_3KHz:
    mostrar_valor_frec_Khcuadrada_Hztriangular 0, 16, 5, 194, 2, 15, 7;8
    valor_4KHz:
    mostrar_valor_frec_Khcuadrada_Hztriangular 0, 17, 8, 206, 3, 10, 5;10
    valor_5KHz:
    mostrar_valor_frec_Khcuadrada_Hztriangular 0, 18, 9, 214, 3, 14, 9;12
    valor_6KHz:
    mostrar_valor_frec_Khcuadrada_Hztriangular 1, 10, 2, 221, 0, 4, 0;14
    valor_7KHz:
    mostrar_valor_frec_Khcuadrada_Hztriangular 1, 11, 1, 225, 4, 13, 2;16
    valor_8KHz:
    mostrar_valor_frec_Khcuadrada_Hztriangular 1, 11, 8, 228, 4, 16, 4;18
    valor_9KHz:
    mostrar_valor_frec_Khcuadrada_Hztriangular 1, 12, 8, 231, 5, 10, 0;20
    valor_10KHz:
    mostrar_valor_frec_Khcuadrada_Hztriangular 1, 13, 5, 233, 5, 12, 6;22
    valor_11KHz:
    mostrar_valor_frec_Khcuadrada_Hztriangular 1, 14, 3, 235, 5, 15, 6;24
    valor_12KHz:
    mostrar_valor_frec_Khcuadrada_Hztriangular 1, 15, 1, 237, 5, 19, 2;26
    valor_13KHz: 
    mostrar_valor_frec_Khcuadrada_Hztriangular 1, 15, 6, 238, 6, 10, 6;28
    valor_14KHz:
    mostrar_valor_frec_Khcuadrada_Hztriangular 1, 16, 1, 239, 6, 12, 8;28
    valor_15KHz:
    mostrar_valor_frec_Khcuadrada_Hztriangular 1, 17, 2, 241, 6, 16, 2;29
    valor_16KHz:
    mostrar_valor_frec_Khcuadrada_Hztriangular 1, 17, 9, 242, 6, 19, 3;33
    valor_17KHz:
    mostrar_valor_frec_Khcuadrada_Hztriangular 1, 18, 5, 243, 7, 11, 7;36
    valor_18KHz:
    mostrar_valor_frec_Khcuadrada_Hztriangular 1, 19, 2, 244, 7, 14, 5	;41
    valor_19KHz:
    mostrar_valor_frec_Khcuadrada_Hztriangular 0, 2, 0, 245, 7, 17, 1	;20, 70.1
    valor_20KHz:
    mostrar_valor_frec_Khcuadrada_Hztriangular 2, 10, 8, 246, 8, 10, 3	;20.8, 80.3

ORG 600h
tabla_senoidal:		;--------tabla de mapeo de la onda senoidal------------
    clrf    PCLATH
    bcf	    PCLATH, 0
    bsf	    PCLATH, 1
    bsf	    PCLATH, 2
    addwf   PCL
    retlw	 127 
    retlw	 133 
    retlw	 139 
    retlw	 146 
    retlw	 152 
    retlw	 158 
    retlw	 164 
    retlw	 170 
    retlw	 176 
    retlw	 181 
    retlw	 187 
    retlw	 192 
    retlw	 198 
    retlw	 203 
    retlw	 208 
    retlw	 212 
    retlw	 217 
    retlw	 221 
    retlw	 225 
    retlw	 229 
    retlw	 233 
    retlw	 236 
    retlw	 239 
    retlw	 242 
    retlw	 244 
    retlw	 247 
    retlw	 249 
    retlw	 250 
    retlw	 252 
    retlw	 253 
    retlw	 253 
    retlw	 254 
    retlw	 254 
    retlw	 254 
    retlw	 253 
    retlw	 253 
    retlw	 252 
    retlw	 250 
    retlw	 249 
    retlw	 247 
    retlw	 244 
    retlw	 242 
    retlw	 239 
    retlw	 236 
    retlw	 233 
    retlw	 229 
    retlw	 225 
    retlw	 221 
    retlw	 217 
    retlw	 212 
    retlw	 208 
    retlw	 203 
    retlw	 198 
    retlw	 192 
    retlw	 187 
    retlw	 181 
    retlw	 176 
    retlw	 170 
    retlw	 164 
    retlw	 158 
    retlw	 152 
    retlw	 146 
    retlw	 139 
    retlw	 133 
    retlw	 127 
    retlw	 121 
    retlw	 115 
    retlw	 108 
    retlw	 102 
    retlw	 96 
    retlw	 90 
    retlw	 84 
    retlw	 78 
    retlw	 73 
    retlw	 67 
    retlw	 62 
    retlw	 56 
    retlw	 51 
    retlw	 46 
    retlw	 42 
    retlw	 37 
    retlw	 33 
    retlw	 29 
    retlw	 25 
    retlw	 21 
    retlw	 18 
    retlw	 15 
    retlw	 12 
    retlw	 10 
    retlw	 7 
    retlw	 5 
    retlw	 4 
    retlw	 2 
    retlw	 1 
    retlw	 1 
    retlw	 0 
    retlw	 0 
    retlw	 0 
    retlw	 1 
    retlw	 1 
    retlw	 2 
    retlw	 4 
    retlw	 5 
    retlw	 7 
    retlw	 10 
    retlw	 12 
    retlw	 15 
    retlw	 18 
    retlw	 21 
    retlw	 25 
    retlw	 29 
    retlw	 33 
    retlw	 37 
    retlw	 42 
    retlw	 46 
    retlw	 51 
    retlw	 56 
    retlw	 62 
    retlw	 67 
    retlw	 73 
    retlw	 78 
    retlw	 84 
    retlw	 90 
    retlw	 96 
    retlw	 102 
    retlw	 108 
    retlw	 115 
    retlw	 121 
    
;-----------llamadas principales para configuracion del pic---------------
main:
    clrf    cont_triangular
    clrf    cont_principal
    clrf    bandera_timer0
    call    config_io
    call    config_reloj
    call    config_timer0
    call    config_ioc_portb
    call    config_int_enable
    call    config_timer1
    banksel PORTA

;-----------------LOOP principal--------------
loop:
    banksel PORTA
    btfss   PORTD, 7	   ;revisar led de de onda triangular
    btfsc   PORTD, 5	    ; si esta apagada revisar led de Khz	 
    goto    frec_KHz	    ; si esta prendida la led de triangular o la de Khz ira a la subrutina de Khz
    call    mod_frec_Hz	    ;si esta apagada la led de Khz ir a la subrutina de hz
menor_4:
    movf    cont_principal, W
    sublw   4			;<l-W> W > l = 0 (negativo)  W <= l = 1 (postivo)
    btfss   STATUS, 0
    goto    mayor_4		;0
    call    config_timer0_256	;cambiar el prescaler a 1:256
    goto loop
mayor_4:
    movf    cont_principal, W
    sublw   11			;<l-W> W > l = 0 (negativo)  W <= l = 1 (postivo)
    btfss   STATUS, 0
    goto    mayor_11		;0
    call    config_timer0_128	;cambiar el prescaler a 1:128
    goto loop
mayor_11:
    movf    cont_principal, W
    sublw   14			;<l-W> W > l = 0 (negativo)  W <= l = 1 (postivo)
    btfss   STATUS, 0
    goto    mayor_15		;0
    call    config_timer0_64	;cambiar el prescaler a 1:64
    goto loop
mayor_15:
    call    config_timer0_32	;cambiar el prescaler a 1:32		
    goto    loop
frec_KHz:
    call    config_timer0_02	   ; mostrar el valor de Khz 
    movf    cont_principal, W	    
    call    tabla_timer0_KHz	    ;llamar a tabla para mostrar khz en cuadrada o hz en triangular 
    movwf   valor_timer0	 
    goto    loop
    
;-----------------Mod de frecuencia ----------
mod_frec_Hz:
    movf    cont_principal, W	    
    call    tabla_timer0_Hz	    
    movwf   valor_timer0	 
    return

;----------Modificación del contador para mostrar en display---------

   


    
;---------------------- Configuracion general -------------------------------   
config_io:    
    banksel ANSEL  ; banco 11
    clrf    ANSEL ; limpiar el registro (hacer entradas digitales)
    clrf    ANSELH  
    
    banksel TRISA	    ; banco 01
    clrf    TRISA	    ; hacer entradas y salidas
    clrf    TRISC	    ; hacer entradas y salidas
    clrf    TRISD 
    clrf    TRISE 
    bsf	    TRISB, 0	    ;  B aumento
    bsf	    TRISB, 1	    ; B decremento
    bsf	    TRISB, 2	    ; B decremento
    bsf	    TRISB, 3	    ; B decremento
    bsf	    TRISB, 4	    ; B decremento
    bcf	    OPTION_REG, 7   ; pull ups enable (RBUP)
    bsf	    WPUB, 0 
    bsf	    WPUB, 1
   
    banksel PORTA	    ;banco 00
    clrf    PORTA	    ; limpiar los puertos
    clrf    PORTC
    clrf    PORTD
    clrf    PORTB
    clrf    PORTE
    bsf	    PORTD, 4
    bsf	    PORTD, 6
    return

;------------Configuracion de pull ups---------------------
config_ioc_portb:
    banksel TRISA
    bsf	    IOCB, 0
    bsf	    IOCB, 1
    bsf	    IOCB, 2
    bsf	    IOCB, 3
    bsf	    IOCB, 4
    banksel PORTA
    movf    PORTB, W	    ; al leer termina la condicion de mismatch
    bcf	    RBIF
    return    
    
;-----------Configuracion del TMR0--------------  
config_timer0:
    banksel TRISA
    bcf T0CS      ; reloj interno
    bcf PSA       ; prescaler
    reset_tmr0
    return
    
config_timer0_256:
    banksel TRISA 
    bsf PS2       ; prescaler 1:2(000) 1:4(001) 1:8(010) 1:16(011) 1:32(100) 1:64(101) 1:128(110) 1:256(111)
    bsf PS1
    bsf PS0
    banksel PORTA
    return 
config_timer0_128:
    banksel TRISA
    bsf PS2       ; prescaler 1:2(000) 1:4(001) 1:8(010) 1:16(011) 1:32(100) 1:64(101) 1:128(110) 1:256(111)
    bsf PS1
    bcf PS0
    banksel PORTA
    return  
config_timer0_64:
    banksel TRISA
    bsf PS2       ; prescaler 1:2(000) 1:4(001) 1:8(010) 1:16(011) 1:32(100) 1:64(101) 1:128(110) 1:256(111)
    bcf PS1
    bsf PS0
    banksel PORTA
    return
config_timer0_32:
    banksel TRISA
    bsf PS2       ; prescaler 1:2(000) 1:4(001) 1:8(010) 1:16(011) 1:32(100) 1:64(101) 1:128(110) 1:256(111)
    bcf PS1
    bcf PS0
    banksel PORTA
    return
config_timer0_02:
    banksel TRISA
    bcf PS2       ; prescaler 1:2(000) 1:4(001) 1:8(010) 1:16(011) 1:32(100) 1:64(101) 1:128(110) 1:256(111)
    bcf PS1
    bcf PS0
    banksel PORTA
    return

config_reloj:
    banksel OSCCON	;oscilador interno de 31kHz(000) 125kHz(001) 250kHz(010) 500kHz(011) 1MHz(100) 2MHz(101) 4MHz(110) 8MHz(111)
    bsf IRCF2
    bsf IRCF1
    bsf IRCF0
    bsf SCS		;reloj interno   
    return   
config_int_enable:	;configuracion de las interrupciones
    bsf GIE	
    bsf RBIE	 
    bcf RBIF	
    bsf T0IE	
    bcf T0IF
    return
config_timer1:		;configuarcion del timer 1
    banksel TRISA 
    bsf	    PIE1, 0   
    banksel PORTA
    bsf	    T1CON, 0
    bcf	    T1CON, 1
    bsf	    T1CON, 4
    bsf	    T1CON, 5
    return
END


