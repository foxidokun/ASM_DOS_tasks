.286
.model tiny
locals @@
.code
org 100h
 
HOTKEY_CODE equ 36h
COLOR equ 4eh
REGISTER_NUM equ 10d

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

; -----------------------------------------------------------------------------
; Print Reg Macro: load args + call PrintReg
PrintRegMacro macro NAME_H, REG_OFFSET
        mov dx, [ REG_OFFSET ]      ; Load ax
        mov bx, NAME_H
        call PrintReg
        add di, 160d - 2 * 7d
endm PrintByteMacro

; -----------------------------------------------------------------------------
; New 09h Interrupt Handler
; -----------------------------------------------------------------------------

New09hInt proc
        push ax

        in al, 60h    ; read scan code from port 60h
        
        cmp al, HOTKEY_CODE     ; compare pressed key with hotkey
        je @@hotkey_pressed   ; ignore interrupt if it is not hotkey
        jmp cs:@@continue_chain ; long jump needed

@@hotkey_pressed:
        push bp 
        mov bp, sp
        push bx cx dx es ds si di ss ; save registers                   ;       |  stack frame  |
                                                                        ;       -----------------
        mov dx, cs              ; set ds to our segment                 ;       | bp-1 | ax     |
        mov ds, dx                                                      ;       | bp   | old bp |
                                                                        ;       | bp+1 | bx     |
        mov bx, 0b800h          ; es -> videomem                        ;       | bp+2 | cx     |
        mov es, bx                                                      ;       | bp+3 | dx     |
                                                                        ;       | bp+4 | es     |
        mov ah, COLOR           ; put color attr                        ;       | bp+5 | ds     |
        mov di, 2*160d - 2*9d   ; Offset = line +linelen - frame width  ;       | bp+6 | si     |
        mov cx, 7d              ; inner length = strlen("AX XXXX")      ;       | bp+7 | di     |
        mov si, offset color_scheme                                     ;       | bp+8 | ss     |
        mov dl, REGISTER_NUM    ; inner height = 10 registers           ;       -----------------
        call DrawFrame          ; Draw frame

        mov di, 3*160d - 16d    ; Set di to first pos in frame

        PrintRegMacro "AX" bp-1 ; Print registers one by one
        PrintRegMacro "BX" bp+1
        PrintRegMacro "CX" bp+2
        PrintRegMacro "DX" bp+3
        PrintRegMacro "SI" bp+6
        PrintRegMacro "DI" bp+7
        PrintRegMacro "BP" bp
        PrintRegMacro "DS" bp+5
        PrintRegMacro "ES" bp+4
        PrintRegMacro "SS" bp+8

        pop ss di si ds es dx cx bx ; restore registers 
        pop bp

@@continue_chain:
        pop ax

        db 0eah         ; jmp far
Old09Ofs dw 0           ; jmp Offset
Old09Seg dw 0           ; jmp Segment

endp New09hInt

; -----------------------------------------------------------------------------
; Reg Print
; di -- pointer to first pos
; ah -- color
; dx -- value
; bh -- First letter
; bl -- Second letter
; 
; expects: es -> videomem
; return: di points after last symbol
; destroys: al bx (di)
; -----------------------------------------------------------------------------
PrintReg proc
        mov al, bh
        stosw
        mov al, bl
        stosw
        
        inc di
        inc di

        call PrintHex       ; Print ax 
        ret  
endp

color_scheme         db 0dah, 0c4h, 0bfh, 0b3h, 0h, 0b3h, 0c0h, 0c4h, 0d9h, 4eh ; Сегменты LT, CT, RT, LM, CM, RM, LB, CB, RB + Color (left/center/right + top/middle/bottom)

ProgramEnd:

end     Start
