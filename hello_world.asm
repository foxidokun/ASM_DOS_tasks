.model tiny
.code

org 100h

start:
    mov ah, 09h                 ; puts (dx)
    mov dx, offset Message      ; dx = Message
    int 21h

    ret
    
.data
Message db "Wellcum back. Again$"

end start