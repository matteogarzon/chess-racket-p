-------------------------------
CHESS GAME by Leonardo Longhi, Matteo Garzon and Loris Vasirani
-------------------------------

The initial idea was to implement a code for the server and a code for the client and the program should have worked this way:
1. Open the MAIN file in the Racket code editor, or any other IDE of your choice that can run code in the Racket language. 
2. You’ll be presented with a welcome page with the instructions on how to run the program. 
3. Namely, to host a game (i.e., server), press “h”. To instead join a game (i.e., client), press “j”). 

- If you host a game, on the terminal screen of Racket the IP and port of the server will show. To terminate the server anytime press “q” and Enter.
- To join a game, on the terminal screen of Racket type the IP and port of the server.
- Of the two players, only one can host, and the other one must join.

But the networking part starts and is able to connect the two players, but it doesn't support an effective game. However, in the archive is present a folder named `chess-racket-with-server` with the program that uses the networking, comprehensive of the code for the game itself, the logic, the server, the client and the images for the pieces.

----- Functions -----

- Implemented the function `render-welcome` that renders the welcome screen.

- Implemented the function `render-exit` that shows a screen for confirming quitting or returning to the game.

- Implemented the function `render-chessboard` that renders the chessboard with the pieces based on the current state.

- Implemented the function `inside-image?` that checks if a mouse click is inside the boundaries of a specific piece.

- Implemented the function `highlight-piece` that highlights the selected piece with a gold border.

- Implemented the function `handle-key` that handles key events inside the program. More specifically: "g"= start the game; "q"= quit; "y"= confirm quitting; "n"= cancel quitting and go back to the game.

- Implemented the function `end-game` that ends the current game and in doing so resets the board.

- Implemented the function `start-game` that starts a new game by entering the gameplay state.

- Implemented the function `exit-game` that shows the screen for confirming the quitting.

- Implemented the function `get-valid-moves` that determines which moves are valid for a specific piece. In this case, moves for pawns are a particular case and for bishops, rooks and the queen this function also uses `calculated-blocked-moves`.

- Implemented the function `calculated-block-moves` that calculates the valid moves for the pieces that could be blocked by other pieces.

- Implemented the function `king-in-check?` that controls if a king is in check.

_ Implemented the function `find-king` that locates the position of a king of a specific color.

- Implemented the function `get-check-path` that determines the path of a piece that's putting the king in check.

- Implemented the function `would-be-in-check?` that checks if a specific move would put the king in a check position.

- Implemented the function `same-color?` that checks if two pieces are of the same color, so if they belong to the same player.

- Implemented the function `handle-move` that handles the moves of the various pieces and it also supports castling and promotion.

- Implemented the function `reset-chessboard` that resets the chessboard to the initial state.

- Implemented the function `change-turn` that alternates the turns between the two players.

- Implemented the function `vector-to-list-of-lists` that converts a Vector<Vector> to a List<List>.

- Implemented the function `vector-copy-deep` that creates a deep copy of a vector and it's needed for the test board.

- Implemented the function `get-winner-text` that returns the message for the winning player.

- Implemented the function 'move-piece-board` that moves the piece from its initial position to another one and updates the board accordingly.

- Implemented the function `set-piece-board` that sets a piece on the chessboard.

- Implemented the function `set-null-board` that removes a piece from a certain position on the chessboard.


- Remove the function `can-move-two-right?`, `can-move-two-left?`,`can-castle-right?` ,`can-castle-left?``castling`, `move-one-forward`, `move-left-diagonal`, `move-right-diagonal` from logic.rkt since it has been ported to main.rkt.


-------------------------------
%%%%%%%%%% MILESTONE %%%%%%%%%%
-------------------------------

- Implemented the following Data type:
  1. Piece
  2. List<Piece>
  3. Maybe<Channel>
  4. Color
  5. Client
  6. Player
  7. Movement

- Revised definition of data type Piece. Now, it a Piece is a structure and his fields are:
  1. position (Posn)
  2. dragged? (Boolean)
  3. img (Image)
  4. width (Number)
  5. height (Number)
  6. present? (Boolean)
  7. color (String)

- Defined the chessboard layout with alternating square colors and composed rows and the full board using geometric primitives

- Imported and scaled images for all chess pieces

- Positioned all pieces on the chessboard in their starting positions

- Defined constants for board square size, colors, and scaling ratios for piece images

- Defined the constant for waiting for incoming connection requests

- Defined the various types of moves

- Defined constant BOARD-VECTOR: the initial setup of the chessboard, with all the pieces in their starting positions.


----- Functions -----

- Implemented the function 'inside-image?' that checks if the mouse click is within the image's clickable area

- Implemented the function 'render-images' that renders the scene with all pieces

- Implemented the function 'render' that renders the chessboard with all pieces

- Implemented the function 'handle-drag' that updates the position of a piece that has been dragged

- Implemented the function 'which-square?' that returns the row and the column as a Posn

- Implemented the function 'put-piece' that places the dragged piece in the center of the square

- Implemented the function 'same-square?' that says if two pieces are in the same square

- Implemented the function 'same-square?' that says if two pieces are in the same square

- Implemented the function 'make-transparent' that makes a piece with 'present?' sets to #false transparent

- Implemented the function 'eaten-piece?' that checks if a piece has been eaten and creates a list with the piece that has 'present?' sets to false

- Implemented the function 'handle-button-down' that determines whether a mouse click interacts with any of the pieces, and if so, modifies the drag-state to #t

- Implemented the function 'handle-button-up' that snaps a dragged piece to the center of the nearest square upon releasing the mouse button, updates the board, and handles any pieces eaten by the dragged piece

- Implemented the function 'handle-mouse' that handles the mouse events

- Implemented the function 'connection-management' that manages the player's connections by informing that they connected and outputting the client that connected

- Implemented the function 'player-connection' that allows player's connections

- Implemented the function 'receive-move' that receives the player's moves

- Implemented the function 'interpret-move' that interprets the player's moves according the input received

- Implemented the function 'alternate-move' that alternates the moves between the two players, ensuring that they play alternately a turn each until the end the a match

- Implemented the function 'possible-pawns-moves' that returns a list of possible moves for pawns

- Implemented the function 'calculate-all-moves' that returns all possible moves used for non-pawn pieces

- Implemented the function 'calculate-move' that calculates move based on 'move' and 'current position'

- Implemented the function 'in-bounds' that determines if the new Posn is inside in the new chessboard

- Implemented the function 'move-piece' that moves piece from original Posn position to new position, and mutates BOARD-VECTOR accordingly

- Implemented some helper functions such as 'set-piece', 'set-null', 'get-piece', 'my-piece?', 'is-there-piece?', 'is-there-opponent-piece?'

- Implemented the function 'move-one-forward?' 

- Implemented the function 'move-two-forward?' 

- Implemented the function 'move-left-diagonal?' 

- Implemented the function 'move-right-diagonal?'