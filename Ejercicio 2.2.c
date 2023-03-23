#include <stdio.h>

int main()
{
	float f, c;
	printf("Ingrese la temperatura en grados Fahrenheit: ");
	scanf("%f", &f);
	c = (f-32)*5/9;
	printf("El valor de %.2f en celcius es: %.2f\n", f, c);
	
	return 0;
}
