#include <stdio.h>
#include "operaciones.h"

int main() {
	int num1, num2, resultado_suma, resultado_resta, resultado_multiplicacion;
	float resultado_division;
	
	printf("Ingresa el primer numero: ");
	scanf("%d", &num1);
	
	printf("Ingresa el segundo numero: ");
	scanf("%d", &num2);
	
	resultado_suma = suma(num1, num2);
	resultado_resta = resta(num1, num2);
	resultado_multiplicacion = multiplicacion(num1, num2);
	resultado_division = division(num1, num2);
	
	printf("La suma de %d y %d es %d\n", num1, num2, resultado_suma);
	printf("La resta de %d y %d es %d\n", num1, num2, resultado_resta);
	printf("La multiplicación de %d y %d es %d\n", num1, num2, resultado_multiplicacion);
	printf("La division de %d y %d es %f\n", num1, num2, resultado_division);
	
	imprimir_pi();
	
	return 0;
}
