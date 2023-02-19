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

set_color_scheme macro
    cmp bl, 5
    je @@input
    
    dec bl
    mov al, 10
    mul bl
    mov bx, ax
    lea si, [bx + offset color_scheme_1]

@@input:
endm

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
    set_color_scheme

    xor ch, ch
    mov cl, dh         ; Load width to cx

    mov ax, 0b800h
    mov es, ax

    push dx         ; Temp store height in stack
    call ReadLine
    mov ax, dx
    pop dx          ; Load height from stack

    call DrawFrameWithText

    mov ax, 4c00h ; exit(0)
    int 21h

    include lib\draw.asm

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
    mov dx, offset invite_string
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
color_scheme_1    db 0dah, 0c4h, 0bfh, 0b3h, 0b0h, 0b3h, 0c0h, 0c4h, 0d9h, 4eh ; Сегменты LT, CT, RT, LM, CM, RM, LB, CB, RB + Color (left/center/right + top/middle/bottom)
color_scheme_2    db 0dah, 0c4h, 0bfh, 0b3h, 0b0h, 0b3h, 0c0h, 0c4h, 0d9h, 4eh ; Сегменты LT, CT, RT, LM, CM, RM, LB, CB, RB + Color (left/center/right + top/middle/bottom)
color_scheme_3    db 0dah, 0c4h, 0bfh, 0b3h, 0b0h, 0b3h, 0c0h, 0c4h, 0d9h, 4eh ; Сегменты LT, CT, RT, LM, CM, RM, LB, CB, RB + Color (left/center/right + top/middle/bottom)
color_scheme_4    db 0dah, 0c4h, 0bfh, 0b3h, 0b0h, 0b3h, 0c0h, 0c4h, 0d9h, 4eh ; Сегменты LT, CT, RT, LM, CM, RM, LB, CB, RB + Color (left/center/right + top/middle/bottom)
color_scheme_user db 10 dup('#')
input_array       db 81 dup(79) ; For 21h::0ah. Max len = 79 bytes (78 max + '\0') [+2 for len and max]
invite_string     db "Input text: $"

test_str db "Hello world!", 00h

end start