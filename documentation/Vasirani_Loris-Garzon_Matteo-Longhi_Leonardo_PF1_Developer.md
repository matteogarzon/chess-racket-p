# Developer Guide

- how the functions are combined together
- which libraries are used for what purpose.

Our project has 3 source files: 

### main.rkt

- This is entry point of the program.
- We used the image and universe libraries for the graphics of the pieces and the chessboard and for creating the UI of the game.
- The functions defined are:
- For the Rendering:
- render: renders the screen based on GAME-STATE.
- render-welcome: renders the welcome screen.
- render-exit: shows a screen for confirming quitting or returning to the game.
- render-chessboard: renders the chessboard with the pieces based on the current state.

-For the Mouse Events:
- handle-mouse: handles mouse events for the game.
- inside-image?: checks if a mouse click is inside the boundaries of a specific piece.
- which-square?: converts mouse coordinates to the correspondent position on the board.
- highlight-piece: highlights the selected piece with a gold border.

For the Keyboard Events:
- handle-key: handles key events inside the program. More specifically: "g"= start the game; "q"= quit; "y"= confirm quitting; "n"= cancel quitting and go back to the game.
- end-game: ends the current game and in doing so resets the board.
- start-game: starts a new game by entering the gameplay state.
- exit-game: shows the screen for confirming the quitting.

For the Logic:
- get-valid-moves: determines which moves are valid for a specific piece. In this case, moves for pawns are a particular case and for bishops, rooks and the queen this function also uses `calculated-blocked-moves`.
- calculated-block-moves: calculates the valid moves for the pieces that could be blocked by other pieces.
- king-in-check?: controls if a king is in check.
- find-king: locates the position of a king of a specific color.
- get-check-path: determines the path of a piece that's putting the king in check.
- would-be-in-check?: checks if a specific move would put the king in a check position.
- make-transparent: creates a transparent version of a piece and it's used for captured pieces.
- same-color?: checks if two pieces are of the same color, so if they belong to the same player.
- handle-move: handles the moves of the various pieces and it also supports castling and promotion.
- reset-chessboard: resets the chessboard to the initial state.
- change-turn: alternates the turns between the two players.

Other functions defined are:
- vector-to-list-of-lists: converts a Vector<Vector> to a List<List>.
- vector-copy-deep: creates a deep copy of a vector and it's needed for the test board.
- get-winner-text: returns the message for the winning player.
- big-bang: used to manage the game state and the various events. It uses `on-mouse` for the mouse events, `on-key` for the key events and `to-draw` for the rendering.
---

### logic.rkt

- The core logic of the game.
- the structure piece is defined: represents a chess piece with properties like type, movement patterns, color, player, etc.
- Here are created the constants for the diagonal moves, vertical moves, horizontal moves, knight moves, king and queen moves and rook moves.

- in-bounds?: checks if a position is inside the chessboard boundaries.
- get-piece: retrieves a piece at a given position
- move-piece: moves a piece from one position to another (by passing two posns)
- set-piece/set-null: helper functions to update board state (called by move-piece)
- in-bounds?: predicate that checks if the passed posn is within the board boundaries
- my-piece?: predicate that checks if a piece belongs to the local player
- is-there-piece?: predicate that checks if any piece exists at the given posn
- is-there-opponent-piece?: predicate that checks if there’s an opponent’s piece at the given posn
- move-one-forward?: checks if the piece can move one square forward.
- move-two-forward?: checks if the piece can move two squares forward, like the pawn in its first move.
- move-left-diagonal?: checks if the piece can move diagonally to the left.
- move-right-diagonal?: checks if the piece can move diagonally to the right.
- move-piece-board: moves the piece from its initial position to another one and updates the board accordingly.
- set-piece-board: sets a piece on the chessboard.
- set-null-board: removes a piece from a certain position on the chessboard.
- checkmate: checks if a move results in a checkmate and so if the game ends according to that.
- can-move-two-right?: checks if a piece can move two squares to the right .
- can-move-two-left?: checks if a piece ca move two square to the left.
- can-castle-right?: checks if the king can castle to the right.
- can-castle-left?: checks if the king can castle to the left.
- castling: allows castling when possible.
-move-one-forward: allows the piece to move one square forward.
-move-left-diagonal: allows the piece to move diagonally to the left.
-move-right-diagonal: allows the piece to move diagonally to the right.

---

### server.rkt

- It hosts the game, by obtaining and managing the server's IP address

**Libraries**

- Since we use TCP/IP protocols for network communication, we use the racket/tcp library.
- For the “obtain-ip” function, we need the racket/udp library since we don’t need to send any data - it’s enough to create a connection attempt.

Let’s focus on each function:

- obtain-ip
    - It gets the server's IP address by attempting to connect to Google's DNS (8.8.8.8). If the connection fails, it exits the program.
- connection-management: It announces the connection, and sends the player's color (assigned by the server) to client
- player-connection: it accepts incoming TCP connections and sets up input/output ports for the players.
- receive-move: receives and validates moves from players and handles disconnections
- check-move: validates chess moves using functions from logic.rkt
- interpret-move
    - Interprets the moves according to the input, defining how the game state will have to be updated, based on a disconnection, quitting, invalid move or instead a valid move.
- game-management
    - It manages a single game between the two players, by: validating the moves, updating the game state, handling invalid moves, and managing the game termination
- close-connection: closes input ports, output ports, and the TCP listener
- game-session
    - Handles a game session composed of multiple games between the same players.
- multiple-games
    - Handles multiple game sessions, by waiting for the player connection, asking the user to play again, and therefore managing game restarts
- start-server
    - Main server entry point
    - Sets up TCP listener
    - Displays connection info
    - Monitors for quit command
    - Starts game management
    - Handles port conflicts

---

### client.rkt

- It’s responsible to connect the computer (the client) to the server that hosts the game.

**Libraries**

- Since we use TCP/IP protocols for network communication, we use the racket/tcp library

**Code and Functions**

A variable CHESS-COLOR is declared to store whether the player’s pieces are black or white. This is done a color is assigned randomly to each player. Let’s focus on the functions: 

- connect-ip
    - It prompts the user for an IP address.
    - It handles connection errors gracefully
- connect-to-server
    - It establishes the connection to the server using the typed IP and port (1234, randomly chosen)
- send-move-to-server
    - Sends the player's moves to the server.
- receive-move-from-server
    - This function receives the opponent’s moves from the server, converting before-move and after-move into posns (since they were sent as numbers)
    - It also makes sure these move are valid, by using “in-bounds”.
- disconnect-client: disconnects the client from the server
- handle-game-session
   - Allows and handles a game session composed of multiple games between the same players.
   - It’s responsible for managing the game flow, by doing the following:
    - It receives the player's color (assigned by the server).
    - It handles the feature to play again after a game ends, namely by continuing with a new game or quit the connection.
- start-client
    - The entry point of this file, called by main.rkt. It initiates the game handling (handle-game).