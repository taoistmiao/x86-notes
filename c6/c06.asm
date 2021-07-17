; 2021-07-15
; Boot sector code update

jmp near start

mytext db 'L',0x07,'a',0x07,'b',0x07,'e',0x07,'l',0x07,' ',0x07,'o',0x07,\
            'f',0x07,'f',0x07,'s',0x07,'e',0x07,'t',0x07,':',0x07
number db 0,0,0,0,0

start:
    ; set base address
    mov ax, 0x7c0
    mov ds, ax

    mov ax, 0xb800
    mov es, ax

    cld  ; clear the direction flag, low to high (std: set)
    mov si, mytext  ; offset of the source
    mov di, 0  ; offset of the destination
    mov cx, (number - mytext) / 2  ; number of bytes/words being copied
    rep movsw  ; repeat copying until cx is 0

    mov ax, number  ; label's offset

    ; calculate value on different positions of "number"
    mov bx, ax  ; pointer to number
    mov cx, 5  ; number of loop
    mov si, 10
digit:
    xor dx, dx
    div si
    mov [bx], dl  ; store
    inc bx
    loop digit

    ; show each number
    mov bx, number
    mov si, 4
show:
    mov al, [bx+si]
    add al, 0x30  ; get corresponding ASCII code
    mov ah, 0x04  ; property of character
    mov [es:di], ax
    add di, 2
    dec si
    jns show  ; jump is not "signed" (SF)

    mov word [es:di], 0x0744  ; "D"

    jmp near $

    times 510-($-$$) db 0
    db 0x55,0xaa
