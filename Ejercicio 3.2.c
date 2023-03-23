#include <stdio.h>

int main()
{
	int i, N;
	printf("Ingrese la cantidad de numeros:");
	scanf("%d",&N);
	for (i = 1; i <= N; i++) {
		printf("%d, ",i);
	}
	return 0;
}
