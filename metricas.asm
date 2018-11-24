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
%define sys_exit				0x01
%define sys_fork				0x02
%define sys_read				0x03
%define sys_write				0x04
%define sys_open				0x05
%define sys_close				0x06
%define sys_waitpid				0x07
%define sys_creat				0x08
%define sys_link				0x09
%define sys_unlink				0x0A

%define stdin					0x00
%define stdout					0x01
%define stderr					0x02

%define todos_los_permisos		0777

%define O_TRUNC					0x200
%define O_CREAT					0x040
%define O_WRONLY				0x001
%define O_RDONLY				0x000

%define ascii_zero				0x30
%define nln						0x0A
%define tab						0x09

%define exit_success			0x00
%define exit_fail_inputfile		0x01
%define exit_fail_outputfile	0x02
%define exit_fail				0x03

%define deteccion_eof			0x100

%define max_len_linea			1024
%define max_lineas				1024

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
	mensaje_ayuda		db	nln, "Calculador de Metricas.", nln
						db	" - Proyecto para Organizacion de Computadoras, Segundo Cuatrimestre 2018", nln
						db	" - Autores:", nln
						db	tab, "VEGA, Maximiliano Nicolas", nln
						db	tab, "ZANARDI, Franco Ivan", nln, nln
						db	"Este programa calcula la cantidad de letras, palabras, lineas y parrafos de un texto.", nln, nln
						db	"Uso: ./metricas [argumentos]", nln, nln,
						db	"Argumentos:",  nln
						db	"[-h]", tab, tab, tab, tab, tab,	"Muestra el menu de ayuda.",nln
						db	"[archivo_entrada]", tab, tab, tab,	"Lee el archivo de texto especificado y calcula las metricas sobre el, imprime el resultado por pantalla.", nln
						db	"[archivo_entrada archivo_salida]", tab,"Lee el archivo de entrada especificado, calcula las metricas sobre el, y guarda el resultado en el archivo de salida.", nln, nln
	longitud_ayuda		EQU	$-mensaje_ayuda

	msg_res				db	nln, "Resultado del calculo de metricas:", nln
	msg_res_len			EQU	$-msg_res

	msg_letras			db	"Cantidad de letras: "
	msg_letras_len		EQU	$-msg_letras

	msg_palabras		db	nln, "Cantidad de palabras: "
	msg_palabras_len	EQU	$-msg_palabras

	msg_lineas			db	nln, "Cantidad de lineas: "
	msg_lineas_len		EQU	$-msg_lineas

	msg_parrafos		db	nln, "Cantidad de parrafos: "
	msg_parrafos_len	EQU	$-msg_parrafos

	msg_final			db	nln, nln
	msg_final_len		EQU	$-msg_final

	arch_temp			db	"metricas.tmp",0	; Caracter nulo al final
	arch_temp_len		EQU	$-arch_temp

	fdescriptor			dd	stdin
	fdescriptor_out		dd	stdout
	flen				dd	0


section .bss
	cadena	resb	max_len_linea
	fchar	resd	1


section .text
	global _start





;
; salir
;
; Descripción:
;	Envia la señal de terminación del programa con el código de error correspondiente.
;
; Input:
;	Tope de la pila - Código de error
;
salir: 
	mov EAX, sys_exit	; sys_call = sys_exit
	pop EBX				; Obtenemos el código de error.
	int 0x80





;
; es_letra
;
; Descripción:
;	Verifica si el caracter recibido en el input es una letra del abecedario ingles (puede ser tanto mayúscula como minúscula).
;
; Input:
;	ESI - Caracter a verificar
;
; Output:
;	EDI - 1 si el caracter es una letra, 0 en caso contrario
;
es_letra:
	; Verificamos si el caracter esta entre la 'A' y la 'Z'
	cmp ESI, 65 ; 'A'
	jl .no_es_letra

	cmp ESI, 90	; 'Z'
	jle .es_letra

	
	; Verificamos si el caracter está entre la 'a' y la 'z'
	cmp ESI, 97	; 'a'
	jl .no_es_letra

	cmp ESI, 122; 'z'
	jle .es_letra


	; Si no es una letra, EDI = 0
	.no_es_letra:
		mov EDI, 0
		jmp .salir

	; Si es una letra, EDI = 1
	.es_letra:
		mov EDI, 1

	.salir:
		ret	; Continúa la ejecución desde la instrucción posterior que invocó a este procedimiento.





;
; es_delimitador
;
; Descripción:
;	Verifica si el caracter recibido en el input es un delimitador válido.
;
; Input:
;	ESI - Caracter a verificar.
;
; Output
;	EDI - 1 si el caracter es un delimitador, 0 en caso contrario
;
es_delimitador:
	; Realizamos la comparación con cada delimitador posible, si es alguno de ellos, saltar a ".es_delimitador"
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


	; Si no es delimitador, EDI = 0
	mov EDI, 0
	jmp .salir


	; Es un delimitador, EDI = 1
	.es_delimitador:
	mov EDI, 1

	
	.salir:
		ret		; Continúa la ejecución desde la instrucción posterior que invocó a este procedimiento.





;
; leer_caracter
;
; Descripción:
;	Lee un único caracter del archivo especificado en el input y lo guarda en el output.
;
; Input:
;	'fdescriptor' - Descriptor del archivo a leer.
;
; Output:
;	ESI - El caracter leído.
;
; Notas:
;	Si EAX >= 0, EAX representa la cantidad de bytes leídos en el archivo.
;	Si EAX <  0, EAX representa un código de error particular
;
leer_caracter:
	; Preserva los valores de los registros utilizando la pila
	push EAX
	push EBX
	push ECX
	push EDX


	; Lee un unico caracter del archivo
	mov EAX, sys_read 		; sys_call = sys_exit
	mov EBX, [fdescriptor]	; Descriptor del archivo.
	mov ECX, fchar 			; Dirección en memoria en donde se guardará los bytes leídos del archivo.
	mov EDX, 1				; Cantidad de bytes a leer.
	int 0x80
	

	; Verificamos EoF o error de lectura
	cmp EAX, 0
	je .eof					; Si se leyó 0 bytes, llegamos al final del archivo.
	jl .error_lectura		; Si EAX dió un número negativo, hubo error en la lectura.

	
	; Guarda el valor del caracter en el registro ESI
	mov ESI, [fchar]
	jmp .salir
	
	
	; Al leer el final del archivo, guardamos un delimitador especial en ESI
	.eof:
		mov ESI, deteccion_eof
		jmp .salir

		
	; Si hubo error en la lectura, finalizamos la ejecución del programa.
	.error_lectura:
		push exit_fail_inputfile 	; Pasamos el código de error.
		jmp salir

		
	; Salir sin error en lectura.
	.salir:
		; Restablecer el valor de los registros
		pop EDX
		pop ECX
		pop EBX
		pop EAX

		; Continúa la ejecución desde la instrucción posterior que invocó a este procedimiento.
		ret





;
; division_con_resta
;
; Descripción:
;	Realizamos la division entre los parámetros de entrada y guardamos tanto el cociente como el resto en los de salida.
;
; Input:
;	EAX - Dividendo
;	EBX - Divisor
;
; Output:
;	EAX - Cociente
;	EBX - Resto
;
; Nota:
;	Implementamos este método ya que la instrucción DIV de assembler trabajaba con números pequeños (pues utilizaba
;	registros de 1 byte) y en caso de estar procesando un archivo muy grande se manejarán números mayores a lo que
;	estos registros permiten.
;	Al trabajar con EAX y EBX, tenemos espacio más que suficiente para realizar estos cálculos.
;
division_con_resta:
	push ECX	; Preservamos el valor del registro ECX

	mov ECX, 0	; Cuenta la cantidad de veces que entra el divisor en el dividendo.
	
	; Bucle del algoritmo de división
	.loop:
		cmp EAX, EBX	; Si el dividendo es menor que el divisor, terminamos
		jl .fin

		sub EAX, EBX	; Si el dividendo es mayor o igual que el divisor, restarle el divisor
		inc ECX			; Llevar la cuenta de cuentas veces entra el divisor en el dividendo.

		jmp .loop
	
	; Al finalizar, guardamos en los registros correspondientes los valores de salida.
	.fin
		mov EBX, EAX	; EBX = Resto
		mov EAX, ECX	; EAX = Cociente

		pop ECX			; Restauramos el valor del registro ECX

		ret				; Continúa la ejecución desde la instrucción posterior que invocó a este procedimiento.





;
; imprimir_numero
;
; Descripción:
;	Imprime el número en el descriptor de archivo (ambos recibidos en el input)
;
; Input:
;	EAX					- Número a imprimir
;	'fdescriptor_out'	- Descriptor del archivo donde se escribirá el número
;
imprimir_numero:
	; Preservamos el valor de los registros
	push EBX
	push ECX
	push EDX

	
	; Ingresamos un delimitador en la pila, para saber cuando dejar de desapilar.
	push 0
	
	
	; En cada paso dividimos el número por 10 y guardamos el resto en la pila, hasta que el resultado de la división sea 0,
	; es decir, guardamos todos los dígitos.
	; Notar que en la pila quedará el dígito más significativo en el tope y el menos significativo en el fondo.
	.caso_recursivo:
		mov EBX, 10				; El divisor es 10
		call division_con_resta	; Produce:   EAX = EAX / EBX,   EBX = EAX % EBX

		add EBX, ascii_zero		; Le sumamos el código ASCII del '0' al resto de la divisón, para convertirlo de número a caracter.
		push EBX				; Apilamos el caracter.

		cmp EAX, 0				; Si el resultado de la division es mayor que cero, continuar iterando.
		jne .caso_recursivo
	

	mov EDX, 1	; Cantidad de bytes a imprimir, queda establecido aqui ya que las siguientes instrucciones lo usaran.

	
	; En cada paso desapilamos un dígito y lo imprimimos, recordar que los dígitos estaban guardados al revés en la pila,
	; por lo que al desapilar nos queda el número ordenado.
	.imprimir_recursivo:
		pop ECX					; Obtenemos el numero (en formato ASCII) del tope de la pila
		cmp ECX, 0				; En caso de que sea el delimitador, salimos del metodo
		je .imprimir_espacio
		
		mov [fchar], ECX		; Guardamos en fchar el caracter que obtuvimos de la pila.
		mov ECX, fchar			; Ponemos en ECX la dirección en memoria que almacena el caracter leído en la pila.
		call imprimir			; Delegamos en la rutina que imprimir en el archivo con el descriptor almacenado en 'fdescriptor_out'.

		jmp .imprimir_recursivo

	
	; Luego de imprimir el número, imprimimos un espacio para separarlo de los siguientes números.
	.imprimir_espacio:
		mov ECX, 0x20			; Colocamos en CL el código ascii del espacio ' '.
		mov [fchar], ECX		; Ponemos en fchar el código ascii del espacio ' '.
		mov ECX, fchar			; Ponemos en ECX la dirección de memoria que contiene el caracter a imprimir, en este caso el espacio.
		call imprimir			; Delegamos en la rutina que imprimir en el archivo con el descriptor almacenado en 'fdescriptor_out'.
		jmp .salir

		
	.salir:
		; Restablecemos el valor de los registros.
		pop EDX
		pop ECX
		pop EBX

		; Continúa la ejecución desde la instrucción posterior que invocó a este procedimiento.
		ret





;
; mostrar_resultados
;
; Descripción:
;	Imprime los resultados del cálculo de las metricas. 
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

	; Continúa la ejecución desde la instrucción posterior que invocó a este procedimiento.
	ret	





;
; calcular_metricas:
;
; Descripcion:
;	Este método calcula las métricas del archivo de entrada, lo hace simulando un autómata finito determinista
;	con la excepción de que al llegar a algunos estados realiza una operacion en concreta (aumenta algun contador).
;
; Input:
;	'fdescriptor'		- Descriptor del archivo de entrada
;	'fdescriptor_out'	- Descriptor del archivo de salida
;
; Output:
;	EAX - Cantidad de letras.
;	EBX - Cantidad de palabras.
;	ECX - Cantidad de lineas.
;	EDX - Cantidad de parrafos.
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


	; ESTADO "BASURA (sin parrafo)"
	;	Nota: Este es el estado inicial del autómata.
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


	; ESTADO "LETRA (sin parrafo)"
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


	; ESTADO "LINEA"
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


	; ESTADO "LINEA Y PARRAFO"
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


	
	; ESTADO "LINEA, PARRAFO Y PALABRA"
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


	; ESTADO "PALABRA"
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


	; ESTADO "LETRA (con parrafo)"
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


	; ESTADO "BASURA (con parrafo)"
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


	; Esto no existe como estado, se supone que todos los estados anteriores son aceptadores, pero delegamos
	; aquí por si fuese necesario agregar más comportamiento o modificar algo, para modularizar.
	.aceptador:
		call mostrar_resultados
	

	; Restaurar los valores de los registros.
	pop EDI
	pop ESI
	pop EDX
	pop ECX
	pop EBX
	pop EAX
	
	; Continúa la ejecución desde la instrucción posterior que invocó a este procedimiento.
	ret





;
; imprimir
;
; Descripción:
;	Imprime en el archivo cuyo descriptor es recibido en el input.
;
; Input:
;	'fdescriptor_out'	- Descriptor del archivo de salida.
;	ECX					- Puntero a la cadena a escribir.
;	EDX					- Cantidad de caracteres a escribir.
;
imprimir:
	; Guardamos los valores de los registros que utilizaremos
	push EAX
	push EBX 

	; Preparamos para escribir
	mov EAX, sys_write			; sys_call = sys_write
	mov EBX, [fdescriptor_out]	; Se establece el descriptor del archivo.
	int 0x80

	; Evaluamos si la llamada al sistema retornó un error en EAX.
	cmp EAX, 0 		
	jge .salir	; Si EAX es menor a 0 entonces se produjo un error.
	

	; En caso de error en la escritura, finalizamos la ejecución del programa.
	.error:
		push exit_fail_outputfile	; Especificamos el código de error.
		jmp salir


	; Terminar le ejecución del procedimiento normalmente.
	.salir:
		; Restablecemos los valores de los registos utilizados
		pop EBX
		pop EAX
		
		; Continúa la ejecución desde la instrucción posterior que invocó a este procedimiento.
		ret




;
; crear_arch_temp
;
; Descripción:
;	Crea el archivo temporal
;
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
	jge .salir	; Si EAX >= 0, no hubo error.
	
	
	; En caso de error en la escritura, finalizamos la ejecución del programa.
	.error:
		push exit_fail_inputfile	; Especificamos el código de error.
		jmp salir

		
	; Terminar la ejecución del procedimiento normalmente.
	.salir
		; Guarda la direccion del archivo en 'fdescriptor'
		mov [fdescriptor], EAX

		; Reestablecer el valor de los registros
		pop ECX
		pop EBX
		pop EAX
		
		; Continúa la ejecución desde la instrucción posterior que invocó a este procedimiento.
		ret





;
; consEntrada_consSalida
;
; Descripción:
;	Correspondiente al modo "consola entrada, consola salida" del programa.
;	Lee caracteres de la consola y los guarda en un archivo temporal, luego utilizando el archivo temporal
;	delega en el procedimiento 'calcular_metricas' (que utiliza un archivo) para realizar los cálculos e
;	imprimirlos por pantalla.
;
; Notas:
;	Sólo se pueden leer hasta 'max_len_lineas' caracteres por linea.
;	Sólo se pueden ingresar hasta 'max_lineas' lineas.
;
consEntrada_consSalida:
	mov ESI, 0				; Contador de caracteres leidos (offset) en una linea.
	mov EDI, 0				; Contador lineas]

	call crear_arch_temp	; Creamos el archivo temporal donde guardaremos lo que el usuario ingrese por consola.

	
	; Bucle de lectura de caracteres
	.loop:
		; Leer un caracter por consola
		mov EAX, sys_read
		mov EBX, stdin
		mov ECX, cadena		; Guardar en cadena + offset
		add ECX, ESI		; Le sumamos el offset a cadena.
		mov EDX, 1			; Leemos de a un caracter
		int 0x80

		inc ESI				; Aumentamos el contador de caracteres leidos.


		; Verificar buffer overflow (las lineas tienen un maximo de caracteres posibles)
		cmp ESI, max_len_linea	; Si el contador de caracteres es igual al maximo posible, quiere decir que
								; ya nos desbordamos del buffer.
		je .bufferOverflow


		; Verificar que si se llego a EoF o si hubo error en la lectura.
		cmp EAX, 0	; Si el read leyó 0 bytes, entonces signfica que el usuario escribió <ctrl+d>
					; sin ningún byte para procesar. Es decir, el usuario escribió caracteres seguidos de <ctrl+d> (o <enter>)
					; y luego de ello escribió <ctrl+d> por lo que el programa recibió en la última linea 0 bytes para procesar,
					; por lo cual el read retornará 0 en EAX.

		je .fin_loop		; Como se ingresó ctrl+d finalizamos el loop.
		jl .readfile_error	; Si retornó un error menor a 0 entonces se produjo un error en la lectura.


		; Continua el programa (lectura exitosa, sin EoF ni overflow):
		mov CL, BYTE[ECX]	; Obtener el caracter leido en CL


		; Si el usuario NO ingresó un salto de linea, volver a loop.
		cmp CL, nln
		jne .loop


		; El usuario ingresó un salto de linea. 
		inc EDI						; Aumenta el contador de lineas
		call escribir_linea_buffer	; Escribe la linea en el archivo temporal.
		cmp EDI, max_lineas			; Verificamos que el usuario no se haya excedido del máximo de lineas.
		je .demasiadasLineas		; En caso de exceso, terminación errónea.
		jne .loop					; Si no hubo error, continuar la ejecucion del bucle.
	

	; Al finalizar el bucle
	.fin_loop:
		dec ESI		; Al salir del loop decrementamos el registro ESI que contiene la cantidad de caracteres leídos
					; en la última linea, ya que se utilizará como offset.
		call escribir_linea_buffer	; Escribe la última linea en el archivo temporal.
	
		mov EAX, stdout
		mov [fdescriptor_out], EAX

		; Cerrar el archivo temporal (cuyo descriptor está guardado en 'fdescriptor')
		call cerrar_archivo
		
		; Abrimos el archivo nuevamente con modo sólo lectura.
		mov EAX, sys_open
		mov EBX, arch_temp
		mov ECX, O_RDONLY			; Modo sólo lectura
		mov EDX, todos_los_permisos	; Todos los permisos.
		int 0x80

		; Verificamos si el descriptor es válido.
		cmp EAX, 0
		jl .openfile_error		; Si el descriptor es menor a 0, hubo error al abrir el archivo.
		
		; Descriptor válido
		mov [fdescriptor], EAX	; Guardamos el número de descriptor obtenido al abrir el archivo.

		; Calcular las métricas, cerrar el archivo temporal y borrarlo.
		call calcular_metricas
		call cerrar_archivo
		call borrar_arch_temp

		; Terminar la ejecución del programa de forma exitosa.
		push exit_success
		jmp salir

	
	; Terminaciones erróneas:
	.openfile_error:
		jmp .salirFracaso

	.readfile_error:
		jmp .salirFracaso

	.bufferOverflow:		; Se ingresaron mas caracteres de los permitidos (buffer overflow)
		jmp .salirFracaso

	.demasiadasLineas:		; Se ingresaron mas lineas de las permitidas
		jmp .salirFracaso
	
	.salirFracaso
		; Cerrar y borrar el archivo temporal.
		call cerrar_archivo
		call borrar_arch_temp
		
		; Terminar la ejecución del programa con el código de error apropiado.
		push exit_fail_inputfile
		jmp salir




	
;
; escribir_linea_buffer
;
; Descripción:
;	Guarda la longitud de la linea a escribir en el archivo temporal en una dirección de memoria,
;	resetea el contador de caracteres, y delega en el método para escribir en el archivo temporal.
;
; Nota:
;	Este método se creó para modularizar, pues su propia existencia no es muy útil.
;
; Input:
;	ESI - Longitud de la linea a escribir.
;
; Output:
;	ESI = 0
;
escribir_linea_buffer:
	mov [flen], ESI			; Guardar la longitud de la linea en 'flen'			
	mov ESI, 0				; Resetear el contador de caracteres
	call append_arch_temp	; Escribir la linea en el archivo temporal
	ret						; Continúa la ejecución desde la instrucción posterior que invocó a este procedimiento.





;
; append_arch_temp
;
; Descripción:
;	Escribe la linea recibida en el archivo temporal.
;
; Input:
;	'fdescriptor'	- Descriptor del archivo a escribir.
;	'cadena'		- Secuencia de caracteres a escribir.
;	'flen'			- Cantidad de caracteres a escribir.
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

	
	; Verificamos el resultado de la instrucción de escribir.
	cmp EAX, 0
	jge .salir	; Si EAX >= 0, salir exitosamente del método

	
	; EAX < 0, hubo error al escribir.
	.error:
		; Indicar el código de error y finalizar la ejecución del programa.
		push exit_fail_inputfile
		jmp salir

		
	; EAX >= 0, éxito al escribir en el archivo.
	.salir:
		; Restaurar el valor de los registros
		pop EDX
		pop ECX
		pop EBX
		pop EAX
		
		; Continúa la ejecución desde la instrucción posterior que invocó a este procedimiento.
		ret





;
; cerrar_archivo
;
; Descripción:
;	Ejecuta la instrucción para cerrar el archivo indicado por input.
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

	; Verificamos el resultado de la operación
	cmp EAX, 0
	je .salir

	; Si EAX != 0, hubo error al cerrar el archivo.
	.error:
		; Indicar el código de error y terminar la ejecución del programa.
		push exit_fail_inputfile
		jmp salir

	; Si EAX == 0, terminacion exitosa.
	.salir:
		; Restablecer el valor de los registros
		pop EBX
		pop EAX

		; Continúa la ejecución desde la instrucción posterior que invocó a este procedimiento.
		ret





;
; borrar_arch_temp
;
; Descripción:
;	Borra el archivo temporal utilizado en el modo "consola entrada, consola salida".
;
borrar_arch_temp:
	; Guardar los contenidos de los registros utilizados en la pila
	push EAX
	push EBX

	
	; Borrar el archivo temporal
	mov EAX, sys_unlink
	mov EBX, arch_temp	; Nombre del archivo temporal.
	int 0x80


	; Verificamos el resultado de la operación
	cmp EAX, 0
	je .salir


	; Si EAX != 0, hubo error al borrar el archivo.
	.error:
		; Indicar el código de error y terminar la ejecución del programa.
		push exit_fail_inputfile
		jmp salir


	; Si EAX == 0, terminacion exitosa.
	.salir:
		; Devolver el valor de los registros.
		pop EBX
		pop EAX

		; Continúa la ejecución desde la instrucción posterior que invocó a este procedimiento.
		ret





;
; archEntrada_consSalida
;
; Descripción:
;	Correspondiente al modo "archivo entrada, consola salida" del programa.
;	Abre y lee el archivo especificado, realiza el cálculo de las métricas y las imprime por pantalla.
;
; Input:
;	EBX - Direccion del archivo de entrada.
;
archEntrada_consSalida:
	; Abrir el archivo pasado por parametro (para la entrada)
	mov EAX, sys_open
	mov ECX, O_RDONLY			; Modo solo lectura
	mov EDX, todos_los_permisos	; Permisos
	int 0x80


	; Verificamos que no haya error al abrir el archivo.
	cmp EAX, 0
	jl .error_entrada


	; Guarda el descriptor del archivo en fdescriptor
	mov [fdescriptor], EAX

	
	; Cargar el descriptor de la consola en fdescriptor_out
	mov EAX, stdout
	mov [fdescriptor_out], EAX

	
	; Calcular las metricas y salir exitosamente
	call calcular_metricas
	jmp .salir_exitosamente


	; EAX < 0, terminacion anormal.
	.error_entrada:
		; Cargamos el código de error y finalizamos la ejecución del programa.
		push exit_fail_inputfile
		jmp salir

	
	; EAX >= 0, terminacion exitosa.
	.salir_exitosamente:
		; Cargamos el código de error apropiado y finalizamos la ejecución del programa.
		push exit_success
		jmp salir





;
; archEntrada_archSalida
;
; Descripción:
;	Correspondiente al modo "archivo entrada, archivo salida" del programa.
;	Abre el archivo de entrada y el de salida (especificados en el input), lee el archivo de entrada,
;	realiza el cálculo de las métricas, y escribe el resultado en el archivo de salida.
;
; Input:
;	EBX - Direccion del archivo de entrada.
;	ECX - Direccion del archivo de salida.
;
archEntrada_archSalida:
	push ECX	; Guardamos el parametro ECX, pues necesitamos usarlo para la instrucción de abrir el archivo.

	
	; Abrir el archivo de entrada pasado por parametro
	mov EAX, sys_open
	mov ECX, O_RDONLY			; Modo solo lectura
	mov EDX, todos_los_permisos	; Permisos
	int 0x80

	; Verificamos si hubo error al abrir el archivo de entrada.
	cmp EAX, 0
	jl .error_entrada

	; Guarda el descriptor del archivo de entrada en fdescriptor
	mov [fdescriptor], EAX

	
	
	; Abrir el archivo salida pasado por parametro
	pop EBX										; Recuperamos el parametro ECX
	mov EAX, sys_open
	mov ECX, O_CREAT | O_TRUNC | O_WRONLY  		; Modo O_CREAT | O_TRUNC | O_WRONLY => Si no existe se crea y al escribir sobre un archivo ya existente primero borra todo su contenido.
												; Además abre el archivo en modo escritura.
	mov EDX, todos_los_permisos					; Permisos
	int 0x80

	; Verificamos si hubo error al abrir el archivo de salida.
	cmp EAX, 0
	jl .error_salida

	; Guardar el descriptor del archivo de salida en fdescriptor_out
	mov [fdescriptor_out], EAX

	
	
	; Calcular las metricas y finalizar el programa exitosamente.
	call calcular_metricas
	jmp .salir_exitosamente


	; Hubo error al abrir el archivo de entrada.
	.error_entrada:
		; Cargamos el código de error correspondiente y terminamos la ejecución del programa.
		push exit_fail_inputfile
		jmp salir


	; Hubo error al abrir el archivo de salida.
	.error_salida:
		; Cargamos el código de error correspondiente y terminamos la ejecución del programa.
		push exit_fail_outputfile
		jmp salir


	; Procedimiento exitoso.
	.salir_exitosamente:
		; Cargamos el código de error "éxito" y terminamos la ejecución del programa.
		push exit_success
		jmp salir





;
; verificar_ayuda
;
; Descripción:
;	Verifica si el parámetro ingresado es el parámetro de ayuda.
;
; Input:
;	EAX - Cantidad de argumentos recibidos al ejecutarse el programa.
;	EBX - Un puntero a un argumento string.
;
; Output:
;	ESI - Devuelve 1 si hay que mostrar ayuda, 0 en caso contrario.
;
verificar_ayuda:
	; Verificamos si el primer caracter del parámetro es un '-'
	cmp BYTE[EBX], 45
	mov ESI, 0			; Si no lo es, ESI=0 y salir del procedimiento.
	jne .salir_ayuda

	push exit_fail		; Ponemos en la pila el posible error (en caso que no sea exactamente "-h")

	inc EBX				; Apuntamos al siguiente caracter
	cmp BYTE[EBX], 104	; Verificamos si es 'h'
	jne salir			; Si el segundo caracter no es 'h' entonces el parametro no es exactamente "-h". Salir con error.
						; Se asume que un archivo con nombre valido no empieza con el caracter "-".

	; Una vez leido "-h" queda verificar que luego de la 'h' esté el caracter nulo '\0'
	inc EBX				; Apuntamos al siguiente caracter
	cmp BYTE[EBX], 0	; Verificamos si es el caracter nulo
	jne salir			; En caso de que no fuese el caracter nulo, el parámetro es inválido (pues no es exactamente "-h"). Salir con error.

	; Por último, en caso de ser válido el formato, la cantidad de parámetros debe ser 2 (el propio programa y '-h')
	cmp EAX, 2			; Si hay más de 2 argumentos, es una ejecución inválida.
	jne salir

	; A esta altura estamos seguros de que el parametro "-h" es totalmente correcto.
	pop ESI				; Quitamos el posible error de la pila
	mov ESI, 1			; Es ayuda

	.salir_ayuda:
		ret				; Continúa la ejecución desde la instrucción posterior que invocó a este procedimiento.




;
; mostrar_ayuda
;
; Descripción:
;	Imprime por consola una breve documentación sobre cómo utilizar el programa.
;
mostrar_ayuda:
	; Cargar el mensaje de ayuda
	mov ECX, mensaje_ayuda
	mov EDX, longitud_ayuda

	mov EAX, stdout
	mov [fdescriptor], EAX 	; Colocamos como descriptor stdout para utilizar el procedimiento imprimir.
	
	call imprimir			; Imprimimos la ayuda.

	; Colocamos el código de terminación "éxito" y finalizamos la ejecución del programa.
	push exit_success
	jmp salir





;
; _start
;
; Descripción:
;	Punto de comienzo del programa, verifica los argumentos que ingresó el usuario y luego en base
;	a ello se pone en alguno de los modos del programa;
;		- "ayuda"
;		- "consola entrada, consola salida"
;		- "archivo entrada, consola salida"
;		- "archivo entrada, archivo salida"
;	En caso de recibir una combinación inválida de parámetros, finaliza con código de error.
;
; Input:
;	Tope de la pila	- La cantidad de argumentos del tope de la pila seguida de los mismos.
;
_start:
	pop EAX ; Cantidad de argumentos
	pop EBX ; Sacamos el nombre del programa


	; ARGC = 1 -> Modo "consola entrada, consola salida"
	cmp EAX, 1
	je consEntrada_consSalida

	
	; Si no hay un argumento, debe haber mas ...
	pop EBX	; Capturamos el segundo argumento.
	
	
	; ARGC = 2 -> Puede ser el modo "-h" o "archivo entrada, consola salida"
	cmp EAX, 2
	jne .mas_de_dos_arg		; Si hay más de dos argumentos, directamente no realizamos la verificación de si "-h".

	call verificar_ayuda	; Verificamos si el argumento es "-h"
							; Devuelve en ESI un 1 en caso de que haya que mostrar ayuda, y un 0 en caso contrario.
	
	; Modo ayuda: "-h"
	cmp ESI, 1
	je mostrar_ayuda

	; Modo "archivo entrada, consola salida"
	jne archEntrada_consSalida ; Si ESI no es igual a 1, entonces es 0, lo que quiere decir que no es el modo ayuda, luego, debemos intentar con el modo archivo entrada, consola salida.


	.mas_de_dos_arg:
	pop ECX	; Capturamos el tercer argumento (recordemos que EBX contiene el segundo)


	; ARGC = 3 -> Modo "archivo entrada, archivo salida"
	cmp EAX, 3
	je archEntrada_archSalida ; subrutina para dos parámetros.


	; ARGC > 3 -> Argumentos invalidos.
	push exit_fail
	jmp salir
