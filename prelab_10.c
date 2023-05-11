// CONFIG1
#pragma config FOSC = INTRC_NOCLKOUT// Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
#pragma config PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
#pragma config MCLRE = OFF       // RE3/MCLR pin function select bit (RE3/MCLR pin function is MCLR)
#pragma config CP = OFF         // Code Protection bit (Program memory code protection is disabled)
#pragma config CPD = OFF        // Data Code Protection bit (Data memory code protection is disabled)
#pragma config BOREN = OFF       // Brown Out Reset Selection bits (BOR enabled)
#pragma config IESO = OFF        // Internal External Switchover bit (Internal/External Switchover mode is enabled)
#pragma config FCMEN = OFF       // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is enabled)
#pragma config LVP = OFF         // Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

// CONFIG2
#pragma config BOR4V = BOR40V   // Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
#pragma config WRT = OFF        // Flash Program Memory Self Write Enable bits (Write protection off)

#define _XTAL_FREQ 1000000

#include<xc.h>
#include<pic.h>
#include<stdint.h>

//-------------------------------variables------------------------------------|
uint8_t counter;
uint8_t counter_comparador;
unsigned int centena; // Almacena las centenas en  ASCII
unsigned int decena; // Almacena las decenas en  ASCII
unsigned int unidad; // Almacena las unidades en  ASCII
uint8_t uart_data;
uint8_t numero_recibido; //alamacena el valor que se escribe en la terminal




//|------------------------------prototipos------------------------------------|

void setup(void);
void __interrupt() isr(void);



//-------------main----------------------

void    main(void){
    setup();

    while(1){
        TXREG = centena + 48; // Enviar el valor de las centenas
        __delay_ms(10); 
                
        TXREG = decena + 48; // Enviar el valor de las decenas
        __delay_ms(10); 
                
        TXREG = unidad + 48; // Enviar el valor de las unidades
  
        //TXREG = counter;
        __delay_ms(10); 
        
        
        //EXTRAAAAAAAAAAAAAAAA
        TXREG = '\n'; // Enviar nueva línea
        __delay_ms(10);

        TXREG = '\r'; // Enviar retorno 
        __delay_ms(10);


        PORTA = counter; //poner el valor del contador en el puerto A

 
        
        if(RCIF == 1){
            uart_data = RCREG;
            PIR1bits.RCIF = 0; // Borrar el indicador

        } 
        
        if (uart_data >= '0' && uart_data <= '9') {
         numero_recibido = uart_data - '0';

        if (numero_recibido >= 0 && numero_recibido <= 255) {
            PORTD = numero_recibido;
        }
    }

// Con este código:

        if (uart_data != 0) {
            numero_recibido = uart_data;

            if (numero_recibido >= 0 && numero_recibido <= 255) {
                PORTD = numero_recibido;
            }
            uart_data = 0;
        }
        
//    // Verificar si el valor recibido (almacenado en 'uart_data') está en el rango de caracteres numéricos ASCII '0' a '9'
//    if (uart_data >= '0' && uart_data <= '9') {
//        // Convertir el valor ASCII en 'uart_data' a su representación numérica entera
//        // restando el valor ASCII de '0'
//         numero_recibido = uart_data - '0';
//
//        // Verificar si el número recibido está en el rango de 0 a 255
//    if (numero_recibido   >= 0 && numero_recibido   <= 255) {
//            // Si el número recibido está en el rango válido, asignarlo al Puerto D
//            PORTD = numero_recibido ;
//        }
//    }
        
    }
}

//|------------------------------Setup----------------------

void setup(void){
    
//-------------configuracion de puertos----------------
    ANSEL   =   0;
    ANSELH  =   0;
    TRISA   =   0;
    TRISD = 0;
    
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
    PORTD = 0;
    
    
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

       


//----------------Interrupcion--------------------
void __interrupt() isr(void) {
    // Comprobar si se ha producido una interrupción en PORTB 
    if (RBIF) {
        // Si RB0 está presionado  y RB1 no está presionado 
        if (RB0 == 0 && RB1 == 1) {
            counter++; // Incrementar el contador
        }
        // Si RB0 no está presionado  y RB1 está presionado 
        if (RB0 == 1 && RB1 == 0) {
            counter--; // Decrementar el contador
        }
        
        centena = (counter/100); // Calcular las centenas del valor
        
        decena = ((counter/10)%10); // Calcular las decenas del valor
        
        unidad = (counter%10); // Calcular las unidades del valor
        // Limpiar la bandera de interrupción de PORTB 
        RBIF = 0;
    }
     __delay_ms(10);

}

