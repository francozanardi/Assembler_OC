section .data
	mensaje_ayuda db "Esta es la ayuda.",0xA
	longitud_ayuda EQU $-mensaje_ayuda

section .text
	global _start


salir: 
	mov EAX, 1 ; sys_call = sys_exit
	pop EBX ; obtenemos el estado de salida, si hay error o no.
	int 0x80

imprimir_stdout: ; asume que ECX y EDX tienen los valores válidos.
	mov EAX, 4 ; sys_call = sys_write
	mov EBX, 1 ; se coloca como descriptor del archivo al stdout
	int 0x80
	ret

verificar_ayuda: ; verifica si el parámetro es el parámetro de ayuda
	cmp BYTE[EBX], 45 ; Verificamos si el primer caracter del segundo parametro es un '-'
	jne son_metricas ; sino es un gion definitivamente no era el parámetro '-h'
	
	inc EBX
	cmp BYTE[EBX], 104 ; comprobamos si el siguiente caracter es la h
	jne son_metricas ; si el siguiente no era la h entonces el argumento no era '-h'

	inc EBX
	cmp BYTE[EBX], 32 ; comprobamos si el último caracter es un espacio
	je mostrar_ayuda ; Si es un espacio el último caracter entonces el parámetro era '-h ', procedemos a mostrar la ayuda.

mostrar_ayuda:
	mov ECX, mensaje_ayuda
	mov EDX, longitud_ayuda
	call imprimir_stdout
	push 0
	jmp salir

consEntrada_consSalida:
	push 0
	jmp salir

archEntrada_consSalida:
	push 0
	jmp salir

archEntrada_archSalida:
	push 0
	jmp salir

_start:
	pop EAX ; cantidad de argumentos
	pop EBX ; sacamos el nombre del programa

	cmp EAX, 1
	je consEntrada_consSalida ; si no hay parámetros, nos dirigimos a una subrutina especifica.

	; evaluamos si estamos en el caso de -h
	; tenemos más de un parámetro.
	pop EBX ; capturamos la dirección en memoria del segundo argumento.
	jmp verificar_ayuda

	son_metricas:
		cmp EAX, 2
		je archEntrada_consSalida ; subrutina para actuar con un parámetro.

		cmp EAX, 3
		je archEntrada_archSalida ; subrutina para dos parámetros.

		push 1
		jmp salir

