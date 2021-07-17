; 2021-07-16

jmp near start

message:
    db '1+2+3+...+100='

start:
    mov ax, 0x7c0
    mov ds, ax

    mov ax, 0xb800
    mov es, ax

    mov si, message
    mov di, 0
    mov cx, start - message

    ; Show the content of the message
    show_m:
        mov al, [si]
        mov ah, 0x07
        mov [es:di], ax
        add di, 2
        inc si
        loop show_m

    ; calculate sum of 1 to 100
    xor ax, ax
    mov cx, 100
    grow:
        add ax, cx
        loop grow

    ; individual number on different position
    xor cx, cx
    mov ss, cx
    mov sp, cx

    mov bx, 10
    xor cx, cx
    divide:
        inc cx
        xor dx, dx
        div bx
        or dl, 0x30  ; 0000_xxxx or(+) 0011_0000
        push dx
        cmp ax, 0
        jne divide

    ; show the content of numbers
    show_d:
        pop dx
        mov dh, 0x07
        mov [es:di], dx
        add di, 2
        loop show_d
    
    jmp near $

    times 510-($-$$) db 0
    db 0x55,0xaa
