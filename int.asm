.286
.model tiny
locals @@
.code
org 100h
 
HOTKEY_CODE equ 36h
COLOR equ 4eh
REGISTER_NUM equ 10d

Start:  jmp Main

include lib\format.asm
include lib\draw.asm


; -----------------------------------------------------------------------------
; New 09h Interrupt Handler
; -----------------------------------------------------------------------------
New09hInt proc
        push ax

        in al, 60h    ; read scan code from port 60h
        
        cmp al, HOTKEY_CODE     ; compare pressed key with hotkey
        jne @@continue_chain   ; ignore interrupt if it is not hotkey

        mov al, cs:[IsOverlayActive]
        xor al, 1
        mov cs:[IsOverlayActive], al

@@continue_chain:
        pop ax

        db 0eah         ; jmp far
Old09Ofs dw 0           ; jmp Offset
Old09Seg dw 0           ; jmp Segment

endp New09hInt


; -----------------------------------------------------------------------------
; New 08h Interrupt Handler
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Print Reg Macro: load args + call PrintReg
PrintRegMacro macro NAME_H, REG_OFFSET
        mov dx, [ REG_OFFSET ]      ; Load ax
        mov bx, NAME_H
        call PrintReg
        add di, 160d - 2 * 7d
endm PrintByteMacro

New08hInt proc
        push ax

        mov al, cs:[IsOverlayActive]
        test al, al
        jnz @@active     ; ignore interrupt if not activated
        jmp cs:@@continue_chain ; long jump needed

@@active:
        push bp 
        mov bp, sp
        push bx cx dx si di ds es ss ; save registers                   ;       |  stack frame  |
                                                                        ;       -----------------
        mov dx, cs              ; set ds to our segment                 ;       | bp-1 | ax     |
        mov ds, dx                                                      ;       | bp   | old bp |
                                                                        ;       | bp+1 | bx     |
        mov bx, 0b800h          ; es -> videomem                        ;       | bp+2 | cx     |
        mov es, bx                                                      ;       | bp+3 | dx     |
                                                                        ;       | bp+4 | si     |
        mov ah, COLOR           ; put color attr                        ;       | bp+5 | di     |
        mov di, 160d - 2*9d   ; Offset = line +linelen - frame width    ;       | bp+6 | ds     |
        mov cx, 7d              ; inner length = strlen("AX XXXX")      ;       | bp+7 | es     |
        mov si, offset color_scheme                                     ;       | bp+8 | ss     |
        mov dl, REGISTER_NUM    ; inner height = 10 registers           ;       -----------------
        call DrawFrame          ; Draw frame

        mov di, 2*160d - 16d    ; Set di to first pos in frame

        PrintRegMacro "AX" bp-1 ; Print registers one by one
        PrintRegMacro "BX" bp+1
        PrintRegMacro "CX" bp+2
        PrintRegMacro "DX" bp+3
        PrintRegMacro "SI" bp+4
        PrintRegMacro "DI" bp+5
        PrintRegMacro "BP" bp
        PrintRegMacro "DS" bp+6
        PrintRegMacro "ES" bp+7
        PrintRegMacro "SS" bp+8

        pop ss es ds di si dx cx bx ; restore registers 
        pop bp

@@continue_chain:
        pop ax

        db 0eah         ; jmp far
Old08Ofs dw 0           ; jmp Offset
Old08Seg dw 0           ; jmp Segment

endp New08hInt

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
IsOverlayActive      db 00h

HandlersCodeEnd:

Main:   
        xor bx, bx              ; Set es = 0
        mov es, bx
        mov bx, 8*4             ; Bx = offset (int 8h)

        mov ax, es:[bx]         ; Save offset of old handler
        mov [Old08Ofs], ax
        mov ax, es:[bx+02]      ; Save segment of old handler
        mov [Old08Seg], ax

        mov ax, es:[bx+04]         ; Save offset of old handler
        mov [Old09Ofs], ax
        mov ax, es:[bx+06]      ; Save segment of old handler
        mov [Old09Seg], ax

        cli                     ; Write new offset + segment
        mov es:[bx], offset New08hInt
        mov ax, cs
        mov es:[bx+2], ax
        mov es:[bx+6], ax
        mov es:[bx+4], offset New09hInt
        sti

        mov ax, 3100h                   ; Exit without releasing dx pages of memory
        mov dx, offset HandlersCodeEnd
        shr dx, 4
        inc dx
        int 21h

end     Start
