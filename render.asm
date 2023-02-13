.model tiny

.code

org 100h

column_num      equ 2d
row_num         equ 5d
column_sep_size equ 10d


start:
    mov ax, 0b850h ; es points to video mem
    mov es, ax

    ; xor bx, bx -- not needed

    mov byte ptr [free_mem], row_num            ; for ([free_mem]] = row_num; [free_mem] > 0; [free_mem]--)
    column_loop:
        mov dh, column_num                      ; for (dh = column_num; dh > 0; dh--)
        row_loop:
            mov si, offset Message              ; load Message string to screen
            mov cx, message_len
            load_loop:
                mov dl, [si]
                mov byte ptr es:[bx], dl
                lea bx, [bx + 2]
                inc si
            loop load_loop

            lea bx, [bx - message_len * 2]      ; return bx to first char

            mov cx, message_len
            mov dl, 00111110b ; Yellow on red background
            color_loop:
                xor dl, 11110000b ; Switch between two colors
                mov byte ptr es:[bx+1], dl
                lea bx, [bx + 2]
            loop color_loop

            lea bx, [bx + 2 * column_sep_size]                ; move bx to another column

        dec dh
        cmp dh, 0
        jne row_loop


        lea bx, [bx + 160d - 2*(2*10 + 2*message_len)]   ; move bx to next row

        mov al, byte ptr [free_mem]
        dec al
        mov byte ptr [free_mem], al

        cmp byte ptr al, 0

    jne column_loop

    mov ax, 4c00h
    int 21h

.data 
    Message db "Welcome back. Again"
    message_len equ $ - Message                 ; message len

free_mem:                                       ; pointer to free mem

end start