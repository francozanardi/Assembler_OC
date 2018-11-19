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
	push EAX
	push EBX 
	; salvamos los datos de los registros a utilizar
	
	mov EAX, 4 ; sys_call = sys_write
	mov EBX, 1 ; se coloca como descriptor del archivo al stdout
	int 0x80
	
	; restablecemos los valores de los registos utilizados
	pop EBX
	pop EAX
	ret

verificar_ayuda: ; verifica si el parámetro es el parámetro de ayuda
	cmp BYTE[EBX], 45 ; Verificamos si el primer caracter del segundo parametro es un '-'
	jne son_metricas ; sino es un gion definitivamente no era el parámetro '-h'
	
	push 1 ; ponemos en la pila el posible error
	; Este error se da cuando la cadena comienza con '-' pero no es '-h '
	
	inc EBX ; apuntamos al siguiente caracter
	cmp BYTE[EBX], 104 ; comprobamos si el siguiente caracter es la 'h'
	jne salir ; si el siguiente no era la h entonces el argumento no era '-h'.
	; Notar que la pila ya tiene el número de error de salida.
	; Finalizamos el programa con error porque asumimos que un archivo válido no puedo comenzar con '-'
	
	pop ESI ; si no hubo error entonces descartamos el valor ingresado en la pila
	
	; por ahora ponemos '-h' como válido, sin espacio al final, porque eso nos da problemas.
	;inc EBX ; apuntamos al siguiente caracter
	;cmp BYTE[EBX], 32 ; comprobamos si el último caracter es un espacio
	je mostrar_ayuda ; Si es un espacio el último caracter entonces el parámetro era '-h ', procedemos a mostrar la ayuda.
	
	;push 1 ; ponemos en la pila el error
	;jmp salir ; finalizamos con error ya que el parámetro no finaliza con ' '.

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

