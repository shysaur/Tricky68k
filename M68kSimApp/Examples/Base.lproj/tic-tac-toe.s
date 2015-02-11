

    ; 
    ; Tic-Tac-Toe
    ;
    ; Plays tic-tac-toe with the user. It should never lose. 
    ; Exercise for the reader: make the program play with itself.
    ;
    ; To play, at the "?" prompt type the number of the cell where you wish
    ; to move, and then press enter.
    ;
    ;    1 | 2 | 3
    ;   ---+---+---
    ;    4 | 5 | 6
    ;   ---+---+---
    ;    7 | 8 | 9
    ;


	public start	;Make the entry point public
	org $2000		;Place the origin at $2000


TTY:              equ $FFE000
X_CELL:           equ 1
PLR_CELL:         equ X_CELL
EMPTY_CELL:       equ 0
O_CELL:           equ -1
OPPONENT_CELL:    equ O_CELL


    ;Main game loop
start:
    bsr initBoard
    move.w #X_CELL,whoseTurn
    
    bsr askOrder
    bne .cpuenter
    bsr printBoard
.loop:
    bsr checkGameOver
    bne .gameEnd
    bsr checkDraw
    bne .gameDraw
   
    bsr playerTurn
    neg.w whoseTurn
.cpuenter
    bsr cpuTurn
    neg.w whoseTurn
    bsr printBoard
    bra .loop
    
.gameDraw:
    move.l #drawString,a0
    bsr printLine
    bra start
    
.gameEnd:
    bmi .odidwin
    move.l #XString,a0
    bsr printLine
    bra start
    
.odidwin:
    move.l #OString,a0
    bsr printLine
    bra start    
    
    
    ;Ask the player who will go first.
askOrder:
    movea.l #orderQuery,a0
    bsr printLine
    movea.l #keyBuffer,a0
    bsr getLine
    
    movea.l #keyBuffer,a0
    clr.w d0
.checknumber:
    move.b (a0)+,d0
    beq askOrder
    sub.b #'0',d0
    blt .checknumber
    cmp.b #1,d0
    bgt .checknumber
    and.b d0,d0
    rts
    

    ;Execute a player turn (ask the player which move to perform)
playerTurn:
    movea.l #moveQuery,a0
    bsr printLine
    movea.l #keyBuffer,a0
    bsr getLine
    movea.l #keyBuffer,a0
    clr.w d0
.checknumber:
    move.b (a0)+,d0
    beq playerTurn
    sub.b #'1',d0
    blt .checknumber
    cmp.b #9,d0
    bgt .checknumber
    add.w d0,d0
    move.l #board,a0
    move.w (a0,d0),d1
    bne playerTurn
    move.w whoseTurn,(a0,d0)
    rts
    
    
    ;Execute a CPU turn (running the AI)
cpuTurn:
    movea.l #.jumpTable,a0
.loop:
    movea.l (a0)+,a1
    move.l a0,-(sp)
    jsr (a1)
    move.l (sp)+,a0
    and.w d0,d0
    beq .loop
    rts
    
.jumpTable:
    dc.l cpuWin
    dc.l cpuBlockWin
    dc.l cpuBlockFork
    dc.l cpuFirstCorner
    dc.l cpuCenter
    dc.l cpuCorner
    dc.l cpuSide
    dc.l cpuSuccess ;should never hit
    
    
    ;Try to win
cpuWin:
    movea.l #0,a0
.loop:
    bsr getPlayerRowAndStats
    cmp.b #2,d3
    bne .nomatch
    cmp.b #1,d4
    bne .nomatch
    bra moveFirstEmpty
.nomatch:
    add.w #3,a0
    cmp.w #8*3,a0
    bne .loop
    bra cpuFail
    
    
    ;Try to block an opponent win
cpuBlockWin:
    movea.l #0,a0
.loop:
    bsr getPlayerRowAndStats
    cmp.b #2,d5
    bne .nomatch
    cmp.b #1,d4
    bne .nomatch
    bra moveFirstEmpty
.nomatch:
    add.w #3,a0
    cmp.w #8*3,a0
    bne .loop
    bra cpuFail 
    
    
    ;Try to block a fork
cpuBlockFork:
    movea.l #18,a0
    bsr .test
    bne cpuSuccess
    movea.l #21,a0
.test:
    bsr getPlayerRowAndStats
    and.w d0,d0
    bpl cpuFail
    cmp.w d0,d2
    beq cpuSide
    bra cpuFail
    
    
    ;Move in a corner only if the board is clear
cpuFirstCorner:
    moveq.l #9,d1
    move.l #board,a0
.loop:    
    move.w (a0)+,d0
    bne cpuFail
    subq.l #1,d1
    bne .loop
    
    
    ;Try to move in a corner
cpuCorner:
    movea.l #18,a0
    bsr .test
    bne cpuSuccess
    movea.l #21,a0
.test:
    bsr getPlayerRowAndStats
    and.w d0,d0
    beq moveIn1
    and.w d2,d2
    beq moveIn3
    bra cpuFail
    
    
    ;Try to move in the center
cpuCenter:
    movea.l #18,a0
    bsr getPlayerRowAndStats
    and.w d1,d1
    beq moveIn2
    bra cpuFail
    
    
    ;Try to move on a side
cpuSide:
    movea.l #0,a0
    bsr .test
    bne cpuSuccess
    movea.l #3*3,a0
.test:
    bsr .test1
    bne cpuSuccess
    adda.w #6,a0
.test1:
    bsr getPlayerRowAndStats
    and.w d2,d2
    beq moveIn2
    bra cpuFail


    ;Utility functions for failure and success.
cpuFail:
    clr.l d0
    rts
    
cpuSuccess:
    moveq.l #1,d0
    rts


    ;Return in D0 who won (0 if nobody)
checkGameOver:
    move.l #0,a0
    moveq.l #8,d7
.loop:
    bsr getRowAndStats
    cmp.b #3,d3
    beq .done
    cmp.b #3,d5
    beq .done
    adda.w #3,a0
    subq.w #1,d7
    bne .loop
    clr.w d0
.done:
    and.w d0,d0
    rts
    
    
    ;Checks for a draw. Returns DO.w zero if not, nonzero if yes
checkDraw:
    move.l #board,a0
    moveq.l #9,d1
.loop:
    move.w (a0)+,d0
    beq .done
    subq.l #1,d1
    bne .loop
    and.w d0,d0
.done:
    rts


    ;Initialize the game board
initBoard:
    move.b #9,d0
    movea.l #board,a0
.loop:
    move.w #0,(a0)+
    subq.b #1,d0
    bne .loop
    rts


    ;Prints board
printBoard:
    move.b #3,d1
    movea.l #board,a0
    movea.l #(OXOtab+1),a1
.loop:
    clr.w d2
    move.w #' ',TTY
    move.w (a0)+,d0
    move.b (a1,d0.w),d2
    move.w d2,TTY
    move.w #' ',TTY
    move.w #'|',TTY
    move.w #' ',TTY
    move.w (a0)+,d0
    move.b (a1,d0.w),d2
    move.w d2,TTY
    move.w #' ',TTY
    move.w #'|',TTY
    move.w #' ',TTY
    move.w (a0)+,d0
    move.b (a1,d0.w),d2
    move.w d2,TTY
    subq.b #1,d1
    beq .return
    movem.l d0-d1/a0-a1,-(sp)
    move.l #spacer,a0
    bsr printLine
    movem.l (sp)+,d0-d1/a0-a1
    bra .loop
.return:
    move.w #$0A,TTY
    rts


    ;Read the specified row/column/diagonal and compute some statistics, in
    ;respect to the current player
    ;input  A0: index in the search table of the row
    ;output D0, D1, D2: row asked, with 1 = current player
    ;       D3, D4, D5: player cells, empty cells, and opponent cells count
getPlayerRowAndStats:
    bsr getRowAndStats
    move.w whoseTurn,d6
    bpl .done
    
    neg.w d0
    neg.w d1
    neg.w d2
    exg d3,d5
    
.done:
    rts
    
    
    ;Read the specified row/column/diagonal and compute some statistics.
    ;input  A0.l: index in the search table of the row (preserved)
    ;output D0.w, D1.w, D2.w: row asked
    ;       D3.l, D4.l, D5.l: X cells, empty cells, and O cells count
getRowAndStats:
    move.l a0,a3
    adda.l #searchTable,a3
    clr.l d3
    clr.l d4
    clr.l d5
    clr.l d6
    move.l #board,a2
    
    move.b (a3),d6
    bsr .count
    move.w d2,d0
    
    move.b 1(a3),d6
    bsr .count
    move.w d2,d1
    
    move.b 2(a3),d6
.count:
    add.b d6,d6
    move.w (a2,d6),d2
    beq .empty
    bmi .ocell
    addq.b #1,d3
    rts
.empty:
    addq.b #1,d4
    rts
.ocell:
    addq.b #1,d5
    rts
    
    
    ;Move in the first empty cell of the specified row/column/diagonal
    ;input D0.w, D1.w, D2.w: row
    ;      A0.l: index in the search table of the row (not preserved)
moveFirstEmpty:
    and.w d0,d0
    beq moveIn1
    and.w d1,d1
    beq moveIn2
    
    
    ;Move in the specified cell of the specified row/column/diagonal
    ;input  A0.l: index in the search table of the row (not preserved)
    ;output D0.l: = 1
moveIn3:
    adda.w #1,a0
moveIn2:
    adda.w #1,a0
moveIn1:
    adda.l #searchTable,a0
    clr.l d0
    move.b (a0),d0
    add.b d0,d0
    move.l #board,a0
    move.w whoseTurn,(a0,d0)
    moveq.l #1,d0
    rts
    
    
    ;Print a string (like puts)
    ;input A0: address of null-terminated string
printLine:  
    clr.w d0                    ;Keep the high byte of D0.w clear
.next:
    move.b (a0)+,d0             ;Read the next character
    beq .stop                   ;If it's the terminator, stop
    move.w d0,TTY               ;Otherwise write the character
    bra .next                   ;Next loop
.stop:
    rts                         ;Return
    
    
    ;Read a string (like gets)
    ;  input A0: address of buffer
    ;returns A0: address of terminating '\0'
getLine:
.loop:
    move.w TTY,d0
    bmi .loop                   ;Loop until there's a character in the FIFO
    move.b d0,(a0)+             ;Write that character in the buffer
    cmp.b #$0A,d0
    bne .loop                   ;Continue if not a newline
    move.b #$00,-(a0)           ;Otherwise terminate the string
    rts                         ;Return
    

searchTable:
    dc.b 0, 1, 2
    dc.b 3, 4, 5
    dc.b 6, 7, 8
    dc.b 0, 3, 6
    dc.b 1, 4, 7
    dc.b 2, 5, 8
    dc.b 0, 4, 8
    dc.b 2, 4, 6


XString:
    dc.b "X won!",$0A,$0A,0
OString:
    dc.b "O won!",$0A,$0A,0
drawString:
    dc.b "Draw...",$0A,$0A,0
orderQuery:
    dc.b "Tricky68k first (1) or player first (0)? ",0
moveQuery:
    dc.b "? ",0
spacer:
    dc.b $0A,"---+---+---",$0A,0
OXOtab:
    dc.b "O X"

    
    align 2

board:
    ds.w 9
whoseTurn:
    ds.w 1
    
keyBuffer:
    ds.b 256
    


