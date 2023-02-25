;Archivo:	postlab_5.s
;Dispositivo:	PIC16F887
;Autor:		Sebastian Mayén Dávila
;Copilador:	pic-as (v2.40),MPLABX v6.05
;
;Progra:	contador por botones en displays en el mismo puerto en decimal
;Hardware:	display leds and push buttons
; 
; Creado:	24 de febrero, 2023
; Ultima modificacion: 24 de febrero, 2023
    
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
  movlw 253	    ;mover literal de valor de timer0 a W
  movwf TMR0	    ;Se carga el valor inicial al TMR0
  bcf T0IF	    ;Se apaga la bandera de interrupción del timer0
  endm
  
;-----------------Variables--------------
PSECT udata_shr
  W_TEMP:	    DS 1    ;Variable reservada para guardar el W Temporal
  STATUS_TEMP:	    DS 1    ;Variable reservada para guardar el STATUS Temporal
  valor:	    DS 1    ;Variable del valor a modificar 
  banderas:	    DS 1    ;banderas para seleccion de display
  display_var:	    DS 3    ;24 bits porque son 3 displays 
    
  unidades:	    DS 1    ;variable de unidades
  decenas:	    DS 1    ;variable de decenas
  centenas:	    DS 1    ;variable de centenas
    
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
pop:			    
    swapf   STATUS_TEMP, W  ;volver a W el orden de los nibbles
    movwf   STATUS	    ;volver al registro status el valor original
    swapf   W_TEMP, F	    
    swapf   W_TEMP, W
    retfie
;------------Subrutinas de interrupciones------------
int_button:
    banksel PORTA
    btfss   PORTB, 0	;si es 1 salta, 0 continua (estan en pull ups)
    incf    PORTA	;incrementar el puerto A
    btfss   PORTB, 1	;si es 1 salta, 0 continua (estan en pull ups)
    decf    PORTA	;decrementar el puerto A
    bcf	    RBIF	;apagar bandera de interrupcion
    return

;---------------interupcion de TMR0-------------    
int_TMR0:
    call seleccion_display  ;llamar a subrutina 
    reset_tmr0		    ;llamar a macro
    return
    
seleccion_display:
    clrf    PORTD	    ;limpiar el puerto de seleccion cada vez que se active la interrupción
    btfsc   banderas, 0	    
    goto    display_0
    btfsc   banderas, 1
    goto    display_1
    goto    display_2
display_0:		    ;prender el display de unidades  
    movf    display_var, W  ;mover el valor modificado al puerto C
    movwf   PORTC
    bsf	    PORTD, 0	    
    bcf	    banderas, 0
    bsf	    banderas, 1
    return
display_1:		    ;prender el display de decenas
    movf    display_var+1, W ;mover el valor modificado al puerto C
    movwf   PORTC
    bsf	    PORTD, 1
    bcf	    banderas, 1
    bsf	    banderas, 2
    return
display_2:		    ;prender el display de centenas
    movf    display_var+2, W ;mover el valor modificado al puerto C
    movwf   PORTC
    bsf	    PORTD, 2
    bcf	    banderas, 2
    bsf	    banderas, 0
    return

    
;------------Codigo principal--------------
PSECT code, delta=2, abs
ORG 100h
 
tabla:
    clrf    PCLATH
    bsf	    PCLATH, 0
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
    
;-----------llamadas principales para configuracion del pic---------------
main:
    call config_io
    call config_reloj
    call config_timer0
    call config_ioc_portb
    call config_int_enable
    banksel PORTA

;-----------LOOP principal--------------------
loop:
    movf    PORTA, W		;mover el valor de puerto A a W
    movwf   valor		;mover el valor de puerto A a la variable 
    call    preparar_display	;llamar a subrutinas de variables unidad, decenas, centenas
    
    clrf    unidades
    clrf    decenas
    clrf    centenas
    
    call    cont_centenas
    call    cont_decenas
    call    cont_unidades
    goto    loop

;----------Modificación del contador para mostrar en display---------
preparar_display:
    movf    decenas, W	    ;mover decenas a W
    call    tabla	    ;llamar a tabla para equivalencia del display
    movwf   display_var+1   ;cargar el valor a display 
    
    movf    centenas, W	    ;mover centenas a W
    call    tabla	    ;llamar a tabla para equivalencia del display
    movwf   display_var+2   ;cargar el valor a display 
    
    movf    unidades, W	    ;mover unidades a W
    call    tabla	    ;llamar a tabla para equivalencia del display
    movwf   display_var	    ;cargar el valor a display 
    
    return

cont_centenas:
    movlw   100
    subwf   valor, F	;valor - W = valor
    incf    centenas
    btfsc   STATUS, 0	; W > f = 0 (negativo)  W <= f = 1 (postivo)
    goto    $-4		; C = 1
    decf    centenas	; C = 0
    movlw   100
    addwf   valor, F	;volver al valor sin la cantidad de centenas unicamente decenas y unidades
    return
cont_decenas:
    movlw   10
    subwf   valor, F	;valor - W = valor
    incf    decenas
    btfsc   STATUS, 0	; W > f = 0 (negativo)  W <= f = 1 (postivo)
    goto    $-4		; C = 1
    decf    decenas	; C = 0
    movlw   10
    addwf   valor, F	;volver al valor sin la cantidad de decenas unicamente unidades
    return
cont_unidades:
    movlw   1
    subwf   valor, F	;valor - W = valor
    incf    unidades
    btfsc   STATUS, 0	; W > f = 0 (negativo)  W <= f = 1 (postivo)
    goto    $-4		; C = 1
    decf    unidades	; C = 0
    movlw   1
    addwf   valor, F	;llega a 0
    return
    
;---------------------- Configuracion general -------------------------------   
config_io:    
    bsf	    STATUS, 5  ; banco 11
    bsf	    STATUS, 6
    clrf    ANSEL ; limpiar el registro (hacer entradas digitales)
    clrf    ANSELH  
    
    bsf	    STATUS, 5 ; banco 01
    bcf	    STATUS, 6
    clrf    TRISA  ; hacer entradas y salidas
    clrf    TRISC  ; hacer entradas y salidas
    clrf    TRISD 
    bsf	    TRISB, 0;  B aumento
    bsf	    TRISB, 1 ; B decremento
    bcf	    OPTION_REG, 7 ; pull ups enable (RBUP)
    bsf	    WPUB, 0 
    bsf	    WPUB, 1
   
    bcf	    STATUS, 5 ;banco 00
    bcf	    STATUS, 6
    clrf    PORTA  ; limpiar los puertos
    clrf    PORTC
    clrf    PORTD
    clrf    PORTB
    return

;------------Configuracion de pull ups---------------------
config_ioc_portb:
    banksel TRISA
    bsf	    IOCB, 0
    bsf	    IOCB, 1
    banksel PORTA
    movf    PORTB, W  ; al leer termina la condicion de mismatch
    bcf	    RBIF
    return    
    
;-----------Configuracion del TMR0--------------   
config_timer0:
    banksel TRISA
    bcf T0CS      ; reloj interno
    bcf PSA       ; prescaler 
    bsf PS2       ; prescaler 1:2(000) 1:4(001) 1:8(010) 1:16(011) 1:32(100) 1:64(101) 1:128(110) 1:256(111)
    bsf PS1
    bsf PS0
    reset_tmr0
    return    
config_reloj:
    banksel OSCCON	;oscilador interno de 31kHz(000) 125kHz(001) 250kHz(010) 500kHz(011) 1MHz(100) 2MHz(101) 4MHz(110) 8MHz(111) 
    bcf IRCF2
    bsf IRCF1
    bcf IRCF0
    bsf SCS		;reloj interno
    return   
config_int_enable:	;configuracion de las interrupciones
    bsf GIE	
    bsf RBIE	 
    bcf RBIF	
    bsf T0IE	
    bcf T0IF	
    return
END



