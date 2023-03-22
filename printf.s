; nasm -f elf64 -l printf.lst printf.s  ;  ld -s -o printf printf.o

%include "src/generals.s"
%include "config.s"



static _specificator_processing:function

static _print_char:function

static _print_string:function

static _print_dec_num:function

static _print_hex_num:function

static _print_oct_num:function

static _print_bin_num:function


section .text

global _start                  ; predefined entry point name for ld

_start:    
    
    
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

    PRINT_STRING qword [out_descriptor], Ascii_table + SPECIFICATOR, 0x01 

    sub r12, 0x08                   ;specifier printout does not require a parameter

    jmp .end_switch

.not_specificator_symbol:

    sub al, 'b'                     ;subtract the minimum switch's value 
    cmp al, byte Cnt_print_mode
    jae .print_switch_defaulte

    jmp qword [.start_print_switch + rax * 0x08]

.print_switch_char:

    call _print_char
    jmp .end_switch

.print_switch_string:

    call _print_string
    jmp .end_switch

.print_switch_dec_num:

    call _print_dec_num
    jmp .end_switch

.print_switch_hex_num:

    call _print_hex_num
    jmp .end_switch

.print_switch_bin_num:

    call _print_bin_num
    jmp .end_switch

.print_switch_oct_num:

    call _print_oct_num
    jmp .end_switch


.print_switch_defaulte:
    nop                             ;do anathing

.end_switch:  

    inc r9                          ;move to the next character

    ret 


section .rodata

.start_print_switch: dq .print_switch_bin_num , \
                        .print_switch_char    , \
                        .print_switch_dec_num , \
                        .print_switch_defaulte, \
                        .print_switch_defaulte, \
                        .print_switch_defaulte, \
                        .print_switch_hex_num , \
                        .print_switch_defaulte, \
                        .print_switch_defaulte, \
                        .print_switch_defaulte, \
                        .print_switch_defaulte, \
                        .print_switch_defaulte, \
                        .print_switch_defaulte, \
                        .print_switch_oct_num,  \
                        .print_switch_defaulte, \
                        .print_switch_defaulte, \
                        .print_switch_defaulte, \
                        .print_switch_string  , \
                        .print_switch_defaulte, \
                        .print_switch_defaulte, \
                        .print_switch_defaulte, \
                        .print_switch_defaulte, \
                        .print_switch_defaulte

Cnt_print_mode equ ($ - .start_print_switch) >> 0x03 ;count print's mode 

section .text

;------------------------------------------------------------------------
;specifier mode processing. Print character
;------------------------------------------------------------------------
;Expected:  out_descriptor 
;Entre:     rbx - ascii code symbol 
;Exit:      none
;Destroy:   rax, rdx, rsi, rdi 
;------------------------------------------------------------------------
   
_print_char:

    mov rsi, Ascii_table
    add rsi, rbx
    PRINT_STRING qword [out_descriptor], rsi, 0x01
    ret 

;------------------------------------------------------------------------
;specifier mode processing. Print string
;------------------------------------------------------------------------
;Expected:  out_descriptor 
;Entre:     rbx - string's address
;Exit:      none
;Destroy:   rax, rdx, rsi, rdi 
;------------------------------------------------------------------------
   
_print_string:

    mov di, ds                      ;-------------------
    mov es, di                      ;-------------------

    mov rdi, rbx                    ;-------------------
    call _get_len                   ;get string's length

    mov rdx, rdi                    ;save string's length

    PRINT_STRING qword [out_descriptor], rbx, rdx
    ret 

;------------------------------------------------------------------------
;specifier mode processing. Print number in decimal number system
;------------------------------------------------------------------------
;Expected:  out_descriptor 
;Entre:     rbx - number 
;Exit:      none
;Destroy:   rax, rdx, rsi, rdi 
;------------------------------------------------------------------------
   
_print_dec_num:

    nop
    ret 

;------------------------------------------------------------------------
;specifier mode processing. Print number in hexical number system
;------------------------------------------------------------------------
;Expected:  out_descriptor 
;Entre:     rbx - number 
;Exit:      none
;Destroy:   rax, rdx, rsi, rdi 
;------------------------------------------------------------------------
   
_print_hex_num:

    xor rcx, rcx
    mov cl, 0x40 	                ;counter

.next:

    sub cl, 0x04 				    ;decrement counter
    
    mov rdx, 0x0f			        ;hex mask
    
    shl rdx, cl      		        ;shift mask

    and rdx, rbx				    ;get cur symbol
    shr rdx, cl       			    ;move to rdx

    mov rsi, Ascii_table
    
    add rsi, '0'
    add rsi, rdx

    cmp dx, 0x0a
    jb .not_letter

    sub rsi, 0x0a
    add rsi, 0x31

.not_letter:

    push rcx    ;save to stack rcx, beccause syscall change rcx

    PRINT_STRING qword [out_descriptor], rsi, 0x01

    pop rcx     ;get rcx from stack

    cmp cl, 0x00
    jne .next


    PRINT_STRING qword [out_descriptor], Ascii_table + 'h', 0x01

    ret 

;------------------------------------------------------------------------
;specifier mode processing. Print number in binary number system
;------------------------------------------------------------------------
;Expected:  out_descriptor 
;Entre:     rbx - number 
;Exit:      none
;Destroy:   rax, rdx, rsi, rdi 
;------------------------------------------------------------------------
   
_print_bin_num:

    nop
    ret 

;------------------------------------------------------------------------
;specifier mode processing. Print number in octal number system
;------------------------------------------------------------------------
;Expected:  out_descriptor 
;Entre:     rbx - number 
;Exit:      none
;Destroy:   rax, rdx, rsi, rdi 
;------------------------------------------------------------------------
   
_print_oct_num:

    nop
    ret 

section .data

out_descriptor: dq 0x00
            
msg:        db "%h", 0xa, TERM_CHAR
string:     db "good bad", TERM_CHAR



