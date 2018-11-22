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

%define ascii_zero		0x30
%define nln			0x0A

%define exit_success		0x00
%define exit_fail		0x01

%define deteccion_eof		0x100

%define max_len_linea		100
%define max_lineas		100



section .data
	mensaje_ayuda	db	"Esta es la ayuda.",nln
	longitud_ayuda	EQU	$-mensaje_ayuda

	arch_temp	db	"metricas.tmp",0	; Caracter nulo al final
	arch_temp_len	EQU	$-arch_temp

	fhandler	dd	stdin
	fhandlerout	dd	stdout
	flen		dd	0


section .bss
	cadena	resb	max_len_linea
	fchar	resb	1


section .text
	global _start



salir: 
	mov EAX, sys_exit	; sys_call = sys_exit
	pop EBX			; obtenemos el estado de salida, si hay error o no.
	int 0x80



; Asume que ESI contiene un caracter, devuelve 1 si es una letra, 0 en caso contrario.
es_letra:
	cmp ESI, 65 ; 'A'
	jl _noesletra

	cmp ESI, 90 ; 'Z'
	jle _esletra

	cmp ESI, 97 ; 'a'
	jl _noesletra

	cmp ESI, 122 ; 'z'
	jle _esletra


	_noesletra:
	mov ESI, 0
	jmp _salir

	_esletra:
	mov ESI, 1

	_salir:
	ret



; Lee un caracter del archivo que contiene el texto al cual calcularle las metricas
; 
; Asume que en 'fhandler' esta cargado el manejador.
; Devuelve el valor en ESI.
leer_caracter:
	; Preserva los valores de los registros utilizando la pila
	push EAX
	push EBX
	push ECX
	push EDX

	; Lee un unico caracter del archivo
	mov EAX, sys_read
	mov EBX, [fhandler]
	mov ECX, fchar
	mov EDX, 1
	int 0x80

	; Guarda el valor del caracter en el registro ESI
	cmp EAX, 0
	je .eof

	mov ESI, [fchar] ; ojo con esto, puede llegar a estar mal
	jmp .salir
	
	.eof:
	mov ESI, deteccion_eof

	.salir:
	; Restablece el valor de los registros
	pop EDX
	pop ECX
	pop EBX
	pop EAX

	; Regresa al metodo que invoco a este 
	ret



; Recibe un numero en EAX y lo imprime en 'fhandlerout'
imprimir_numero:
	push EBX; Preservamos el valor del registro EBX
	push ECX
	push EDX


	push 0	; Delimitador para saber cuando dejar de desapilar

	mov DL, 10	; Lo usamos como constante
	mov EBX, 0	; Inicializamos en 0
	.casorecursivo:
		div DL			; Dividimos el numero por 10
		mov BL, AH		; Nos quedamos con el modulo de la division, es decir, el digito menos significativo
		add BL, ascii_zero	; Al digito menos significativo le sumamos el codigo ascii del 0 para convertirlo en un caracter.

		mov DH, AL
		mov EAX, 0
		mov AL, DH		; Hacemos EAX = EAX / 10 
		push EBX		; Guardamos el caracter en la pila

		cmp AL, 0		; Si el resultado de la division es mayor que cero, volver
		jne .casorecursivo
	
	mov EBX, [fhandlerout]
	mov EDX, 1

	.imprimirrecursivo
		pop ECX
		cmp ECX, 0
		je .salir		; Si encontramos el delimitador, salimos del metodo
		
		mov EAX, sys_write	; Reconfiguramos el registro EAX el cual fue modificado en la llamada al sistema.
		mov [fchar], CL
		mov ECX, fchar
		int 0x80

		jmp .imprimirrecursivo

	.salir

	mov EAX, sys_write
	mov CL, 0x20
	mov [fchar], CL
	mov ECX, fchar
	int 0x80

	pop EDX
	pop ECX
	pop EBX	; Restablecemos el valor del registro EBX

	ret



; Se asume que recibe los siguientes datos en los registros indicados:
;
;	EAX = cantidad de letras
;	EBX = cantidad de palabras
;	ECX = cantidad de lineas
;	EDX = cantidad de parrafos
;
; H = modulo
; L = resultado division
mostrar_resultados:
	call imprimir_numero

	mov EAX, EBX
	call imprimir_numero

	mov EAX, ECX
	call imprimir_numero

	mov EAX, EDX
	call imprimir_numero
	
	ret



; Calcular metricas
;
; Se asume que 'fhandler' ya tiene el descriptor del archivo de entrada y que 'fhandlerout' contiene el descriptor del archivo de salida.
; 
calcular_metricas:
	; Preservar el valor de los registros utilizando la pila
	push EAX
	push EBX
	push ECX
	push EDX
	push ESI

	mov EAX, 0	; Contador de letras
	mov EBX, 0	; Contador de palabras
	mov ECX, 0	; Contador de lineas
	mov EDX, 0	; Contador de parrafos


	basura_sin_parrafo:
		call leer_caracter

		; IF input=EoF entonces ir al estado aceptador
		cmp ESI, deteccion_eof
		jne .seguir	; Si no es 0, entonces continuar con los otros casos
		inc ECX		; Si es 0, actualizar los registros correspondientes
		jmp aceptador

		.seguir:
		; IF input=\n entonces ir al estado linea
		cmp ESI, nln
		je linea

		; IF input es letra entonces ir al estado letra
		call es_letra
		cmp ESI, 1
		je letra

		; IF input es delimitador entonces volver a este mismo estado
		jmp basura_sin_parrafo
	

	letra:
		call leer_caracter

		inc EAX

		; IF input=EoF entonces ir al estado aceptador
		cmp ESI, deteccion_eof
		jne .seguir	; Si no es 0, entonces continuar con los otros casos
		inc EBX		; Si es 0, actualizar los registros correspondientes
		inc ECX
		inc EDX
		jmp aceptador

		.seguir:
		; IF input=\n entonces ir al estado "parrafo, palabra y linea"
		cmp ESI, nln
		je parrafo_palabra_linea

		; IF input es letra entonces ir al estado "letra"
		call es_letra
		cmp ESI, 1
		je letra

		; IF input es delimitador entonces ir al estado "palabra"
		jmp palabra


	linea:
		call leer_caracter

		inc ECX

		; IF input=EoF entonces ir al estado aceptador
		cmp ESI, deteccion_eof
		jne .seguir	; Si no es 0, entonces continuar con los otros casos
		inc ECX		; Si es 0, actualizar los registros correspondientes
		jmp aceptador

		.seguir:
		; IF input=\n entonces ir al estado "linea"
		cmp ESI, nln
		je linea

		; IF input es letra entonces ir al estado "letra"
		call es_letra
		cmp ESI, 1
		je letra

		; IF input es delimitador entonces ir al estado "basura sin parrafo"
		jmp basura_sin_parrafo


	palabra:
		call leer_caracter

		inc EBX

		; IF input=EoF entonces ir al estado aceptador
		cmp ESI, deteccion_eof
		jne .seguir	; Si no es 0, entonces continuar con los otros casos
		inc ECX		; Si es 0, actualizar los registros correspondientes
		inc EDX
		jmp aceptador

		.seguir:
		; IF input=\n entonces ir al estado "parrafo y linea"
		cmp ESI, nln
		je parrafo_linea

		; IF input es letra entonces ir al estado "letra"
		call es_letra
		cmp ESI, 1
		je letra

		; IF input es delimitador entonces ir al estado "basura con parrafo"
		jmp basura_con_parrafo


	basura_con_parrafo:
		call leer_caracter

		; IF input=EoF entonces ir al estado aceptador
		cmp ESI, deteccion_eof
		jne .seguir	; Si no es 0, entonces continuar con los otros casos
		inc ECX		; Si es 0, actualizar los registros correspondientes
		inc EDX
		jmp aceptador

		.seguir:
		; IF input=\n entonces ir al estado "parrafo y linea"
		cmp ESI, nln
		je parrafo_linea

		; IF input es letra entonces ir al estado "letra"
		call es_letra
		cmp ESI, 1
		je letra

		; IF input es delimitador entonces volver a este mismo estade
		jmp basura_con_parrafo


	parrafo_palabra_linea:
		call leer_caracter

		inc EBX
		inc ECX
		inc EDX

		; IF input=EoF entonces ir al estado aceptador
		cmp ESI, deteccion_eof
		jne .seguir	; Si no es 0, entonces continuar con los otros casos
		inc ECX		; Si es 0, actualizar los registros correspondientes
		jmp aceptador

		.seguir:
		; IF input=\n entonces ir al estado "linea"
		cmp ESI, nln
		je linea

		; IF input es letra entonces ir al estado "letra"
		call es_letra
		cmp ESI, 1
		je letra

		; IF input es delimitador entonces ir al estado "basura sin parrafo"
		jmp basura_sin_parrafo


	parrafo_linea:
		call leer_caracter

		inc ECX
		inc EDX

		; IF input=EoF entonces ir al estado aceptador
		cmp ESI, deteccion_eof
		jne .seguir	; Si no es 0, entonces continuar con los otros casos
		inc ECX		; Si es 0, actualizar los registros correspondientes
		jmp aceptador

		.seguir:
		; IF input=\n entonces ir al estado "linea"
		cmp ESI, nln
		je linea

		; IF input es letra entonces ir al estado "letra"
		call es_letra
		cmp ESI, 1
		je letra

		; IF input es delimitador entonces ir al estado "basura sin parrafo"
		jmp basura_sin_parrafo



	aceptador:
		call mostrar_resultados
	

	; Restaurar los valores de los registros.
	pop ESI
	pop EDX
	pop ECX
	pop EBX
	pop EAX

	; Regresa al metodo que invoco a este
	ret



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

	; Vuelve al metodo que llamo
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
	mov ECX, 0777; permisos del archivo creado.
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

	; Bucle de lectura de caracteres
	.loop:
		mov EAX, sys_read	; Leer un caracter por consola.
		mov EBX, stdin
		mov ECX, cadena		; Guardar en cadena + offset
		add ECX, ESI		; Sumamos el offset.
		mov EDX, 1		; Leemos de a un caracter
		int 0x80

		inc ESI			; Aumentamos el contador de caracteres leidos.

		cmp ESI, max_len_linea	; Si el contador de caracteres es igual al maximo posible, quiere decir que
					; ya nos desbordamos del buffer.
		je .bufferOverflow

		cmp EAX, 0		; Si el read leyó 0 bytes, entonces signfica que el usuario escribió <ctrl+d>
					; sin ningún byte para procesar. Es decir, el usuario escribió caracteres seguidos de <ctrl+d> (o <enter>)
					; y luego de ello escribió <ctrl+d> por lo que el programa recibió en la última linea 0 bytes para procesar,
					; por lo cual el read retornará 0 en EAX.

		je .fin_loop		; Como se ingresó ctrl+d finalizamos el loop.

		mov CL, BYTE[ECX]	; Obtener el caracter leido en CL

		; IF: Si el usuario ingreso un salto de linea
		cmp CL, nln
		jne .loop		; Saltar al bloque ELSE

		; Bloque THEN, El usuario ingreso un salto de linea, vamos a escribir en un archivo temporal
		inc EDI				; Aumenta el contador de lineas
		call escribir_linea_buffer	;
		cmp EDI, max_lineas		; Verificamos que el archivo no se haya excedido del maximo de lineas
		je .demasiadasLineas		; En caso de exceso, terminacion erronea
		jne .loop
	

	.fin_loop:
		dec ESI				; Al salir del loop decrementamos el registro ESI que contiene la cantidad de caracteres leídos
						; en la última linea, ya que se utilizará como offset.
		call escribir_linea_buffer
	
		mov AL, stdout
		mov [fhandlerout], AL 		; esto puede causar problemas. AL 1 byte [fhandlerout] son 4bytes, solo se reemplaza el primer byte, creo.

						; No veo necesario cerrar y abrir de nuevo el archivo temporal, el descriptor seguirá siendo el mismo.
		call cerrar_archivo
		
		; Abrimos el archivo nuevamente con modo solo lectura.
		mov EAX, sys_open
		mov EBX, arch_temp
		mov ECX, 0		; solo lectura
		mov EDX, 0777
		int 0x80


		; asumimos que eax es mayor a 0

		mov [fhandler], EAX

		call calcular_metricas
	

		call cerrar_archivo
		call borrar_arch_temp

		push exit_success
		jmp salir

	; Se ingresaron mas caracteres de los permitidos (buffer overflow)
	.bufferOverflow:
		jmp .salirFracaso
	
	.demasiadasLineas:
		jmp .salirFracaso
	
	.salirFracaso
		call cerrar_archivo	; Cerrar el archivo temporal
		call borrar_arch_temp	; Borrarlo
		push exit_fail
		jmp salir


; Asume que 
escribir_linea_buffer:
	mov [flen], ESI		; Guardar la longitud de la linea en 'flen'			
	mov ESI, 0		; Resetear el contador de caracteres
	call append_arch_temp	; Escribir la linea en el archivo temporal
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

	;  Regresa a la instrucción posterior de la invocación de 'append_arch_temp'.
	ret



; Cierrar el archivo cuyo descriptor está almacenado en fhandler.
cerrar_archivo:
	; Guardar el contenido de los registros en la pila
	push EAX
	push EBX

	; Cerrar el archivo
	mov EAX, sys_close ; sys_call = sys_close
	mov EBX, [fhandler] 
	int 0x80

	; Restablecer el valor de los registros
	pop EBX
	pop EAX

	; Regresa a la instrucción posterior de la invocación de 'cerrar_arch_temp'.
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



; Recibe en EBX la direccion del archivo de entrada.
archEntrada_consSalida:
	; Abrir el archivo pasado por parametro (para la entrada)
	mov EAX, sys_open
	mov ECX, 0	; Modo solo lectura
	mov EDX, 0777	; Permisos
	int 0x80

	; Guardar la referencia al archivo en fhandler
	mov [fhandler], EAX

	pop EBX; Cargamos el segundo argumento
	; Abrir el archivo pasado por segundo parametro (para la salida)
	mov EAX, sys_open
	mov ECX, 0
	mov EDX, 0777
	int 0x80
	; Cargar la referencia a la consola en fhandlerout
	mov EAX, stdout
	mov [fhandlerout], EAX

	; Calcular las metricas
	call calcular_metricas

	; Finalizar exitosamente
	push exit_success
	jmp salir

	
	
; Recibe en EBX la direccion del archivo de entrada
; Recibe en ECX la direccion del archivo de salida
archEntrada_archSalida:
	push ECX	; Guardamos el parametro ECX

	; Abrir el archivo pasado por parametro
	mov EAX, sys_open
	mov ECX, 0	; Modo solo lectura
	mov EDX, 0777	; Permisos
	int 0x80

	; Guardar la referencia al archivo en fhandler
	mov [fhandler], EAX

	pop EBX		; Recuperamos el parametro ECX

	; Abrir el archivo pasado por parametro
	mov EAX, sys_open
	mov ECX, 0x241	; Modo O_CREAT | O_TRUNC | O_WRONLY => Si no existe se crea y al escribir sobre un archivo ya existente primero borra todo su contenido.
	; Ademas abre el archivo en modo escritura.
	mov EDX, 0777	; Permisos
	int 0x80

	; Guardar la referencia al archivo en fhandler
	mov [fhandlerout], EAX

	; Calcular las metricas
	call calcular_metricas

	; Finalizar exitosamente
	push exit_success
	jmp salir




; Verifica si el parámetro es el parámetro de ayuda
;
; Asume que el registro EAX contiene la cantidad de argumentos recibidos al ejecutarse el programa.
; Asume que el registro EBX contiene un puntero a un argumento string.
verificar_ayuda:
	cmp BYTE[EBX], 45	; Verificamos si el primer caracter del segundo parametro es un '-'
	jmp son_metricas	; sino es un gion definitivamente no era el parámetro '-h'

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

	je mostrar_ayuda ; Si es un espacio el último caracter entonces el parámetro era '-h ', procedemos a mostrar la ayuda.




mostrar_ayuda:
	mov ECX, mensaje_ayuda
	mov EDX, longitud_ayuda
	call imprimir_stdout
	push exit_success
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

		pop ECX
		cmp EAX, 3
		je archEntrada_archSalida ; subrutina para dos parámetros.

		push exit_fail
		jmp salir

