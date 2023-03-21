; nasm -f elf64 -l printf.lst printf.s  ;  ld -s -o printf printf.o

%include "src/generals.s"
%include "config.s"


section .text

global _start                  ; predefined entry point name for ld

_start:    

    push Msg

    call printf

    EXIT 0


;------------------------------------------------------------------------
;print out the string with parametors in the format string
;------------------------------------------------------------------------
;Entre:     [rbp + 16] - format string address, any number of input parameters
;Exit:      none
;Destroy:   
;--------------------------------------------------------------

printf:

    push rbp
    mov  rbp, rsp  

    mov r9, qword [rbp + 0x10]  ;start format string address
    mov r10, r9                 ;start format string address

    dec r9                      ;correct format string addreaa

.next:

    inc r9                      ;current string address++

    cmp byte [r9], SPECIFICATOR     ;-----------------------------------
    jne .not_specificator           ;check is cur character specificator

    mov rdx, r9     ;-----------------
    sub rdx, r10    ;get length string

    PRINT_STRING CONSOL_OUT, r10, rdx

    call specifier_processing

    mov r10, r9     ;new string address
    dec r9
    jmp .next

.not_specificator:

    cmp byte [r9], TERM_CHAR        ;---------------------------------------
    jne .next                       ;check is cur character terminate symbol

    mov rdx, r9    ;-----------------
    sub rdx, r10   ;get length string

    PRINT_STRING CONSOL_OUT, r10, rdx


    pop rbp
    ret 2d * 1d

specifier_processing:

    inc r9

    cmp byte [r9], SPECIFICATOR  ;-----------------------------------
    jne .not_specificator

    PRINT_STRING CONSOL_OUT, Ascii_table + SPECIFICATOR, 1
    inc r9    

.not_specificator:
    
    
    ret

section .data
            
Msg:        db "%%Hello % !%%%%%%", 0x0a, '%', TERM_CHAR



