# Developer Guide

- how the functions are combined together
- which libraries are used for what purpose.

Our project has 3+2 source files: 

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
- move-piece-board: moves a piece from one position to another (by passing two posns)
- set-piece/set-null: helper functions to update board state (called by move-piece)
- in-bounds?: predicate that checks if the passed posn is within the board boundaries


---

### piece.rkt

- It defines:
- the piece structure.
- the Color type ("White" or "Black")
- the GameState type, that is a Vector<Vector> where each inner vector represents a row of the chessboard and the elements are a piece or an empty square (a 0).
- Various types of move, like diagonal, vertical, for the knight, for the rook, etc.
- The elements of the chessboard: the alternated square colors, the square size, the ratio for rendering pieces relatively to the square size, the chessboard itself and the empty chessboard.
- The images for the various pieces.
- The dimensions of the various pieces.
- The BOARD-VECTOR: the initial setup of the chessboard, with all the pieces in their starting positions.