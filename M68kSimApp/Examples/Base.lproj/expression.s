

    ; 
    ; Expression Calculator
    ;
    ; Reads a mathematical expression from the teletype, computes its
    ; value, then prints it. If the expression is invalid, "Parsing error"
    ; is printed.
    ;
    ;   Negative numbers like -1234 are not accepted, but you can write
    ; (0 - 1234) instead. Also, this program does not divide and multiply
    ; correctly if the operands do not fit in 16 bits (that is, they are
    ; < -32768 or > 32767).
    ; 


tty             equ $FFE000     ;TTY port

TOK_UNK         equ 0  ;kills everyting
TOK_NUMBER      equ 1  ;value in D1
TOK_OPERATOR    equ 2  ;+, -, *, /, as is in D1
TOK_TERM        equ 3  ;=, \0, ), as is in D1


    public start
    org $2000 
    
    
    ;Main loop
start:
    move.l #lineBuffer,a0
    bsr getLine                 ;Read the next expression
    
    move.l #lineBuffer,a0
    bsr parseExpression         ;Compute its value (returned in D4)
    
    cmp.b #TOK_UNK,d0           ;If last token parsed was of unknown
    beq .error                  ;type, an error occured
    
    move.l d4,d0
    move.l #lineBuffer,a0
    bsr itoa                    ;Convert the result to a string
    bsr printLine               ;Print the result
    bra start                   ;Next expression
    
.error:
    move.l #errorMessage,a0
    bsr printLine               ;Error: print error message
    bra start                   ;Next expression
    
    
    ;Read an expression pointed to by A0
    ;Returns numeric result in d4, in d0/d1 last token read
parseExpression:
    bsr parseToken          ;Parse the first token
    cmp.b #TOK_NUMBER,d0
    bne .error              ;First token must be a number
    move.l d1,d4            ;Initialize our accumulator
    
.loop:
    bsr parseToken          ;Parse an operator/terminator
    cmp.b #TOK_TERM,d0
    beq .done               ;If a terminator, return
    cmp.b #TOK_OPERATOR,d0
    bne .error              ;If not an operator not a terminator, fail
    move.l d1,d3            ;Save the type of operation we'll have to do
    
    ;For * and /, we use as a right-hand side the next token in the
    ;stream; for + and - we wait until we have parsed the rest of the
    ;expression, by recursively calling this same function on the
    ;rest of the string. This ensures that * and / are evaluated first.
    
    cmp.b #$2A,d1
    beq .hipriority
    cmp.b #$2F,d1
    beq .hipriority         ;If * or /, get the tokens  
    
    movem.l d3-d4,-(sp)     ;Otherwise + or -; parse the rest of the
    bsr parseExpression     ; expression, and use its value as
    move.l d4,d2            ; right-hand value
    movem.l (sp)+,d3-d4
    
    cmp.b #TOK_TERM,d0
    bne .error              ;If an error had occurred, propagate it
    
    cmp.b #$2B,d3
    beq .plus               ;Do a sum for +
    
.minus:
    sub.l d2,d4             ;Do a subtraction for -.
    rts
    
.plus:
    add.l d2,d4
    
.done:
    rts
    
.hipriority:
    bsr parseToken          ;For * and /, get the next token
    cmp.b #TOK_NUMBER,d0
    bne .error              ;If was not a number, error out
    
    cmp.b #$2A,d3
    beq .multiply           ;If operator was *, do a multiplication
    
.divide:
    divs d1,d4              ;Otherwise do a division
    ext.l d4                ;Remove the remainder and sign-extend
    bra .loop               ;Go ahead parsing

.multiply:
    muls d1,d4              ;Do the multiplication
    bra .loop               ;Go ahead parsing
    
.error
    moveq #TOK_UNK,d0       ;If error, return an unknown token
    rts                     ;Return
    
    
    ;Reads a token and return its type and value.
    ; . Parenthesis transform expressions in tokens,
    ; . Terminator tokens return to the parent sub-expression,
    ; . +, -, *, / are operators.
    ; . Numbers are values. Numbers are unsigned only, to get
    ;   negative numbers just use (0 - number).
    ;Returns in D0: type, D1: value
    ;Scan address in A0
parseToken:
    bsr skipBlanks          ;Skip leading blanks
    move.b (a0)+,d1         ;Get first character of the token
    
    beq .term               ;If '\0', it's a terminator
    cmp.b #$3D,d1
    beq .term               ;We consider '=' a valid terminator too
    
    cmp.b #$28,d1           ;If got an '(', go parse the subexpression
    beq .groupToken         ; it encloses
    cmp.b #$29,d1           ;')' closes a subexpression, treat it as
    beq .term               ; a terminator
    
    cmp.b #$2A,d1
    beq .operator
    cmp.b #$2B,d1
    beq .operator
    cmp.b #$2D,d1
    beq .operator
    cmp.b #$2F,d1
    beq .operator           ;*, +, -, / are operators
    
    cmp.b #$30,d1
    blt .error
    cmp.b #$39,d1           ;If not a digit, then unknown character
    bgt .error              ; (we already tested all known characters)
    
    ;Get a number token
.number:
    lea (-1,a0),a0          ;Move pointer back one character
    bsr atoi                ;Read our number
    move.l d0,d1
    moveq #TOK_NUMBER,d0    ;Set token type
    rts                     ;Return

    ;One-character tokens
.error: 
    moveq #TOK_UNK,d0
    rts
.operator:
    moveq #TOK_OPERATOR,d0
    rts
.term:
    moveq #TOK_TERM,d0      ;Just set the type
    rts                     ; and return
    
    ;Group token (parenthesis-enclosed expression)
.groupToken:
    movem.l d3-d4,-(sp)     ;Save current parsing state
    bsr parseExpression     ;Parse the subexpression
    move.l d4,d2            
    movem.l (sp)+,d3-d4     ;Restore old parsing state
    cmp.b #$29,d1
    bne .error              ;If an error occured, propagate it
    move.l d2,d1            ;Otherwise return result of subexpression
    moveq #TOK_NUMBER,d0    ; as a fake number token.
    rts                     ;Return
    
    
    ;Increment A0 until a non-blank character is found
    ;A0 pointer
skipBlanks:
    move.b (a0),d0          ;Check this character
    beq .done               ;If \0, consider not a blank
    cmp.b #20,d0
    bgt .done               ;If ASCII code over $20, not a blank
    lea (1,a0),a0           ;Otherwise it's a blank, increment A0
    bra skipBlanks          ;Continue
.done:
    rts                     ;Return
    
    
    ;Convert decimal numeric string to its value
    ;input: A0 address of first digit
    ;output: d0 result
atoi:
    clr.l d6                ;Initialize result
    clr.l d1
    moveq #10,d7            
.loop:
    move.b (a0)+,d1         ;Get the next character
    sub #$30,d1
    bmi .stop
    cmp #9,d1
    bgt .stop               ;If not a digit, stop, otherwise get its value
    
    bsr mulu16by32          ;Mul the old result by 10 (make space for new digit)
    add.l d1,d6             ;Add the new digit
    
    bra .loop               ;Next
.stop:
    move.l d6,d0            ;When finished, copy in D0 the result
    lea (-1,a0),a0          ;Back off one character
    rts                     ;Return
    
    
    ;Convert signed integer value to its decimal string representation
    ;input: d0 number to print, a0 addr of buffer
    ;output: a0 address of string
itoa:                       ;Make space for the result in the buffer
    adda.l #12,a0           ; (the string will be constructed backwards)
    move.b #0,-(a0)         ;Terminate the string
    move.l d0,d6
    tst.l d6
    beq .zero               ;Special-case zero
    bpl .loop
    neg.l d6                ;Get absolute value
.loop:
    move.w #10,d7           ;Divide the value by 10
    bsr divu32by16          ; (remainder = next digit in D7)
    
    add.b #$30,d7           ;Make the ASCII character for the digit
    move.b d7,-(a0)         ;Append to the left of the string
    tst.l d6
    bne .loop               ;Continue if not done
.end:
    tst.l d0                ;When done, check sign again
    bpl .ok
    move.b #$2D,-(a0)       ;If negative, add the dash
.ok:
    rts                     ;Return
    
.zero:
    move.b #$30,-(a0)       ;For the zero, we just print zero
    rts                     ;Return


    ;32-bit by 16-bit division
    ;d6.l,d7.w = d6.l / d7.w
divu32by16:
    movem.l d4-d5,-(sp) ;Save the registers we use
    move.l d6,d5
    clr.w d5
    eor.l d5,d6         ;d6 = low word of dividend
    swap d5             ;d5 = high word of divisor
    divu d7,d5
    clr.l d4
    move.w d5,d4        ;d4 = high word of result
    eor.l d4,d5         
    swap d4
    add.l d5,d6     
    divu d7,d6
    move.l d6,d7
    clr.w d7
    eor.l d7,d6         ;d6 = low word of result
    swap d7             ;d7 = final remainder
    add.l d4,d6         ;d6 = final result
    movem.l (sp)+,d4-d5 ;Restore registers
    rts                 ;Return

    
    ;32-bit by 16-bit multiplication
    ;d6.l = d6.l * d7.w
mulu16by32:
    move.l d5,-(sp)     ;Save the extra register we use
    move.l d6,d5
    swap d5 
    mulu d7,d6          ;Multiply d7 by the low word
    mulu d7,d5          ;Multiply d7 by the high word
    swap d5
    clr.w d5
    add.l d5,d6         ;Sum the two mid-products
    move.l (sp)+,d5     ;Restore register
    rts                 ;Return
    
    
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
    
    
    
errorMessage:
    dc.b "Parsing error!",0
    
lineBuffer:
    ds.b 256


