; bootloader.asm
[BITS 16]        ; We are in 16-bit real mode
[ORG 0x7C00]     ; The boot sector is loaded at 0x7C00

; Define buffer size
buffer_size equ 100
buffer db buffer_size dup(0)  ; Input buffer for command

; Print a message
start:
    ; Check for keyboard presence
    call check_keyboard

    ; Enter command loop
command_loop:
    ; Prompt for input
    mov si, prompt_msg
    call print_string

    ; Read user input
    call read_input

    ; Print the entered command for debugging
    mov si, buffer          ; Print the command entered
    call print_string

    ; Process the command
    call process_command

    ; Jump back to the command loop
    jmp command_loop

; Check keyboard presence function
check_keyboard:
    ; Wait for the keyboard controller to be ready
    mov dx, 0x60            ; Keyboard data port
    in al, dx               ; Read from the port (check if we can read)
    jz keyboard_error        ; If zero, keyboard is not present

    ; Print success message
    mov si, success_msg
    call print_string
    ret

keyboard_error:
    ; Print error message
    mov si, error_msg
    call print_string
    jmp $

; Read input function
read_input:
    mov si, buffer          ; Point SI to buffer
    mov cx, buffer_size     ; Set maximum input length

.read_loop:
    ; Read character from keyboard
    mov ah, 0x00           ; BIOS keyboard read function
    int 0x16               ; Wait for a key press

    ; Check for Enter key (carriage return)
    cmp al, 0x0D           ; Check if the key is Enter
    je .end_input

    ; Check for Backspace
    cmp al, 0x08           ; Check if the key is Backspace
    je .backspace

    ; Store character in buffer
    stosb                   ; Store character in buffer
    ; Print character to the screen
    mov ah, 0x0E           ; BIOS teletype function
    int 0x10               ; Print character
    jmp .read_loop

.backspace:
    cmp si, buffer          ; Check if the buffer is not empty
    je .read_loop           ; If empty, do nothing
    dec si                  ; Move back in buffer
    ; Print backspace character
    mov ah, 0x0E           ; BIOS teletype function
    mov al, 0x08           ; Backspace character
    int 0x10               ; Print backspace
    mov al, ' '            ; Print space over the character
    int 0x10               ; Print space
    jmp .read_loop          ; Continue reading input

.end_input:
    mov byte [si], 0       ; Null-terminate the string
    ret

; Process command function
process_command:
    mov si, buffer          ; Load the address of the input command

    ; Check for "shutdown" command
    mov di, shutdown_cmd
    call string_compare
    je shutdown_system

    ; Check for "hello" command
    mov di, hello_cmd
    call string_compare
    je hello_user

    ; If command not recognized
    mov si, unrecognized_msg
    call print_string
    ret

shutdown_system:
    mov si, shutdown_msg
    call print_string
    jmp $

hello_user:
    mov si, hello_msg
    call print_string
    ret

; String comparison function
string_compare:
    push ax
    push cx
    push dx

    ; Compare each character in the command
    mov cx, buffer_size
.next_char:
    lodsb                   ; Load byte from buffer into AL
    cmp al, [di]           ; Compare with command character
    jne .not_equal         ; If not equal, go to not_equal
    inc di                 ; Move to next character in command
    cmp byte [di], 0       ; Check for null terminator
    je .equal              ; If end of command string, it's equal
    jmp .next_char

.not_equal:
    pop dx
    pop cx
    pop ax
    ret

.equal:
    pop dx
    pop cx
    pop ax
    ret

; Print string function with alignment
print_string:
    mov ah, 0x0E            ; BIOS teletype function
.loop:
    lodsb                   ; Load next byte into AL
    cmp al, 0               ; Check for null terminator
    je .done                ; If null, we are done
    int 0x10                ; Print character
    jmp .loop
.done:
    ; Print new line
    mov ah, 0x0E
    mov al, 0x0D           ; Carriage return
    int 0x10
    mov al, 0x0A           ; Line feed
    int 0x10
    ret

; Messages
success_msg db 'Keyboard detected!', 0
error_msg db 'Error: Keyboard not detected.', 0
prompt_msg db 'Enter command: ', 0
shutdown_cmd db 'shutdown', 0
hello_cmd db 'hello', 0
shutdown_msg db 'System shutting down...', 0
hello_msg db 'Hello user!', 0
unrecognized_msg db 'Sorry but I dont recognize this command.', 0

; Fill the boot sector with 0x00 after the code
times 510 - ($ - $$) db 0
dw 0xAA55              ; Boot signature
