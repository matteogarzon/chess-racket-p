# User Guide

### What does the program do?

- This is a chess game, that can be played with another computer through the network.

### How to run the program

Before running the program, make sure all the source folder nor files have not been modified! Most importantly, both players need to be connected to a network, otherwise you won’t be able to play. 

After these initial steps, follow this procedure:

1. Open the MAIN file in the Racket code editor, or any other IDE of your choice that can run code in the Racket language. 
2. You’ll be presented with a welcome page with the instructions on how to run the program. 
3. Namely, to host a game (i.e., server), press “h”. To instead join a game (i.e., client), press “j”). 

- If you host a game, on the terminal screen of Racket the IP and port of the server will show. To terminate the server anytime press “q” and Enter.
- To join a game, on the terminal screen of Racket type the IP and port of the server.
- Of the two players, only one can host, and the other one must join.

### How to use the program

The gameplay is straightforward:

- To start moving your own piece, select one of your choice. Dots will show on different squares, indicating on which places the piece can be moved to.
- To make the move, select one of the dots. The piece won’t move if you select any other square!
- You can’t move the opponent’s pieces. Once the opponent moves a pawn, you will see the change on your chessboard.

- To help the player, when moving the King, red dots will show to indicate in which positions the King will be in check afterwards.
- The game ends once the King has been checked.

- To exit the game anytime, press “q”. Scared of pressing it by mistake? No worries, there’ll be a prompt page asking for confirmation (”y” to official ending the game, “n” to resume).