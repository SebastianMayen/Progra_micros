#include <stdio.h>

int main() {
	int numeros[10];
	int *puntero = numeros;

	for (int i = 0; i < 10; i++) {
		printf("Ingresa un numero %d: ", i);
		scanf("%d", &numeros[i]);
	}
	
	printf("Los elementos del array multiplicados por 2 son:\n");
	for (int i = 0; i < 10; i++) {
		printf("%d\n", *puntero * 2);
		puntero++;
	}
	printf("\n");
	
	return 0;
}

