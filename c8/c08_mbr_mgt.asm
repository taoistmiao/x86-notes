; c08 mbr
; 2021-07-30

app_lba_start equ 100  ; number of logical sector

SECTION mbr align=16 vstart=0x7c00

        ; set stack segment and pointer
        mov ax, 0
        mov ss, ax
        mov sp, ax

        ; logical segment for user program
        mov ax, [cs:phy_base]  ; low 16 bits
        mov dx, [cs:phy_base+0x02]  ; high 16 bits
        mov bx, 16
        div bx
        mov ds, ax
        mov es, ax

        ; read the start of the program
        xor di, di
        mov si, app_lba_start
        xor bx, bx
        call read_hard_disk_0

        ; calculate the size of the program
        ; read program header
        mov dx, [2]  
        mov ax, [0]
        ; calculate the number of sectors remained
        mov bx, 512
        div bx
        cmp dx, 0
        jnz @1
        dec ax  ; already read one sector

    @1:
        cmp ax, 0  ; size less than 512B
        jz direct

        ; read remaining sectors
        push ds  ; store the header of the program

        mov cx, ax
    @2:
        mov ax, ds
        add ax, 0x20  ; address for next 512B
        mov ds, ax

        xor bx, bx  ; 0 offset
        inc si  ; next logical sector
        call read_hard_disk_0
        loop @2

        pop ds

    
    direct:
        ; calculate the code segment for entry point
        mov dx, [0x08]
        mov ax, [0x06]
        call calc_segment_base
        mov [0x06], ax

        ; process reallocation table
        mov cx, [0x0a]  ; number of entries in table
        mov bx, 0x0c  ; start of table
    realloc:
        mov dx, [bx+0x02]  ; higer 16 bits for 32-bit address
        mov ax, [bx]  ;BUG ax -> dx
        call calc_segment_base
        mov [bx], ax  ; update entry
        add bx, 4  ; next entry
        loop realloc

        jmp far [0x04]  ; transfer control to user program


    ; read a logical sector from storage
    ; input: 
    ;   di_si => (12+16) bits start address of logical sector in LBA28
    ;   ds:bx => destination address of data
    read_hard_disk_0:
        ; register states of caller
        push ax
        push bx
        push cx
        push dx

        ; interact with storage
        ; specify the sectors to be read
        mov dx, 0x1f2
        mov al, 1
        out dx, al
        ; specify the LBA address of the sector
        inc dx
        mov ax, si
        out dx, al  ; LBA[7:0]

        inc dx
        mov al, ah
        out dx, al  ; LBA[15:8]

        inc dx
        mov ax, di
        out dx, al  ; LBA[23:16]

        inc dx
        mov al, 0xe0  ; LBA mode, access main storage 1110_0000
        or al, ah
        out dx, al  ; LBA[27:24]
        ; specify the command to storage (R/W)
        ; 0x1f7 command port and state port 
        inc dx
        mov al, 0x20  ; read command
        out dx, al

        ; wait for the data ready
        .waits:
            in al, dx  ; get the state
            and al, 0x88
            cmp al, 0x08
            jnz .waits

            mov cx, 256  ; number of words to read (512B)
            mov dx, 0x1f0  ; 16-bit data port
        .readw:
            in ax, dx
            mov [bx], ax
            add bx, 2
            loop .readw

        pop dx
        pop cx
        pop bx
        pop ax

        ret


    ; calculate the 16-bit segment base address
    ; input: dx_ax => 32-bit assembly address
    ; return: ax => 16-bit segment base address
    calc_segment_base:
        push dx
        ; real physical address = assembly address (offset) + physical base address
        add ax, [cs:phy_base]
        adc dx, [cs:phy_base+0x02]
        ; reallocated segment dase address
        shr ax, 4
        ror dx, 4
        and dx, 0xf000
        or ax, dx

        pop dx

        ret

    ; physical base address for user program 
    phy_base dd 0x10000

times 510-($-$$) db 0
dw 0xaa55