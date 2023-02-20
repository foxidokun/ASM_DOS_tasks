; -----------------------------------------------------------------------------
; StrLen: strlen(str)
; si -- string pointer
; return: bx -- strlen
; expects: cld
; destroys: ax (si bx) 
; -----------------------------------------------------------------------------

StrLen proc
    mov bx, si

@@iter:  
    lodsw                   ; load byte
    
    test al, al
    jz @@first_zero         ; test first byte
    test ah, ah
    jz @@second_zero        ; test second byte

    jmp @@iter

    @@first_zero:           ; return  si - bx - 1
        sub si, bx
        lea bx, [si - 1]
        ret

    @@second_zero:          ; return si - bx
        sub si, bx
        mov bx, si
        ret
endp 


; -----------------------------------------------------------------------------
; MemCpy: memcpy(dest, src, n)
; si -- src
; di -- dest
; cx -- bytes to copy
; return: none
; expects: cld
; destroys: al (si di cx)
; -----------------------------------------------------------------------------
MemCpy proc
    mov al, cl
    and al, 1b  ; al = cx % 2

    shr cx, 1   ; cx /= 2
    rep movsw   ; move cx words

    test al, al ; move last byte if needed
    jnz @@exit
    movsb

    @@exit:
        ret
endp MemCpy

; -----------------------------------------------------------------------------
; StrCpy: strcpy(dest, src)
; ds:si -- src
; es:di -- dest
; return: none
; expects: cld
; destroys: ax (si di)
; -----------------------------------------------------------------------------
StrCpy proc
    @@copy_byte_loop:
        lodsw
        
        test al, al
        jz @@first_zero

        test ah, ah
        jz @@second_zero

        stosw               ; No zeros -- copy whole word
    jmp @@copy_byte_loop

    @@second_zero: ; Copy last byte and ret
        stosb
    @@first_zero:  ; Ret
        ret

endp StrCpy


; -----------------------------------------------------------------------------
; MemSet: memset(dest, byte, count)
; es:di -- dest
; al -- byte
; cx -- count
; return: none
; destroys: (di)
; expects: cld
; -----------------------------------------------------------------------------
MemSet proc
    rep stosb
    ret
endp MemSet

; -----------------------------------------------------------------------------
; MemCmp: memcmp(lhs, rhs, count)
; ds:si -- lhs
; es:di -- rhs
; cx -- count
; return: cmp flags
; destroys: al
; expects: cld
; -----------------------------------------------------------------------------

MemCmp proc
    mov al, cl
    and al, 1b  ; al = cx % 2
    shr cx, 1

    repz cmpsw
    jne @@exit
    jcxz @@exit

    test al, al ; compare last byte if needed
    jz @@exit
    cmpsb

    @@exit:
        ret

endp MemCmp

; -----------------------------------------------------------------------------
; StrCmp: strcmp(lhs, rhs)
; ds:si -- lhs
; es:di -- rhs
; return: cmp flags
; destroys: al
; expects: cld
; -----------------------------------------------------------------------------
StrCmp proc
@@compare_loop:
    cmpsb

    jne @@exit

    mov al, [si]
    test al, al
    jz @@lhs_zero

    mov al, [di]
    test al, al
    jz @@only_rhs_zero

    loop @@compare_loop

@@lhs_zero:
    mov al, [di]
    test al, al
    jz @@only_lhs_zero
    xor al, al ; Set z flag to 1
    ret

@@only_lhs_zero:
    mov al, 0FFh 
    inc al  ; Set Carry Flag = 1
    xor al, al ; Set Zero Flag = 1
    ret 

@@only_rhs_zero:
    xor al, al
    inc al      ; Set zero flag = 0
@@exit:
    ret

endp StrCmp