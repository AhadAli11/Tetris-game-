etris Game in Assembly (Irvine32)
This project is a Tetris game made using Assembly Language (x86 architecture) and Irvine32 library. It runs in the Windows console and simulates the classic Tetris game using blocks, score tracking, and keyboard controls.

📋 Features
Console-based Tetris game.

Blocks (tetrominoes) fall automatically.

Move blocks left or right using:

A key – move left

D key – move right

Blocks stack when they reach the bottom or collide with others.

Complete rows are cleared automatically.

Score increases as you clear rows.

Game over detection when blocks reach the top.

Display of score and "Game Over" message.

🛠 Technologies Used
Assembly Language (x86)

Irvine32 Library (for console display and input handling)

MASM (Microsoft Macro Assembler)

🎮 How to Play
Run the program using MASM assembler with Irvine32 support.

Blocks will automatically fall from the top.

Press:

A to move block left.

D to move block right.

Try to create full horizontal rows to clear them and increase your score.

If blocks reach near the top of the board, the game ends with a "GAME OVER" message.

📂 Project Structure
main PROC – Main game logic and game loop.

DrawTetromino – Draws the falling block.

EraseTetromino – Erases the block before moving it.

HandleInput – Handles A and D key presses.

StoreTetrominoInBoard – Marks block's final position in the grid.

ClearFullRows – Checks for and clears full rows.

DisplayScore – Shows the player's score.

CheckGameOver – Detects and handles game over.

CleanBoardVisuals – Refreshes the board display.

📌 Requirements
Windows OS

MASM assembler with Irvine32 library installed

A console window to play

📥 How to Run
Assemble and link using MASM with Irvine32:

bash
Copy
Edit
ml /c /coff tetris.asm
link /subsystem:console tetris.obj Irvine32.lib
Run the generated .exe file in the console.

💡 Notes
Blocks currently fall vertically or horizontally (depending on block type).

Rotation of blocks is not implemented yet.

Only left and right movements are supported.

The game ends when the stacked blocks touch the top of the board.

📊 Future Improvements (Optional)
Add rotation feature for tetrominoes.

Implement more tetromino shapes.

Add a speed increase as score grows.

Add background music or sound effects.
