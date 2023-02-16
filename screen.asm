.model tiny
locals @@

color_attr equ 4eh

.code
    org 100h

start:   
    call InputNumber
    mov di, offset free_mem
    
    ; mov ax, bx
    ; push bx
    ; call FormatDec
    ; pop bx
    ; mov di, offset free_mem + 6d ; 5 digits + '$'
    
    ; mov si, bx
    ; call FormatHex
    ; mov bx, si
    
    mov di, offset free_mem; + strlen (0xAAAAh$)
    call FormatBin

    mov ax, 0b800h
    mov es, ax
    mov ah, color_attr
    mov si, offset free_mem
    mov di, 160d * 3 + 80
    mov bx, offset box_symbols
    call StrPrint

    mov bx, offset box_symbols
    mov si, offset free_mem + 6d
    mov di, 160d * 6 + 80
    call StrPrint

    mov bx, offset box_symbols
    mov si, offset free_mem + 6d + 8d
    mov di, 160d * 9 + 80
    call StrPrint

    mov ax, 4c00h
    int 21h

; -----------------------------------------------------------------------------
; InputNumber read number from keyboard
; input: none
; destroys: dx, cx, si
; return: bx -- number
; -----------------------------------------------------------------------------

InputNumber proc
    xor bx, bx
    xor cx, cx
    
    mov dx, offset invite_string ; printf (invite_string)
    mov ah, 09h
    int 21h

    mov si, 10d ; For mul instruction

@@read_loop:
    mov ah, 01H ; Keyboard Input (char -> al)
    int 21h

    cmp al, "$"
    je @@exit

    sub al, "0"
    mov cl, al

    mov ax, bx
    mul si
    add ax, cx
    mov bx, ax

    jmp @@read_loop

@@exit: ret

endp InputNumber

; -----------------------------------------------------------------------------
; FormatDec Format number as decimal string to es:di
; ax -- number
; di -- pointer to buf
; destroys: si, dx, bx, cl
; return: none
; -----------------------------------------------------------------------------

FormatDec proc
    cld
    xor dx, dx

    mov si, 10d

    mov bx, 5 ; No more than 5 digits

    @@format_loop:
        dec bx
        xor dx, dx
        div si
        
        add dx, "0"
        mov es:[di + bx], dl

        test bx, bx
    jne @@format_loop

    mov byte ptr [di + 5], "$"

    ret

endp FormatDec

; -----------------------------------------------------------------------------
; FormatBin Format number as binary string to es:di
; bx -- number
; di -- pointer to buf
; destroys: ax, cx
; return: none
; -----------------------------------------------------------------------------
FormatBin proc
    cld
    mov word ptr [di], 'b0' ; Add "0b" to string begining
    add di, 2

    mov cx, 16 ; loop for 16 bits

    @@format_bit_loop:
        mov ax, bx
        and ax, 8000h  ; Extract frst bit
        shr ax, 15
        add al, "0" ; Convert to char
        
        stosb
        shl bx, 1
    loop @@format_bit_loop

    mov byte ptr [di], '$'
    ret
endp FormatBin


; -----------------------------------------------------------------------------
; FormatHex Format number as Hex string to es:di
; bx -- number
; di -- pointer to buf
; destroys: si, cx
; return: none
; -----------------------------------------------------------------------------
FormatHex proc
    cld
    
    mov word ptr [di], 'x0' ; Add "0x" to string begining
    add di, 2
    
    mov cx, 2   ; Loop for two bytes
@@format_byte_loop: 
    mov si, bx
    and si, 0F000h  ; Extract 4 bits
    shr si, 12d
    add si, offset hex_symbols ; Convert to char
    movsb

    mov si, bx   ; Same with other 4 bits
    and si, 0F00h
    shr si, 8d
    add si, offset hex_symbols
    movsb

    mov bh, bl
    xor ch, ch
loop @@format_byte_loop

    mov word ptr [di], '$h'

    ret
endp FormatHex

; -----------------------------------------------------------------------------
; StrPrint
; ah -- color attr
; si -- string pointer
; di -- offset
; bx -- pointer to box_symbols array
; expects es -> videoseg
; return: none
; destroys: al, cx
; -----------------------------------------------------------------------------
StrPrint proc
    cld
    xor cx, cx
    
    add di, 2d          ; Add trailing whitespace to text
    @@print_loop:       ; Copy string & count len
        lodsb
        inc cx
        cmp al, '$'
        je @@print_loop_exit
        stosw
        jmp @@print_loop
    @@print_loop_exit:

    sub si, cx  ; Return string pointer

    sal cx, 1   ; cx := sizeof (string) aka 2*cx (2 bytes per char)
    sub di, cx  ; Return dest pointer (2 bytes per char)

    sub di, 160d + 2d   ; Move cursor to prev line & return to the original column
    add cx, 4           ; Add two whitespaces (4 bytes)

    mov si, bx ; Reassig reg due to memory indexing limitations
    mov bx, cx

    mov al, [si]                ; Left top angle
    mov byte ptr es:[di], al

    mov al, [si + 2]
    mov byte ptr es:[di + bx], al   ; Right top angle

    mov al, [si + 4]
    mov byte ptr es:[di + bx + 2*160d], al  ; Right bottom

    mov al, [si + 5]
    mov byte ptr es:[di + 2*160d], al       ; Left bottom

    mov al, [si + 3]                    ; Box 
    mov byte ptr es:[di + 160d], al
    mov byte ptr es:[di + bx + 160d], al

    xor bx, bx
    sub cx, 1   ; Return cx to strlen
    sar cx, 1   
    add di, 2d  ; Move cursor to text column
    @@box_print_loop:
        mov al, [si + 1]
        mov es:[di + bx], al
        mov es:[di + bx + 2*160d], al
        add bx, 2
    loop @@box_print_loop
    
    @@return:
    ret
endp StrPrint

; -----------------------------------------------------------------------------
; DATA
; -----------------------------------------------------------------------------

.data
invite_string db "Please input number: $"
box_symbols db 0dah, 0c4h, 0bfh, 0b3h, 0d9h, 0c0h ; сегменты LT, CM, RT, RM, RB, LB (left/center/right top/middle/bottom)
hex_symbols db "0123456789ABCDEF"

free_mem: db "FINDME$"
end start