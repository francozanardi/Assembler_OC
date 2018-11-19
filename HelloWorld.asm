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

%define print			4
%define nln			0x0A	; '\n'


section .data
	mensaje db "Hola OC 2018", nln
	longitud equ $ - mensaje


section .text
	global _start


_start:
mov EAX, print
mov EBX, 1
mov ECX, mensaje
mov EDX, longitud
int 0x80


_exit:
mov EAX, sys_exit
mov EBX, 0
int 0x80
