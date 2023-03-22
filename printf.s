; nasm -f elf64 -l printf.lst printf.s  ;  ld -s -o printf printf.o

%include "src/generals.s"
%include "config.s"



static _specificator_processing:function

static _print_char:function

section .text

global _start                  ; predefined entry point name for ld

_start:    

    push '!'
    push msg
    push CONSOL_OUT
    call _print

    EXIT 0


;------------------------------------------------------------------------
;print out the string with parameters in the format string
;------------------------------------------------------------------------
;Entre:     [rbp + 0x10] - out descriptor
;           [rbp + 0x18] - format string address, any number of input parameters
;Exit:      none
;Destroy:   rax, rdx, rsi, rdi
;           r9  - current position in format string, r10 - last not specificator symbol
;           r12 - pointer to input print's parameters 
;--------------------------------------------------------------

_print:

    push rbp
    mov  rbp, rsp  

    mov r12, 0x10                    ;parameters offset

    mov rax, [rbp + r12]            ;-------------------  
    mov qword [out_descriptor], rax ;save out descriptor

    add r12, 0x08                   ;move on to the next parametr

    mov r9, qword [rbp + r12]       ;start format string address
    mov r10, r9                     ;start format string address

    dec r9                          ;correct format string addreaa

.next:

    inc r9                          ;current string address++

    cmp byte [r9], SPECIFICATOR     ;-----------------------------------
    jne .not_specificator           ;check is cur character specificator

    mov rdx, r9                     ;-----------------
    sub rdx, r10                    ;get length string

    PRINT_STRING qword [out_descriptor], r10, rdx

    add r12, 0x08                   ;set pointer to input print's parameters
    mov rbx, qword [rbp + r12]
    call _specificator_processing

    mov r10, r9                     ;last not specificator symbol address
    dec r9                          ;correct string address
    jmp .next

.not_specificator:

    cmp byte [r9], TERM_CHAR        ;---------------------------------------
    jne .next                       ;check is cur character terminate symbol

    mov rdx, r9                     ;-----------------
    sub rdx, r10                    ;get length string

    PRINT_STRING qword [out_descriptor], r10, rdx

    mov rax, r12                    ;---------------------------------
    sub rax, rsp                    ;get counter of print's parameters

    pop rbp
    ret

 
;------------------------------------------------------------------------
;specifier mode processing
;------------------------------------------------------------------------
;Expected:  out_descriptor 
;Entre:     rbx - current print param
;Exit:      none
;Destroy:   rax, rdx, rsi, rdi 
;           r9 - current position in format string, r12 - pointer to input print's parameters 
;--------------------------------------------------------------
   
_specificator_processing:

    inc r9                          ;-----------------------         
    mov al, byte [r9]               ;get specificator's mode 

    cmp al, SPECIFICATOR            ;check character is specificator symbol
    jne .not_specificator_symbol

    PRINT_STRING qword [out_descriptor], Ascii_table + SPECIFICATOR, 1 

    sub r12, 0x08                   ;specifier printout does not require a parameter

    jmp .end_switch

.not_specificator_symbol:

    sub al, 'c'                     ;subtract the minimum switch's value 
    cmp al, byte Cnt_print_mode
    jae .print_switch_defaulte

    jmp qword [.start_print_switch + rax * 0x08]

.print_switch_char:

    call _print_char
    jmp .end_switch

.print_switch_defaulte:
    nop                             ;do anathing

.end_switch:  

    inc r9                          ;move to the next character

    ret 


section .rodata

.start_print_switch: dq .print_switch_char         \
                        .print_switch_defaulte     

Cnt_print_mode equ ($ - .start_print_switch) >> 0x03 ;count print's mode 

section .text
;------------------------------------------------------------------------
;specifier mode processing
;------------------------------------------------------------------------
;Expected:  out_descriptor 
;Entre:     rbx - ascii code symbol 
;Exit:      none
;Destroy:   rax, rdx, rsi, rdi 
;--------------------------------------------------------------
   
_print_char:

    mov rsi, Ascii_table
    add rsi, rbx
    PRINT_STRING qword [out_descriptor], rsi, 1
    ret 


section .data

out_descriptor: dq 0x00
            
msg:        db "%% Hello %%%c?", 0xa, TERM_CHAR



