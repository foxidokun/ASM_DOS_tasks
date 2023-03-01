; -----------------------------------------------------------------------------
; HEX Print
; di -- points to memory
; ah -- color
; dx -- value
; 
; expects: es -> videomem
; return: di points after last symbol
; destroys: al bx (di)
; -----------------------------------------------------------------------------

PrintByteMacro macro BYTE
    mov bl, BYTE    ; load first byte
    shr bl, 4       ; get first 4bits
    mov al, [symbols + bx]
    stosw

    mov bl, BYTE    ; load first byte
    and bl, 0Fh     ; get last 4bits
    mov al, [symbols + bx]
    stosw
endm

PrintHex proc
    xor bx, bx

    PrintByteMacro dh
    PrintByteMacro dl

    ret
endp PrintHex


symbols db "0123456789ABCDEF"