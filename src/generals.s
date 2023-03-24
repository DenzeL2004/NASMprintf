%ifndef _GEN_MAC_
%define _GEN_MAC_

%define TERM_CHAR 0x00      ;terminate string's symbol 

%define CONSOL_DESCRIPTOR 0x01

%define BUFFER_SIZE 0xff    

;----------------------------------------------------------------
;Exit
;----------------------------------------------------------------
;Enter: %1 - exit code
;Exit: N/A
;Destroy: N/A
;----------------------------------------------------------------
%macro EXIT 1
    
    mov rax, 0x3C   ;syscall number
    mov rdi, %1     ;exit code
    syscall

%endmacro

;----------------------------------------------------------------
;print to consol one symbol
;----------------------------------------------------------------
;Enter:     rdi - stdout, rsi - buffer addres, rdx - string's length
;Exit:      none
;Destroy:   rcx, r11
;----------------------------------------------------------------
_puts:

    mov qword [print_out_descriptor], rdi

    cmp rdx, BUFFER_SIZE                        ;-------------------------------------------------------
    jne .cur_string_less_buffer                 ;check length current string is greater than buffer size

    push rsi                                    ;save current string address
    push rdx                                    ;save current string length

    call _print_buffer

    push rsi                                    ;get current string address
    push rdx                                    ;get current string length

    mov rax, 1h                                 ;syscall number
    syscall

    jmp .return

.cur_string_less_buffer:

    mov rcx, BUFFER_SIZE                        ;get the amount of free space in the buffer
    sub rcx, qword [print_buffer_offset]        ;--------------------------------------------------------

    cmp rcx, rdx                                ;-----------------------------------------------------
    jae .buffer_is_not_full                     ;checking if the current word will overflow the buffer

    mov rdi, print_buffer  
    add rdi, qword [print_buffer_offset]
    sub rdx, rcx                                    

    call _memcpy

    push rsi                                    ;save current string address
    push rdx                                    ;save current string length

    call _print_buffer

    push rsi                                    ;get current string address
    push rdx                                    ;get current string length


.buffer_is_not_full:

    mov rdi, print_buffer  
    add rdi, qword [print_buffer_offset]

    mov rcx, rdx                                ;get the number of characters to be copied to the buffer

    call _memcpy

    add qword [print_buffer_offset], rdx        ;change print buffer offset
.return:

    ret


;------------------------------------------------------------------------
;prints the buffered string at the specified descriptor
;------------------------------------------------------------------------
;Expected:  print_out_descriptor
;Entre:     none
;Exit:      print_buffer_offset
;Destroy:   rax, rdi, rsi, rcx, r11
;------------------------------------------------------------------------

_print_buffer:

    mov rdi, qword [print_out_descriptor]

    mov rsi, print_buffer                       ;buffer address
    mov rdx, qword [print_buffer_offset]        ;the length of the word in the buffer 

    mov rax, 1h                                 ;syscall number
    syscall

    mov qword [print_buffer_offset], 0x00       ;buffer is free

    ret

section .text

;------------------------------------------------------------------------
;Get string lenrth
;------------------------------------------------------------------------
;Expected:  string end by terminate symbol 
;Entre:     es - segment, rdi - string's address
;Exit:      rdi - length
;Destroy:   rdi, rsi
;------------------------------------------------------------------------

_get_len:

    mov rsi, rdi
    dec rdi

.next:
    inc rdi

    cmp byte [rdi], TERM_CHAR
    jne .next

    sub rdi, rsi            ;calc length

    ret


;------------------------------------------------------------------------
;copy n symbols from src to dst string
;------------------------------------------------------------------------ 
;Entry:     rdi - destination address, rsi - source address, rcx - conter
;Exit:      rdi
;Destroy:   rdi, rsi, rcx, df
;------------------------------------------------------------------------
_memcpy:

    cld 

    rep movsb               ;copy from source to destination

    ret 




section .data

print_out_descriptor:   dq 0x00

print_buffer_offset:    dq 0x00
print_buffer:           times BUFFER_SIZE db 0x00


section .rodata 

Int_min_val: dd 0x80000000
Int_min_str: db "-2147483648", TERM_CHAR

Hex_digits:   db "0123456789abcdef"
Oct_digits:   db "01234567"
Bin_digits:   db "01"

%endif

