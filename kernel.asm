; kernel.asm
[BITS 16]
[ORG 0x1000]  ; Kernel will be loaded at 0x1000

start:
    ; Your kernel code goes here
    mov si, kernel_msg
    call print_string

    ; Infinite loop
hang:
    jmp hang

print_string:
    mov ah, 0x0E
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    ret

kernel_msg db 'Kernel loaded successfully!', 0
