.286
.model tiny
locals @@
.code
org 100h
 
HOTKEY_CODE equ 36h          ; Right Shift press
HOTKEY_CODE_RELEASE equ 0b6h ; Right Shift release
COLOR equ 4eh
REGISTER_NUM equ 10d    
TEXT_WIDTH equ 7d       ;inner length = strlen("AX XXXX")      
FIRST_FRAME_POS = 0d
OFFSET_BETWEEN_LINES = 160d - 2*(TEXT_WIDTH+2) ; start of new line - end of old line

Start:  jmp Main

include lib\format.asm
include lib\draw.asm


; -----------------------------------------------------------------------------
; New 09h Interrupt Handler
; -----------------------------------------------------------------------------
; Check pressed key:
; If it is HOTKEY => save/restore screen area & exit
; Else => call original interrupt handler
; -----------------------------------------------------------------------------

New09hInt proc
        push ax

        in al, 60h    ; read scan code from port 60h
        
        cmp al, HOTKEY_CODE_RELEASE
        je @@ignore_key_and_exit        ; Ignore if hotkey is released
        cmp al, HOTKEY_CODE    ; compare pressed scan code with hotkey
        jne @@continue_chain   ; ignore interrupt if it is not hotkey

        mov al, cs:[IsOverlayActive] ; Invert bool flag
        xor al, 1
        mov cs:[IsOverlayActive], al

        test al, al
        jz @@restore_screen ; Restore screen if flag is false

        push ds es cx di si    
        
        mov cx, cs ; Prepare args for CopyBetweenBuffers
        mov es, cx ; es = current segment because of save_buf
        mov cx, 0b800h          
        mov ds, cx ; ds = videomem because we are copying from screen
        mov di, offset save_buf + FIRST_FRAME_POS
        mov si, FIRST_FRAME_POS
        mov cl, TEXT_WIDTH+2    ; +2 frame borders
        mov dl, REGISTER_NUM+2  ; +2 frame borders

        call CopyBetweenBuffers ; Save current screnn to saved buff

        pop si di cx es ds
        jmp @@ignore_key_and_exit

@@restore_screen:
        push ds es cx di si
        
        mov cx, cs      ; Set ds to current segment
        mov ds, cx
        mov cx, 0b800h
        mov es, cx      ; es --> videomem
        mov si, offset save_buf + FIRST_FRAME_POS ; set src offsets
        mov di, FIRST_FRAME_POS                   ; set dst offset
        mov cl, TEXT_WIDTH+2                      ; +2 frame borders
        mov dl, REGISTER_NUM+2                    ; +2 frame borders

        call CopyBetweenBuffers ; Restore screen from saved buff

        pop si di cx es ds

@@ignore_key_and_exit:
        in al, 61h      ; Blink highest bit in keyboard port
        or al, 80h
        out 61h, al
        and al, not 80h
        out 61h, al
        mov al, 20h     ; Restore interrupt controller
        out 20h, al

        pop ax
        iret

@@continue_chain:
        pop ax

        db 0eah         ; jmp far
Old09Ofs dw 0           ; jmp Offset
Old09Seg dw 0           ; jmp Segment

endp New09hInt


; -----------------------------------------------------------------------------
; New 08h Interrupt Handler
; -----------------------------------------------------------------------------
; Print interrupted progmram's regs with funny frame if activation flag is true
; Then call original interrupt handler
; -----------------------------------------------------------------------------

New08hInt proc
        cli
        push ax

        mov al, cs:[IsOverlayActive]
        test al, al
        jz @@continue_chain     ; ignore interrupt if not activated

@@active:
        push bp 
        mov bp, sp
        push bx cx dx si di ds es ss ; save registers                   

        mov dx, cs              ; set ds to our segment                 
        mov ds, dx                                                      


        mov bx, 0b800h
        mov es, bx
        mov bx, offset save_buf + FIRST_FRAME_POS
        mov di, FIRST_FRAME_POS
        mov si, offset draw_buf + FIRST_FRAME_POS
        call UpdateSavedBuffer

        mov bx, cs              ; es -> videomem
        mov es, bx      
        mov ah, COLOR           ; Draw frame into intermediate buffer
        mov di, offset draw_buf + FIRST_FRAME_POS                                                
        call DrawFrameWithRegs

        mov bx, 0b800h          ; Copy internal buffer to screen
        mov es, bx
        mov si, offset draw_buf + FIRST_FRAME_POS
        mov di, FIRST_FRAME_POS
        mov cl, TEXT_WIDTH + 2   ; +2 frame borders 
        mov dl, REGISTER_NUM + 2 ; +2 frame borders
        call CopyBetweenBuffers

        pop ss es ds di si dx cx bx ; restore registers 
        pop bp

        @@continue_chain:
        pop ax

        db 0eah         ; jmp far
Old08Ofs dw 0           ; jmp Offset
Old08Seg dw 0           ; jmp Segment

endp New08hInt

; -----------------------------------------------------------------------------
; DrawFrameWithRegs: Draw frame into es:di buffer with registers name & value
; -----------------------------------------------------------------------------
; input: ah -- color attr
;        es:di -- offset
; input: (stack from bottom to top) ax bp bx cx dx si di ds es ss
; -----------------------------------------------------------------------------
; expects: es -->videomem
; -----------------------------------------------------------------------------
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
;       --------------------
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

        push di
        mov cx, TEXT_WIDTH
        mov si, offset color_scheme
        mov dl, REGISTER_NUM    ; inner height = 10 registers           
        call DrawFrame          ; Draw frame

        pop di
        add di, 160d + 2d ; Set di to first pos in frame

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
; PrintReg: Print register to es:di with given color
; -----------------------------------------------------------------------------
; ah -- color
; bh -- First reg name's letter
; bl -- Second reg name's letter
; dx -- value
; di -- pointer to first pos
; -----------------------------------------------------------------------------
; expects: es -> videomem
; -----------------------------------------------------------------------------
; return: di points after last symbol
; -----------------------------------------------------------------------------
; destroys: al bx (di)
; -----------------------------------------------------------------------------
PrintReg proc
        mov al, bh      ; Print first letter
        stosw
        mov al, bl      ; Print second letter
        stosw
        
        inc di          ; di += sizeof(" ") = 2 bytes
        inc di

        call PrintHex   ; Print ax 
        ret  
endp

; -----------------------------------------------------------------------------
; CopyBetweenBuffers: copy screen area from one frame buffer to another
; -----------------------------------------------------------------------------
; ds:si -- top left corner offset
; es:di -- buffer offset
; cl -- length
; dl -- height
; -----------------------------------------------------------------------------
; return: none
; -----------------------------------------------------------------------------
; destroys: cx (dl di si)
; -----------------------------------------------------------------------------
CopyBetweenBuffers proc
        xor ch, ch

@@str_loop:
        mov dh, cl
        rep movsw  ; Copy one line
        mov cl, dh

        add di, OFFSET_BETWEEN_LINES ; move cursor to new line
        add si, OFFSET_BETWEEN_LINES

        dec dl
        test dl, dl
        jnz @@str_loop ; iterate for next line

        ret
endp CopyBetweenBuffers


; -----------------------------------------------------------------------------
; UpdateSavedBuffer: save diff(videomem, draw_buf) to save_buf
; -----------------------------------------------------------------------------
; ax    -- height (in rows)
; cx    -- length (in bytes)
; es:di -- pointer to top left corner in videomem
; ds:bx -- pointer to top left corner in save_buf
; ds:si -- pointer to top left corner in draw_buf
; -----------------------------------------------------------------------------
; return: none
; -----------------------------------------------------------------------------
; destroys:
; -----------------------------------------------------------------------------
UpdateSavedBuffer proc
        push ax cx dx
        xor cx, cx
    
        mov ax, REGISTER_NUM+2
    @@update_height_loop:
        mov cx, 2*TEXT_WIDTH+4
    
        @@update_width_loop:
            mov dl, es:[di]
            mov dh, cs:[si]

            cmp dl, dh
            je @@not_update
            mov cs:[bx], dx

            @@not_update:
            inc bx
            inc di
            inc si
        loop @@update_width_loop
        
        add bx, OFFSET_BETWEEN_LINES
        add si, OFFSET_BETWEEN_LINES
        add di, OFFSET_BETWEEN_LINES
        dec ax
        test ax, ax
        jnz @@update_height_loop

        pop dx cx ax
        ret
endp UpdateSavedBuffer


; -----------------------------------------------------------------------------
; Data Section
; -----------------------------------------------------------------------------
color_scheme         db 0dah, 0c4h, 0bfh, 0b3h, 0h, 0b3h, 0c0h, 0c4h, 0d9h, 4eh ; Сегменты LT, CT, RT, LM, CM, RM, LB, CB, RB + Color (left/center/right + top/middle/bottom)
IsOverlayActive      db 00h

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

        mov ax, es:[bx]         ; Save offset of old 08h handler
        mov [Old08Ofs], ax
        mov ax, es:[bx+02]      ; Save segment of old 08h handler
        mov [Old08Seg], ax

        mov ax, es:[bx+04]              ; Save offset of old 09h handler
        mov [Old09Ofs], ax
        mov ax, es:[bx+06]              ; Save segment of old 09h handler
        mov [Old09Seg], ax

        cli                             ; Write new offsets + segments
        mov es:[bx], offset New08hInt   ; 08h offset
        mov ax, cs
        mov es:[bx+2], ax               ; 08h segment
        mov es:[bx+6], ax               ; 09h segment
        mov es:[bx+4], offset New09hInt ; 09h offset
        sti

        mov ax, 3100h                   ; Exit without releasing dx pages of memory
        mov dx, offset HandlersCodeEnd
        shr dx, 4
        inc dx
        int 21h

end     Start
