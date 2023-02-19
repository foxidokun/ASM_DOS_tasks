; -----------------------------------------------------------------------------
; DrawLine
; ah -- color attr
; es:di -- dest
; cx -- inner length
; bh -- first symbol
; bl -- last symbol
; dh -- inner symbol
; return: none
; expects: es --> videomem
; destroys: al (al cx di)
; -----------------------------------------------------------------------------
DrawLine proc
    mov al, bh
    stosw

    mov al, dh
    rep stosw

    mov al, bl
    stosw

    ret
endp DrawLine

; -----------------------------------------------------------------------------
; DrawFrame
; ah -- color attr
; es:di -- Top Left corner offset
; cx -- inner length
; si -- pointer to symbols array (see frame_symbols)
; dl -- inner height
; return: none
; expects: es --> videomem
; destroys: al (bx di dx cx)
; -----------------------------------------------------------------------------
DrawFrameOneLineMacro macro
    push cx
    call DrawLine
    pop cx

    sub di, cx
    sub di, cx
    add di, 160d - 4d ; move to next row
endm DrawFrameOneLineMacro

DrawFrame proc
    mov bh, [si + 0]        ; Load header line symbols
    mov dh, [si + 1]
    mov bl, [si + 2]

    DrawFrameOneLineMacro   ; Draw Header line

    mov bh, [si + 3]        ; Load inner line symbols
    mov dh, [si + 4]
    mov bl, [si + 5]
    
    @@inner_loop:
        DrawFrameOneLineMacro   ; Draw inner line
        dec dl
        test dl, dl
    jnz @@inner_loop
    
    mov bh, [si + 6]        ; Load bottom line symbols
    mov dh, [si + 7]
    mov bl, [si + 8]

    DrawFrameOneLineMacro   ; Draw bottom line

    ret
endp DrawFrame

; -----------------------------------------------------------------------------
; DrawText
; ah -- color attr
; si -- pointer to src
; di -- pointer to dest
; expects: es --> videomem
; return: none
; destroys: al (si di)
; -----------------------------------------------------------------------------
DrawText proc

@@copy_loop:
    lodsb
    test al, al
    jz @@exit
    stosw
    jmp @@copy_loop

@@exit:
    ret
endp DrawText

; -----------------------------------------------------------------------------
; DrawFrameWithText
; si -- pointer to symbols array (see frame_symbols)
; es:di -- offset
; ax -- string pointer
; cx -- inner length
; dl -- inner height
; expects: es --> videomem
; return: none
; destroys: al (si di)
; -----------------------------------------------------------------------------
DrawFrameWithText proc
    push ax ; Save registers
    push dx ; Save dl
    push di
    mov ah, [si + 9]
    call DrawFrame ; Draw frame
    
    pop di ; Restore di
    pop dx ; Restore dl
    mov ax, 80d
    mul dl
    add ax, 4  ; Ax = dl * 80d = (dl/2) * 160d
    add di, ax ; Change offset
    
    mov ah, [si + 9] ; Restore color attr
    pop si  ; Restore string pointer (ax to si)

    call DrawText

    ret
endp DrawFrameWithText


; -----------------------------------------------------------------------------

; frame_symbols db 0dah, 0c4h, 0bfh, 0b3h, 0b0h, 0b3h, 0c0h, 0c4h, 0d9h, 4eh ; Сегменты LT, CT, RT, LM, CM, RM, LB, CB, RB + Color (left/center/right + top/middle/bottom)