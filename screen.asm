.model tiny
locals @@

color_attr equ 4eh

.code
    org 100h

start:   
    mov ax, 0b800h
    mov es, ax

    mov bx, 13228d
    mov di, offset free_mem
    call FormatHex

    mov ah, color_attr
    mov si, offset free_mem
    mov di, 160d * 5 + 80
    mov bx, offset symbols
    mov cx, message_len + 15

    call StrPrint

    mov ax, 4c00h
    int 21h

; -----------------------------------------------------------------------------
; FormatHex
; ax -- number
; di -- pointer to buf
; destroys: si, cx
; return: none
; -----------------------------------------------------------------------------
FormatHex proc
    cld
    
    mov cx, 2
    mov word ptr [di], 'x0'
    add di, 2

@@begin: 
    mov si, ax
    and si, 0F000h
    shr si, 12d
    add si, offset hexsymbols
    mov ch, [si]
    mov [di], ch
    inc di

    mov si, ax
    and si, 0F00h
    shr si, 8d
    add si, offset hexsymbols
    mov ch, [si]
    mov [di], ch
    inc di

    mov ah, al
    xor ch, ch
    loop @@begin

    mov word ptr [di], '$h'

    ret
endp FormatHex

; -----------------------------------------------------------------------------
; StrPrint
; ah -- color attr
; si -- string pointer
; di -- offset
; bx -- pointer to symbols array
; cx -- strlen
; expects es -> videoseg
; return: none
; destroys: al
; -----------------------------------------------------------------------------
StrPrint proc
    sub di, 160d        ; Move cursor to prev line
    add cx, 2           ; sizeof(string) = 2 * strlen (+ color codes) + 2*2 (whitespaces)
    sal cx, 1

    mov al, [bx]        ; Reassig reg due to memory indexing limitations
    push si
    mov si, bx
    mov bx, cx

    mov al, [si]                ; Left top angle
    mov byte ptr es:[di], al

    mov al, [si + 2]
    mov byte ptr es:[di + bx], al   ; Right top angle

    mov al, [si + 4]
    mov byte ptr es:[di + bx + 2*160d], al  ; Right bottom

    mov al, [si + 5]
    mov byte ptr es:[di + 2*160d], al       ; Left bottom

    mov al, [si + 3]
    mov byte ptr es:[di + 160d], al
    mov byte ptr es:[di + bx + 160d], al

    mov bx, 0
    sub cx, 1
    sar cx, 1
    add di, 2d
    @@box_print_loop:
        mov al, [si + 1]
        mov es:[di + bx], al
        mov es:[di + bx + 2*160d], al
        add bx, 2
    loop @@box_print_loop
    
    mov bx, si  ; Return registers to normal values
    pop si

    add di, 160d + 2d ; Return pointer to text row

    cld
    @@load_loop:        ; Copy string from memory to string
        lodsb
        cmp al, '$'
        je @@return

        stosw
    jmp @@load_loop
    
    @@return:
    ret
endp StrPrint

; -----------------------------------------------------------------------------
; DATA
; -----------------------------------------------------------------------------

.data
message db "1000-7$"
message_len equ $ - message
symbols db 0dah, 0c4h, 0bfh, 0b3h, 0d9h, 0c0h ; сегменты LT, CM, RT, RM, RB, LB (left/center/right top/middle/bottom)
hexsymbols db "0123456789ABCDEF"

free_mem: db "FINDME$"
end start