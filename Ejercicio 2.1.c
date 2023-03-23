#include <stdio.h>

int main()
{
	int a, b, suma;
	printf("Ingrese dos numeros enteros separados por un espacio: ");
	scanf("%d %d", &a, &b);
	suma = a + b;
	printf("La suma de %d y %d es %d\n", a, b, suma);
	
	return 0;
}
