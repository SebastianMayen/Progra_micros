// CONFIG1
#pragma config FOSC = INTRC_NOCLKOUT // Bits de selección del oscilador (Oscilador INTOSCIO: función de E/S en el pin RA6/OSC2/CLKOUT, función de E/S en el pin RA7/OSC1/CLKIN)
#pragma config WDTE = OFF       // Bit de habilitación del perro guardián (Perro guardián deshabilitado, se puede habilitar mediante el bit SWDTEN del registro WDTCON)
#pragma config PWRTE = OFF      // Bit de habilitación del temporizador de encendido (Temporizador de encendido deshabilitado)
#pragma config MCLRE = OFF      // Bit de selección de la función del pin RE3/MCLR (La función del pin RE3/MCLR es una entrada digital, MCLR está conectado internamente a VDD)
#pragma config CP = OFF         // Bit de protección del código (Protección de código de memoria de programa deshabilitada)
#pragma config CPD = OFF        // Bit de protección de datos (Protección de código de memoria de datos deshabilitada)
#pragma config BOREN = OFF      // Bits de selección del restablecimiento por bajo voltaje (Restablecimiento por bajo voltaje deshabilitado)
#pragma config IESO = OFF       // Bit de selección de conmutación interna/externa (Modo de conmutación interna/externa deshabilitado)
#pragma config FCMEN = OFF      // Bit de habilitación del monitor de reloj a prueba de fallas (Monitor de reloj a prueba de fallas deshabilitado)
#pragma config LVP = OFF        // Bit de habilitación de la programación de voltaje bajo (El pin RB3 tiene E/S digital, se debe utilizar HV en MCLR para la programación)

// CONFIG2
#pragma config BOR4V = BOR40V   // Bit de selección de restablecimiento por bajo voltaje (Restablecimiento por bajo voltaje ajustado a 4.0V)
#pragma config WRT = OFF        // Bits de habilitación de la escritura automática en la memoria de programa Flash (Protección de escritura desactivada)

#include <xc.h>
#include <stdint.h>
#include <pic16f887.h>

#define _XTAL_FREQ 500000 // Frecuencia de oscilación de 500 kHz
#define tmr0_val 246 // Valor del temporizador 0 para un período de 20 ms

// Prototipos de funciones 
void setup(void);
void setupADC(void);
void setupPWM(void);
void tmr0_setup(void);
void delay(unsigned int micro);
void pwmanual(void);
void EEPROMWRITE(uint8_t address, uint8_t data);
uint8_t EEPROMREAD(uint8_t address);
void contmodo(void);
unsigned int map(uint8_t value, int inputmin, int inputmax, int outmin, int outmax);

void setup_UART(void);
void UART_Write_Char(uint8_t character);

unsigned int bandera;
// variable para modo manual y EEPROM
int modo;
unsigned int mapeo1;
unsigned int mapeo2;
unsigned int mapeo3;
unsigned int mapeo4;
unsigned int address;

//variables para modo UART
uint8_t counter;
uint8_t counter_comparador;
unsigned int centena; // Almacena las centenas en  ASCII
unsigned int decena; // Almacena las decenas en  ASCII
unsigned int unidad; // Almacena las unidades en  ASCII
uint8_t uart_data;
uint8_t numero_recibido; //alamacena el valor que se escribe en la terminal



void __interrupt() isr(void) {
    if (PIR1bits.ADIF) {
        PIR1bits.ADIF = 0; // Limpiar la bandera de interrupción del ADC
    }

    if (INTCONbits.T0IF) {
        pwmanual(); // Llamar a la rutina de interrupción del PWM manual
    }

    if (INTCONbits.RBIF) {
        if (PORTBbits.RB1 == 0) {
            //PORTDbits.RD4 = 1;
            EEPROMWRITE(0x10, mapeo1);
            EEPROMWRITE(0x11, mapeo2);
            EEPROMWRITE(0x12, mapeo3);
            EEPROMWRITE(0x13, mapeo4);
        } else if (PORTBbits.RB2 == 0) {
            if (modo == 2) {
                PORTDbits.RD1 = 1;
                mapeo1 = EEPROMREAD(0x10);
                mapeo2 = EEPROMREAD(0x11);
                mapeo3 = EEPROMREAD(0x12);
                mapeo4 = EEPROMREAD(0x13);
            }
        }
        INTCONbits.RBIF = 0; // Limpiar la bandera de interrupción del puerto B
    }    
}

void main(void) {
    setup();
    setupADC();
    setupPWM();
    tmr0_setup();
    modo = 1;
    address = 0;

    while (1) {
        if (PORTBbits.RB0 == 0) {
            __delay_ms(20);
            while (PORTBbits.RB0 == 0) {
                ;
            }
            contmodo(); // Incrementar el contador de modo
        }

        switch (modo) {
            case (1):
                setup();
//agregar leds para indicar  modo
                PORTDbits.RD0 = 1;
                PORTDbits.RD1 = 0;
                PORTDbits.RD2 = 0;       
                PORTDbits.RD3 = 0;
                PORTE = 7;
                ADCON0bits.CHS = 0b0000; // Seleccionar el canal 0
                __delay_us(100);
                ADCON0bits.GO = 1; // Iniciar la conversión ADC
                while (ADCON0bits.GO == 1) { 
                    ; // Esperar a que se complete la conversión
                }

                mapeo1 = map(ADRESH, 0, 255, 3, 20); // Mapear el potenciómetro 1
                CCPR1L = mapeo1; // Asignar el valor al servo 1
                __delay_us(100);

                ADCON0bits.CHS = 0b0010; // Seleccionar el canal 1
                __delay_us(100);
                ADCON0bits.GO = 1; // Iniciar la conversión ADC
                while (ADCON0bits.GO == 1) {
                    ; // Esperar a que se complete la conversión
                }

                mapeo2 = map(ADRESH, 0, 255, 3, 20); // Mapear el potenciómetro 2
                CCPR2L = mapeo2; // Asignar el valor al servo 2
                __delay_us(100);

                ADCON0bits.CHS = 0b0011; // Seleccionar el canal 3
                __delay_us(100);
                ADCON0bits.GO = 1; // Iniciar la conversión ADC
                while (ADCON0bits.GO == 1) {
                    ; // Esperar a que se complete la conversión
                }

                mapeo3 = map(ADRESH, 0, 255, 2, 10); // Mapear el potenciómetro 3
                __delay_us(100);

                ADCON0bits.CHS = 0b0100; // Seleccionar el canal 4
                __delay_us(100);
                ADCON0bits.GO = 1; // Iniciar la conversión ADC
                while (ADCON0bits.GO == 1) {
                    ; // Esperar a que se complete la conversión
                }

                mapeo4 = map(ADRESH, 0, 255, 2, 10); // Mapear el potenciómetro 4
                __delay_us(100);

                break;

            case (2):
//agregar leds para indicar  modo
                PORTDbits.RD0 = 0;
                PORTDbits.RD1 = 1;
                PORTDbits.RD2 = 0;
                PORTDbits.RD3 = 0;
                PORTE = 7;
                CCPR1L = mapeo1; // Actualizar el valor del PWM para el potenciómetro 1
                CCPR2L = mapeo2; // Actualizar el valor del PWM para el potenciómetro 2

                break;      
            case (3):
                 
                if (bandera == 0){
                     CCPR1L = 23; // Actualizar el valor del PWM para el potenciómetro 1
                CCPR2L = 23; // Actualizar el valor del PWM para el potenciómetro 2
                    setup_UART();
                }          
//agregar leds para indicar  modo
                PORTDbits.RD0 = 0;
                PORTDbits.RD1 = 0;
                PORTDbits.RD2 = 1;
                PORTDbits.RD3 = 0;           
                

        if(RCIF == 1){
            uart_data = RCREG;
            PIR1bits.RCIF = 0; // Borrar el indicador

        } 
        
        if (uart_data >= '0' && uart_data <= '9') {
         numero_recibido = uart_data - '0';

        if (numero_recibido >= 0 && numero_recibido <= 255) {
            PORTE = numero_recibido;
            CCPR1L = numero_recibido; // Actualizar el valor del PWM para el potenciómetro 1
            CCPR2L = numero_recibido; // Actualizar el valor del PWM para el potenciómetro 2
        }
    }

// Con este código:

        if (uart_data != 0) {
            numero_recibido = uart_data;

            if (numero_recibido >= 0 && numero_recibido <= 255) {
                PORTE = numero_recibido;
                CCPR1L = numero_recibido; // Actualizar el valor del PWM para el potenciómetro 1
                CCPR2L = numero_recibido; // Actualizar el valor del PWM para el potenciómetro 2
            }
            uart_data = 0;
        }             
                
                break;
                
            case (4):               
//agregar leds para indicar  modo
                PORTDbits.RD0 = 0;
                PORTDbits.RD1 = 0;
                PORTDbits.RD2 = 0;
                PORTDbits.RD3 = 1;
                
                if(RCIF){ // Si el flag de interrupción de recepción está establecido
             PORTE = RCREG;
             CCPR1L = RCREG; // Lee el registro de recepción en el puerto D
             CCPR2L = RCREG; // Lee el registro de recepción en el puerto D
        }
                
                
                break;
                
        }
    }
}
void UART_Write_Char(uint8_t character){ // Función para escribir un solo carácter a la UART
    TXREG = character; // Escribe el carácter al registro de transmisión
    while (!TXSTAbits.TRMT); // Espera a que el carácter se haya transmitido completamente
}
void setup(void) {
    bandera = 0;
    // --------------- Configuración de puertos y pines ---------------
    ANSELH = 0;
    ANSELbits.ANS0 = 1; // RA0 como entrada analógica
    ANSELbits.ANS2 = 1; // RA2 como entrada analógica
    ANSELbits.ANS3 = 1; // RA3 como entrada analógica
    ANSELbits.ANS4 = 1; // RA4 como entrada analógica

    TRISAbits.TRISA0 = 1; // RA0 como entrada
    TRISAbits.TRISA2 = 1; // RA2 como entrada
    TRISAbits.TRISA3 = 1; // RA3 como entrada
    TRISAbits.TRISA4 = 1; // RA4 como entrada

    TRISBbits.TRISB0 = 1; // RB0 como entrada
    TRISBbits.TRISB1 = 1; // RB1 como entrada
    TRISBbits.TRISB2 = 1; // RB2 como entrada
    TRISBbits.TRISB3 = 1; // RB3 como entrada
    TRISBbits.TRISB4 = 1; // RB4 como entrada

    TRISCbits.TRISC3 = 0; // RC3 como salida
    TRISCbits.TRISC4 = 0; // RC4 como salida
    TRISEbits.TRISE2 = 1; // RE2 como entrada
    
    TRISD = 0;
    TRISE  =   0;
    PORTA = 0;
    PORTB = 0;
    PORTC = 0;
    PORTE = 0;
    PORTD = 0;

    // --------------- Configuración de resistencias pull-up ---------------
    OPTION_REGbits.nRBPU = 0; // Habilitar resistencias pull-up en el puerto B
    WPUBbits.WPUB0 = 1; // Habilitar resistencia pull-up en RB0
    WPUBbits.WPUB1 = 1; // Habilitar resistencia pull-up en RB1
    WPUBbits.WPUB2 = 1; // Habilitar resistencia pull-up en RB2
    WPUBbits.WPUB3 = 1; // Habilitar resistencia pull-up en RB3
    WPUBbits.WPUB4 = 1; // Habilitar resistencia pull-up en RB4

    // --------------- Configuración del oscilador ---------------
    OSCCONbits.IRCF = 0b011; // Establecer frecuencia de oscilador en 500kHz
    OSCCONbits.SCS = 1; // Utilizar oscilador interno

    // --------------- Configuración de interrupciones ---------------
    INTCONbits.GIE = 1; // Habilitar interrupciones globales
    INTCONbits.RBIE = 1; // Habilitar interrupciones del puerto B

    IOCBbits.IOCB0 = 1; // Habilitar interrupciones en cambio de estado de RB0
    IOCBbits.IOCB1 = 1; // Habilitar interrupciones en cambio de estado de RB1
    IOCBbits.IOCB2 = 1; // Habilitar interrupciones en cambio de estado de RB2
    IOCBbits.IOCB3 = 1; // Habilitar interrupciones en cambio de estado de RB3
    IOCBbits.IOCB4 = 1; // Habilitar interrupciones en cambio de estado de RB4

    INTCONbits.TMR0IE = 1; // Habilitar interrupciones del TMR0
    INTCONbits.T0IF = 0; // Limpiar bandera de interrupción del TMR0

    INTCONbits.RBIF = 0; // Limpiar bandera de interrupción del puerto B
    PIE1bits.ADIE = 1; // Habilitar interrupciones del ADC
    PIR1bits.ADIF = 0; // Limpiar bandera de interrupción del ADC
    
    
}

void setupADC(void) {
    // --------------- Configuración del reloj del ADC ---------------
    ADCON0bits.ADCS = 0b10; // Fosc/32

    // --------------- Configuración del voltaje de referencia ---------------
    ADCON1bits.VCFG1 = 0; // Voltaje de referencia VSS
    ADCON1bits.VCFG0 = 0; // Voltaje de referencia VDD

    // --------------- Justificación a la izquierda ---------------
    ADCON1bits.ADFM = 0;

    // --------------- Selección de canal inicial ---------------
    ADCON0bits.CHS = 0b0000; // Canal 0

    // --------------- Habilitar el ADC ---------------
    ADCON0bits.ADON = 1;
    PIR1bits.ADIF = 0;
    __delay_ms(100);
}

void setupPWM(void) {
    // --------------- Configuración de los pines CCP1 y CCP2 ---------------
    TRISCbits.TRISC1 = 1; // CCP1 como entrada
    TRISCbits.TRISC2 = 1; // CCP2 como entrada

    // --------------- Configuración del período del PWM ---------------
    PR2 = 155; // Período de 4ms para el TMR2

    // --------------- Configuración del PWM para CCP1 ---------------
    CCP1CONbits.P1M = 0b00; // Modo single output
    CCP1CONbits.CCP1M = 0b1100; // Modo PWM para CCP1
    CCP2CONbits.CCP2M = 0b1111; // Modo PWM para CCP2

    CCP1CONbits.DC1B = 0b11; // Bits menos significativos para el tiempo en alto del PWM
    CCPR1L = 11; // Valor inicial para el PWM

    CCP2CONbits.DC2B0 = 0b1; // Bits menos significativos para el tiempo en alto del PWM
    CCP2CONbits.DC2B1 = 0b1;
    CCPR2L = 11; // Valor inicial para el PWM

    // --------------- Configuración del TMR2 ---------------
    PIR1bits.TMR2IF = 0; // Limpiar bandera del TMR2
    T2CONbits.T2CKPS = 0b11; // Prescaler 16
    T2CONbits.TMR2ON = 1; // Encender el TMR2

    while (!PIR1bits.TMR2IF) {
        ; // Esperar a que se complete el período del TMR2
    }

    // --------------- Habilitar salidas CCP1 y CCP2 ---------------
    TRISCbits.TRISC2 = 0;
    TRISCbits.TRISC1 = 0;
}

void tmr0_setup(void) {
    // --------------- Configuración del TMR0 ---------------
    OPTION_REGbits.T0CS = 0; // Fuente de reloj interna
    OPTION_REGbits.PSA = 0; // Habilitar el prescaler del TMR0
    OPTION_REGbits.PS2 = 0; // Prescaler 1:16
    OPTION_REGbits.PS1 = 1;
    OPTION_REGbits.PS0 = 1;
    INTCONbits.T0IF = 0; // Limpiar bandera de interrupción del TMR0
    TMR0 = tmr0_val; // Valor inicial del TMR0
}

void delay(unsigned int micro) {
    // --------------- Función de retardo en microsegundos ---------------
    while (micro > 0) {
        __delay_us(250);
        micro--;
    }
}

unsigned int map(uint8_t value, int inputmin, int inputmax, int outmin, int outmax) {
    // --------------- Mapear un valor a un rango diferente ---------------
    return ((value - inputmin) * (outmax - outmin)) / (inputmax - inputmin) + outmin;
}


void pwmanual(void) {
    // --------------- Rutina de interrupción del TMR0 para el PWM manual ---------------
    TMR0 = tmr0_val; // Reiniciar el TMR0

    // --------------- Encender el pin RC3 durante mapeo3 microsegundos ---------------
    PORTCbits.RC3 = 1;
    delay(mapeo3);
    PORTCbits.RC3 = 0;

    // --------------- Encender el pin RC4 durante mapeo4 microsegundos ---------------
    PORTCbits.RC4 = 1;
    delay(mapeo4);
    PORTCbits.RC4 = 0;

    INTCONbits.T0IF = 0; // Limpiar bandera de interrupción del TMR0
}

void EEPROMWRITE(uint8_t address, uint8_t data) {
    // --------------- Escribir un dato en la EEPROM ---------------
    while (WR);
    EEADR = address;
    EEDAT = data;

    EECON1bits.EEPGD = 0;
    EECON1bits.WREN = 1;

    INTCONbits.GIE = 0;

    EECON2 = 0x55;
    EECON2 = 0xAA;

    EECON1bits.WR = 1;

    while (PIR2bits.EEIF == 0);
    PIR2bits.EEIF = 0;
    EECON1bits.WREN = 0;
    INTCONbits.RBIF = 0;

    INTCONbits.GIE = 1;
}

uint8_t EEPROMREAD(uint8_t address) {
    // --------------- Leer un dato de la EEPROM ---------------
    while (WR || RD);

    EEADR = address;
    EECON1bits.EEPGD = 0;
    EECON1bits.RD = 1;
    return EEDAT;
}

void contmodo(void) {
    // --------------- Cambiar al siguiente modo ---------------
    if (modo != 4) {
        modo++;
    } else {
        modo = 1;
    }
}
void setup_UART(void){
    bandera = 1;
//-------------configuracion de puertos----------------
    ANSEL   =   0;
    ANSELH  =   0;
    TRISA   =   0;
    TRISE   =   0;
    
     //botones
    TRISBbits.TRISB0 = 1; //rb0 como entrada
    TRISBbits.TRISB1 = 1; //rb1 como entrada 
    
//----------pullups------------------
    OPTION_REGbits.nRBPU = 0; //habilitarr pullups
    WPUBbits.WPUB0 = 1;
    WPUBbits.WPUB1 = 1; 
    
    IOCBbits.IOCB0 = 1; //habilitar interrupciones en rb0
    IOCBbits.IOCB1 = 1; // habilitar interrupciones en rb1

//------------interrupciones-----------------
    INTCONbits.GIE = 1; //habilitar interrupciones globales
    INTCONbits.RBIE = 1; //habilitar interrupciones en portb
    INTCONbits.PEIE = 1;
    INTCONbits.RBIF = 0; //limpirar bander de interrupcion de portb
    
    
   //Se inician los puertos 
    PORTA   =   0;
    PORTB   =   0;
    PORTE   =   0;
    
    
// --------------- Oscilador --------------- 
    OSCCONbits.IRCF = 0b100; // 8 MHz
    OSCCONbits.SCS = 1; // Seleccionar oscilador interno

//------------------UART-------------
    TXSTAbits.SYNC = 0;//asincrono
    TXSTAbits.BRGH = 1;//high baud rate select bit
    
    BAUDCTLbits.BRG16 = 1;//utilizar 16 bits baud rate
    
    SPBRG = 25; //configurar a 9615
    SPBRGH = 0;    

    
    RCSTAbits.SPEN = 1;//habilitar la comunicacion serial
    RCSTAbits.RX9 = 0;//deshabiliamos bit de direccion
    RCSTAbits.CREN = 1;//habilitar recepcion 
    TXSTAbits.TXEN = 1;//habiliar la transmision

    
    //Se inicia el contador en 0
    counter =   0;
    counter_comparador = 255; //valor maximo del contaor

}


