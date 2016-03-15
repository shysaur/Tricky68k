

    ;
    ; Exponentiation
    ;
    ; Compute the nth power of an integer number with the basic exponentiation
    ; algorithm (b*b*b*b...)
    ;
    ; Since the 68k only supports 16-bit by 16-bit multiplication, to take
    ; advantage of all the 32 bits in the registers, we multiply 
    ;


    public start    ;Make the entry point public
    org $2000       ;Place the origin at $2000


start:
    move.l #15,d0
    move.w #6,d1    ;Load the base and the exponent (15^6)
    
    move.l #1,d2    ;Initialize the result
.loop:              ;Count down the exponent
    tst.w d1
    beq .end        ;If no multiplications left, return
    move.l d2,d3
    mulu d0,d2      ;Multiply the low word of the result by the base
    swap d3
    mulu d0,d3
    swap d3         ;Multiply the high word of the result by the exponent, and
    clr.w d3        ; shift it into the high word of d3
    add.l d3,d2     ;Sum the two new partial products
    sub.w #1,d1
    bra .loop       ;Next multiplication
.end:
    bra .end        ;The result is now in D3.


