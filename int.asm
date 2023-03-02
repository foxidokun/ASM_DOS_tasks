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

New08hInt proc
        push ax

        mov al, cs:[IsOverlayActive]
        test al, al
        jnz @@active     ; ignore interrupt if not activated
        jmp cs:@@continue_chain ; long jump needed

@@active:
        push bp 
        mov bp, sp
        push bx cx dx si di ds es ss ; save registers                   
                                                                        
        mov dx, cs              ; set ds to our segment                 
        mov ds, dx                                                      
                                                                        
        mov bx, 0b800h          ; es -> videomem                        
        mov es, bx                                                      
                                                                        
        call DrawFrameWithRegs

        pop ss es ds di si dx cx bx ; restore registers 
        pop bp

@@continue_chain:
        pop ax

        db 0eah         ; jmp far
Old08Ofs dw 0           ; jmp Offset
Old08Seg dw 0           ; jmp Segment

endp New08hInt

; -----------------------------------------------------------------------------
; DrawFrameWithRegs
; input: (stack from bottom to top) ax bp bx cx dx si di ds es ss
; expects: es -->videomem
;       |   stack frame   |
;       -------------------
;       | bp+10| ax       |
;       | bp+9 | old bp   |
;       | bp+8 | bx       |
;       | bp+7 | cx       |
;       | bp+6 | dx       |
;       | bp+5 | si       |
;       | bp+4 | di       |
;       | bp+3 | ds       |
;       | bp+2 | es       |
;       | bp+1 | ss       |
;       | bp   | caller bp|
;       -------------------
; -----------------------------------------------------------------------------
; Print Reg Macro: load args + call PrintReg
PrintRegMacro macro NAME_H, REG_OFFSET
        mov dx, [ REG_OFFSET ]      ; Load ax
        mov bx, NAME_H
        call PrintReg
        add di, 160d - 2 * 7d
endm PrintByteMacro

DrawFrameWithRegs proc

        mov ah, COLOR           ; put color attr                        
        mov di, 160d - 2*9d   ; Offset = line +linelen - frame width    
        mov cx, 7d              ; inner length = strlen("AX XXXX")      
        mov si, offset color_scheme                                     
        mov dl, REGISTER_NUM    ; inner height = 10 registers           
        call DrawFrame          ; Draw frame

        mov di, 2*160d - 16d    ; Set di to first pos in frame

        PrintRegMacro "AX" bp+1 ; Print registers one by one
        PrintRegMacro "BX" bp-1
        PrintRegMacro "CX" bp-2
        PrintRegMacro "DX" bp-3
        PrintRegMacro "SI" bp-4
        PrintRegMacro "DI" bp-5
        PrintRegMacro "BP" bp
        PrintRegMacro "DS" bp-6
        PrintRegMacro "ES" bp-7
        PrintRegMacro "SS" bp-8

        ret
endp

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
