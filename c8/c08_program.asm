; c08 user program
; 2021-07-30

SECTION header vstart=0
    program_length  dd program_end  ; size of the program

    code_entry      dw start
                    dd section.code_1.start
    
    realloc_tbl_len dw (header_end - code_1_segment) / 4  ; number of entries of reallocation table

    ; reallocation table
    code_1_segment  dd section.code_1.start
    code_2_segment  dd section.code_2.start
    data_1_segment  dd section.data_1.start
    data_2_segment  dd section.data_2.start
    stack_segment  dd section.stack.start

    header_end:

SECTION code_1 align=16 vstart=0
    ; print a string ended with '0'
    ; input: ds:bx => address of the string
    put_string:
        push cx 

        .anchor:
            mov cl, [bx]
            or cl, cl  ; modify the flag
            jz .exit
            call put_char
            inc bx
            jmp .anchor

        .exit:
            pop cx
            ret

    ; print a signle character
    ; input: cl => ascii code of the character
    put_char:
        push ax
        push bx
        push dx
        push es

        ; get the cursor position
        mov dx, 0x3d4  ; index port
        mov al, 0x0e  ; specify register of higher 8-bit
        out dx, al
        mov dx, 0x3d5  ; data port
        in al, dx
        mov ah, al

        mov dx, 0x3d4
        mov al, 0x0f  ; specify register of lower 8-bit
        out dx, al
        mov dx, 0x3d5  ; data port
        in al, dx  ; ax holds the current position of cursor
        mov bx, ax

        ; check if the charater is CR
        cmp cl, 0x0d
        jnz .put_0a
        mov bl, 80
        div bl
        mul bl
        mov bx, ax  ; bx holds the next position of cursor
        jmp .set

        ; check if LF
        .put_0a:
            cmp cl, 0x0a
            jnz .put_other
            add bx, 80
            call .roll_screen  ; possible overflow of the screen
            jmp .set

        ; normal visible character
        .put_other:
            mov ax, 0xb800
            mov es, ax
            shl bx, 1  ; one character takes 2 bytes in graphic memory
            mov [es:bx], cl

            ; move cursor
            shr bx, 1
            inc bx
            call .roll_screen  ; possible overflow of the screen

        .set:
            call .set_cursor
        
        pop es
        pop dx
        pop bx 
        pop ax

        ret

    ; check if the text exceeds the screen
    ; input: bx => position of the cursor
    .roll_screen:
        push ax
        push cx
        push ds
        push es

        cmp bx, 2000
        jl .exit_1
        ; move text up a line
        mov ax, 0xb800
        mov ds, ax
        mov es, ax
        cld
        mov si, 0xa0
        mov di, 0x00
        mov cx, 1920
        rep movsw  ; [ds:si] -> [es:di]
        ; move the bottom line
        mov bx, 3840
        mov cx, 80
        .cls:
            mov word [es:bx], 0x0720
            add bx, 2
            loop .cls

        mov bx, 1920
        
        .exit_1:
            pop es
            pop ds
            pop cx
            pop ax

            ret

    ; set cursor 
    ; input: bx => position of the cursor
    .set_cursor:
        push ax
        push dx

        ; higher 8 bits
        mov dx, 0x3d4
        mov al, 0x0e
        out dx, al
        mov dx, 0x3d5
        mov al, bh
        out dx, al
        ; lower 8 bits
        mov dx, 0x3d4
        mov al, 0x0f
        out dx, al
        mov dx, 0x3d5
        mov al, bl
        out dx, al

        pop dx
        pop ax

        ret

    ; entry point of the program
    start:
        ; stack setting
        mov ax, [stack_segment]
        mov ss, ax
        mov sp, stack_end

        ;data segment setting
        mov ax, [data_1_segment]
        mov ds, ax

        ;print the first paragraph
        mov bx, msg0
        call put_string

        push word [es:code_2_segment]
        mov ax, begin
        push ax

        retf
    
    continue:
        mov ax, [es:data_2_segment]
        mov ds, ax

        mov bx, msg1
        call put_string

        jmp $

    
SECTION code_2 align=16 vstart=0
    begin:
        push word [es:code_1_segment]
        mov ax, continue
        push ax

        retf

SECTION data_1 align=16 vstart=0
    msg0 db '  This is NASM - the famous Netwide Assembler. '
         db 'Back at SourceForge and in intensive development! '
         db 'Get the current versions from http://www.nasm.us/.'
         db 0x0d,0x0a,0x0d,0x0a
         db '  Example code for calculate 1+2+...+1000:',0x0d,0x0a,0x0d,0x0a
         db '     xor dx,dx',0x0d,0x0a
         db '     xor ax,ax',0x0d,0x0a
         db '     xor cx,cx',0x0d,0x0a
         db '  @@:',0x0d,0x0a
         db '     inc cx',0x0d,0x0a
         db '     add ax,cx',0x0d,0x0a
         db '     adc dx,0',0x0d,0x0a
         db '     inc cx',0x0d,0x0a
         db '     cmp cx,1000',0x0d,0x0a
         db '     jle @@',0x0d,0x0a
         db '     ... ...(Some other codes)',0x0d,0x0a,0x0d,0x0a
         db 0
        
SECTION data_2 align=16 vstart=0
    msg1 db '  The above contents is written by Gilbert. '
         db '2021-07-30'
         db 0
SECTION stack align=16 vstart=0
    resb 256
    stack_end:

SECTION trail align=16
    program_end:
