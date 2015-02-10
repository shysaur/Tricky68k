

    ;
    ; String Reverser
    ;
    ; Reads a line from the TTY, then writes it back
    ; in reverse character order.
    ;


tty equ $FFE000                 ;TTY port


    public start
    org $2000   
    
    
start:
    move.l #lineBuffer,a0
    jsr getLine                 ;Get a line in the buffer 
    
    movea.l #lineBuffer,a1      ;Get a pointer to the beginning of the buffer
.swaploop:                      ;(A1 points to the left, A0 to the right)
    cmpa.l a1,a0
    ble .stop                   ;If A0 <= A1, we are done
    move.b (a1),d0
    move.b -(a0),d1             ;Otherwise switch the character pointed by A0
    move.b d1,(a1)+             ; with the one pointed by A1, decrementing a0 
    move.b d0,(a0)              ; and incrementing A1
    bra .swaploop               ;Next loop
    
.stop:
    move.l #lineBuffer,a0
    jsr printLine               ;Print the reversed line

    jmp start                   ;Loop to read another line
    
    
    
    ;Print a string (like puts)
    ;input A0: address of null-terminated string
printLine:  
    clr.w d0                    ;Keep the high byte of D0.w clear
.next:
    move.b (a0)+,d0             ;Read the next character
    beq .stop                   ;If it's the terminator, stop
    move.w d0,tty               ;Otherwise write the character
    bra .next                   ;Next loop
.stop:
    move.w #$0A,tty             ;Last thing, we write a newline
    rts                         ;Return
    
    
    ;Read a string (like gets)
    ;  input A0: address of buffer
    ;returns A0: address of terminating '\0'
getLine:
.loop:
    move.w tty,d0
    bmi .loop                   ;Loop until there's a character in the FIFO
    move.b d0,(a0)+             ;Write that character in the buffer
    cmp.b #$0A,d0
    bne .loop                   ;Continue if not a newline
    move.b #$00,-(a0)           ;Otherwise terminate the string
    rts                         ;Return
    
    
lineBuffer:
    ds.b 256                    ;(global) Line buffer
    
    
    
    