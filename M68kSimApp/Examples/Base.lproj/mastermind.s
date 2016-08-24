

    ;
    ; Mastermind
    ;
    ; This small game involves guessing a number from limited information.
    ;   The program only tells you how many digits are different, and if they
    ; are higher or lower than their intended value.
    ;
    ; For instance, +++- means that, on five digits, three are higher than the
    ; generated random number, one is lower, and one is correct.
    ;


    public start    ;Make the entry point public
    org $2000       ;Place the origin at $2000


TTY:              equ $FFE000
DIGIT_COUNT:      equ 5


    ;Main loop
    ;Note that, to improve the randomness of the random numbers generated, the
    ;number to guess is generated after the first guess has been inputed.
start:
    move.w #1,needsNewNumber    ;Flag the need of a new random number
.loop:
    move.l #guessQuery,a0
    bsr printLine
    move.l #keyBuffer,a0
    bsr getLine                 ;Query the next guess
    tst.w needsNewNumber        ;Don't generate a new random number if the user
    beq .nonew                  ; hasn't won yet
    bsr produceNumber           ;Otherwise do it. We'll keep the number until
    clr.w needsNewNumber        ; the user wins.
.nonew:
    bsr compareGuess            ;Check the current guess.
    bsr printResult             ;Print the comparison results.
    tst.w d0                    ;If the user hasn't won, ask again without
    beq .loop                   ; changing number
    bra start                   ;Otherwise flag the number to change.


    ;Print the results of the comparison done by compareGuess.
    ;input: D0 amount of bigger digits or -1 on error, D1 amount of smaller
    ;       digits
    ;output: D0 one if the user has won, otherwise zero
printResult:
    tst.w d0
    bmi .error                  ;If D0 < 0, print the error message
    move.w d0,d2
    or.w d1,d2                  ;If both D0 and D1 are zero, print the win
    beq .win                    ; message
    movem.l d0-d1,-(sp)
    move.l #result,a0           ;Otherwise print the beginning of the standard
    bsr printLine               ; result message
    movem.l (sp)+,d0-d1
.lplus:
    sub.w #1,d0
    bmi .lminus
    move.w #'+',TTY             ;Print one '+' for each bigger digit
    bra .lplus
.lminus:
    sub.w #1,d1
    bmi .end
    move.w #'-',TTY             ;Print one '-' for each smaller digit
    bra .lminus
.end:
    move.w #$0A,TTY             ;Print the final newline
    move.w #0,d0
    rts                         ;Return that the user hasn't won yet

    ;Error message
.error:
    move.l #inputErrorMessage,a0
    bsr printLine               ;Print the error message
    move.w #0,d0
    rts                         ;Return that the user hasn't won yet

    ;Win message
.win:
    move.l #winMessage,a0
    bsr printLine               ;Print the win message
    move.w #1,d0
    rts                         ;Return that the user has won


    ;Compares the current digits in keyBuffer with the current number to guess.
    ;output: D0 amount of bigger digits or -1 on a parsing error, D1 amount of
    ;        smaller digits
compareGuess:
    move.l #currentNumber,a0
    move.l #keyBuffer,a1
    clr.w d0                    ;Initialize the bigger numbers counter
    clr.w d1                    ;Initialize the smaller numbers counter
    move.b #DIGIT_COUNT,d2      ;Loop for each digit
.loop:
    move.b (a1)+,d3
    cmp.b #'0',d3
    blt .fail
    cmp.b #'9',d3               ;Return an error if the current input character
    bgt .fail                   ; is not a numeral
    cmp.b (a0)+,d3              ;If it is equal to the digit to guess, don't
    beq .next                   ; increment the counters
    bgt .plus                   ;If it is greater, increment the counter in D0
    add.w #1,d1
    bra .next                   ;Otherwise increment D1
.plus:
    add.w #1,d0
.next:
    sub.b #1,d2
    bne .loop                   ;Next digit
    move.b (a1),d3              ;Fail if there are more characters on the input
    bne .fail                   ; line than the 5 digits.
    rts                         ;Otherwise return.

.fail:
    move.w #-1,d0
    rts                         ;Fail by returning -1 in D0.


    ;Generate a new number to guess. The number to guess is stored as a string
    ;to make the comparison easy.
produceNumber:
    move.b #DIGIT_COUNT,d1
    move.l #currentNumber,a0    ;currentNumber will contain our number
.loop:
    movem.l d1/a0,-(sp)
    bsr randomNumber            ;Get 32 random bits in D0
    movem.l (sp)+,d1/a0         ;Multiply the lower 16 bits in D0.l by 16 to get
    mulu #10,d0                 ; a random number between 0 and 10 in the high
    swap.w d0                   ; half of D0.l, then swap it in the low half
    add.b #'0',d0               ;Get the ASCII character for the number
    move.b d0,(a0)+             ;Store it
    sub.b #1,d1
    bne .loop                   ;Next number
    rts                         ;Return


    ;Generate 32 random bits using a Galois LFSR.
    ;output: D0 the random number
randomNumber:
    move.b #32,d1               ;Every loop generates one bit
    move.l randomState,d0
    bne .loop                   ;If the current LFSR state is zero, initialize
    move.l #$1E0EBD7F,d0        ; it (zero is the stable state of the LFSR)
.loop:
    lsr.l #1,d0                 ;Shift right
    bcc .noxor                  ;XOR with the maximal polynomial if the shifted
    eor.l #$80000062,d0         ; out bit is one
.noxor:
    sub.b #1,d1
    bne .loop                   ;Next bit
    move.l d0,randomState       ;Save the resulting state and return it as the
    rts                         ; random number


    ;Print a string (like puts)
    ;input: A0 address of null-terminated string
printLine:
    clr.w d0                    ;Keep the high byte of D0.w clear
.next:
    move.b (a0)+,d0             ;Read the next character
    beq .stop                   ;If it's the terminator, stop
    move.w d0,TTY               ;Otherwise write the character
    bra .next                   ;Next loop
.stop:
    rts                         ;Return


    ;Read a string (like gets). Note that we exploit the I/O cycle to waste
    ;some PRNG states, to gather some entropy. It's easily manipulated, but
    ;it's still better than nothing, and we don't have many alternatives.
    ;input: A0 address of buffer
    ;output: A0 address of terminating '\0'
getLine:
.loop:
    bsr randomNumber            ;Cycle the PRNG
    move.w TTY,d0
    bmi .loop                   ;Loop until there's a character in the FIFO
    move.b d0,(a0)+             ;Write that character in the buffer
    cmp.b #$0A,d0
    bne .loop                   ;Continue if not a newline
    move.b #$00,-(a0)           ;Otherwise terminate the string
    rts                         ;Return


guessQuery:
    dc.b "Enter your ", DIGIT_COUNT+'0', "-digit guess:",$0A,0
result:
    dc.b "Wrong answer! Your results: ",0
winMessage:
    dc.b "Correct!",$0A,$0A,"Now I'll change my number!",$0A,0
inputErrorMessage:
    dc.b "That wasn't ", DIGIT_COUNT+'0', " digits!",$0A,0


    align 2

randomState:
    ds.l 1
needsNewNumber:
    ds.w 1
currentNumber:
    ds.b DIGIT_COUNT
    align 2
keyBuffer:
    ds.b 256


