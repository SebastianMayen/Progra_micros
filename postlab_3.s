;Archivo:    postlab3.s
;Dispositivo: PIC16F887
;Autor:       Sebastian May�n D�vila
;Copilador: pic-as (v2.40),MPLABX v6.05
;
;Progra: contador de segundos y display
;Hardware: LEDs and pushbutton display
; 
; Creado: 10 de febrero, 2023
; Ultima modificacion: 10 de febrero, 2023
    
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

  
PSECT udata_bank0 ;common memory
  cont: DS 1 ;1 byte
   
PSECT resVect, class=CODE, abs, delta=2
    
;-------------vector reset--------------
ORG 00h ; iniciamos en la direccion 0
resetVec:
    PAGESEL main 
    goto main

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
    retlw   01110111B  ;A
    retlw   01111100B  ;b
    retlw   00111001B  ;C
    retlw   01011110B  ;d
    retlw   01111001B  ;E
    retlw   01110001B  ;F

 ;------configuracion principal --------
main: 
    call config_io
    call config_reloj
    call config_timer0
    banksel PORTA

loop: 
    btfss T0IF  
    goto $-1
    call reset_tmr0
    incf PORTD
    btfsc PORTD, 4
    call contador_segundos ; contador de segundos 
    btfsc PORTB, 6
    call dec_porta ; decrementar el display
    btfsc PORTB, 7
    call inc_porta  ;aumentar el display
    movf PORTA, W
    call tabla   ; llamada a la tabla para convertir al display
    movwf PORTC
    bcf PORTB, 4  ;---- verificar que el cont de segundos es igual al del display
    movf PORTA, W 
    subwf PORTB, W
    btfsc ZERO 
    call zero_flaj
    goto loop 

    ;-------- bandera del contador de display y segundos iguales 
zero_flaj:
    clrf PORTB; limpiar el contador de segundos 
    bsf PORTB, 4 ; prender el led de alerta
    return
 
    
    ;------- contador de segundos
contador_segundos:
    incf PORTB ; incrementa despues de 10 veces el timer 0
    clrf PORTD ; y se limpia el puerto D
    return
    
    
    ;-------- incremento y decremento por botones del display
inc_porta:
    call delay_small
    btfsc PORTB, 7 ; antirebote
    goto $-1
    incf PORTA
    btfsc PORTA, 4
    clrf PORTA
    return   
    
dec_porta:
    call delay_small
    btfsc PORTB, 6 ; antirebote
    goto $-1
    decf PORTA
    movlw 15
    btfsc PORTA, 4
    movwf PORTA
    return
 
    
    ; *--------configuracion del timer 0 para estar a 100ms y reset
config_timer0:
    banksel TRISA
    bcf T0CS      ; reloj inerno
    bcf PSA       ; prescaler 
    bsf PS2       ; prescaler 1:256 (111)
    bsf PS1
    bsf PS0 
    banksel PORTA
    call reset_tmr0
    return
    
reset_tmr0:
    movlw 158   ; volver el timer 0 a su valor inicial
    movwf TMR0
    bcf   T0IF
    return
 
    ;-------- configuracion de entradas y salidas 
config_io:
    bsf STATUS, 5  ; banco 11
    bsf STATUS, 6
    clrf ANSEL ; limpiar el registro (hacer entradas digitales)
    clrf ANSELH  ; limpiar el registro (hacer entradas digitales)
    
    bsf STATUS, 5 ; banco 01
    bcf STATUS, 6
    clrf TRISA  ; hacer salidas
    clrf TRISC
    clrf TRISD
    bcf TRISB, 0 ; salida 
    bcf TRISB, 1 ; salida
    bcf TRISB, 2 ; salida 
    bcf TRISB, 3 ; salida
    bcf TRISB, 4 ; salida
    bsf TRISB, 6 ; entrada 
    bsf TRISB, 7 ; entrada
   
    bcf STATUS, 5 ;banco 00
    bcf STATUS, 6
    clrf PORTA  ; limpiar los puertos
    clrf PORTC
    clrf PORTD
    clrf PORTB
    return
    
;---------- oscilador de 1Mhz--------------
config_reloj: 
    banksel OSCCON   ;100 oscilador interno de 1MHz
    bsf IRCF2
    bcf IRCF1
    bcf IRCF0
    bsf SCS ; reloj interno
    return
    
  ;--------delay para botones    
delay_small:
    movlw 164     ; peque�o delay para evitar ruido al momento de presionar los push buttons 
    movwf cont
    decfsz cont, 1
    goto $-1
    return
    
END


