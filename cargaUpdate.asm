; ---------------------------------------------------------------------------------------------------------------------------------------------------
;
; Proyecto de Assembler
;   Organización de Computadoras, Departamento de Ciencias e Ingeniería de la Computación, Universidad Nacional del Sur
;   Segundo Cuatrimestre 2018
;
; Autores:
;	- VEGA, Maximiliano Nicolas
;	- ZANARDI, Franco Ivan
;
; ---------------------------------------------------------------------------------------------------------------------------------------------------


%define sys_restart_syscall	0x00
%define sys_exit			0x01
%define sys_fork			0x02
%define sys_read			0x03
%define sys_write			0x04
%define sys_open			0x05
%define sys_close			0x06
%define sys_waitpid			0x07
%define sys_creat			0x08
%define sys_link			0x09

%define stdout				0x01

%define exit_success		0x00
%define exit_fail			0x01



section .data
	mensaje_ayuda db "Esta es la ayuda.",0xA
	longitud_ayuda EQU $-mensaje_ayuda

	
	
section .text
	global _start

	

salir: 
	mov EAX, sys_exit	; sys_call = sys_exit
	pop EBX				; obtenemos el estado de salida, si hay error o no.
	int 0x80

	
	
imprimir_stdout: ; asume que ECX y EDX tienen los valores válidos.
	push EAX
	push EBX 
	; salvamos los datos de los registros a utilizar
	
	mov EAX, sys_write	; sys_call = sys_write
	mov EBX, stdout		; se coloca como descriptor del archivo al stdout
	int 0x80
	
	; restablecemos los valores de los registos utilizados
	pop EBX
	pop EAX
	ret



; Verifica si el parámetro es el parámetro de ayuda
;
; Asume que el registro EAX contiene la cantidad de argumentos recibidos al ejecutarse el programa.
; Asume que el registro EBX contiene un puntero a un argumento string.
verificar_ayuda:
	cmp BYTE[EBX], 45	; Verificamos si el primer caracter del segundo parametro es un '-'
	jne son_metricas	; sino es un gion definitivamente no era el parámetro '-h'
	
	push exit_fail		; ponemos en la pila el posible error
						; Este error se da cuando el segundo argumento no es estrictamente igual a "-h" (se admiten espacios luego y antes),
						; también se produce si hay argumentos de sobra.
	
	inc EBX				; apuntamos al siguiente caracter
	cmp BYTE[EBX], 104	; comprobamos si el siguiente caracter es la 'h'
	jne salir			; si el siguiente no era la h entonces el argumento no era '-h'.
						; Notar que la pila ya tiene el número de error de salida.
						; Finalizamos el programa con error porque asumimos que un archivo válido no puedo comenzar con '-'
	
	; Una vez leido "-h" queda verificar que luego de la 'h' esté el caracter nulo '\0'
	inc EBX				; Apuntamos al siguiente caracter
	cmp BYTE[EBX], 0	; Verificamos si es el caracter nulo
	jne salir			; En caso de que no fuese el caracter nulo, el parámetro es inválido (pues no es '-h')
	
	; Por último, en caso de ser válido el formato, la cantidad de parámetros debe ser 2 (el propio programa y '-h')
	cmp EAX, 2			; Si hay más de 2 argumentos, es una ejecución inválida.
	jne salir
	
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
	push exit_success
	jmp salir

	
	
consEntrada_consSalida:
	push exit_fail
	jmp salir

	
	
archEntrada_consSalida:
	push exit_fail
	jmp salir

	
	
archEntrada_archSalida:
	push exit_fail
	jmp salir

	
	
_start:
	pop EAX ; cantidad de argumentos
	pop EBX ; sacamos el nombre del programa

	cmp EAX, 1
	je consEntrada_consSalida ; si no hay parámetros, nos dirigimos a una subrutina especifica.

	; evaluamos si estamos en el caso de -h
	; tenemos más de un parámetro.
	pop EBX		; capturamos la dirección en memoria del segundo argumento.
	jmp verificar_ayuda

	son_metricas:
		cmp EAX, 2
		je archEntrada_consSalida ; subrutina para actuar con un parámetro.

		cmp EAX, 3
		je archEntrada_archSalida ; subrutina para dos parámetros.

		push exit_fail
		jmp salir

