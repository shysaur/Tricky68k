

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


    public start    ;Make the entry point public
	org $2000		;Place the origin at $2000


TTY:              equ $FFE000
X_CELL:           equ 1
PLR_CELL:         equ X_CELL
EMPTY_CELL:       equ 0
O_CELL:           equ -1
OPPONENT_CELL:    equ O_CELL


    ;Main game loop
start:
    bsr initBoard               ;Clear the game board
    move.w #X_CELL,whoseTurn    ;The first player is always X
    
    bsr askOrder                ;Ask who goes first
    bne .cpuenter               ;Jump to the CPU turn execution if CPU first
    bsr printBoard              ;Otherwise show the empty board to the user
.loop:
    bsr playerTurn              ;Player turn!
    bsr checkGameOver
    bne .gameEnd
    bsr checkDraw               ;Check if game ended (user won or draw)
    bne .gameDraw               ;We could omit this since the player can't win!
    
    neg.w whoseTurn             ;Switch X/O flag
.cpuenter
    bsr cpuTurn                 ;CPU turn! Run the AI
    bsr printBoard              ;Show the board after the two moves
    bsr checkGameOver
    bne .gameEnd
    bsr checkDraw
    bne .gameDraw               ;Check if game ended (CPU won or draw)
    
    neg.w whoseTurn             ;Switch X/O flag
    bra .loop                   ;Next loop
    
    ;Branched here if game ended with a draw
.gameDraw:
    move.l #drawString,a0
    bsr printLine               ;Say "draw..."
    bra start                   ;Restart the game
    
.gameEnd:
    bmi .odidwin                ;If O did win, print the "O has won" string
    move.l #XString,a0
    bsr printLine               ;Otherwise print the "X has won string
    bra start                   ;Restart the game
.odidwin:
    move.l #OString,a0
    bsr printLine               ;Print the "O has won" string
    bra start                   ;Restart the game
    
    
    ;Ask the player who will go first.
    ;output D0.w, flags: 0 if player first, 1 if CPU first
askOrder:
    movea.l #orderQuery,a0
    bsr printLine               ;Print the "who goes first?" string
    movea.l #keyBuffer,a0
    bsr getLine                 ;Read a line of characters from the TTY
    
    movea.l #keyBuffer,a0
    clr.w d0                    ; Look for the first number that is zero or 1:
.checknumber:
    move.b (a0)+,d0             ;Read next character
    beq askOrder                ;If zero, line has ended, try again
    sub.b #'0',d0
    blt .checknumber            ;If character < '0', try next character
    cmp.b #1,d0
    bgt .checknumber            ;If character > '1', try next character
    and.b d0,d0                 ;Set the zero flag according to the value of D0
    rts                         ;Return
    

    ;Execute a player turn (ask the player which move to perform)
playerTurn:
    movea.l #moveQuery,a0
    bsr printLine               ;Print the "?" prompt
    movea.l #keyBuffer,a0
    bsr getLine                 ;Read a line of characters from the TTY
    
    movea.l #keyBuffer,a0
    clr.w d0                    ; Look for the first N that is 1 <= N <= 9
.checknumber:
    move.b (a0)+,d0             ;Read next character
    beq playerTurn              ;If zero, line has ended, try again
    sub.b #'1',d0               ;Offset the character to get a 0-8 integer
    blt .checknumber            ;If character < '1', try next character
    cmp.b #9,d0
    bgt .checknumber            ;If character > '9', try next character
    add.w d0,d0                 ;Get the offset in the board array
    move.l #board,a0
    move.w (a0,d0),d1           ;Read the current contents of the chosen cell
    bne playerTurn              ;If cell not empty, try again
    move.w whoseTurn,(a0,d0)    ;Otherwise move in that cell
    rts                         ;Return
    
    
    ;Execute a CPU turn (running the AI)
    ;The AI consists in trying to do a list of more-or-less clever things,
    ;until one succeeds. Each sub-function must return in D0 if it succeeded
    ;(non zero) or not (zero).
cpuTurn:
    movea.l #.jumpTable,a0
.loop:
    movea.l (a0)+,a1            ;Read the next subfunction's entry point
    move.l a0,-(sp)  
    jsr (a1)                    ;Call the subfunction
    move.l (sp)+,a0       
    and.w d0,d0                 ;Check if it succeeded
    beq .loop                   ;If not, try the next subfunction
    rts                         ;Otherwise we're done, return
    
.jumpTable:
    dc.l cpuWin
    dc.l cpuBlockWin
    dc.l cpuBlockFork
    dc.l cpuFirstCorner
    dc.l cpuCenter
    dc.l cpuCorner
    dc.l cpuSide
    dc.l cpuSuccess             ;(should never execute)
    
    
    ;If the CPU has 2 in a row and a free cell, move in that cell to win.
cpuWin:
    suba.l a0,a0
.loop:
    bsr getPlayerRowAndStats    ;Get the next row
    cmp.b #2,d3
    bne .nomatch                
    cmp.b #1,d4                 ;Try next row if this row doesn't have 2 CPU
    bne .nomatch                ; cells and a free cell.
    bra moveFirstEmpty          ;Otherwise move in the empty cell and win
.nomatch:
    add.w #3,a0
    cmp.w #8*3,a0
    bne .loop                   ;Loop thru all the possible rows
    bra cpuFail                 ;If no match anywhere, fail
    
    
    ;If the opponent has 2 in a row and a free cell, move in that cell to
    ;prevent the opponent from winning.
cpuBlockWin:
    suba.l a0,a0
.loop:
    bsr getPlayerRowAndStats    ;Get the next row
    cmp.b #2,d5
    bne .nomatch
    cmp.b #1,d4                 ;Try next row if this row doesn't have 2
    bne .nomatch                ; opponent cells and a free cell
    bra moveFirstEmpty          ;Otherwise move the empty cell to block the win
.nomatch:
    add.w #3,a0
    cmp.w #8*3,a0
    bne .loop                   ;Loop thru all the possible rows
    bra cpuFail                 ;If no match anywhere, fail
    
    
    ;Try to block a fork. 
    ;  A fork is a common technique to stump inexperienced player. It consists
    ;of moving in such a way that in the end you simultaneously have more than 
    ;one way to win. The pre-final state of a fork may be one of these two: 
    ;
    ; 1)  . |   | X    2)  X | . | X      (Only X shown. When the board is in
    ;    ---+---+---      ---+---+---     this state, you can move in any of
    ;       | X | .          |   | .      the cells marked with a dot to win,
    ;    ---+---+---      ---+---+---     unless the opponent already occupies
    ;     . |   | X          |   | X      one of them)
    ;
    ;As it is obvious from the drawing, to use this trick you need three turns,
    ;thus it is impossible to leverage it if you are playing as O (because in 4
    ;turns X can easily win before you).
    ;  If you are playing as X, in the second turn the CPU always plays the 
    ;top-left corner or the center, thus it is impossible to make a type 1 fork
    ;because it would involve moving in the corners before the center, and
    ;the CPU moves in the center as soon as it is possible.
    ;  There are no implicit protections for a type 2 fork though. This fork 
    ;involves moving in two opposite corners, and then in one of the two free
    ;corners left.
    ;  Since moving in the first corner makes the CPU move in the center, we
    ;can detect this fork attempt by checking if the player moved in two
    ;opposite corners, and then moving in any side cell, causing
    ;an immediate threat for X.
    ;
    ;  X | O | 
    ; ---+---+---    X must move in the cell marked by a dot. Then, the CPU
    ;    | O |       will see a potential win for X in the bottommost row
    ; ---+---+---    and will move in the * cell, killing the fork attempt.
    ;  * | . | X
    ;
    ;Note that the instinctive way of the inexperienced player to respond to a 
    ;fork is to move in a corner himself, which merely leaves the other corner
    ;available for completing the fork.
cpuBlockFork:
    movea.l #18,a0
    bsr .test                   ;Check the left-to-right diagonal
    bne cpuSuccess              ;We're done if we found the fork there
    movea.l #21,a0              ;Otherwise check the other diagonal
.test:
    bsr getPlayerRowAndStats
    and.w d0,d0                 ;If the CPU has already moved in a corner of
    bpl cpuFail                 ; this diagonal, the player can't fork there.
    beq cpuFail                 ;Not a fork if a cell is still empty
    cmp.w d0,d2                 ;If the opponent took both corners of the
    beq cpuSide                 ; diagonal, it's a fork: move in a side
    bra cpuFail                 ;Otherwise, fail
    
    
    ;Move in a corner only if the board is clear.
cpuFirstCorner:
    moveq.l #9,d1
    move.l #board,a0            ;Loop thru the whole board
.loop:    
    move.w (a0)+,d0
    bne cpuFail                 ;Fail if found a non-empy cell
    subq.l #1,d1
    bne .loop                   ;Loop until we have checked all the cells
    ;When we have checked all cells are empty fall down into cpuCorner to move
    ;in a corner.
    
    ;Try to move in a corner
cpuCorner:
    movea.l #18,a0
    bsr .test                   ;Try to move in the first diagonal
    bne cpuSuccess              ;If we succeeded, we're done
    movea.l #21,a0              ;Otherwise try the second diagonal
.test:
    bsr getPlayerRowAndStats
    and.w d0,d0                 
    beq moveIn1                 ;If the first corner is clear move there
    and.w d2,d2
    beq moveIn3                 ;If the second corner is clear move there
    bra cpuFail                 ;Otherwise fail
    
    
    ;Try to move in the center
cpuCenter:
    movea.l #18,a0              ;Get a diagonal
    bsr getPlayerRowAndStats
    and.w d1,d1
    beq moveIn2                 ;If the center is clear move there
    bra cpuFail                 ;Otherwise fail
    
    
    ;Try to move on a side
cpuSide:
    movea.l #4*3,a0
    bsr .test                   ;Try the top and bottom sides
    bne cpuSuccess              ;If success, we're done
    movea.l #1*3,a0             ;Otherwise try the left and right sides
.test:
    bsr getPlayerRowAndStats
    and.w d0,d0
    beq moveIn1                 ;Try one cell
    and.w d2,d2
    beq moveIn3                 ;Try the other cell
    bra cpuFail                 ;If both are taken, fail


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
    moveq.l #8,d7           ;Check all the rows, columns and diagonals
.loop:
    bsr getRowAndStats
    cmp.b #3,d3
    beq .done               ;If X took all the cells, he has won
    cmp.b #3,d5
    beq .done               ;Same thing for O
    adda.w #3,a0
    subq.w #1,d7
    bne .loop               ;Otherwise check next row/column/diagonal
    clr.w d0                ;If checked everything and nobody has won, return 0
.done:
    and.w d0,d0
    rts                     ;Return
    
    
    ;Checks for a draw. Returns DO.w zero if not, nonzero if yes.
checkDraw:
    move.l #board,a0
    moveq.l #9,d1           ;Check if all cells are taken
.loop:
    move.w (a0)+,d0
    beq .done               ;If found an empty cell, we're done, not a draw
    subq.l #1,d1
    bne .loop               ;Next cell
    and.w d0,d0             ;If all cells are filled, it's a draw. Update flags
.done:
    rts                     ;Return


    ;Initialize the game board
initBoard:
    move.b #9,d0
    movea.l #board,a0       ;Zero out all the cells
.loop:
    move.w #0,(a0)+         ;Zero out this cell
    subq.b #1,d0
    bne .loop               ;Zero out next cell
    rts                     ;Return


    ;Prints board
printBoard:
    move.b #3,d1                ;Print 3 rows
    movea.l #board,a0
    movea.l #(OXOtab+1),a1  
.loop:
    clr.w d2
    move.w #' ',TTY             ;Print a space
    move.w (a0)+,d0
    move.b (a1,d0.w),d2         ;Get the character for the leftmost cell
    move.w d2,TTY               ;Print it
    move.w #' ',TTY
    move.w #'|',TTY
    move.w #' ',TTY             ;Print spacers between leftmost and center cell
    move.w (a0)+,d0
    move.b (a1,d0.w),d2
    move.w d2,TTY               ;Print the center cell
    move.w #' ',TTY
    move.w #'|',TTY
    move.w #' ',TTY             ;Print spacers between center and rightmost cell
    move.w (a0)+,d0
    move.b (a1,d0.w),d2
    move.w d2,TTY               ;Print the rightmost cell
    subq.b #1,d1
    beq .return                 ;If last row, don't print the row separator
    movem.l d0-d1/a0-a1,-(sp)
    move.l #spacer,a0
    bsr printLine               ;Print the row separator
    movem.l (sp)+,d0-d1/a0-a1
    bra .loop                   ;Next row
.return:
    move.w #$0A,TTY             ;Print terminating newline
    rts                         ;Return


    ;Read the specified row/column/diagonal and compute some statistics, in
    ;respect to the current player
    ;input  A0: index in the search table of the row
    ;output D0, D1, D2: row asked, with 1 = current player
    ;       D3, D4, D5: player cells, empty cells, and opponent cells count
getPlayerRowAndStats:
    bsr getRowAndStats      ;Get absolute row data
    move.w whoseTurn,d6     ;If we're playing as X, we're already set
    bpl .done
    
    neg.w d0
    neg.w d1
    neg.w d2                
    exg d3,d5               ;Otherwise switch O for X
    
.done:
    rts                     ;Return
    
    
    ;Read the specified row/column/diagonal and compute some statistics.
    ;input  A0.l: index in the search table of the row (preserved)
    ;output D0.w, D1.w, D2.w: row asked
    ;       D3.l, D4.l, D5.l: X cells, empty cells, and O cells count
getRowAndStats:
    move.l a0,a3            ;Get the address of the row/column/diag
    adda.l #searchTable,a3  ; in the lookup table
    clr.l d3
    clr.l d4
    clr.l d5
    clr.l d6                ;Initialize variables
    move.l #board,a2        ;Use A2 as base register for indexing in the board
    
    move.b (a3),d6
    bsr .count              ;Read and count the first cell
    move.w d2,d0            ;Move in first cell register
    
    move.b 1(a3),d6
    bsr .count              ;Read and count the second cell
    move.w d2,d1            ;Move in the second cell register
    
    move.b 2(a3),d6         ;Read and count the third cell
.count:
    add.b d6,d6             ;Get the offset in the board for this cell
    move.w (a2,d6),d2       ;Read the cell in A2 (third cell reg)
    beq .empty              ;Count as empty if empty
    bmi .ocell              ;Count as O cell if contains O
    addq.b #1,d3            ;Otherwise count as X cell
    rts                     ;Return
.empty:
    addq.b #1,d4            ;(count as empty)
    rts
.ocell:
    addq.b #1,d5            ;(count as O cell)
    rts
    
    
    ;Move in the first empty cell of the specified row/column/diagonal
    ;input D0.w, D1.w, D2.w: row
    ;      A0.l: index in the search table of the row (not preserved)
moveFirstEmpty:
    and.w d0,d0
    beq moveIn1             ;If 1st cell empty, move there
    and.w d1,d1
    beq moveIn2             ;If 2nd cell empty, move there
    ;Otherwise assume the 3rd cell is empty and move there
    
    
    ;Move in the specified cell of the specified row/column/diagonal
    ;input  A0.l: index in the search table of the row (not preserved)
    ;output D0.l: = 1
moveIn3:
    adda.w #1,a0                ;Add 1 more to A0 (1+1=2)
moveIn2:
    adda.w #1,a0                ;Add 1 more to A0 (1=1)
moveIn1:                        ;Don't add anything to A0
    adda.l #searchTable,a0      ;Get the address of the cell index
    clr.l d0
    move.b (a0),d0              ;Read the index of the cell in the board
    add.b d0,d0                 ;Get the offset
    move.l #board,a0
    move.w whoseTurn,(a0,d0)    ;Move there
    moveq.l #1,d0               
    rts                         ;Return 1 (for success)
    
    
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
    dc.b 0, 1, 2                ; \
    dc.b 3, 4, 5                ;  > rows
    dc.b 6, 7, 8                ; /
    dc.b 0, 3, 6                ; \
    dc.b 1, 4, 7                ;  > columns
    dc.b 2, 5, 8                ; /
    dc.b 0, 4, 8                ; \
    dc.b 2, 4, 6                ; / diagonals


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
    


