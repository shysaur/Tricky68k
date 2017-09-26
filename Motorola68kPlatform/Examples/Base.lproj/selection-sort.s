

    ; 
    ; Selection Sort
    ;
    ; Selection Sort is one of the simplest sorting algorithms and, like
    ; the more widely known Bubble Sort, its performance is O(n^2).
    ;
    ;   It works by swapping the first item of the array with the smallest item
    ; in it, and then recursively doing the same for the sub-array which we
    ; get by removing the first item from the original array:
    ;
    ;   3  5  4  2  1
    ;  [1] 5  4  2  3     Put 1 in place; sub-array now is 5, 4, 2, 3
    ;  [1][2] 4  5  3     Put 2 in place; sub-array now is 4, 5, 3
    ;  [1][2][3] 5  4     Put 3 in place; sub-array now is 5, 4
    ;  [1][2][3][4] 5     Put 4 in place; sub-array now is 5
    ;  [1][2][3][4][5]    We're done
    ;
    ;   To make things simpler, instead of searching for the smallest number
    ; and switching it in place later, we switch in the smallest number while
    ; we are searching. This spares us from keeping track of the position of
    ; the smallest item, because we always switch it to the first slot.
    ;
    ;   3  5  4  2  1     Searching for a number lesser than 3
    ;  (3)>5  4  2  1
    ;  (3) 5 >4  2  1     4 and 5 are bigger than 3, do nothing
    ;  (2) 5  4 >3  1     2 < 3, switch them. Now search for a number < 2
    ;  (1) 5  4  3 >2     1 < 2, switch them. Now search for a number < 1
    ;  [1] 5  4  3  2     Got to the end of the array
    ;
    ;   This program keeps in D0 the current minimum, in A0 the starting
    ; address of the current array, and in A1 the address of the item which is
    ; being compared. You can scroll the RAM dump to the location of the data,
    ; and then you can step in repeatedly in the debugger to see the algorithm
    ; working.
    ;
    ;   Note that the usage of auto-incrementing addressing modes causes the
    ; contents of the address registers to be off by one item most of the
    ; time.
    ;


    public start        ;Make the entry point public
    org $2000           ;Place the origin at $2000


start:
    move.w #10,d2       ;Ten items to sort
    movea.l #data,a0    
    
.outer:
    tst.w d2
    beq .end            ;If no more items to be sorted, we're done
    
    move.w (a0)+,d0     ;Get the first item of the sub-array starting at A0
    move.l a0,a1        ;Get address of the next item in the sub-array
    move.w d2,d3        ;Get length of sub-array
    
.inner:                 ;Loop thru the items of the sub-array and find the
    sub.w #1,d3         ; minimum:
    tst.w d3
    beq .next           ;If checked all items, next sub-array
    
    move.w (a1)+,d1
    cmp.w d1,d0         ;If the first item (minimum) is greater than this item,
    ble .noswap         ; don't swap
    
    move.w d1,-2(a0)
    move.w d0,-2(a1)    ;Otherwise swap first item and this item
    move.w d1,d0        ;Keep first item register in sync
    
.noswap:
    bra .inner          ;Next item
    
.next:
    sub.w #1,d2
    bra .outer          ;Next sub-array
    
.end:
    bra .end            ;We're done, loop forever. You can breakpoint here
                        ;to see the results.


    org $3000           ;(place the data in an easy to scroll to place)

data:
    dc.w 10, 9, 40, 99, 3, 0, -1, 46, 37, 2

