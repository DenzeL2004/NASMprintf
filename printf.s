; nasm -f elf64 -l printf.lst printf.s  ;  ld -s -o printf printf.o

%include "src/generals.s"
%include "config.s"

global _printf

static print:function

static specificator_processing:function

static print_char:function

static print_string:function

static print_int_dec_num:function

static print_hex_rep:function

static print_oct_rep:function

static print_bin_rep:function

static print_num_rep:function

section .text

;------------------------------------------------------------------------
;wrapper for C function call. SYSCALL 
;------------------------------------------------------------------------
_printf:

    pop qword [return_address]          ;save return address
    
    push r9
    push r8 
    push rcx
    push rdx
    push rsi
    push rdi

    call printf wrt ..plt              

    add rsp, 0x08 * 6d                  ;clearing the stack of arguments

    push qword [return_address]         ;save return address

    ret

;------------------------------------------------------------------------
;print out the string with parameters in the format string. CDECL
;------------------------------------------------------------------------
;Entre:     [rbp + 0x10] - format string address, any number of input parameters
;Exit:      none
;Destroy:   rax, rdx, rsi, rdi
;           r9  - current position in format string, r10 - last not specificator symbol
;           r12 - pointer to input print's parameters 
;------------------------------------------------------------------------

printf:

    push rbp
    mov  rbp, rsp  

    mov r12, 0x10                   ;parameters offset

    mov r9, qword [rbp + r12]       ;start format string address
    mov r10, r9                     ;start format string address

    dec r9                          ;correct format string addreaa

.next:

    inc r9                          ;current string address++

    cmp byte [r9], SPECIFICATOR     ;-----------------------------------
    jne .not_specificator           ;check is cur character specificator

    mov rdx, r9                     ;-----------------
    sub rdx, r10                    ;get length string

    mov rdi, CONSOL_DESCRIPTOR
    mov rsi, r10


    call _puts

    add r12, 0x08                   ;set pointer to input print's parameters
    mov rbx, qword [rbp + r12]
    call specificator_processing

    mov r10, r9                     ;last not specificator symbol address
    dec r9                          ;correct string address
    jmp .next

.not_specificator:

    cmp byte [r9], TERM_CHAR        ;---------------------------------------
    jne .next                       ;check is cur character terminate symbol

    mov rdx, r9                     ;-----------------
    sub rdx, r10                    ;get length string

    mov rdi, CONSOL_DESCRIPTOR
    mov rsi, r10

    call _puts

    mov rax, r12                    ;---------------------------------
    sub rax, rsp                    ;get counter of print's parameters

    call _print_buffer

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
   
specificator_processing:

    inc r9                          ;-----------------------         
    mov al, byte [r9]               ;get specificator's mode 

    sub al, 'b'                     ;subtract the minimum switch's value 
    cmp al, byte Cnt_print_mode
    jae .print_switch_default

    jmp qword [.start_print_switch + rax * 0x08]

.print_switch_char:

    call print_char
    jmp .end_switch

.print_switch_string:

    call print_string
    jmp .end_switch

.print_switch_dec_num:

    call print_int_dec_num
    jmp .end_switch

.print_switch_hex_num:

    call print_hex_rep
    jmp .end_switch

.print_switch_oct_num:

    call print_oct_rep
    jmp .end_switch

.print_switch_bin_num:

    call print_bin_rep
    jmp .end_switch

.print_switch_default:
    xor rbx, rbx
    mov bl, byte [r9]
    call print_char

    sub r12, 0x08                   ;another specifier does not require a parameter

.end_switch:  

    inc r9                          ;move to the next character

    ret 


section .rodata

.start_print_switch: dq .print_switch_bin_num, \
                        .print_switch_char   , \
                        .print_switch_dec_num, \
                        .print_switch_default, \
                        .print_switch_default, \
                        .print_switch_default, \
                        .print_switch_default, \
                        .print_switch_default, \
                        .print_switch_default, \
                        .print_switch_default, \
                        .print_switch_default, \
                        .print_switch_default, \
                        .print_switch_default, \
                        .print_switch_oct_num,  \
                        .print_switch_default, \
                        .print_switch_default, \
                        .print_switch_default, \
                        .print_switch_string , \
                        .print_switch_default, \
                        .print_switch_default, \
                        .print_switch_default, \
                        .print_switch_default, \
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
   
print_char:

    mov byte [temp_string], bl

    mov rdi, CONSOL_DESCRIPTOR
    mov rsi, temp_string
    mov rdx, 0x01

    call _puts
    ret 

;------------------------------------------------------------------------
;specifier mode processing. Print string
;------------------------------------------------------------------------
;Expected:  out_descriptor 
;Entre:     rbx - string's address
;Exit:      none
;Destroy:   rax, rdx, rsi, rdi 
;------------------------------------------------------------------------
   
print_string:

    mov rdi, rbx                    ;-------------------
    call _get_len                   ;get string's length

    mov rdx, rdi                    ;save string's length

    mov rdi, CONSOL_DESCRIPTOR
    mov rsi, rbx

    call _puts
    ret 

;------------------------------------------------------------------------
;specifier mode processing. Print number in decimal number system
;------------------------------------------------------------------------
;Expected:  out_descriptor 
;Entre:     rbx - number 
;Exit:      none
;Destroy:   rax, rdx, rsi, rdi 
;------------------------------------------------------------------------
   
print_int_dec_num:

    test ebx, dword [Int_min_val]   ;------------------------
    je .not_negative                ;chec is negative number?

    xor eax, eax                    ;--------------------------------
    sub eax, ebx                    ;translate from additional format

    cmp eax, ebx                    ;----------------------
    jne .not_int_min                 ;check value is integer?

    mov rbx, Int_min_str            ;-------------------
    call print_string              ;print Int_min_value

    ret

.not_int_min:

    mov ebx, eax

    mov rdi, CONSOL_DESCRIPTOR

    mov byte [temp_string],  '-'
    mov rsi, temp_string

    mov rdx, 0x01

    call _puts

.not_negative:

    std

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

    call print_string              ;print temp_string 

    ret 

;------------------------------------------------------------------------
;specifier mode processing. Print number in bin number system
;------------------------------------------------------------------------
;Expected:  out_descriptor 
;Entre:     rbx - number
;Exit:      none
;Destroy:   rax, rbx, cx, rdx, rsi, rdi 
;------------------------------------------------------------------------
   
print_hex_rep:

    mov rdx, Hex_digits
    mov cl, 0x04
    call print_num_rep

    mov rdi, CONSOL_DESCRIPTOR
    
    mov byte [temp_string],  'h'
    mov rsi, temp_string

    mov rdx, 0x01

    call _puts 

    ret 

;------------------------------------------------------------------------
;specifier mode processing. Print number in bin number system
;------------------------------------------------------------------------
;Expected:  out_descriptor 
;Entre:     rbx - number
;Exit:      none
;Destroy:   rax, rbx, cx, rdx, rsi, rdi 
;------------------------------------------------------------------------
   
print_oct_rep:

    mov rdx, Oct_digits
    mov cl, 0x03
    call print_num_rep

    mov rdi, CONSOL_DESCRIPTOR
    
    mov byte [temp_string],  'o'
    mov rsi, temp_string

    mov rdx, 0x01

    call _puts

    ret 

;------------------------------------------------------------------------
;specifier mode processing. Print number in bin number system
;------------------------------------------------------------------------
;Expected:  out_descriptor 
;Entre:     rbx - number
;Exit:      none
;Destroy:   rax, rbx, cx, rdx, rsi, rdi 
;------------------------------------------------------------------------
   
print_bin_rep:

    mov rdx, Bin_digits
    mov cl, 0x01
    call print_num_rep

    mov rdi, CONSOL_DESCRIPTOR

    mov byte [temp_string],  'b'
    mov rsi, temp_string

    mov rdx, 0x01

    call _puts

    ret 

;------------------------------------------------------------------------
;specifier mode processing. Print number in second degree system
;------------------------------------------------------------------------
;Expected:  out_descriptor 
;Entre:     rbx - number, rdx - print digit format, cl - power 2
;Exit:      none
;Destroy:   rax, rbx, cx, rdx, rsi, rdi 
;------------------------------------------------------------------------
   
print_num_rep:

    std

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

    call print_string              ;print temp_string

    ret 

section .data

temp_string:    times BUFFER_SIZE db 0x00

            
msg:        db "%a%z%# %d %s  %x %d%%%c%b", 0xa, TERM_CHAR
string:     db "Love", TERM_CHAR

return_address: dq 0x00


