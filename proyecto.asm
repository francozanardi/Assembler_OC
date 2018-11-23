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





%define sys_restart_syscall		0x00
%define sys_exit			0x01
%define sys_fork			0x02
%define sys_read			0x03
%define sys_write			0x04
%define sys_open			0x05
%define sys_close			0x06
%define sys_waitpid			0x07
%define sys_creat			0x08
%define sys_link			0x09
%define sys_unlink			0x0A

%define stdin				0x00
%define stdout				0x01
%define stderr				0x02

%define todos_los_permisos		0777

%define O_TRUNC				0x200
%define O_CREAT				0x040
%define O_WRONLY			0x001
%define O_RDONLY			0x000

%define ascii_zero			0x30
%define nln				0x0A
%define tab				0x09

%define exit_success			0x00
%define exit_fail_inputfile		0x01
%define exit_fail_outputfile		0x02
%define exit_fail			0x03

%define deteccion_eof			0x100

%define max_len_linea			1000
%define max_lineas			1000

; Convenciones posibles:
;  a) Una linea VACIA que contenga un salto de linea (es decir: \n\n) cuenta como linea.
;  b) Para que una linea cuente como tal, debe tener AL MENOS un caracter (de cualquier tipo) seguido de un salto de linea.
;
; de acuerdo a la convencion tomada, reemplazar la siguiente macro con el valor indicado:
;  a) .linea
;  b) .basura_sin_parrafo
;
%define interpretacion_lineas	.linea





section .data
	mensaje_ayuda		db	"Calculador de Metricas.", nln
				db	" - Proyecto para Organizacion de Computadoras, Segundo Cuatrimestre 2018", nln
				db	" - Autores:", nln
				db	tab, "VEGA, Maximiliano Nicolas", nln
				db	tab, "ZANARDI, Franco Ivan", nln, nln
				db	"Este programa calcula la cantidad de letras, palabras, lineas y parrafos de un texto.", nln, nln
				db	"Uso: ./metricas [argumentos]", nln, nln,
				db	"Argumentos:",  nln
				db	"[-h]", tab, tab, tab, tab, tab,	"Muestra el menu de ayuda.",nln
				db	"[archivo_entrada]", tab, tab, tab,	"Lee el archivo de texto especificado y calcula las metricas sobre el, imprime el resultado por pantalla.",nln
				db	"[archivo_entrada archivo_salida]", tab,"Lee el archivo de entrada especificado, calcula las metricas sobre el, y guarda el resultado en el archivo de salida.",nln
	longitud_ayuda		EQU	$-mensaje_ayuda

	msg_res			db	nln, "Resultado del calculo de metricas:", nln
	msg_res_len		EQU	$-msg_res

	msg_letras		db	"Cantidad de letras: "
	msg_letras_len		EQU	$-msg_letras

	msg_palabras		db	nln, "Cantidad de palabras: "
	msg_palabras_len	EQU	$-msg_palabras

	msg_lineas		db	nln, "Cantidad de lineas: "
	msg_lineas_len		EQU	$-msg_lineas

	msg_parrafos		db	nln, "Cantidad de parrafos: "
	msg_parrafos_len	EQU	$-msg_parrafos

	msg_final		db	nln, nln
	msg_final_len		EQU	$-msg_final

	arch_temp		db	"metricas.tmp",0	; Caracter nulo al final
	arch_temp_len		EQU	$-arch_temp

	fdescriptor		dd	stdin
	fdescriptor_out		dd	stdout
	flen			dd	0


section .bss
	cadena	resb	max_len_linea
	fchar	resb	1


section .text
	global _start





salir: 
	mov EAX, sys_exit	; sys_call = sys_exit
	pop EBX			; obtenemos el estado de salida, si hay error o no.
	int 0x80





;
; Input:
;	ESI - Un caracter
;
; Output:
;	EDI - 1 si el caracter es una letra, 0 en caso contrario
;
es_letra:
	cmp ESI, 65 ; 'A'
	jl .no_es_letra

	cmp ESI, 90 ; 'Z'
	jle .es_letra

	cmp ESI, 97 ; 'a'
	jl .no_es_letra

	cmp ESI, 122 ; 'z'
	jle .es_letra


	.no_es_letra:
		mov EDI, 0
		jmp .salir

	.es_letra:
		mov EDI, 1

	.salir:
		ret





;
; Input:
;	ESI - Un caracter
;
; Output
;	EDI - 1 si el caracter es delimitador, 0 en caso contrario
;
es_delimitador:
	cmp ESI, 32 ; ' '
	je .es_delimitador

	cmp ESI, 9 ; '\t'
	je .es_delimitador

	cmp ESI, 46 ; '.'
	je .es_delimitador
	
	cmp ESI, 44 ; ','
	je .es_delimitador

	cmp ESI, 58 ; ':'
	je .es_delimitador

	cmp ESI, 59 ; ';'
	je .es_delimitador

	cmp ESI, 63 ; '?'
	je .es_delimitador

	cmp ESI, 33 ; '!'
	je .es_delimitador

	cmp ESI, 41 ; ')'
	je .es_delimitador

	cmp ESI, 34 ; '"'
	je .es_delimitador

	cmp ESI, 39 ; '''
	je .es_delimitador



	; No es delimitador
	mov EDI, 0
	jmp .salir

	.es_delimitador:
	mov EDI, 1

	.salir:
		ret





; Lee un caracter del archivo que contiene el texto al cual calcularle las metricas
; 
; Asume que en 'fdescriptor' esta cargado el descriptor.
; Devuelve el valor en ESI.
leer_caracter:
	; Preserva los valores de los registros utilizando la pila
	push EAX
	push EBX
	push ECX
	push EDX

	; Lee un unico caracter del archivo
	mov EAX, sys_read 	; sys_call = sys_exit
	mov EBX, [fdescriptor]	; EBX contiene el descriptor del archivo.
	mov ECX, fchar 		; ECX contiene la dirección en memoria en donde se guardará los bytes leídos del archivo.
	mov EDX, 1		; EDX coniene la cantidad de bytes a leer.
	int 0x80
	
	; Si EAX es mayor o igual a 0, esto representa la cantidad de bytes leídos en el archivo.
	; Si EAX es menor a 0, este valor representa un error particular, sea cual sea el error nuestro programa
	; realiza una llamada al sistema con sys_exit notificando el error 'exit_fail_inputfile'.


	; Comprobamos si hay error en la lectura del archivo o si este no lleyó ningún byte (llegó al final del archivo).
	cmp EAX, 0
	je .eof
	jl .error_lectura

	; Guarda el valor del caracter en el registro ESI
	mov ESI, [fchar] ; ojo con esto, puede llegar a estar mal
	jmp .salir
	
	.eof:
		mov ESI, deteccion_eof
		jmp .salir


	.error_lectura:
		push exit_fail_inputfile 	; pasamos por parámetro el número de error.
		jmp salir

	.salir:
		; Restablece el valor de los registros
		pop EDX
		pop ECX
		pop EBX
		pop EAX

		; Regresa al metodo que invoco a este 
		ret





; Division manual, para evitar el problema de que al utilizar div solo se puede trabajar con numeros pequenos
;
; Input:
;	EAX - Dividendo
;	EBX - Divisor
;
; Output:
;	EAX - Cociente
;	EBX - Resto
;
division_por_resta:
	push ECX	; Preservamos el valor del registro ECX

	mov ECX, 0
	
	.loop:
		cmp EAX, EBX	; Si el dividendo es menor que el divisor, terminamos
		jl .fin

		sub EAX, EBX	; Si el dividendo es mayor o igual que el divisor, restarle el divisor
		inc ECX		; Llevar la cuenta de cuentas veces entra el divisor en el dividendo.

		jmp .loop
	
	.fin
		mov EBX, EAX	; EBX = Resto
		mov EAX, ECX	; EAX = Cociente

	pop ECX		; Restauramos el valor del registro ECX

	ret





; Recibe un numero en EAX y lo imprime en 'fdescriptor_out'
imprimir_numero:
	; Preservamos el valor de los registros, utilizando la pila
	push EBX
	push ECX
	push EDX

	; Ingresamos un delimitador en la pila, para saber cuando dejar de desapilar.
	push 0
	
	.caso_recursivo:
		mov EBX, 10
		call division_por_resta	; produce: EAX = EAX / EBX,   EBX = EAX % EBX

		add EBX, ascii_zero	; Agregamos el ultimo caracter caracter a la pila, transformado a ASCII
		push EBX

		cmp EAX, 0		; Si el resultado de la division es mayor que cero, volver
		jne .caso_recursivo
	

	mov EDX, 1			; EDX es la cantidad de bytes a imprimir, queda establecido aqui ya que las siguientes instrucciones lo usaran.

	.imprimir_recursivo:
		pop ECX			; Obtenemos el numero (en formato ascii) del tope de la pila
		cmp ECX, 0		; En caso de que sea el delimitador, salimos del metodo
		je .imprimir_espacio
		
		mov [fchar], CL		; Guardamos en fchar el caracter que obtuvimos de la pila.
		mov ECX, fchar		; Ponemos en ECX la dirección en memoria que almacena el caracter leído en la pila.
		call imprimir		

		jmp .imprimir_recursivo

	.imprimir_espacio:
		mov CL, 0x20		; Colocamos en CL el código ascii del espacio ' '.
		mov [fchar], CL		; Ponemos en fchar el código ascii del espacio ' '.
		mov ECX, fchar		; Ponemos en ECX la dirección de memoria que contiene el caracter a imprimir, en este caso el espacio.
		call imprimir		; Delegamos en la rutina que imprimir en el archivo con el descriptor almacenado en 'fdescriptor_out'.
		jmp .salir

	.salir:
		pop EDX
		pop ECX
		pop EBX	; Restablecemos el valor del registro EBX

		ret





; Imprime los resultados del calculo de las metricas. 
;
; Input:
;	EAX - cantidad de letras
;	EBX - cantidad de palabras
;	ECX - cantidad de lineas
;	EDX - cantidad de parrafos
;
mostrar_resultados:
	; Preservar los valores de los registros
	push ECX
	push EDX
	push ESI
	push EDI

	; Como los registros ECX y EDX contienen informacion que necesitamos, pero a la vez los usamos para imprimir por pantalla,
	; movemos sus valores a registros auxiliares
	mov ESI, ECX
	mov EDI, EDX


	; Imprimir mensaje inicial
	mov ECX, msg_res
	mov EDX, msg_res_len
	call imprimir


	; Imprimir mensaje para letras
	mov ECX, msg_letras
	mov EDX, msg_letras_len
	call imprimir
	; Imprimir cantidad de letras
	call imprimir_numero


	; Imprimir mensaje para palabras
	mov ECX, msg_palabras
	mov EDX, msg_palabras_len
	call imprimir
	; Cargar la cantidad de palabras en EAX e imprimirlo.
	mov EAX, EBX
	call imprimir_numero


	; Imprimir mensaje para lineas
	mov ECX, msg_lineas
	mov EDX, msg_lineas_len
	call imprimir
	; Cargar la cantidad de lineas en EAX e imprimirlo.
	mov EAX, ESI
	call imprimir_numero


	; Imprimir mensaje para parrafos
	mov ECX, msg_parrafos
	mov EDX, msg_parrafos_len
	call imprimir
	; Cargar la cantidad de parrafos en EAX e imprimirlo.
	mov EAX, EDI
	call imprimir_numero


	; Imprimir el mensaje final
	mov ECX, msg_final
	mov EDX, msg_final_len
	call imprimir


	; Restaurar los valores de los registros
	pop EDI
	pop ESI
	pop EDX
	pop ECX

	; Continuar la ejecucion en el metodo que invoco a este.
	ret





;
; calcular_metricas:
;
; Descripcion:
;	Este metodo calcula las metricas del archivo de entrada, lo hace simulando un automata finito
;	determinista, con la excepcion de que al llegar a cada uno de los estados realiza una operacion
;	en concreta (aumenta algun contador).
;
; Input:
;	'fdescriptor'		- Descriptor del archivo de entrada
;	'fdescriptor_out'	- Descriptor del archivo de salida
; 
calcular_metricas:
	; Preservar el valor de los registros utilizando la pila
	push EAX
	push EBX
	push ECX
	push EDX
	push ESI
	push EDI

	; Inicializamos los contadores
	mov EAX, 0	; Contador de letras
	mov EBX, 0	; Contador de palabras
	mov ECX, 0	; Contador de lineas
	mov EDX, 0	; Contador de parrafos


	.basura_sin_parrafo:
		call leer_caracter

		; input = EOF
		; Acepta la cadena.
		cmp ESI, deteccion_eof
		je .aceptador

		; input = \n
		; Ir al estado "linea"
		cmp ESI, nln
		je .linea

		; input es letra
		; Ir al estado "letra sin parrafo"
		call es_letra
		cmp EDI, 1
		je .letra_sin_parrafo

		; input es delimitador
		; Quedarse en este estado.
		call es_delimitador
		cmp EDI, 1
		je .basura_sin_parrafo

		; input es basura
		; Quedarse en este estado.
		jmp .basura_sin_parrafo


	.letra_sin_parrafo:
		call leer_caracter

		inc EAX	; Sumar una letra

		; input = EOF
		; Acepta la cadena.
		cmp ESI, deteccion_eof
		je .aceptador

		; input = \n
		; Ir al estado "linea, parrafo, palabra"
		cmp ESI, nln
		je .linea_parrafo_palabra

		; input es letra
		; Quedarse en este estado.
		call es_letra
		cmp EDI, 1
		je .letra_sin_parrafo

		; input es delimitador
		; Ir al estado "palabra"
		call es_delimitador
		cmp EDI, 1
		je .palabra

		; input es basura
		; Ir al estado "basura sin parrafo"
		jmp .basura_sin_parrafo


	.linea:
		call leer_caracter

		inc ECX ; Sumar una linea

		; input = EOF
		; Acepta la cadena.
		cmp ESI, deteccion_eof
		je .aceptador

		; input = \n
		; Ir al estado "basura sin parrafo" o "linea" (leer convenciones)
		cmp ESI, nln
		je interpretacion_lineas

		; input es letra
		; Ir al estado "letra sin parrafo"
		call es_letra
		cmp EDI, 1
		je .letra_sin_parrafo

		; input es delimitador
		; Ir al estado "basura sin parrafo"
		call es_delimitador
		cmp EDI, 1
		je .basura_sin_parrafo

		; input es basura
		; Ir al estado "basura sin parrafo"
		jmp .basura_sin_parrafo


	.linea_parrafo:
		call leer_caracter

		inc ECX ; Sumar una linea
		inc EDX ; Sumar un parrafo

		; input = EOF
		; Acepta la cadena.
		cmp ESI, deteccion_eof
		je .aceptador

		; input = \n
		; Ir al estado "basura sin parrafo" o "linea" (leer convenciones)
		cmp ESI, nln
		je interpretacion_lineas

		; input es letra
		; Ir al estado "letra sin parrafo"
		call es_letra
		cmp EDI, 1
		je .letra_sin_parrafo

		; input es delimitador
		; Ir al estado "basura sin parrafo"
		call es_delimitador
		cmp EDI, 1
		je .basura_sin_parrafo

		; input es basura
		; Ir al estado "basura sin parrafo"
		jmp .basura_sin_parrafo


	.linea_parrafo_palabra:
		call leer_caracter

		inc EBX	; Sumar una palabra
		inc ECX ; Sumar una linea
		inc EDX ; Sumar un parrafo

		; input = EOF
		; Acepta la cadena.
		cmp ESI, deteccion_eof
		je .aceptador

		; input = \n
		; Ir al estado "basura sin parrafo" o "linea" (leer convenciones)
		cmp ESI, nln
		je interpretacion_lineas

		; input es letra
		; Ir al estado "letra sin parrafo"
		call es_letra
		cmp EDI, 1
		je .letra_sin_parrafo

		; input es delimitador
		; Ir al estado "basura sin parrafo"
		call es_delimitador
		cmp EDI, 1
		je .basura_sin_parrafo

		; input es basura
		; Ir al estado "basura sin parrafo"
		jmp .basura_sin_parrafo


	.palabra:
		call leer_caracter

		inc EBX ; Sumar una palabra

		; input = EOF
		; Acepta la cadena.
		cmp ESI, deteccion_eof
		je .aceptador

		; input = \n
		; Ir al estado "linea, parrafo"
		cmp ESI, nln
		je .linea_parrafo

		; input es letra
		; Ir al estado "letra con parrafo"
		call es_letra
		cmp EDI, 1
		je .letra_con_parrafo

		; input es delimitador
		; Ir al estado "basura con parrafo"
		call es_delimitador
		cmp EDI, 1
		je .basura_con_parrafo

		; input es basura
		; Ir al estado "basura con parrafo"
		jmp .basura_con_parrafo


	.letra_con_parrafo:
		call leer_caracter

		inc EAX ; Sumar una letra

		; input = EOF
		; Acepta la cadena.
		cmp ESI, deteccion_eof
		je .aceptador

		; input = \n
		; Ir al estado "linea, parrafo, palabra"
		cmp ESI, nln
		je .linea_parrafo_palabra

		; input es letra
		; Quedarse en el estado.
		call es_letra
		cmp EDI, 1
		je .letra_con_parrafo

		; input es delimitador
		; Ir al estado "palabra"
		call es_delimitador
		cmp EDI, 1
		je .palabra

		; input es basura
		; Ir al estado "basura con parrafo" 
		jmp .basura_con_parrafo


	.basura_con_parrafo:
		call leer_caracter

		; input = EOF
		; Acepta la cadena.
		cmp ESI, deteccion_eof
		je .aceptador

		; input = \n
		; Ir al estado "linea, parrafo"
		cmp ESI, nln
		je .linea_parrafo

		; input es letra
		; Ir al estado "letra con parrafo"
		call es_letra
		cmp EDI, 1
		je .letra_con_parrafo

		; input es delimitador
		; Quedarse en este estado.
		call es_delimitador
		cmp EDI, 1
		je .basura_con_parrafo

		; input es basura
		; Quedarse en este estado.
		jmp .basura_con_parrafo


	.aceptador:
		call mostrar_resultados
	

	; Restaurar los valores de los registros.
	pop EDI
	pop ESI
	pop EDX
	pop ECX
	pop EBX
	pop EAX

	; Regresa al metodo que invoco a este
	ret





;
; Imprime en el archivo cuyo descriptor está almacenado en 'fdescriptor_out'.
;
; Input:
;	ECX - Puntero a la cadena a escribir.
;	EDX - Cantidad de caracteres a escribir.
;
imprimir:
	; Guardamos los valores de los registros que utilizaremos
	push EAX
	push EBX 

	mov EAX, sys_write		; sys_call = sys_write
	mov EBX, [fdescriptor_out]	; se coloca el descriptor del archivo.
	int 0x80

				; Evaluamos si la llamada al sistema retornó un error en EAX.
	cmp EAX, 0 		; Si EAX es menor a 0 entonces se produjo un error.
	jge .salir
		

	.error:
		push exit_fail_outputfile
		jmp salir


	.salir:
		; Restablecemos los valores de los registos utilizados
		pop EBX
		pop EAX

		; Vuelve al metodo que llamo
		ret




;
; Crea el archivo temporal
;
; Deja guardado su descriptor en 'fdescriptor'
;
crear_arch_temp:
	; Guardar los contenidos de los registros utilizados en la pila
	push EAX
	push EBX
	push ECX

	; Crear el archivo temporal
	mov EAX, sys_creat
	mov EBX, arch_temp
	mov ECX, todos_los_permisos
	int 0x80

	; Controlamos que la llamada al sistema no haya retornado un error.
	cmp EAX, 0
	jge .salir

	.error:
		push exit_fail_inputfile
		jmp salir ; realizamos la llamada al sistema sys_exit con el error correspondiente.

	.salir
		; Guarda la direccion del archivo en 'fdescriptor'
		mov [fdescriptor], EAX

		; Reestablecer el valor de los registros
		pop ECX
		pop EBX
		pop EAX

		; Volver al que llamo
		ret





;
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
		; Leer un caracter por consola
		mov EAX, sys_read
		mov EBX, stdin
		mov ECX, cadena		; Guardar en cadena + offset
		add ECX, ESI		; Le sumamos el offset a cadena.
		mov EDX, 1		; Leemos de a un caracter
		int 0x80

		inc ESI			; Aumentamos el contador de caracteres leidos.


		; Verificar buffer overflow (las lineas tienen un maximo de caracteres posibles)
		cmp ESI, max_len_linea	; Si el contador de caracteres es igual al maximo posible, quiere decir que
					; ya nos desbordamos del buffer.
		je .bufferOverflow


		; Verificar que si se llego a EoF o si hubo error en la lectura.
		cmp EAX, 0		; Si el read leyó 0 bytes, entonces signfica que el usuario escribió <ctrl+d>
					; sin ningún byte para procesar. Es decir, el usuario escribió caracteres seguidos de <ctrl+d> (o <enter>)
					; y luego de ello escribió <ctrl+d> por lo que el programa recibió en la última linea 0 bytes para procesar,
					; por lo cual el read retornará 0 en EAX.

		je .fin_loop		; Como se ingresó ctrl+d finalizamos el loop.
		jl .readfile_error	; Si retornó un error menor a 0 entonces se produjo un error en la lectura.


		; Continua el programa (lectura exitosa, sin EoF ni overflow):
		mov CL, BYTE[ECX]	; Obtener el caracter leido en CL


		; Si el usuario NO ingreso un salto de linea, volver a loop.
		cmp CL, nln
		jne .loop		; En cambio, si lo leyo, continuar la ejecucion del bucle.


		; El usuario ingreso un salto de linea. 
		inc EDI				; Aumenta el contador de lineas
		call escribir_linea_buffer	;
		cmp EDI, max_lineas		; Verificamos que el archivo no se haya excedido del maximo de lineas
		je .demasiadasLineas		; En caso de exceso, terminacion erronea
		jne .loop			; Si no hubo error, continuar la ejecucion del bucle.
	

	.fin_loop:
		dec ESI				; Al salir del loop decrementamos el registro ESI que contiene la cantidad de caracteres leídos
						; en la última linea, ya que se utilizará como offset.
		call escribir_linea_buffer
	
		mov AL, stdout
		mov [fdescriptor_out], AL 	; esto puede causar problemas. AL 1 byte [fdescriptor_out] son 4bytes, solo se reemplaza el primer byte, creo.

						; No veo necesario cerrar y abrir de nuevo el archivo temporal, el descriptor seguirá siendo el mismo.
		call cerrar_archivo
		
		; Abrimos el archivo nuevamente con modo solo lectura.
		mov EAX, sys_open
		mov EBX, arch_temp
		mov ECX, O_RDONLY		; solo lectura
		mov EDX, todos_los_permisos
		int 0x80

		cmp EAX, 0
		jl .openfile_error
		
		mov [fdescriptor], EAX

		call calcular_metricas
		call cerrar_archivo
		call borrar_arch_temp

		push exit_success
		jmp salir

	.openfile_error:
		jmp .salirFracaso

	.readfile_error:
		jmp .salirFracaso

	; Se ingresaron mas caracteres de los permitidos (buffer overflow)
	.bufferOverflow:
		jmp .salirFracaso
	
	; Se ingresaron mas lineas de las permitidas
	.demasiadasLineas:
		jmp .salirFracaso
	
	.salirFracaso
		call cerrar_archivo	; Cerrar el archivo temporal
		call borrar_arch_temp	; Borrarlo
		push exit_fail_inputfile
		jmp salir




;
; Asume que 
;
escribir_linea_buffer:
	mov [flen], ESI		; Guardar la longitud de la linea en 'flen'			
	mov ESI, 0		; Resetear el contador de caracteres
	call append_arch_temp	; Escribir la linea en el archivo temporal
	ret





;
; Escribe el contenido de 'cadena' al final del archivo temporal.
;
; Input
;	'fdescriptor' - Contiene el descriptor del archivo temporal en el cual escribir.
;
append_arch_temp:
	; Preservar el valor de los registros
	push EAX
	push EBX
	push ECX
	push EDX
	

	; Escribir en el archivo el buffer
	mov EAX, sys_write
	mov EBX, [fdescriptor]
	mov ECX, cadena
	mov EDX, [flen]	
	int 0x80

	; Comparamos si EAX < 0, o EAX >= 0
	cmp EAX, 0
	jge .salir 

	; EAX < 0, terminacion anormal
	.error:
		push exit_fail_inputfile
		jmp salir

	; EAX = 0, terminacion exitosa
	.salir:
		; Restaurar el valor de los registros
		pop EDX
		pop ECX
		pop EBX
		pop EAX

		;  Regresa a la instrucción posterior de la invocación de 'append_arch_temp'.
		ret





;
; Cierrar el archivo especificado.
;
; Input:
;	'fdescriptor' - Descriptor del archivo a cerrar.
;
cerrar_archivo:
	; Guardar el contenido de los registros en la pila
	push EAX
	push EBX

	; Cerrar el archivo
	mov EAX, sys_close
	mov EBX, [fdescriptor] 
	int 0x80

	cmp EAX, 0
	je .salir

	; Si EAX != 0, terminacion a normal.
	.error:
		push exit_fail_inputfile
		jmp salir

	; Si EAX == 0, terminacion exitosa.
	.salir:
		; Restablecer el valor de los registros
		pop EBX
		pop EAX

		; Regresa a la instrucción posterior de la invocación de 'cerrar_arch_temp'.
		ret





;
; Borrar el archivo temporal
;
; Input:
;	'fdescriptor' - Descriptor del archivo temporal.
;
borrar_arch_temp:
	; Guardar los contenidos de los registros utilizados en la pila
	push EAX
	push EBX

	; Borrar el archivo temporal
	mov EAX, sys_unlink
	mov EBX, arch_temp
	int 0x80

	cmp EAX, 0
	je .salir

	; Si EAX != 0, terminacion anormal.
	.error:
		push exit_fail_inputfile
		jmp salir

	; Si EAX == 0, terminacion exitosa.
	.salir:
		; Devolver el valor de los registros.
		pop EBX
		pop EAX

		; Volver al que llamo
		ret





;
; Modo archivo de entrada, consola para la salida.
;
; Input:
;	EBX - Direccion del archivo de entrada.
;
archEntrada_consSalida:
	; Abrir el archivo pasado por parametro (para la entrada)
	mov EAX, sys_open
	mov ECX, O_RDONLY		; Modo solo lectura
	mov EDX, todos_los_permisos	; Permisos
	int 0x80


	; Verificamos que no haya habido error al abrir el archivo.
	cmp EAX, 0
	jl .error_entrada


	; Guarda el descriptor del archivo en fdescriptor
	mov [fdescriptor], EAX

	; Cargar el descriptor del stdout en fdescriptor_out
	mov EAX, stdout
	mov [fdescriptor_out], EAX

	; Calcular las metricas
	call calcular_metricas
	jmp .salir_exitosamente


	; EAX < 0, terminacion anormal.
	.error_entrada:
		push exit_fail_inputfile
		jmp salir

	; EAX >= 0, terminacion exitosa.
	.salir_exitosamente:
		push exit_success
		jmp salir





;
; Modo archivo de entrada, archivo de salida.
;
; Input:
;	EBX - Direccion del archivo de entrada.
;	ECX - Direccion del archivo de salida.
;
archEntrada_archSalida:
	push ECX	; Guardamos el parametro ECX

	; Abrir el archivo de entrada pasado por parametro
	mov EAX, sys_open
	mov ECX, O_RDONLY	; Modo solo lectura
	mov EDX, todos_los_permisos	; Permisos
	int 0x80

	cmp EAX, 0
	jl .error_entrada

	; Guarda el descriptor del archivo en fdescriptor
	mov [fdescriptor], EAX

	pop EBX		; Recuperamos el parametro ECX

	; Abrir el archivo salida pasado por parametro
	mov EAX, sys_open
	mov ECX, O_CREAT | O_TRUNC | O_WRONLY  		; Modo O_CREAT | O_TRUNC | O_WRONLY => Si no existe se crea y al escribir sobre un archivo ya existente primero borra todo su contenido.
	; Ademas abre el archivo en modo escritura.
	mov EDX, todos_los_permisos	; Permisos
	int 0x80

	cmp EAX, 0
	jl .error_salida

	; Guardar el descriptor del archivo en fdescriptor
	mov [fdescriptor_out], EAX

	; Calcular las metricas
	call calcular_metricas
	jmp .salir_exitosamente

	.error_entrada:
		push exit_fail_inputfile
		jmp salir
	
	.error_salida:
		push exit_fail_outputfile
		jmp salir

	.salir_exitosamente:
		; Finalizar exitosamente
		push exit_success
		jmp salir




;
; Verifica si el parámetro ingresado es el parámetro de ayuda
;
; Input:
;	EAX - Cantidad de argumentos recibidos al ejecutarse el programa.
;	EBX - Un puntero a un argumento string.
;
; Output:
;	ESI - Devuelve 1 si hay que mostrar ayuda, 0 en caso contrario.
;
verificar_ayuda:
	cmp BYTE[EBX], 45	; Verificamos si el primer caracter del segundo parametro es un '-'
	mov ESI, 0		; No es ayuda
	jne .salir_ayuda

	push exit_fail		; Ponemos en la pila el posible error (en caso que no sea exactamente "-h")

	inc EBX			; Apuntamos al siguiente caracter
	cmp BYTE[EBX], 104	; Verificamos si es 'h'
	jne salir		; Si el segundo caracter no es 'h' entonces el parametro no es exactamente "-h". Salir con error.
				; Se asume que un archivo con nombre valido no empieza con el caracter "-".

	; Una vez leido "-h" queda verificar que luego de la 'h' esté el caracter nulo '\0'
	inc EBX			; Apuntamos al siguiente caracter
	cmp BYTE[EBX], 0	; Verificamos si es el caracter nulo
	jne salir		; En caso de que no fuese el caracter nulo, el parámetro es inválido (pues no es exactamente "-h"). Salir con error.

	; Por último, en caso de ser válido el formato, la cantidad de parámetros debe ser 2 (el propio programa y '-h')
	cmp EAX, 2		; Si hay más de 2 argumentos, es una ejecución inválida.
	jne salir

	; A esta altura estamos seguros de que el parametro "-h" es totalmente correcto.
	pop ESI			; Quitamos el posible error de la pila
	mov ESI, 1		; Es ayuda

	.salir_ayuda:
	ret




;
; Muestra la ayuda correspondiente al modo "-h" por pantalla.
;
mostrar_ayuda:
	mov ECX, mensaje_ayuda
	mov EDX, longitud_ayuda

	mov EAX, stdout
	mov [fdescriptor], EAX 		; Colocamos como descriptor stdout para que se imprima por pantalla.
	call imprimir

	push exit_success
	jmp salir





;
; Punto de comienzo del programa
;
_start:
	pop EAX ; Cantidad de argumentos
	pop EBX ; Sacamos el nombre del programa


	; ARGC = 1 -> Modo "consola entrada, consola salida"
	cmp EAX, 1
	je consEntrada_consSalida

	; Si no hay un argumento, debe haber mas ...
	pop EBX			; Capturamos el segundo argumento.

	; ARGC = 2 -> Puede ser el modo "-h" o "archivo entrada, consola salida"
	cmp EAX, 2
	jne .mas_de_dos_arg

	call verificar_ayuda	; Verificamos si el argumento es "-h"
				; Devuelve en ESI un 1 en caso de que haya que mostrar ayuda, y un 0 en caso contrario.
	; Modo ayuda: "-h"
	cmp ESI, 1
	je mostrar_ayuda

	; Modo "archivo entrada, consola salida"
	jne archEntrada_consSalida ; Si ESI no es igual a 1, entonces es 0, lo que quiere decir que no es el modo ayuda, luego, debemos intentar con el modo archivo entrada, consola salida.


	.mas_de_dos_arg:
	pop ECX			; Capturamos el tercer argumento (recordemos que EBX contiene el segundo)


	; ARGC = 3 -> Modo "archivo entrada, archivo salida"
	cmp EAX, 3
	je archEntrada_archSalida ; subrutina para dos parámetros.


	; ARGC > 3 -> Argumentos invalidos.
	push exit_fail
	jmp salir

