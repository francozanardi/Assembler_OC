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
%define sys_exit		0x01
%define sys_fork		0x02
%define sys_read		0x03
%define sys_write		0x04
%define sys_open		0x05
%define sys_close		0x06
%define sys_waitpid		0x07
%define sys_creat		0x08
%define sys_link		0x09
%define sys_unlink		0x0A

%define stdin			0x00
%define stdout			0x01
%define stderr			0x02

%define nln			0x0A

%define exit_success		0x00
%define exit_fail		0x01

%define max_len_linea		100
%define max_lineas		100	



section .data
	mensaje_ayuda	db	"Esta es la ayuda.",nln
	longitud_ayuda	EQU	$-mensaje_ayuda

	arch_temp	db	"metricas.tmp",0	; Caracter nulo al final
	arch_temp_len	EQU	$-arch_temp

	fhandler	dd	1 ;cambie a 16bits, porque así hizo Fede, y por defecto puse la consola.
	flen		dd	0


section .bss
	cadena	resb	max_len_linea


section .text
	global _start



salir: 
	mov EAX, sys_exit	; sys_call = sys_exit
	pop EBX			; obtenemos el estado de salida, si hay error o no.
	int 0x80



; Calcular metricas
;
; Se asume que en el 
calcularMetricas:
	



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


; Limpia la cadena llenandola de caracteres nulo.
limpiar_cadena:
	; Preservar el contenido de los registros EAX y EBX
	push EAX
	push EBX

	; Iterar desde EAX=(max_len_linea - 1) hasta 0
	mov EAX, max_len_linea
	_seguirLimpiando:
		dec EAX			; EAX --

		mov EBX, cadena		; Calcular la posicion del caracterer, cadena + offset
		add EBX, EAX

		mov [EBX], BYTE 0	; Ponerle el caracter nulo
		cmp EAX, 0		; Si EAX != 0, continuar iterando
		jne _seguirLimpiando

	; Devolver el valor de los registros EAX y EBX
	pop EBX
	pop EAX

	; Volver al metodo que llamo
	ret



; Crea el archivo temporal
;
; Deja guardado su manejador en 'fhandler'
crear_arch_temp:
	; Guardar los contenidos de los registros utilizados en la pila
	push EAX
	push EBX
	push ECX

	; Crear el archivo temporal
	mov EAX, sys_creat
	mov EBX, arch_temp
	mov ECX, 0777; acá van los permisos en realidad. arch_temp_len
	int 0x80

	; falta controlar que eax sea mayor a 0.

	
	; Guarda la direccion del archivo en 'fhandler'
	mov [fhandler], EAX

	; Reestablecer el valor de los registros
	pop ECX
	pop EBX
	pop EAX

	; Volver al que llamo
	ret


; Modo consola entrada, consola salida.
; El usuario debe escribir texto por consola (finalizando su input con Ctrl D), luego se calculan las métricas
; y por último se imprimen los resultados (también por consola).
;
consEntrada_consSalida:
	mov ESI, 0 ; Contador de caracteres leidos (offset) en una linea.
	mov EDI, 0 ; Contador lineas]

	call crear_arch_temp
	call limpiar_cadena

	; Bucle de lectura de caracteres
	_loop:
		mov EAX, sys_read	; Leer un caracter por consola.
		mov EBX, stdin
		mov ECX, cadena		; Guardar en cadena + offset
		add ECX, ESI		; Sumamos el offset.
		mov EDX, 1		; Leemos de a un caracter
		int 0x80

		inc ESI			; Aumentamos el contador de caracteres leidos.

		cmp ESI, max_len_linea	; Si el contador de caracteres es igual al maximo posible, quiere decir que
					; ya nos desbordamos del buffer.
		je _bufferOverflow

		mov AL, BYTE[ECX]	; Obtener el caracter leido en AL

		; IF: Si el usuario ingreso un salto de linea
		cmp AL, nln
		jne _continuar		; Saltar al bloque ELSE

		; Bloque THEN, El usuario ingreso un salto de linea, vamos a escribir en un archivo temporal
		inc EDI				; Aumenta el contador de lineas
		call escribir_linea_buffer	;
		cmp EDI, max_lineas		; Verificamos que el archivo no se haya excedido del maximo de lineas
		je _demasiadasLineas		; En caso de exceso, terminacion erronea
		jmp _loop

		; Bloque ELSE, El usuario NO ingreso un salto de linea
		_continuar:
		cmp AL, 0		; Caracter nulo = EOF = Ctrl D
		jne _loop		; Mientras que no se lea el caracter nulo, continuar leyendo
	

	dec ESI
	call escribir_linea_buffer

	; Al finalizar de leer (exitosamente)
	;mov EAX, sys_write
	;mov EBX, stdout
	;mov ECX, cadena
	;mov EDX, max_len_linea
	;int 0x80
	call cerrar_arch_temp
	;call borrar_arch_temp

	push exit_success
	jmp salir

	; Se ingresaron mas caracteres de los permitidos (buffer overflow)
	_bufferOverflow:
		jmp _salirFracaso
	
	_demasiadasLineas:
		jmp _salirFracaso
	
	_salirFracaso
		call cerrar_arch_temp	; Cerrar el archivo temporal
		;call borrar_arch_temp	; Borrarlo
		push exit_fail
		jmp salir


; Asume que 
escribir_linea_buffer:
	mov [flen], ESI		; Guardar la longitud de la linea en 'flen' 			
	mov ESI, 0		; Resetear el contador de caracteres
	call append_arch_temp	; Escribir la linea en el archivo temporal
	call limpiar_cadena	; Limpiamos el buffer - al remover esta linea, deja de funcionar correctamente el Ctrl-D (no se por que)
	ret




; Escribe el contenido de 'cadena' al final del archivo
;
; Se asume que el manejador del archivo esta en 'fhandler'
append_arch_temp:
	; Preservar el valor de los registros
	push EAX
	push EBX
	push ECX
	push EDX

	; Escribir en el archivo el buffer
	mov EAX, sys_write
	mov EBX, [fhandler]
	mov ECX, cadena
	mov EDX, [flen]	
	int 0x80

	; Restaurar el valor de los registros
	pop EDX
	pop ECX
	pop EBX
	pop EAX

	; Volver al metodo que llamo
	ret



; Cierrar el manejador del archivo temporal
;
; Se asume que esta abierto y guardada su referencia en 'fhandler'
cerrar_arch_temp:
	; Guardar el contenido de los registros en la pila
	push EAX
	push EBX

	; Cerrar el archivo
	mov EAX, sys_close
	mov EBX, [fhandler]
	int 0x80

	; Restablecer el valor de los registros
	pop EBX
	pop EAX

	; Volver al que llamo
	ret



; Borrar el archivo temporal
;
; Asume que su manejador esta guardado en 'fhandler' para cerrarlo
borrar_arch_temp:
	; Guardar los contenidos de los registros utilizados en la pila
	push EAX
	push EBX

	; Borrar el archivo temporal
	mov EAX, sys_unlink
	mov EBX, arch_temp
	int 0x80

	; Devolver el valor de los registros.
	pop EBX
	pop EAX

	; Volver al que llamo
	ret



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

