INCLUDE Irvine32.inc
INCLUDELIB user32.lib

GetAsyncKeyState PROTO STDCALL :DWORD

.data
;game over
gameOverMsg BYTE "GAME OVER", 0


;for score
score DWORD 0                    ; Initialize score to 0
scoreMsg BYTE "Score: ", 0       ; Label for score



; Grid dimensions (playable area)
GRID_WIDTH  EQU 16
GRID_HEIGHT EQU 22

; Game state
gameBoard   BYTE GRID_WIDTH * GRID_HEIGHT DUP(0) ; 0 = empty, 1 = occupied
block       BYTE 219      ; Block character (?)
space       BYTE ' '      ; Space character

; Tetromino position (top-left corner of the 4x4 matrix)
tetromino_pos_row DWORD 0 ; Adjusted to row  for vertical centering
tetromino_pos_col DWORD 8 ; Start at column 5 (center of 14 columns)

; I-tetromino definition (4x4 matrix)

tetromino_T BYTE 1,0,0,0
            BYTE 1,0,0,0
            BYTE 1,0,0,0
            BYTE 0,0,0,0

tetromino_I BYTE 0,0,0,0
            BYTE 1,1,1,1
            BYTE 0,0,0,0
            BYTE 0,0,0,0

tetromino_0 BYTE 0,0,0,0
            BYTE 0,0,0,0
            BYTE 0,0,1,1
            BYTE 0,0,1,1

tetromino_L BYTE 0,0,0,0
            BYTE 0,0,0,0
            BYTE 0,0,0,1
            BYTE 1,1,1,1
           
tetromino_Z BYTE 1,1,0,0
            BYTE 0,1,1,0
            BYTE 0,0,0,0
            BYTE 0,0,0,0

tetromino_j BYTE 1,0,0,0
            BYTE 1,1,1,0
            BYTE 0,0,0,0
            BYTE 0,0,0,0

; Debug message
msg BYTE "Drawing tetromino...", 0

.code
main PROC
    call Clrscr
    mov eax, white + (black * 16)
    call SetTextColor

    ; Print top wall
    mov ecx, GRID_WIDTH + 2
print_top_wall:
    mov al, block
    call WriteChar
    loop print_top_wall

    call Crlf

    ; Print side walls
    mov ecx, GRID_HEIGHT
print_leftright_wall:
    mov al, block
    call WriteChar

    push ecx
    call SpacePrinter
    pop ecx

    mov al, block
    call WriteChar

    call Crlf
    loop print_leftright_wall

    ; Bottom wall
    mov ecx, GRID_WIDTH + 2
print_bottom_wall:
    mov al, block
    call WriteChar
    loop print_bottom_wall
                          ; board is created ider 
    ;socore calling
    call DisplayScore

    ; Game loop: let the tetromino fall
main_game_loop:
    mov tetromino_pos_row, 0     ; Reset position to top

tetromino_fall_loop:
    call DrawTetromino
     call HandleInput
    ; Delay ~300 ms (adjust as needed)
    mov eax, 300
    call Delay

    call EraseTetromino

       ; Check if next move will cause collision
    pushad
    mov ecx, 0   ; row counter
check_collision_rows:
    cmp ecx, 4
    jge no_collision

    mov edx, 0   ; col counter
check_collision_cols:
    cmp edx, 4
    jge next_check_row

    ; Check if tetromino_I[ecx * 4 + edx] is 1
    mov eax, ecx
    imul eax, 4
    add eax, edx
    movzx ebx, tetromino_I[eax]
    cmp bl, 1
    jne skip_check

    ; Calculate next row and col
    mov eax, ecx
    add eax, tetromino_pos_row
    inc eax                      ; one row down
    cmp eax, GRID_HEIGHT
    jge collision_detected       ; hit bottom

    mov esi, edx
    add esi, tetromino_pos_col
    mov edi, eax
    imul edi, GRID_WIDTH
    add edi, esi
    cmp gameBoard[edi], 1
    je collision_detected

skip_check:
    inc edx
    jmp check_collision_cols

next_check_row:
    inc ecx
    jmp check_collision_rows

no_collision:
    popad
    add tetromino_pos_row, 1
    jmp tetromino_fall_loop

collision_detected:
    popad

    ; Draw final position one last time (optional visual clarity)
    call DrawTetromino

    ; Store final position into gameBoard so it's solid
    call StoreTetrominoInBoard
    call CleanBoardVisuals
    call CheckGameOver             ; chk ager game over

    call ClearFullRows

    ; Small delay to show stacking
    mov eax, 100
    call Delay

    ; Start falling next tetromino from top
    jmp main_game_loop



    ; Final draw at bottom
    call DrawTetromino

    ; Optional delay to pause before next block
    mov eax, 100
    call Delay

    jmp main_game_loop     ; Repeat with new tetromino

    exit
main ENDP

; Procedure to print 14 spaces (matching 14-column playable width)
SpacePrinter PROC
    mov edx, GRID_WIDTH
print_space_loop:
    mov al, space
    call WriteChar
    dec edx
    jnz print_space_loop
    ret
SpacePrinter ENDP

; Procedure to draw the I-tetromino
DrawTetromino PROC
    pushad

    
    xor esi, esi          ; row counter (0 to 3)
row_loop:
    cmp esi, 4
    jge end_draw

    xor edi, edi          ; col counter (0 to 3)
col_loop:
    cmp edi, 4
    jge next_row

    ; index = (row * 4) + col
    mov eax, esi
    imul eax, 4
    add eax, edi
    movzx ebx, tetromino_I[eax]  ; load value (0 or 1)
    cmp bl, 1
    jne skip_block

    ; --- Calculate position for Gotoxy ---
    ; Row (dh)
    mov eax, esi
    add eax, tetromino_pos_row
    add eax, 1               ; +1 for top wall
    mov dh, al

    ; Column (dl)
    mov eax, edi
    add eax, tetromino_pos_col
    add eax, 1               ; +1 for left wall
    mov dl, al
    
    cmp dh, GRID_HEIGHT + 1
jge skip_block
cmp dl, GRID_WIDTH + 1
jge skip_block

    call Gotoxy
    mov al, block
    call WriteChar

skip_block:
    inc edi
    jmp col_loop

next_row:
    inc esi
    jmp row_loop

end_draw:
    popad
    ret
DrawTetromino ENDP


; Procedure to erase the I-tetromino
EraseTetromino PROC
    pushad

    xor esi, esi
row_loop_e:
    cmp esi, 4
    jge end_erase

    xor edi, edi
col_loop_e:
    cmp edi, 4
    jge next_row_e

    ; index = (esi * 4) + edi
    mov eax, esi
    imul eax, 4
    add eax, edi
    movzx ebx, tetromino_I[eax]
    cmp bl, 1
    jne skip_erase

    ; Calculate Gotoxy position
    mov eax, esi
    add eax, tetromino_pos_row
    add eax, 1
    mov dh, al

    mov eax, edi
    add eax, tetromino_pos_col
    add eax, 1
    mov dl, al
    cmp dh, GRID_HEIGHT + 1
 jge skip_erase

cmp dl, GRID_WIDTH + 1
 jge skip_erase


    call Gotoxy
    mov al, space
    call WriteChar

skip_erase:
    inc edi
    jmp col_loop_e

next_row_e:
    inc esi
    jmp row_loop_e

end_erase:
    popad
    ret
EraseTetromino ENDP



StoreTetrominoInBoard PROC
    pushad
    xor esi, esi
store_row_loop:
    cmp esi, 4
    jge store_done
    xor edi, edi
store_col_loop:
    cmp edi, 4
    jge next_store_row
    mov eax, esi
    imul eax, 4
    add eax, edi
    movzx ebx, tetromino_I[eax]
    cmp bl, 1
    jne skip_store

    ; Calculate final position
    mov ecx, esi
    add ecx, tetromino_pos_row
    mov edx, edi
    add edx, tetromino_pos_col

    ; Bounds check to avoid memory overrun
    cmp ecx, GRID_HEIGHT
    jge skip_store
    cmp edx, GRID_WIDTH
    jge skip_store

    ; Compute index in gameBoard safely
    mov eax, ecx
    imul eax, GRID_WIDTH
    add eax, edx
    mov gameBoard[eax], 1

skip_store:
    inc edi
    jmp store_col_loop
next_store_row:
    inc esi
    jmp store_row_loop
store_done:
    popad
    ret
StoreTetrominoInBoard ENDP
HandleInput PROC
    pushad

    ; Check if 'A' key (left) is pressed
    mov eax, 'A'
    invoke GetAsyncKeyState, eax
    test ax, 8000h
    jz check_right

    ; Check if move left is possible (only block cells matter)
    mov ecx, 0          ; row counter (0 to 3)
    mov ebx, 1          ; flag: 1 means can move left

check_left_rows:
    cmp ecx, 4
    jge left_check_done

    mov edx, 0          ; col counter (0 to 3)

check_left_cols:
    cmp edx, 4
    jge next_left_row

    ; index = (row * 4) + col
    mov eax, ecx
    imul eax, 4
    add eax, edx
    movzx esi, tetromino_I[eax]  ; get tetromino cell (0 or 1)
    cmp esi, 1
    jne skip_left_cell

    ; Calculate the position after moving left
    mov eax, ecx
    add eax, tetromino_pos_row    ; final row on board

    mov edi, edx
    add edi, tetromino_pos_col    ; final col on board
    dec edi                      ; after moving left (col-1)

    ; Check left boundary
    cmp edi, 0
    jl no_move_left

    ; Check collision with occupied gameBoard cell
    mov ebp, eax
    imul ebp, GRID_WIDTH
    add ebp, edi
    cmp gameBoard[ebp], 1
    je no_move_left

skip_left_cell:
    inc edx
    jmp check_left_cols

next_left_row:
    inc ecx
    jmp check_left_rows

left_check_done:
    cmp ebx, 1
    jne skip_left_move

    ; If flag is 1, move left
    dec tetromino_pos_col
    jmp check_right

no_move_left:
    mov ebx, 0
    jmp left_check_done

skip_left_move:
    ; Do nothing, cannot move left

check_right:
    ; Check if 'D' key (right) is pressed
    mov eax, 'D'
    invoke GetAsyncKeyState, eax
    test ax, 8000h
    jz done_input

    ; Check if move right is possible (only block cells matter)
    mov ecx, 0          ; row counter (0 to 3)
    mov ebx, 1          ; flag: 1 means can move right

check_right_rows:
    cmp ecx, 4
    jge right_check_done

    mov edx, 0          ; col counter (0 to 3)

check_right_cols:
    cmp edx, 4
    jge next_right_row

    ; index = (row * 4) + col
    mov eax, ecx
    imul eax, 4
    add eax, edx
    movzx esi, tetromino_I[eax]  ; get tetromino cell (0 or 1)
    cmp esi, 1
    jne skip_right_cell

    ; Calculate the position after moving right
    mov eax, ecx
    add eax, tetromino_pos_row    ; final row on board

    mov edi, edx
    add edi, tetromino_pos_col    ; final col on board
    inc edi                      ; after moving right (col+1)

    ; Check right boundary
    mov eax, GRID_WIDTH
    cmp edi, eax
    jge no_move_right

    ; Check collision with occupied gameBoard cell
    mov ebp, eax
    imul ebp, GRID_WIDTH
    add ebp, edi
    cmp gameBoard[ebp], 1
    je no_move_right

skip_right_cell:
    inc edx
    jmp check_right_cols

next_right_row:
    inc ecx
    jmp check_right_rows

right_check_done:
    cmp ebx, 1
    jne skip_right_move

    ; If flag is 1, move right
    inc tetromino_pos_col
    jmp done_input

no_move_right:
    mov ebx, 0
    jmp right_check_done

skip_right_move:
    ; Do nothing, cannot move right

done_input:
    popad
    ret
HandleInput ENDP



ClearFullRows PROC
    pushad

    mov esi, 0                  ; Start from row 0

check_next_row:
    cmp esi, GRID_HEIGHT
    jge done_check

    ; Check if row esi is full
    mov edi, esi
    imul edi, GRID_WIDTH        ; edi = start index of the row
    mov ecx, GRID_WIDTH
    xor ebx, ebx                ; Counter for full blocks

check_row_fill:
    mov al, gameBoard[edi]
    cmp al, 1
    jne row_not_full
    inc ebx
    inc edi
    loop check_row_fill

    ; If full, delete row
    cmp ebx, GRID_WIDTH
    jne row_not_full
    ;                          part to add scoree
    add score, 10
    call DisplayScore

    ; Move all rows above down by 1
    mov ecx, esi
shift_rows_down:
    cmp ecx, 0
    jl clear_top_row
    mov edi, ecx
    dec edi
    imul edi, GRID_WIDTH
    mov esi, ecx
    imul esi, GRID_WIDTH
    mov edx, 0

copy_row:
    cmp edx, GRID_WIDTH
    jge next_shift
    mov al, gameBoard[edi + edx]
    mov gameBoard[esi + edx], al
    inc edx
    jmp copy_row

next_shift:
    dec ecx
    jmp shift_rows_down

clear_top_row:
    ; Clear top row (row 0)
    mov edi, 0
    mov ecx, GRID_WIDTH
clear_top_loop:
    mov gameBoard[edi], 0
    inc edi
    loop clear_top_loop

    ; ADD DELAY to make cleared row effect visible
    mov eax, 400         ; Delay ~400 ms
    call Delay

    ; Clear all non-occupied spaces visually
    call ClearBoardArtifacts

    jmp check_next_row

row_not_full:
    inc esi
    jmp check_next_row

done_check:
    popad
    ret
ClearFullRows ENDP

; Clear all spaces on screen where gameBoard = 0
ClearBoardArtifacts PROC
    pushad

    mov esi, 0              ; row index
clear_rows:
    cmp esi, GRID_HEIGHT
    jge end_clear

    mov edi, 0              ; col index
clear_cols:
    cmp edi, GRID_WIDTH
    jge next_row_clear

    ; Calculate gameBoard index
    mov eax, esi
    imul eax, GRID_WIDTH
    add eax, edi
    cmp gameBoard[eax], 1
    je skip_clear

    ; Convert to screen position (dh, dl)
  mov eax, esi
add eax, 1
mov dh, al           ; al holds low 8 bits of eax

mov eax, edi
add eax, 1
mov dl, al
              ; offset for left wall
    call Gotoxy
    mov al, space
    call WriteChar

skip_clear:
    inc edi
    jmp clear_cols

next_row_clear:
    inc esi
    jmp clear_rows

end_clear:
    popad
    ret
ClearBoardArtifacts ENDP

CleanBoardVisuals PROC
    pushad

    mov esi, 0              ; row index
clean_rows:
    cmp esi, GRID_HEIGHT
    jge end_clean

    mov edi, 0              ; col index
clean_cols:
    cmp edi, GRID_WIDTH
    jge next_clean_row

    ; Calculate gameBoard index
    mov eax, esi
    imul eax, GRID_WIDTH
    add eax, edi
    mov bl, gameBoard[eax]

    ; Convert to screen position (dh, dl)
    mov eax, esi
    add eax, 1              ; +1 for wall
    mov dh, al

    mov eax, edi
    add eax, 1              ; +1 for wall
    mov dl, al

    call Gotoxy
    cmp bl, 1
    je draw_block

    mov al, space
    call WriteChar
    jmp next_cell

draw_block:
    mov al, block
    call WriteChar

next_cell:
    inc edi
    jmp clean_cols

next_clean_row:
    inc esi
    jmp clean_rows

end_clean:
    popad
    ret
CleanBoardVisuals ENDP


; score pro
DisplayScore PROC
    pushad

    ; Calculate display position (below the board)
    mov dh, GRID_HEIGHT + 3      ; 1 line below bottom wall
    mov dl, 0                    ; start at leftmost column
    call Gotoxy

    ; Print "Score: "
    lea edx, scoreMsg
    call WriteString

    ; Print the score number
    mov eax, score
    call WriteDec

    popad
    ret
DisplayScore ENDP

 ;                    game over ky liya 

 CheckGameOver PROC
    pushad

    mov ecx, GRID_WIDTH         ; Number of columns in top row
    mov esi, 1      ; row index 2 (3rd row)
    imul esi, GRID_WIDTH ; to get start index of that row in gameBoard

check_cells:
    mov al, gameBoard[esi]
    cmp al, 1                   ; If cell is occupied
    je game_over

    inc esi
    loop check_cells
    popad
    ret                         ; No game over detected

game_over:
    ; Move cursor below score
    mov dh, GRID_HEIGHT + 4     ; Line below score
    mov dl, 0
    call Gotoxy

    ; Print "GAME OVER"
    mov edx, OFFSET gameOverMsg
    call WriteString

    ; Infinite loop to stop game
stop_game:
    jmp stop_game

    popad
    ret
CheckGameOver ENDP



END main