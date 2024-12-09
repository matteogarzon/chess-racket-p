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





