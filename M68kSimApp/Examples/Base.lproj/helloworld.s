

    ;
    ; Hello World
    ;
    ; Writes "Hello World!" to the TTY.
    ;


tty equ $FFE000     ;Base address of the TTY memory-mapped device.
    ;  Write to this address to write a character to the TTY, read from this
    ;address to read a character from the TTY. If -1 is read, the keyboard 
    ;buffer is empty and there is no character to read.


    public start        ;Make the entry point public
    org $2000           ;Place the origin at $2000


start:
    move.l #text,a0     ;Load the base address of the string
    clr.w d0            ;Keep high byte of d0.w empty
.loop:
    move.b (a0)+,d0     ;Read next character
    beq .done           ;If it was zero (terminator), we're done
    move.w d0,tty       ;Write that character to the TTY
    bra .loop           ;Next character
.done:
    bra .done           ;Lock the CPU when we're done
    
    
text:
    dc.b "Hello world!",$A,0


