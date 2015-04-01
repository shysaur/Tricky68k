

    ;
    ; Count Digits
    ;
    ; Counts how many decimal digits a number contains.
    ;


    public start      ;Make the entry point public
    org $2000         ;Place the origin at $2000


start:
    move.w #1234,d0    ;Move in D0 the number to count the digits of.
    
    move.w #1,d1       ;D1: digit counter. A number has at least one digit, so
                       ; we start with one.
.loop:
    divu.w #10,d0      ;D0.w = D0.l / 10. The high word of D0 contains the
                       ; remainder of the division. Thus, if D0 = $00000005,
                       ; after this instruction D0 will be = $00010002 because
                       ; 5 / 2 = 2.5 (2 with a remainder of 1).
    and.l #$FFFF,d0    ;Remove the high bits of D0 to discard the remainder.
    beq .end           ;If D0 is zero, we shifted out the last digit. Since we
                       ; already counted this digit by initializing the counter
                       ; to one, we can quit.
    add.w #1,d1        ;Otherwise, count the digit we shifted out
    bra .loop          ;Next loop!
    
.end:
    bra .end           ;When the program gets here, the result will be in D1.
                       ; You can set a breakpoint to this instruction in the
                       ; simulator to read the result in the rightmost panel.


