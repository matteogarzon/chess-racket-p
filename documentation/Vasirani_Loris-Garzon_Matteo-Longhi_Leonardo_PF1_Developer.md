# Developer Guide

- how the functions are combined together
- which libraries are used for what purpose.

Our project has 3 source files: 

### main.rkt

- This is entry point of the program.
- We used the image and universe libraries for the graphics of the pieces and the chessboard and for creating the UI of the game.
- The functions defined are:
-

---

### logic.rkt

- The core logic of the game.
- the structure piece is defined: represents a chess piece with properties like type, movement patterns, color, player, etc.

- get-piece: retrieves a piece at a given position
- move-piece: moves a piece from one position to another (by passing two posns)
- set-piece/set-null: helper functions to update board state (called by move-piece)
- in-bounds?: predicate that checks if the passed posn is within the board boundaries
- my-piece?: predicate that checks if a piece belongs to the local player
- is-there-piece?: predicate that checks if any piece exists at the given posn
- is-there-opponent-piece?: predicate that checks if there’s an opponent’s piece at the given posn

Let’s focus on how the moves for each piece are calculated: 

**Pieces Movement** (calculate-all-moves)

- It calculates moves for non-pawn pieces
- It handles repeatable movements (like bishops/rooks, by calling recursively this function!)
- It prevents moving through pieces

**Pawn Movement** (possible-pawn-moves)

- Since pawn have special rules, a dedicated function was created for it. It handles forward movement (one or two squares from starting position), and diagonal captures.

**Special King Movement** (calculate-all-kings-moves)

- It calculates the moves by calling “calculate-all-moves”, but it also handles castling rules through helper functions: castling, can-castle-right?, can-castle-left?.

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