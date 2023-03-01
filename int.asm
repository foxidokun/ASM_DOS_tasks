.286
.model tiny
.code
org 100h
 
Start:  cli
        xor bx, bx
        mov es, bx
        mov bx, 9*4

        mov ax, es:[bx]
        mov [Old09Ofs], ax
        mov ax, es:[bx+02]
        mov [Old09Seg], ax
        mov es:[bx], offset New09hInt
        mov ax, cs
        mov es:[bx+2], ax
        sti

        mov ax, 3100h
        mov dx, offset ProgramEnd
        shr dx, 4
        inc dx
        int 21h

New09hInt proc
        push ax bx es

        mov bx, 0b800h
        mov es, bx
        mov bx, 160*5d + 80d

        mov ah, 4eh
        in al, 60h       ; read from port 60h
        mov es:[bx], ax  ; store in vmem

        in al, 61h
        or al, 80h
        out 61h, al
        and al, not 80h
        out 61h, al

        mov al, 20h
        out 20h, al

        pop es bx ax

        pushf
        db 09ah         ; call far
Old09Ofs dw 0
Old09Seg dw 0

        iret
        endp

ProgramEnd:

end     Start
