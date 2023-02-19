.model tiny
locals @@

.code
    org 100h

; Params
; Y 
; X
; Height
; Width
; Type

; -----------------------------------------------------------------------------

start:
    mov si, 82h
    call ReadNumber ; Read y
    mov al, 160d
    mul bl
    mov di, ax      ; offset = 160 * y 
    
    call ReadNumber ; Read x
    shl bx, 1
    add di, bx      ; offset += 2*x (two bytes per char)

    call ReadNumber ; Read height
    mov dl, bl      ; Store 

    call ReadNumber ; Read width
    mov dh, bl      ; Temp store width in dh

    call ReadNumber

    push dx 
    call SetColorScheme
    pop dx

    xor ch, ch
    mov cl, dh         ; Load width to cx

    mov ax, 0b800h
    mov es, ax

    push dx         
    call ReadLine
    mov ax, dx
    pop dx          ; Load height from stack

    call DrawFrameWithText

    mov ax, 4c00h ; exit(0)
    int 21h

    include lib\draw.asm

; -----------------------------------------------------------------------------
; Choose color scheme
; input: bl -- number of color scheme
; return: si -- pointer to symbol array
; destroys: ax bx dx
; -----------------------------------------------------------------------------

load_symbol_macro macro ARRAY, NUM
    mov ah, 09h
    mov dx, offset ARRAY
    int 21h

    mov ah, 01h
    int 21h
    mov color_scheme_user[NUM], al

    mov ah, 02h
    mov dl, 0dh ; \r
    int 21h
    mov dl, 0ah ; \n
    int 21h
endm 

SetColorScheme proc
    cmp bl, 5
    je @@input
    
    dec bl
    mov al, 10
    mul bl
    mov bx, ax
    lea si, [bx + offset color_scheme_1]
    jmp @@exit
@@input:
    load_symbol_macro color_invite_string_LT 0
    load_symbol_macro color_invite_string_CT 1
    load_symbol_macro color_invite_string_RT 2
    load_symbol_macro color_invite_string_LM 3
    load_symbol_macro color_invite_string_CM 4
    load_symbol_macro color_invite_string_RM 5
    load_symbol_macro color_invite_string_LB 6
    load_symbol_macro color_invite_string_CB 7
    load_symbol_macro color_invite_string_RB 8

    mov si, offset color_scheme_user
@@exit:
    ret
endp SetColorScheme

; -----------------------------------------------------------------------------
; Read Number From String
; si -- input string
; return: bl -- number
;         si -- points to next symbol after first not digit
; destroys: cx ax
; -----------------------------------------------------------------------------

ReadNumber proc
    cld
    xor bx, bx

    mov ch, 10d

@@loop_scan:
    lodsb
    sub al, '0'
    jb @@exit
    cmp al, 9d
    ja @@exit

    mov cl, al
    mov al, bl
    mul ch         ; ax = 10al
    add al, cl
    mov bl, al
    jmp @@loop_scan

@@exit:
    ret
endp ReadNumber

; -----------------------------------------------------------------------------
; Read string From stdin
; return: dx -- pointer to null-terminated string
; destroys: ah, bx
; -----------------------------------------------------------------------------

ReadLine proc
    mov ah, 09h
    mov dx, offset text_invite_string
    int 21h

    mov ah, 0aH
    mov dx, offset input_array

    int 21h
    
    add dx, 2
    mov bx, dx
    mov ah, [bx - 1] ; Load len of input
    add bl, ah
    adc bh, 0

    mov byte ptr [bx], 00h    
    
    ret
endp ReadLine

.data
color_scheme_1         db 0dah, 0c4h, 0bfh, 0b3h, 0b0h, 0b3h, 0c0h, 0c4h, 0d9h, 4eh ; Сегменты LT, CT, RT, LM, CM, RM, LB, CB, RB + Color (left/center/right + top/middle/bottom)
color_scheme_2         db 0dah, 0c4h, 0bfh, 0b3h, 0b0h, 0b3h, 0c0h, 0c4h, 0d9h, 4eh ; Сегменты LT, CT, RT, LM, CM, RM, LB, CB, RB + Color (left/center/right + top/middle/bottom)
color_scheme_3         db 0dah, 0c4h, 0bfh, 0b3h, 0b0h, 0b3h, 0c0h, 0c4h, 0d9h, 4eh ; Сегменты LT, CT, RT, LM, CM, RM, LB, CB, RB + Color (left/center/right + top/middle/bottom)
color_scheme_4         db 0dah, 0c4h, 0bfh, 0b3h, 0b0h, 0b3h, 0c0h, 0c4h, 0d9h, 4eh ; Сегменты LT, CT, RT, LM, CM, RM, LB, CB, RB + Color (left/center/right + top/middle/bottom)
color_scheme_user      db 10 dup(4eh)
input_array            db 81 dup(79) ; For 21h::0ah. Max len = 79 bytes (78 max + '\0') [+2 for len and max]
color_invite_string_LT db "Symbol for left top corner: $"
color_invite_string_CT db "Symbol for top horizontal line: $"
color_invite_string_RT db "Symbol for right top corner: $"
color_invite_string_LM db "Symbol for left vertical line: $"
color_invite_string_CM db "Symbol for inner cells: $"
color_invite_string_RM db "Symbol for right vertical line: $"
color_invite_string_LB db "Symbol for left bottom corner: $"
color_invite_string_CB db "Symbol for bottom horizontal line: $"
color_invite_string_RB db "Symbol for right bottom corner: $"
text_invite_string     db "Input text: $"


test_str db "Hello world!", 00h

end start