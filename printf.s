; nasm -f elf64 -l printf.lst printf.s  ;  ld -s -o printf printf.o

%include "src/generals.s"
%include "config.s"


static _specificator_processing:function

static _print_char:function

static _print_string:function

static _print_int_dec_num:function

static _print_hex_rep:function

static _print_oct_rep:function

static _print_bin_rep:function

static _print_num_rep:function

section .text

global _start                  ; predefined entry point name for ld

_start:    
    
    push 127d
    push 33d
    push 100d
    push 3802d
    push string
    push -1d
    
    push msg
    push CONSOL_OUT
    call _print

    add sp, 0x08 * 8d

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

    call _print_int_dec_num
    jmp .end_switch

.print_switch_hex_num:

    call _print_hex_rep
    jmp .end_switch

.print_switch_oct_num:

    call _print_oct_rep
    jmp .end_switch

.print_switch_bin_num:

    call _print_bin_rep
    jmp .end_switch

.print_switch_defaulte:
    sub r12, 0x08                   ;another specifier does not require a parameter

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
                        .print_switch_defaulte, \
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
                        .print_switch_hex_num

Cnt_print_mode equ ($ - .start_print_switch) >> 0x03 ;count print's mode 

section .text

;------------------------------------------------------------------------
;specifier mode processing. Print character
;------------------------------------------------------------------------
;Expected:  out_descriptor 
;Entre:     rbx - ascii code symbol 
;Exit:      none
;Destroy:   rax, rbx, rdx, rsi, rdi 
;------------------------------------------------------------------------
   
_print_char:

    add rbx, Ascii_table
    PRINT_STRING qword [out_descriptor], rbx, 0x01
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
   
_print_int_dec_num:

    test ebx, dword [Int_min_val]   ;------------------------
    je .not_negative                ;chec is negative number?

    xor eax, eax                    ;--------------------------------
    sub eax, ebx                    ;translate from additional format

    cmp eax, ebx                    ;----------------------
    jne .not_int_min                 ;check value is integer?

    mov rbx, Int_min_str            ;-------------------
    call _print_string              ;print Int_min_value

    ret

.not_int_min:

    mov ebx, eax

    PRINT_STRING qword [out_descriptor], Ascii_table + '-', 0x01

.not_negative:

    std

    mov di, ds
    mov es, di

    mov rdi, temp_string + BUFFER_SIZE - 0x01   ;buffer address where we will write
    mov byte [rdi], TERM_CHAR                   ;set to buffer terminatee character
    dec rdi

    mov ecx, 0x0a                   ;divider

.next:

    mov eax, ebx                    ;--------------
    xor edx, edx                    ;--------------
    div ecx                         ;get last digit

    xchg eax, edx                   ;change the remainder and quotient

    mov ebx, edx                    ;save quotient

    add al, '0'                     ;ascii code character

    stosb                           ;set to buffer current character

    cmp ebx, 0x00                   ;check num is zero
    jne .next

    inc rdi                         ;------------------
    mov rbx, rdi                    ;get correct temp_string address

    call _print_string              ;print temp_string 

    ret 

;------------------------------------------------------------------------
;specifier mode processing. Print number in bin number system
;------------------------------------------------------------------------
;Expected:  out_descriptor 
;Entre:     rbx - number
;Exit:      none
;Destroy:   rax, rbx, cx, rdx, rsi, rdi 
;------------------------------------------------------------------------
   
_print_hex_rep:

    mov rdx, Hex_digit
    mov cl, 0x04
    call _print_num_rep

    PRINT_STRING  qword [out_descriptor], Ascii_table + 'h', 0x01

    ret 

;------------------------------------------------------------------------
;specifier mode processing. Print number in bin number system
;------------------------------------------------------------------------
;Expected:  out_descriptor 
;Entre:     rbx - number
;Exit:      none
;Destroy:   rax, rbx, cx, rdx, rsi, rdi 
;------------------------------------------------------------------------
   
_print_oct_rep:

    mov rdx, Oct_digit
    mov cl, 0x03
    call _print_num_rep

    PRINT_STRING  qword [out_descriptor], Ascii_table + 'o', 0x01

    ret 

;------------------------------------------------------------------------
;specifier mode processing. Print number in bin number system
;------------------------------------------------------------------------
;Expected:  out_descriptor 
;Entre:     rbx - number
;Exit:      none
;Destroy:   rax, rbx, cx, rdx, rsi, rdi 
;------------------------------------------------------------------------
   
_print_bin_rep:

    mov rdx, Bin_digit
    mov cl, 0x01
    call _print_num_rep

    PRINT_STRING  qword [out_descriptor], Ascii_table + 'b', 0x01

    ret 

;------------------------------------------------------------------------
;specifier mode processing. Print number in second degree system
;------------------------------------------------------------------------
;Expected:  out_descriptor 
;Entre:     rbx - number, rdx - print digit format, cl - power 2
;Exit:      none
;Destroy:   rax, rbx, cx, rdx, rsi, rdi 
;------------------------------------------------------------------------
   
_print_num_rep:

   std

    mov di, ds
    mov es, di

    mov rdi, temp_string + BUFFER_SIZE - 0x01   ;buffer address where we will write
    
    mov al, TERM_CHAR                           ;set to buffer terminatee character
    stosb                         

    mov ch, 0x01                                ;--------
    shl ch, cl                                  ;--------
    dec ch                                      ;get mask                  

    xor ax, ax

.next:

    mov al, bl                      ;save cur number to rsi       
    and al, ch                      ;get last digit

    mov al, byte [rdx + rax]  ;get character in hex representation

    stosb                           ;set to buffer current character

    shr rbx, cl                     ;next digit

    cmp rbx, 0x00                   ;check num is zero
    jne .next

    inc rdi                         ;------------------
    mov rbx, rdi                    ;get correct temp_string address

    call _print_string              ;print temp_string

    ret 

section .data

out_descriptor: dq 0x00

temp_string: times BUFFER_SIZE db 0x00
            
msg:        db "%d %s %x %d%%%c%b", 0xa, TERM_CHAR
string:     db "Love", TERM_CHAR



