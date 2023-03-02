.286
.model tiny
locals @@
.code
org 100h
 
HOTKEY_CODE equ 36h     ; Right Shift
COLOR equ 4eh
REGISTER_NUM equ 10d    
TEXT_WIDTH equ 7d       ;inner length = strlen("AX XXXX")      
FIRST_FRAME_POS = 160d - 2*(TEXT_WIDTH+2)

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

        test al, al
        jz @@restore_screen

        push ds es cx di si
        mov cx, cs
        mov es, cx

        mov cx, 0b800h
        mov ds, cx
        mov di, offset save_buf + FIRST_FRAME_POS
        mov si, FIRST_FRAME_POS
        mov cl, TEXT_WIDTH+2
        mov dl, REGISTER_NUM+2

        call CopyBetweenBuffers

        pop si di cx es ds
        jmp @@continue_chain

@@restore_screen:
        push ds es cx di si
        mov cx, cs
        mov ds, cx

        mov cx, 0b800h
        mov es, cx
        mov si, offset save_buf + FIRST_FRAME_POS
        mov di, FIRST_FRAME_POS
        mov cl, TEXT_WIDTH+2
        mov dl, REGISTER_NUM+2

        call CopyBetweenBuffers

        pop si di cx es ds

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
        cli
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
                                                                        
        mov bx, offset draw_buf      ; es -> videomem
        shr bx, 4     
        add bx, dx              
        mov es, bx                                                      
                                                                        
        call DrawFrameWithRegs

        mov bx, 0b800h      
        mov es, bx
        mov si, offset draw_buf + FIRST_FRAME_POS
        mov di, FIRST_FRAME_POS
        mov cl, TEXT_WIDTH + 2
        mov dl, REGISTER_NUM + 2
        call CopyBetweenBuffers

        pop ss es ds di si dx cx bx ; restore registers 
        pop bp

@@continue_chain:
        pop ax

        sti
        db 0eah         ; jmp far
Old08Ofs dw 0           ; jmp Offset
Old08Seg dw 0           ; jmp Segment

endp New08hInt

; -----------------------------------------------------------------------------
; DrawFrameWithRegs
; input: 
; input: (stack from bottom to top) ax bp bx cx dx si di ds es ss
; expects: es -->videomem
;       |   stack frame   |
;       -------------------
;       | bp+22 | ax       |
;       | bp+20 | old bp   |
;       | bp+18 | bx       |
;       | bp+16 | cx       |
;       | bp+14 | dx       |
;       | bp+12 | si       |
;       | bp+10 | di       |
;       | bp+8  | ds       |
;       | bp+6  | es       |
;       | bp+4  | ss       |
;       | bp+2  | ret addr |
;       | bp    | caller bp|
;       -------------------
; -----------------------------------------------------------------------------
; Print Reg Macro: load args + call PrintReg
PrintRegMacro macro NAME_H, REG_OFFSET
        mov dx, [ REG_OFFSET ]      ; Load ax
        mov bx, NAME_H
        call PrintReg
        add di, 160d - 2*TEXT_WIDTH
endm PrintByteMacro

DrawFrameWithRegs proc
        push bp
        mov bp, sp

        mov ah, COLOR                   ; put color attr                        
        mov di, FIRST_FRAME_POS ; Offset = line +linelen - frame width    
        mov cx, TEXT_WIDTH              ; 
        mov si, offset color_scheme                                     
        mov dl, REGISTER_NUM    ; inner height = 10 registers           
        call DrawFrame          ; Draw frame

        mov di, FIRST_FRAME_POS + 160d + 2d ; Set di to first pos in frame

        PrintRegMacro "AX" bp+22 ; Print registers one by one
        PrintRegMacro "BX" bp+18
        PrintRegMacro "CX" bp+16
        PrintRegMacro "DX" bp+14
        PrintRegMacro "SI" bp+12
        PrintRegMacro "DI" bp+10
        PrintRegMacro "BP" bp+20
        PrintRegMacro "DS" bp+8
        PrintRegMacro "ES" bp+6
        PrintRegMacro "SS" bp+4

        pop bp
        ret
endp

; -----------------------------------------------------------------------------
; PrintReg
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
        mov al, bh      ; Print first letter
        stosw
        mov al, bl      ; Print second letter
        stosw
        
        inc di          ; di += sizeof(" ") = 2 bytes
        inc di

        call PrintHex       ; Print ax 
        ret  
endp

; -----------------------------------------------------------------------------
; CopyBetweenBuffers: copy lines from one buffer to another
; ds:si -- top left corner offset
; es:di -- buffer offset
; cl -- length
; dl -- height
;
; return: none
; destroys: cx (dl di si)
; -----------------------------------------------------------------------------
CopyBetweenBuffers proc
        xor ch, ch

@@str_loop:
        mov dh, cl
        rep movsw
        mov cl, dh

        add di, FIRST_FRAME_POS
        add si, FIRST_FRAME_POS

        dec dl
        test dl, dl
        jnz @@str_loop

        ret
endp CopyBetweenBuffers


; -----------------------------------------------------------------------------
; Data Section
; -----------------------------------------------------------------------------
color_scheme         db 0dah, 0c4h, 0bfh, 0b3h, 0h, 0b3h, 0c0h, 0c4h, 0d9h, 4eh ; Сегменты LT, CT, RT, LM, CM, RM, LB, CB, RB + Color (left/center/right + top/middle/bottom)
IsOverlayActive      db 00h

align 16
draw_buf: db 160d * 25d dup(4eh)   ; three buf setup
save_buf: db 160d * 25d dup(4eh)



; ##############################################################################
; SETUP SECTION 
; Set handlers & exit
; ##############################################################################

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
