; hardware interrupt

SECTION header vstart=0
    program_length dd program_end

    ; entry point
    code_entry      dw start
                    dd section.code.start
    
    realloc_tbl_len dw (header_end - realloc_begin) / 4

    realloc_begin:
        code_segment    dd section.code.start
        data_segment    dd section.data.start
        stack_segment   dd section.stack.start
    
    header_end:

SECTION code align=16 vstart=0
    start:
        ; initialize segment registers
        mov ax, [stack_segment]
        mov ss, ax
        mov sp, ss_pointer
        mov ax, [data_segment]
        mov ds, ax

        ; print initial messages
        mov bx, init_msg
        call put_string

        mov bx, inst_msg
        call put_string

        ; calculate offset of 0x70 interrupt in IVT
        mov al, 0x70
        mov bl, 4
        mul bl
        mov bx, ax

        ; modify the IVT for 0x70 interrupt
        cli

        push es
        mov ax, 0x0000
        mov es, ax
        mov word [es:bx], new_int_0x70  ; offset address
        mov word [es:bx+2], cs  ;segment address
        pop es

        ; configure RTC
        mov al, 0x0b    ; access register B
        or al, 0x80 ; block NMI
        out 0x70, al
        mov al, 0x12    ; set register B
        out 0x71, al    

        mov al, 0x0c
        out 0x70, al
        in al, 0x71 ; read register C to clear it

        ; configure 8259
        in al, 0xa1
        and al, 0xfe ; clear IMR for bit 0
        out 0xa1, al

        sti

        mov bx, done_msg
        call put_string
        mov bx, tips_msg
        call put_string

        mov cx, 0xb800
        mov ds, cx
        mov byte [12*160 + 33*2], '@'

    .idle:
        hlt
        not byte [12*160+33*2+1]
        jmp .idle

    new_int_0x70:
        push ax
        push bx
        push cx
        push dx
        push es

        ; wait for the data stable
        .w0:            
            mov al, 0x0a
            or al, 0x80
            out 0x70, al
            in al, 0x71
            test al, 0x80
            jnz .w0

        ; read second
        xor al, al
        or al, 0x80
        out 0x70, al
        in al, 0x71
        push ax
        ; read minute
        mov al, 2
        or al, 0x80
        out 0x70, al
        in al, 0x71
        push ax
        ; read hour
        mov al, 4
        or al, 0x80
        out 0x70, al
        in al, 0x71
        push ax
        ; clear register C
        mov al, 0x0c
        out 0x70, al
        in al, 0x71

        mov ax, 0xb800
        mov es, ax

        ; convert hour to ascii
        pop ax
        call bcd_to_ascii
        mov bx, 12*160 + 36*2
        ; print hour
        mov [es:bx], ah
        mov [es:bx+2], al
        ; print ":"
        mov al, ':'
        mov [es:bx+4], al
        not byte [es:bx+5]

        ; convert minute to ascii
        pop ax
        call bcd_to_ascii
        ; print minute
        mov [es:bx+6], ah
        mov [es:bx+8], al
        ; print ":"
        mov al, ':'
        mov [es:bx+10], al
        not byte [es:bx+11]

        ; convert second to ascii
        pop ax
        call bcd_to_ascii
        ; print second
        mov [es:bx+12], ah
        mov [es:bx+14], al
        
        mov al, 0x20
        out 0xa0, al
        out 0x20, al

        pop es
        pop dx
        pop cx
        pop bx
        pop ax

        iret   
    
    ; convert BCD to ASCII
    ; input: al -> bcd code
    ; output: ax -> ascii code
    bcd_to_ascii:
        mov ah, al
        and al, 0x0f
        add al, 0x30

        shr ah, 4
        and ah, 0x0f
        add ah, 0x30

        ret

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

SECTION data align=16 vstart=0
    init_msg    db 'Starting ...',0x0d,0x0a,0

    inst_msg    db 'Installing a new interrupt 70H...',0

    done_msg    db 'Done.',0x0d, 0x0a,0

    tips_msg    db 'Clock is now working.',0

SECTION stack align=16 vstart=0
    resb 256
    ss_pointer:

SECTION program_trail
    program_end:
