/*
 * File:   main.c
 * Author: mayen
 *
 *
 */
#pragma config FOSC = INTRC_CLKOUT// Oscillator Selection bits (INTOSC oscillator: CLKOUT function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
#pragma config PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
#pragma config MCLRE = OFF       // RE3/MCLR pin function select bit (RE3/MCLR pin function is MCLR)
#pragma config CP = OFF         // Code Protection bit (Program memory code protection is disabled)
#pragma config CPD = OFF        // Data Code Protection bit (Data memory code protection is disabled)
#pragma config BOREN = OFF     // Brown Out Reset Selection bits (BOR disabled)
#pragma config IESO = OFF      // Internal External Switchover bit (Internal/External Switchover mode is disabled)
#pragma config FCMEN = OFF     // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
#pragma config LVP = OFF

#pragma config BOR4V = BOR40V
#pragma config WRT  =   OFF

#include <xc.h>
#include <stdint.h>
#include <pic16f887.h>

#define _XTAL_FREQ 8000000  


// Variables 
unsigned int ADC_voltaje1;
int loop;
char option_selected;
int equivalent;


// Prototipos 
void setup(void);
void setupADC(void);
void initUART(void);
void print(unsigned char *palabra);
void conversion(int voltaje);

//Interrupciones 
void __interrupt() isr (void){
  if(PIR1bits.ADIF){ // reestableser las interrupciones 
      PORTBbits.RB7=1;
      PIR1bits.ADIF=0; // Interrupcion de ADC
      PIR1bits.TXIF=0; // Interrupcion de transmicion
  }  
}
void main(void) {
    setup();
    
    while(1){
        print("l)Leer Potenciometro\r"); // Menu de la terminal
        print("2)Enviar ASCII \r");
        
        while(PIR1bits.RCIF==0){ // interrupcion de eusart
            ;
        }
        ADCON0bits.CHS = 0b0001; // seleccion del canal
        __delay_us(100);
        ADCON0bits.GO=1;        // inicial la conbercion 
        while(ADCON0bits.GO==1){ // loop mientras se hacer la convercion
            ;
        }
        ADC_voltaje1= ADRESH;  // mandar el valor de ADRESH a una variable 
        conversion(ADC_voltaje1); // usar la funcion para hacer la convercion 
        __delay_us(100);
        option_selected= RCREG; // guardar el valor recivido en option de seleccion 
        if(option_selected == '1'){ // Si es uno mostar el valor del poteciometro en un puerto
            print("Valor del potenciometro en caracter Ascii = ");
            TXREG= ADC_voltaje1;
            PORTD = TXREG;
            print("\r");
            
        }else if(option_selected == '2'){ // Si es dos introducir el valor que se muestre en el port B 
            print("Introduce el caracter a leer en el puero B: \r");
            while(PIR1bits.RCIF ==0){ // ciclo miestras se recive la señal
                ;
            }
            PORTB=RCREG; // mostrar en el puero B
        }else{
            print("error al elegir");
        }
    }
    
}
void setup(void){
    TRISB=0;
    PORTB=0;
    TRISD=0;
    PORTD=0;
    OSCCONbits.IRCF= 0b111;
    OSCCONbits.SCS=1;
    INTCONbits.GIE=1;
    PIE1bits.ADIE=1;
    INTCONbits.TMR0IE=1;
    PIR1bits.ADIF=0;

// setupADC
    TRISAbits.TRISA1=1;
    ANSELbits.ANS1=1; //ans1 como entrda analogivs
    ADCON0bits.ADCS= 0b10; // bandera del adc 
    ADCON1bits.VCFG1=0; 
    ADCON1bits.VCFG0=0;
    ADCON1bits.ADFM=0;
    ADCON0bits.CHS= 0b0001; // canal del ADC
    ADCON0bits.ADON=1; 
    __delay_us(100);
        

// initUART
    SPBRG=12;       // Configuracion para UART
    TXSTAbits.SYNC=0;
    RCSTAbits.SPEN=1;
    TXSTAbits.TXEN=1;
    PIR1bits.TXIF=0;
    RCSTAbits.CREN=1;
    
}
void conversion(int voltaje){ // convercion del valor 
    equivalent=(unsigned short)(48+((float)(207)/(255))*(voltaje-0));
}
void print(unsigned char *palabra){ // ciclo para mostrar una cadena de caracteres 
    while(*palabra !='\0'){
        while(TXIF != 1);
        TXREG= *palabra;
        *palabra++;
    }
}

