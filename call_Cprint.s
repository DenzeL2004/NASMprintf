; nasm -f elf64 -l call_Cprint.lst call_Cprint.s ; gcc -no-pie Cprintf.o -o Cprint

%include "src/generals.s"


global _start

extern printf

section .text

_start:
    mov rdi, msg                ;address format string
    mov rsi, -1d
    mov rdx, string

    mov rcx, 3802d
    mov r8, 100d
    mov r9, 33d

    push '!'
    push msg
    push 10101b

    call printf wrt ..plt

    EXIT 0

section .data

msg:        db "%a%z%# %d %s  %x %d%%%c%b %c, %s! %b", 0xa, TERM_CHAR
string:     db "Love!!!", TERM_CHAR




