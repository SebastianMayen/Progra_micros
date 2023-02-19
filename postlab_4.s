;Archivo:    postlab4.s
;Dispositivo: PIC16F887
;Autor:       Sebastian Mayén Dávila
;Copilador: pic-as (v2.40),MPLABX v6.05
;
;Progra: contador de segundos y display
;Hardware: LEDs and pushbutton display
; 
; Creado: 17 de febrero, 2023
; Ultima modificacion: 17 de febrero, 2023
    
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


;-----------------MACROS----------------
reset_tmr0 macro
  banksel PORTA	;banco 00
  movlw 246	;valor inicial del TMR0
  movwf TMR0	;Se carga el valor inicial
  bcf T0IF	;Se apaga la bandera de interrupción por Overflow del TMR0
  endm
  
;---------variables a utilizar----------
  
PSECT udata_bank0 ;common memory
  cont:	    DS 1; 1 byte
  W_TEMP:   DS 1 ;Variable reservada para guardar el W Temporal
  STATUS_TEMP: DS 1 ;Variable reservada para guardar el STATUS Temporal
  cont_unidades: DS 1
  cont_decenas: DS 1
    
    
;--------------vector Reset-------------   
PSECT VectorReset, class=CODE, abs, delta=2
;-------------vector reset--------------
ORG 00h		;Posición 0000h para el reset
    
VectorReset:
    PAGESEL main 
    goto main
    
; ----configuracion del microcontrolador----
;PSECT code, delta=2, abs
    
;-------------Vector de Interrupción---------
    
ORG 04h			    ;posicionamiento para las interrupciones.
push:
    movwf W_TEMP	    ;guardado temporal de STATUS y W
    swapf STATUS, W 
    movwf STATUS_TEMP
isr:			    ;instrucciones de la interrupcion
    btfsc T0IF		;revision de la bandera de interrupcion por el TMR0
    call inte_TMR0	;Si esta en 1 la bandera, se llama la subrutina de interrupcion	    
    btfsc RBIF		;revision de la bandera de interrupcion on-change del PORTB
    call inte_portb	;Si esta en 1 la bandera, se llama la subrutina de interrupcion
    
pop:			    
    swapf STATUS_TEMP, W
    movwf STATUS
    swapf W_TEMP, F
    swapf W_TEMP, W
    retfie

;----------SubRutinas de INTERRUPCIÓN-------
inte_portb: ;interrupcion en el puertoB
    banksel PORTB
    btfss PORTB, 0 
    incf PORTA
    btfss PORTB, 1	
    decf PORTA
    bcf RBIF
    return
   
inte_TMR0:
    reset_tmr0 ;macro
    decfsz cont	
    return
    call set_cont 
    call inc_unidades
    return
    
inc_unidades:
    banksel PORTD
    incf cont_unidades
    movf cont_unidades, W
    call tabla
    ;banksel PORTD
    movwf PORTD
    movf cont_unidades, W
    sublw 10
    btfsc ZERO 
    call inc_decenas
    return

inc_decenas:
    clrf cont_unidades
    incf cont_decenas
    movf cont_decenas, W
    call tabla
    movwf PORTC
    movf cont_decenas, W
    sublw 6
    btfsc ZERO
    call reset_decenas
    return
reset_decenas:
    clrf cont_decenas
    movf cont_decenas, W
    call tabla
    movwf PORTC
    return
    
set_cont:
    movlw 100 
    movwf cont 
    return
       
PSECT code, delta=2, abs    
ORG 100h	

tabla:
    banksel PCLATH
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
    retlw   00111111B  ;0
 
 ;------configuracion-------
main:
    movlw 100
    movwf cont
    
    call config_tmr0	
    call config_io	
    call config_reloj	
    call config_push	
    call config_inte	
    banksel PORTA
    
    ;------loop principal-------
loop:  
    
    goto loop
    
    ;--------sub rutinas---------  

config_push:
    banksel TRISA
    bsf IOCB,0 ; 
    bsf IOCB,1 ; 
    
    banksel PORTA
    movf PORTB, W   ;lectura del PORTB
    bcf RBIF	    ;Se limpia la bandera RBIF
    return
    
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
    bsf	    WPUB, 7
   
    bcf	    STATUS, 5 ;banco 00
    bcf	    STATUS, 6
    clrf    PORTA  ; limpiar los puertos
    clrf    PORTC
    clrf    PORTD
    clrf    PORTB
    return
    
    
config_tmr0:
    banksel TRISA
    bcf T0CS      ; reloj interno
    bcf PSA       ; prescaler 
    bsf PS2       ; prescaler 1:256 (111)
    bsf PS1
    bsf PS0
    reset_tmr0
    return    

config_reloj:
    banksel OSCCON   ;100 oscilador interno de 1MHz
    bsf IRCF2
    bcf IRCF1
    bcf IRCF0
    bsf SCS ; reloj interno
    return
    
config_inte: ;configuracion de las interrupciones
    bsf GIE	
    bsf RBIE	 
    bcf RBIF	
    bsf T0IE	
    bcf T0IF	
    return
    
    
END 