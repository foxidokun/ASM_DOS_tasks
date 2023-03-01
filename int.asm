.286
.model tiny
locals @@
.code
org 100h
 
HOTKEY_CODE equ 36h
COLOR equ 4eh

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

include lib\format.asm
include lib\draw.asm

New09hInt proc
        push ax

        in al, 60h       ; read from port 60h
        
        cmp al, HOTKEY_CODE
        jne @@continue_chain

        push bp 
        mov bp, sp
        push bx cx dx es ds si di ; save registers

;       stack frame:
;
;       -----------------
;       | bp-1 | ax     |
;       | bp   | old bp |
;       | bp+1 | bx     |
;       | bp+2 | cx     |
;       | bp+3 | dx     |
;       | bp+4 | es     |
;       | bp+5 | ds     |
;       | bp+6 | si     |
;       | bp+7 | di     |
;       -----------------

        mov dx, cs
        mov ds, dx

        mov bx, 0b800h ; es -> videomem
        mov es, bx

        mov ah, COLOR  ; put color attr
        mov di, 160d - 2*9d ; Offset = linelen - frame width
        mov cx, 7d          ; inner length = strlen("AX XXXX")
        mov si, offset color_scheme
        mov dl, 6d          ; inner height = 6 (AX BX CX DX SI DI)
        call DrawFrame      ; Draw frame

        mov di, 2*160d - 16d
        mov al, "A"
        stosw
        mov al, "X"
        stosw
        
        inc di
        inc di

        mov dx, [bp-1]      ; Load ax
        call PrintHex       ; Print ax    

        pop di si ds es dx cx bx ; restore registers 
        pop bp

@@continue_chain:
        in al, 61h
        or al, 80h
        out 61h, al
        and al, not 80h
        out 61h, al

        mov al, 20h
        out 20h, al

        pop ax

        pushf
        db 09ah         ; call far
Old09Ofs dw 0
Old09Seg dw 0

        iret
endp New09hInt

color_scheme         db 0dah, 0c4h, 0bfh, 0b3h, 0h, 0b3h, 0c0h, 0c4h, 0d9h, 4eh ; Сегменты LT, CT, RT, LM, CM, RM, LB, CB, RB + Color (left/center/right + top/middle/bottom)

ProgramEnd:

end     Start
