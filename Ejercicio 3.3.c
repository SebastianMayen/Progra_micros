#include <stdio.h>

int main()
{
	int i, N, A = 0, B = 1, F;
	printf("Ingrese la cantidad de numeros de la serie de Fibonacci:");
	scanf("%d",&N);
	for (i = 0; i <= N; i++) {
		F = A + B;
		A = B;
		B = F;
		printf("%d, ",F);
	}
	return 0;
}
