.model tiny
locals @@

.code
    org 100h

start: 
    mov si, offset teststr  
    call StrLen ; bx = strlen()


    ; mov di, offset teststr
    ; mov al, "@"
    ; lea cx, [bx-1]

    ; call MemSet

    ; mov si, offset teststr
    ; mov di, offset teststr2

    ; call StrCpy

    ; mov ah, 09h
    ; mov dx, offset teststr2
    ; int 21h                     ; print (teststr2)


    mov di, offset teststr
    mov si, offset teststr2
    call StrCmp

    jz str_equ
    ja str_bigger
    jb str_lower

    str_equ:
        mov ah, 09h
        mov dx, offset str_equ_msg
        int 21h
        jmp switch_end
    str_bigger:
        mov ah, 09h
        mov dx, offset str_big_msg
        int 21h
        jmp switch_end
    str_lower:
        mov ah, 09h
        mov dx, offset str_low_msg
        int 21h
        jmp switch_end


    switch_end:
    mov ax, 4c00h   ; exit(0)
    int 21h


include lib\strlib.asm

.data
teststr  db "Wellcome back. Again$", 00h
teststr2 db "Wellcome back. Bgain$", 00h

str_equ_msg db "Equal$"
str_big_msg db "Bigger$"
str_low_msg db "Lower$"

end start