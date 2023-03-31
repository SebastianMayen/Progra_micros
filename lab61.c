// CONFIG1
#pragma config FOSC = INTRC_NOCLKOUT// Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
#pragma config PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
#pragma config MCLRE = OFF      // RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
#pragma config CP = OFF         // Code Protection bit (Program memory code protection is disabled)
#pragma config CPD = OFF        // Data Code Protection bit (Data memory code protection is disabled)
#pragma config BOREN = OFF      // Brown Out Reset Selection bits (BOR disabled)
#pragma config IESO = OFF       // Internal External Switchover bit (Internal/External Switchover mode is disabled)
#pragma config FCMEN = OFF      // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
#pragma config LVP = OFF        // Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

// CONFIG2
#pragma config BOR4V = BOR40V   // Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
#pragma config WRT = OFF        // Flash Program Memory Self Write Enable bits (Write protection off)

#include <xc.h>
#include <stdint.h>

#define DISP_PORT   PORTC       // Puerto del display
#define DISP_DDR    TRISC       // DDR del display
#define DP_PIN      7           // Pin del punto decimal
#define _XTAL_FREQ 8000000

int display_mostrar;
int voltaje; /////variable para el cambio del voltaje

uint8_t centenas;
uint8_t decenas;
uint8_t unidades;
uint8_t residuo;

uint8_t bandera = 0;
uint8_t display[3];


///VALORES PARA LOS DISPLAYS
uint8_t TABLA[16] = {0b00111111, //0
                     0b00000110, //1
                     0b01011011, //2
                     0b01001111, //3
                     0b01100110, //4
                     0b01101101, //5
                     0b01111101, //6
                     0b00000111, //7
                     0b01111111, //8
                     0b01100111,///9
                     01110111,//A
                     01111100,//B
                     00111001,//C
                     01011110,//D
                     01111001,//E
                     01110001//F 

}; 

//PROTOTIPOS
void setup (void);
void displays(int numeros);

//INTERRUPCIONES 
void __interrupt() isr(void) {
    if (PIR1bits.ADIF) {                    //CHEQUEA INTERUPCION DEL ADC

        if (ADCON0bits.CHS == 0b0000){          // CANAL 0 AN0
            PORTD = ADRESH;//MUEVE EL VALOR AL ADRESH
            //ADCON0bits.CHS = 0b0001;// CAMBIA A CANAL 1
        }
        else if (ADCON0bits.CHS == 0b0001){ //(ADCON0bits.CHS == 0b0001)//CHEQUEA SI EL CANAL ES 1
            display_mostrar = ADRESH; // MUEVE EL VALOR DEL ADRESH AL PORTB
            PORTB = ADRESH;
            //ADCON0bits.CHS = 0b0000;//CAMBIAR A CANAL 0
        }
            PIR1bits.ADIF = 0;
    }
    
    if (INTCONbits.T0IF){ //CHEQUEAR INTERRUPCION DEL TMR0
        PORTE = 0;
    
    // Chequear el valor de la variable bandera y actualizar el display correspondiente

        if (bandera == 0){//chequear la nbadera
            PORTC = display[2];// usar el prot c
            PORTE = 1;// habilita el diaplay
            bandera = 1;//cambia el valor de la bandra
            
        }
        else if (bandera == 1){ //chequea si la bandera es 1
            PORTC = display[1];// muestra el digito en potrc
            PORTE = 2;// habilita display de decenas
            bandera = 2;//cambia la bandera
        }
        else if (bandera == 2){ //chequea  si la bandera es 2
            PORTC = display[0];//
            PORTE = 4;//habiliya display de unidades
            bandera = 0;// cambia valor de la bandera
        }
        TMR0 = 216;
        INTCONbits.T0IF = 0; ///reiniciar el tmr0
            
    }
    return;
    
}


////////////////////principal
void main(void) {
    DISP_DDR = 0x00;    // Configurar como salida
    DISP_PORT = 0x7F;   // Encender todos los segmentos
    setup();// llama  a la funcion setup

    while(1) {
        //enciende el punto decimal
        DISP_PORT |= (1 << DP_PIN);

        ADCON0bits.GO = 1;/// incicia la conversacion analogia a dig
        voltaje = (int)(display_mostrar*((float)5/255*(100)));
        displays(voltaje);
     
       // Asigna los valores correspondientes de la tabla a cada dígito del display

        display[0] = TABLA[unidades];
        display[1] = TABLA[decenas];
        display[2] = TABLA[centenas];
        
        ///apagar [unto deciaml]
        DISP_PORT &= ~(1 << DP_PIN);
     // Verifica si la conversión ADC ha finalizado
    
    if (ADCON0bits.GO == 0){
        if (ADCON0bits.CHS == 0b0000)
            ADCON0bits.CHS = 0b0001;
        else
            ADCON0bits.CHS = 0b0000;
           __delay_us(100);
    }
        }
    
    return;
}

//CONFIGURACION 
void setup (void){
    ANSEL = 0b00000011;     //AN0 Y AN1 COMO ENTRADA ANALOGICAS 
    ANSELH = 0;
    
    TRISA = 0b00000011;     //a0 y a1 como entrada
    TRISB  = 0;             ///PORTB COMO SALIDA
    TRISC = 0;              //PORTC COMO SALIDA
    TRISD = 0;              // PORTD COMO SALIDA
    TRISE = 0;
    
    //INICIA PUERTOS
    PORTA = 0;
    PORTB = 0;
    PORTC = 0;
    PORTD = 0;
    PORTE = 0;
     //oscilador
    OSCCONbits.IRCF = 0b111 ; //8Mhz
    OSCCONbits.SCS = 1;
    

    //tmr0
    OPTION_REGbits.T0CS = 0; //Usar Timer0 con Fosc/4
    OPTION_REGbits.PSA = 0; //Prescaler con el Timer0
    OPTION_REGbits.PS2 = 1; //Prescaler de 256
    OPTION_REGbits.PS1 = 1;
    OPTION_REGbits.PS0 = 1;  
    TMR0 = 216; //VALOR INICIAL DEL TMR0
    
    //Banderas e interrupciones
    INTCONbits.T0IF = 0;    //interrupcion del tmr0
    INTCONbits.T0IE = 1;    //interrupcion del tmr0
    INTCONbits.GIE = 1; 
    INTCONbits.PEIE = 1;    // habilitar interrupciones perifericas
    PIE1bits.ADIE = 1;      // habilitar interrupciones de ADC
    PIR1bits.ADIF = 0;      // limpiar la bandera de interrupcion del ADC
    
    ////CONFIGURACION DE ADC
    ADCON0bits.ADCS = 0b10 ; //fosc/32 
    ADCON0bits.CHS = 0b0000; //chs 0000 an0 selecciona canal
    //ADCON0bits.CHS = 0001//chs 0001 an0 selecciona canal
    __delay_ms(1); 
    
    ///////CONFIGURACIN DEL ADC
    ADCON1bits.ADFM = 0; ///justificado a la izquuierda
    ADCON1bits.VCFG0 = 0; //vdd como referenias
    ADCON1bits.VCFG1 = 0; //vss como referencias
    ADCON0bits.ADON = 1; //inicial el adc
    __delay_us(100);
    ADIF = 0 ; //LIMPIAR LA BANDERA
}
void displays (int numeros){            // Calcula las centenas dividiendo numeros por 100 y redondeando al entero más cercano
    centenas = (uint8_t)(numeros/100);// Calcula el residuo después de extraer las centenas
    residuo = numeros%100;          // Calcula las decenas dividiendo el residuo por 10 y redondeando al entero más cercano
    decenas = residuo/10;           // Calcula el nuevo residuo después de extraer las decenas
    residuo = residuo%10;           // Asigna el valor restante (residuo) a las unidades
    unidades = residuo;
    
    return;
    
    
}