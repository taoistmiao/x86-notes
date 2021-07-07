; 2021-07-06
; Boot sector code

; set base address for VRAM (Video RAM) in text mode
mov ax, 0xb800  ; mov general register, immediate operand
mov es, ax  ; mov segment register, general register/ memory unit

; print string "Label offset:"
; every character corresponds to two bytes: ASCII + property
mov byte [es:0x00], 'L'
mov byte [es:0x01], 0x07

mov byte [es:0x02], 'a'
mov byte [es:0x03], 0x07

mov byte [es:0x04], 'b'
mov byte [es:0x05], 0x07

mov byte [es:0x06], 'e'
mov byte [es:0x07], 0x07

mov byte [es:0x08], 'l'
mov byte [es:0x09], 0x07

mov byte [es:0x0a], ' '
mov byte [es:0x0b], 0x07

mov byte [es:0x0c], "o"
mov byte [es:0x0d], 0x07

mov byte [es:0x0e], 'f'
mov byte [es:0x0f], 0x07

mov byte [es:0x10], 'f'
mov byte [es:0x11], 0x07

mov byte [es:0x12], 's'
mov byte [es:0x13], 0x07

mov byte [es:0x14], 'e'
mov byte [es:0x15], 0x07

mov byte [es:0x16], 't'
mov byte [es:0x17], 0x07

mov byte [es:0x18], ':'
mov byte [es:0x19], 0x07

; get label offset
mov ax, number
mov bx, 10

; set base address of data segment
mov cx, cs
mov ds, cx

; 1's number
mov dx, 0
div bx
mov [0x7c00+number+0x00], dl

; 10's number
xor dx, dx  ; clear dx
div bx
mov [0x7c00+number+0x01], dl

; 100's number
xor dx, dx  ; clear dx
div bx
mov [0x7c00+number+0x02], dl

; 1000's number
xor dx, dx  ; clear dx
div bx
mov [0x7c00+number+0x03], dl

; 1000_0's number
xor dx, dx  ; clear dx
div bx
mov [0x7c00+number+0x04], dl

; print offset in decimal
; start from left
mov al, [0x7c00+number+0x04]
add al, 0x30    ; convert to ASCII code
mov [es:0x1a], al
mov byte [es:0x1b], 0x04    ; red character in black bg

mov al, [0x7c00+number+0x03]
add al, 0x30    ; convert to ASCII code
mov [es:0x1c], al
mov byte [es:0x1d], 0x04

mov al, [0x7c00+number+0x02]
add al, 0x30    ; convert to ASCII code
mov [es:0x1e], al
mov byte [es:0x1f], 0x04

mov al, [0x7c00+number+0x01]
add al, 0x30    ; convert to ASCII code
mov [es:0x20], al
mov byte [es:0x21], 0x04

mov al, [0x7c00+number+0x00]
add al, 0x30    ; convert to ASCII code
mov [es:0x22], al
mov byte [es:0x23], 0x04

mov byte [es:0x24], 'D'
mov byte [es:0x25], 0x07

infi:
    jmp near infi

number:
    db 0, 0, 0, 0, 0

times 203 db 0
dw 0xaa55
