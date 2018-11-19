; Maximiliano Nicolas Vega
; 18-11-2018
;
; Recibe una cadena de texto por parametro e imprime la misma invertida.
;
; ./InvertirTexto "cadena"



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
%define ascii_zero			0x30
%define exit_success		0x00
%define exit_fail			0x01
%define nln					0x0A	; '\n'

%define buf_size			64
%define char_relleno		0x5F



section .bss
	buffer resb buf_size


	
section .data	
	error_msg	db	"ERROR: Ingresaste x parametros, debes ingresar uno",nln
	error_len	equ	$ - error_msg 
	
	buff_of_msg db	"ERROR: Ha ingresado demasiados caracteres en el buffer.",nln
	buff_of_len	equ $ - buff_of_msg

	
	
section .text
	global _start


	
; Asume que en el tope de la pila está el codigo de terminación del programa
_exit:
	pop EBX						; Obtengo el código de terminación en EBX
	mov EAX, sys_exit			; Indicamos a sys_call que vamos a salir
	int 0x80



; Llena el buffer con el caracter especificado en la constante
; Preserva los valores de los registro EAX y EBX que utiliza.
_prepararbuffer:
	push EAX	; Guardar el valor de los registros
	push EBX

	; Recorrer desde EAX=(buf_size - 1) hasta 0
	mov EAX, buf_size
	iterar:
		dec EAX				; Decrementar contador
		
		mov EBX, buffer		; Calcular la posición del caracter en el buffer
		add EBX, EAX
		mov [EBX], BYTE char_relleno	; Escribir el nuevo caracter
		
		cmp EAX, 0
		jnz iterar			; Iterar mientras que el contador sea mayor a 0.
	
	pop EBX	; Reestablecer los valores de los registros
	pop EAX

	ret		; Continuar la ejecución del método que invocó



; Procesamos el único parámetro (cadena a invertir)
_procesar:
	pop EAX					; Tiramos el parámetro con el nombre del programa
	pop EAX					; Guardamos el unico argumento que nos interesa

	mov ECX, 0				; Contador de caracteres
	
	call _prepararbuffer	; Inicializa todo el buffer con un caracter especificado.

	; Bucle de lectura de caracteres
	_loop:
		cmp BYTE[EAX], 0	; Si el buffer = '\0' significa que terminó el string.
		je _proceder

		mov EBX, buffer		; Calcular la posicion del caracter en el buffer invertido (62 - pos, ya que 63 es el salto de linea)
		add EBX, buf_size - 2
		sub EBX, ECX

		mov DL, BYTE[EAX]	; Leer un caracter es un byte, pero el registro guarda 4 bytes, por lo que nos quedamos con el byte menos significativo.
							; Notemos que todo lo que se descarta no forma parte del caracter que nos interesa.
							; Lo guardamos en el primer byte del registro D, por lo que se explica en la siguiente instrucción.
		mov [EBX], DL		; Guardamos el caracter en su posición correspondiente del buffer.
							; Fue necesario usar DL, ya que no se puede acceder a la memoria dos veces en una misma instrucción (mov [EBX], BYTE[EAX] no está permitido)

		inc ECX				; Aumentar el contador de caracteres
		inc EAX				; Desplazar el buffer de lectura
		
		cmp ECX, buf_size	; Revisamos que no haya buffer overflow, si lo hay; terminación con error.
		je _bufferoverflow
		
		jmp _loop			; Iterar de nuevo

	; Éxito al terminar de leer los caracteres, imprimir el mensaje invertido.
	_proceder:
		mov [buffer + buf_size - 1], BYTE nln	; Insertar un salto de linea en el último caracter del buffer.

		mov eax, sys_write			; Escribimos por consola el buffer invertido.
		mov ebx, stdout				; Por algún motivo, al este tener menos de 64 caracteres, no imprime basura al comienzo.
		mov ecx, buffer
		mov edx, buf_size
		int 0x80

		push exit_success			; Condicion exitosa y salir
		jmp _exit
	
	; Hubo buffer overflow al leer el mensaje, terminación con error.
	_bufferoverflow:
		push exit_fail
		jmp _exit



; Bloque 'main'
_start:
	pop EAX					; EAX = Cantidad de argumentos

	cmp EAX, 2				; Si hay dos parámetros, procesar el texto, sino salir con error
	jz _procesar

	add EAX, ascii_zero
	dec EAX
	mov [error_msg + 18], AL; Nos quedamos con los primer byte de EAX, y lo escribimos en la posicion de la X en el mensaje de error

	mov eax, sys_write		; Imprimimos el mensaje de error (de paso practicamos con el buffer, ya que imprime la cant. de parámetros recibidos).
	mov ebx, stdout
	mov ecx, error_msg
	mov edx, error_len
	int 0x80

	push exit_fail			; Condicion exitosa y salir
	jmp _exit