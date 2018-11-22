#include <stdio.h>
#include <fcntl.h>

int main() {
	printf("O_CREAT: %x\nO_WRONLY: %x\nO_TRUNC: %x\n", O_CREAT, O_WRONLY, O_TRUNC);
	printf("O_CREAT | O_WRONLY | O_TRUNC: %x\n", O_CREAT | O_WRONLY | O_TRUNC);
	return 0;
	}

