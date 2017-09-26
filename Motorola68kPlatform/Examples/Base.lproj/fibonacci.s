

    ;
    ; Recursive Fibonacci
    ;
    ; Computes the n-th Fibonacci number recursively (and slowly). This example
    ; demonstrates recursion, and the correspondence between C language and
    ; assembly.
    ;
    ;   Note that the last input that doesn't cause overflow in the output
    ; is 24 because 16-bit integers are used in the computation.
    ;
    ;   In the comments, the C program equivalent to the assembly code is
    ; provided. This C code has the following int sizes:
    ;   sizeof(char) == 1
    ;   sizeof(int) == 2 (ints are 16-bit words)
    ;   sizeof(void*) == 4
    ;
    ;   See the end of the file for additional notes on the calling convention
    ; and stack layout used.
    ;


        public start    ;Make the entry point public
        org $2000       ;Place the origin at $2000


tty     equ $FFE000     ;extern int tty;  /* TTY port; &tty == 0xFFE000 */


    ;void start(void) {
start:
.tmp    equ -2          ;int tmp;
    link fp,#-2         ;/* Allocate the frame */
.loop                   ;for (;;) {
    bsr getInt          ;  tmp = getInt();
    bsr fibonacci       ;  fibonacci(tmp);  /* tmp is already at the end of
                        ;                    * the frame, we don't copy it */
    bsr printInt        ;  printInt(tmp);
    bra .loop           ;}
    ;}


    ;int fibonacci(int n) {
fibonacci:
.n      equ 8
    link fp,#0          ;/* Allocate the frame */
    move.w .n(fp),d0    ;/* n is now in D0 */
    ble .zero           ;if (n > 0) {   /* Note: the test is inverted */
    sub.w #1,d0         ;  register int d0 = n-1;
    beq .one            ;  if (d0 != 1) {    /* Again the test is inverted */
    move.w d0,-(sp)
    bsr fibonacci
    move.w (sp)+,d0     ;    d0 = fibonacci(d0);  /* d0 = n-1 */
    move.w .n(fp),d1    ;    register int d1 = n;
    move.w d0,.n(fp)    ;    n = d0;
    sub.w #2,d1
    move.w d1,-(sp)
    bsr fibonacci
    move.w (sp)+,d0     ;    d0 = fibonacci(d1-2); /* also, d1 is destroyed */
    add.w d0,.n(fp)     ;    n += d0;
    bra .end            ;    return n;  /* n is already the last int in the */
.one:                   ;  } else {     /* param. area, so we don't copy it */
    move.w #1,.n(fp)    ;    n = 1;
    bra .end            ;    return n;
                        ;  }
.zero:                  ;} else
    clr.w .n(fp)        ;  n = 0;
.end:
    unlk fp
    rts                 ;return n;
    ;}


    ;unsigned int getInt(void) {
getInt:
    link fp,#0          ;/* Allocate the frame */
    clr.w d1            ;register int d1 = 0;
                        ;register int d0;
.skip:                  ;do {   /* Skip leading non-numeric characters */
    move.w tty,d0
    bmi .skip           ;  while ((d0 = tty) < 0);  /* Wait next character */
    sub.w #'0',d0       ;  d0 -= '0';
    bmi .skip
    cmp.w #9,d0
    bgt .skip           ;} while (d0 < 0 || d0 > 9);
.loop:                  ;do {   /* Read the number; d0 already contains
    mulu.w #10,d1       ;        * the first digit */
    add.w d0,d1         ;  d1 = d1 * 10 + d0;       /* Add the next digit */
.waitc:
    move.w tty,d0
    bmi .waitc          ;  while ((d0 = tty) < 0);  /* Wait next character */
    sub.w #'0',d0       ;  d0 -= '0';
    bmi .end            ;} while (d0 >= 0 &&        /* (inverted test) */
    cmp.w #9,d0
    ble .loop           ;         d0 <= 9);
.end:
    move.w d1,8(fp)     ;/* Write the return value */
    unlk fp
    rts                 ;return d1;
    ;}


    ;void printInt(unsigned int n) {
printInt:
.n      equ 8
.buf    equ -8          ;char buf[8];
    link fp,#-8         ;/* Allocate the frame */
    lea (.buf+8,fp),a0  ;register char *a0 = &buf[8];
    clr.b -(a0)         ;*(--a0) = '\0';  /* Terminate the string */
    move.w .n(fp),d0    ;register int d0 = m;
.loop:                  ;do {
    and.l #$0000FFFF,d0 ;  /* Remove high half of d0.l */
    divu.w #10,d0       ;  /* High half of d0.l = d0.l % 10
    move.l d0,d1        ;   * Low half of d0.l = d0.l / 10 */
    swap d1             ;  register int d1 = d0 % 10; d0 = d0 / 10;
    add.b #'0',d1
    move.b d1,-(a0)     ;  *(--a0) = '0' + d1;
    tst.w d0
    bne .loop           ;} while (d0 != 0);
    clr.w d0            ;d0 = 0;
.out:
    move.b (a0)+,d0
    beq .end            ;while ((d0 = *(a0++)) != 0) {  /* (inverted test) */
    move.w d0,tty       ;  tty = d0;
    bra .out
.end                    ;}
    move.w #$0A,tty     ;tty = '\n';
    unlk fp
    rts                 ;return;
    ;}


;
;              Notes on Stack Frames and Calling Conventions
;
; When writing assembly code, it is natural to use registers and global varia-
; bles in place of local variables, just because it's easier and faster.
;   If a local variable is destroyed by some function call, it is usually saved
; on the stack (the MOVEM instruction is particularly suited for this task).
;
; All local variables in a recursive function must not change when a recursion
; step ends. Thus, to move less data around, all variables are kept directly on
; the stack.
;   Since most C compilers don't analyze the code to check for recursive fun-
; ctions (it's a difficult task), they use the stack for local storage, even
; when it wouldn't be needed.
;
; Local variables are not just those that are created and destroyed in the con-
; text of a function. Some local variables must survive between two different
; function calls: the function parameters and the return value.
;   One way to handle these variables is to store them in the registers. Since
; early computers had few registers and compilers were simple, they are usually
; saved on the stack, instead.
;
; Every function reserves a zone in the stack for itself, called stack frame.
; On the M68k, this can be done using the LINK r,#c instruction, which is
; equivalent to:
;   1. movea r,-(sp)
;   2. movea sp,r
;   3. adda #c,sp
; The r register used by LINK is called Frame Pointer. Usually, on the M68k, the
; frame pointer register is A6 (which, for this reason, can also be called FP,
; like A7 can also be called SP).
;
; FP is the head pointer of the linked list of every frame in the stack, and it
; can be used to access the topmost frame (because it points to the bottom of
; it).
;   When a function exits, it must remove its stack zone to restore SP to its
; previous value, so that RTS will work properly. This is done by the UNLK r
; instruction, which is equivalent to:
;   1. movea r,sp
;   2. movea r,(sp)+
;
; Function parameters are usually pushed on the top of the caller function's
; frame, and thus they appear after the called function's frame.
;   Since FP points to the previous frame pointer, which is followed by the
; return address, the parameter area starts 8 bytes after the current FP.
;   Conventionally, all parameters are pushed in reverse order, so that their
; addresses on the stack increase with their index.
;
; The return values are written by the called function at the end of the
; parameter area.
;   Thus, if the called function doesn't take any parameter, but it returns a
; value, the caller must allocate some space on the stack anyway.
;



