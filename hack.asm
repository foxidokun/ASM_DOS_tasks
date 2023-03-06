.286
.model tiny
locals @@
.code
org 100h

Start: call VerifyPass

    mov ax, 4c00h ; exit(0)
    int 21h


VerifyPass proc
    push bp
    mov bp, sp

    mov si, ds
    mov es, si

    sub sp, 2 * pass_length ; create local bufs

    mov si, offset pass     ; Load good pass
    lea di, [bp - pass_length]
    mov cx, pass_length
    rep movsb

    lea bx, [bp - 2 * pass_length]
@@get_pass_loop:
    mov ah, 01h
    int 21h
    cmp al, 0dh
    je @@scan_end

    mov [bx], al
    inc bx
jmp @@get_pass_loop

@@scan_end:
    mov cx, pass_length

    lea si, [bp - pass_length]
    lea di, [bp - 2*pass_length]

@@compare_loop:
    cmpsb
    jne @@bad_end
loop @@compare_loop


@@good_end:
    mov ah, 09h
    mov dx, offset good_str
    int 21h
    jmp @@end
@@bad_end:
    mov ah, 09h
    mov dx, offset bad_str
    int 21h
@@end:
    add sp, 2*pass_length

    pop bp
    ret
endp 


pass: db "Wee-Wee"
pass_length = $ - pass

good_str: db "Welcome to the club buddy$"
bad_str:  db "Hey buddy, I think you've got the wrong door, the hacker club's two blocks down$"

end Start
