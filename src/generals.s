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

    add qword [print_buffer_offset], rdx        ;
.return:

    ret

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
;Destroy:   al, rdi, df
;------------------------------------------------------------------------

_get_len:

    cld      

    mov al, TERM_CHAR
    mov rsi, rdi            ;save start address

    dec rdi
.next:
    inc rdi 

    cmp byte [rdi], al
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

Hex_digit:   db "0123456789abcdef"
Oct_digit:   db "01234567"
Bin_digit:   db "01"

Ascii_table: db 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, \
                0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f, \
                0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f, \
                0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f, \
                0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f, \
                0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f, \
                0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f, \
                0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7a, 0x7b, 0x7c, 0x7d, 0x7e, 0x7f, \
                0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8a, 0x8b, 0x8c, 0x8d, 0x8e, 0x8f, \
                0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9d, 0x9e, 0x9f, \
                0xa0, 0xa1, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7, 0xa8, 0xa9, 0xaa, 0xab, 0xac, 0xad, 0xae, 0xaf, \
                0xb0, 0xb1, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xbb, 0xbc, 0xbd, 0xbe, 0xbf, \
                0xc0, 0xc1, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xcb, 0xcc, 0xcd, 0xce, 0xcf, \
                0xd0, 0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xdb, 0xdc, 0xdd, 0xde, 0xdf, \
                0xe0, 0xe1, 0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea, 0xeb, 0xec, 0xed, 0xee, 0xef, \
                0xf0, 0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd, 0xfe, 0xff  



%endif

