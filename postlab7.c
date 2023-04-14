/*
 * File:   Lab7.c
 * Author: Sebastian Mayén Dávila
 *
 * Created on 10 de abril de 2023,
 */






#pragma config FOSC = INTRC_NOCLKOUT// Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
#pragma config PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
#pragma config MCLRE = OFF      // RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
#pragma config CP = OFF         // Code Protection bit (Program memory code protection is disabled)
#pragma config CPD = OFF        // Data Code Protection bit (Data memory code protection is disabled)
#pragma config BOREN = OFF      // Brown Out Reset Selection bits (BOR disabled)
#pragma config IESO = OFF       // Internal External Switchover bit (Internal/External Switchover mode is disabled)
#pragma config FCMEN = ON      // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
#pragma config LVP = ON        // Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)
// CONFIG2
#pragma config BOR4V = BOR40V   // Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
#pragma config WRT = OFF        // Flash Program Memory Self Write Enable bits Write protection off)
// #pragma config statements should precedeproject file includes.
// Use project enums instead of #define for ON and OFF.



#include <xc.h>
#include <stdint.h>
#include "PWM_manual.h" // incluimos la libreria 
//variables globales 
#define _XTAL_FREQ 8000000
int duty_on;
int canal_entrada = 0;
int canal_salida = 0;
int periodo_sig = 1;

void setup(void){ // setup configuaracion de entradas y salidas 
    
    TRISC = 0;       // entredad y salida analogica de 
    TRISD = 0;
    TRISA = 0b1;
    ANSEL = 0b1;
    PORTC = 0;
    
    OSCCONbits.IRCF = 0b111;
    OSCCONbits.SCS = 1;
    
    PIR1bits.ADIF = 0;
    
    INTCONbits.PEIE = 1;   // confiugracion de interrupciones 
    INTCONbits.GIE = 1;
    
    
    PR2 = 249;          
    PIR1bits.TMR2IF = 0;
    T2CONbits.T2CKPS = 0b11;
    T2CONbits.TMR2ON = 1;
    while(PIR1bits.TMR2IF == 0);
    PIR1bits.TMR2IF = 0;
    
    ADCON0bits.ADCS = 0b10;
    ADCON0bits.CHS = 0b0000;
    ADCON0bits.ADON = 1;
    __delay_us(50);
    ADCON1bits.ADFM = 0;
    ADCON1bits.VCFG0 = 0;
    ADCON1bits.VCFG1 = 0;
    
    ADIF = 0;
    return;
}
int lectura_ADC(unsigned char canal){ // funcion para el dc 
    ADCON0bits.CHS = canal; // numero de canal
    
    ADCON0bits.GO = 1;       // retornar el valor del adresh
    while (ADCON0bits.GO);
    return ADRESH;
    
}

void main(void){ // loop para mandar a llamar a la libreria 
    setup();
    
    while(1){
        int duty_on = lectura_ADC(canal_entrada); // duty en canal de entrada
        PORTD = duty_on;
        PWM_duty(canal_salida, duty_on, periodo_sig); // funcion para el pwm manual
    }
    return;
}

