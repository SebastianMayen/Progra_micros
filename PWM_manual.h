
#ifndef PWM_MANUAL_H
#define PWM_MANUAL_H
#include <xc.h>
#include <stdint.h>
#define _XTAL_FREQ 8000000
int PWM_config(char canal, int periodo_ms){ // estableser el valor del periodo
    int periodo = periodo_ms;
    return periodo; // retornarl el periodo con el valor de la variable 
}
int PWM_duty(int canal, int duty_on, int periodo_sig){ // funcion para el duty de la señal
    if(canal>=7){       // estableser que el registro solo tiene 8 bits 
        canal = 7;
    }else if (canal<0){
        canal = 0;
    }
    int num = PWM_config(canal, periodo_sig);
    int cycle;
    for (cycle = 0; cycle<= 255 ; cycle++){ // ciclo para moverel valor del canal
        if(duty_on>=cycle){
            PORTC = (0b1<<canal);
        }else{
            PORTC = 0;
            
        }
        int i = 0;
        for (i;i<num;i++){
            __delay_us(1);
        }
    }
    return 0;
}
#endif




































