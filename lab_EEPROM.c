/* 
 * File:   lab_EEPROM.c
 * Author: Mayen
 *
 * Created on 24 de abril de 2023, 06:50 PM
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

#define _XTAL_FREQ 4000000
#define dirEEPROM 0x04

//variables *************************************

uint8_t potValue;
uint8_t botonPrevState;

// prototipos de funciones **********************

void setup(void);
void writeToEEPROM(uint8_t data, uint8_t address);
uint8_t readFromEEPROM(uint8_t address);

void __interrupt() isr(void){
    if(INTCONbits.RBIF){      // interrupcion que revisa el puerto B 
        PORTB = PORTB;
        INTCONbits.RBIF = 0;
    }
}

// ciclo principal ***************************

void main(void){

    setup();
    ADCON0bits.GO = 1;
    
    //loop principal *************************
    
    while(1){
        if(ADCON0bits.GO == 0){
            potValue = ADRESH;
            PORTD = potValue;  // guardo en el puerto D el valor de potenciometro
            __delay_us(50);
            ADCON0bits.GO = 1;
        }
        
        PORTC = readFromEEPROM(dirEEPROM);  // guardo en la direccion 4 que habia puesto anteriormente
        
        if(RB0 == 0)      // antirebote
            botonPrevState = 1;
        
        if(RB0 == 1 && botonPrevState == 1){
            writeToEEPROM(potValue, dirEEPROM);
            botonPrevState = 0;
        }
        if (RB1 == 0){      // se duerme el pic
            INTCONbits.RBIF = 0;
            SLEEP();
            while(RB2 == 1){
            
            }
        } 
    }
}

// Configuraciones ***********************************

void setup(void){
//CONFIGURACION DE PUERTOS
    ANSEL = 0b00100000;
    ANSELH = 0x00;
    
    TRISA = 0x00;
    TRISB = 0x07;  // set RB0 & RB1 como input (para botones)
    TRISC = 0x00;
    TRISD = 0x00;
    TRISE = 0x01;  // set RE0 como Input para el Potenciometro
    
    PORTA = 0x00;
    PORTB = 0x00;
    PORTC = 0x00;
    PORTD = 0x00;
    PORTE = 0x00;
    
    //CONFIGURACION DE PULL UP
    OPTION_REGbits.nRBPU = 0;
    WPUBbits.WPUB0 = 1;
    WPUBbits.WPUB1 = 1;
    WPUBbits.WPUB2 = 1;
    
    //CONFIGURACION DE INTERRUPCIONES SIN GIE
    INTCONbits.RBIE = 1;
    INTCONbits.RBIF = 0;
    IOCBbits.IOCB0 = 1;
    
    //CONFIGURACION DEL OSCILADOR A 4MHZ
    OSCCONbits.IRCF2 = 1;
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 0;
    OSCCONbits.SCS = 1;
    
    //CONFIGURACION DEL ADC 
    ADCON1bits.ADFM = 0;  //justificar a a la izquierda
    ADCON1bits.VCFG0 = 0; // voltaje de referencia en VSS y VDD
    ADCON1bits.VCFG1 = 0;
    
    ADCON0bits.ADCS = 1; // ADC clokc FOSC/8
    ADCON0bits.CHS = 5; // Canal 05 seleccionado
    __delay_us(100);
    ADCON0bits.ADON = 1; //Encender el modulo
}


//funciones ************************************

void writeToEEPROM (uint8_t data, uint8_t address){
    EEADR = address;
    EEDAT = data;
    
    EECON1bits.EEPGD = 0; // Escribir a memoria de datos
    EECON1bits.WREN = 1; //Habilitar escritura a EEPROM (datos)
    
    INTCONbits.GIE = 0; // Deshabilitar interrupciones 
    
    EECON2 = 0x55; // Secuencia obligatoria
    EECON2 = 0xAA;
    EECON1bits.WR = 1; // Habilitar escritura
    
    INTCONbits.GIE = 1; //Habilitar interrupciones
    EECON1bits.WREN = 0; //Deshabilitar escritura de EEPROM    
}

uint8_t readFromEEPROM(uint8_t address){
    EEADR = address;
    EECON1bits.EEPGD = 0;
    EECON1bits.RD = 1;
    return EEDAT;
}


















