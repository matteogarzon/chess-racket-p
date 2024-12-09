;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-advanced-reader.ss" "lang")((modname piece) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #t #t none #f () #f)))
(require 2htdp/image)
(require 2htdp/universe)
(require racket/base)
(provide (struct-out piece))
(provide piece)
(provide BOARD-VECTOR)

; CONSTANTS
(define DIAGONAL-MOVES (list (make-posn 1 1) (make-posn 1 -1) (make-posn -1 1) (make-posn -1 -1)))
(define VERTICAL-MOVES (list (make-posn 1 0) (make-posn -1 0)))
(define HORIZONTAL-MOVES (list (make-posn 0 1) (make-posn 0 -1)))
(define KNIGHT-MOVES (list (make-posn 2 1) (make-posn 2 -1) (make-posn -2 1) (make-posn -2 -1) (make-posn 1 2) (make-posn 1 -2) (make-posn -1 2) (make-posn -1 -2)))
(define KING-QUEEN-MOVES (append DIAGONAL-MOVES VERTICAL-MOVES HORIZONTAL-MOVES))
(define ROOK-MOVES (append VERTICAL-MOVES HORIZONTAL-MOVES))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Data type ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; a Piece is a structure:
; where:
;   type           :    String         ; The type of piece (e.g., "pawn", "king")
;   movements      :    List<Posn>     ; List of possible movement directions
;   repeatable?    :    Boolean        ; Whether the piece can repeat its movement
;   player         :    Number         ; 1 for black, 2 for white
;   color          :    String         ; "black" or "white"
;   selected?      :    Boolean        ; Whether piece is currently selected
;   img            :    Image          ; Visual representation
;   width          :    Number         ; Width of piece image
;   height         :    Number         ; Height of piece image
;   present?       :    Boolean        ; Whether piece is still in play
; interpretation: a piece of the chessboard with his own type, movement-state,
; repeatable-state, player, color, selected-state, image, width, height, and present-state
(define-struct piece [type movement repeatable? player color selected? img width height present?] #:transparent)

; a Color is one of the following:
; - "White"
; - "Black"
; interpretation: the possible colors of the pieces

; a GameState is a Vector<Vector>
; interpretation: each inner vector represents a row on the board and each element is either a Piece or 0 (empty square)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Constants ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Defining the squares colors
(define SQUARE-COLOR-1 "light blue")   ; Color 1
(define SQUARE-COLOR-2 "white") ; Color 2

; Defining the side of the squares
(define SQUARE-SIDE 64)

; Defining the division ratio (i.e. how big the pieces are in relation to the squares on the board)
(define DIV-RATIO (/ SQUARE-SIDE 130))

; Creating the chessboard squares
(define CHESSBOARD-SQUARE-1 (rectangle SQUARE-SIDE SQUARE-SIDE "solid" SQUARE-COLOR-1)) ; Square 1
(define CHESSBOARD-SQUARE-2 (rectangle SQUARE-SIDE SQUARE-SIDE "solid" SQUARE-COLOR-2)) ; Square 2

; Creating a transparent square in which the pieces are placed
(define TRANSPARENT-CHESSBOARD (rectangle (* 8 SQUARE-SIDE) (* 8 SQUARE-SIDE) "solid" "transparent"))

; Defining the rows of the chessboard
; When the first square is color 110.21.
(define CHESSBOARD-ROW-1
  (beside (rectangle SQUARE-SIDE SQUARE-SIDE "solid" SQUARE-COLOR-1)
          (rectangle SQUARE-SIDE SQUARE-SIDE "solid" SQUARE-COLOR-2)
          (rectangle SQUARE-SIDE SQUARE-SIDE "solid" SQUARE-COLOR-1)
          (rectangle SQUARE-SIDE SQUARE-SIDE "solid" SQUARE-COLOR-2)
          (rectangle SQUARE-SIDE SQUARE-SIDE "solid" SQUARE-COLOR-1)
          (rectangle SQUARE-SIDE SQUARE-SIDE "solid" SQUARE-COLOR-2)
          (rectangle SQUARE-SIDE SQUARE-SIDE "solid" SQUARE-COLOR-1)
          (rectangle SQUARE-SIDE SQUARE-SIDE "solid" SQUARE-COLOR-2)))

; When the first square is color 2
(define CHESSBOARD-ROW-2
  (beside (rectangle SQUARE-SIDE SQUARE-SIDE "solid" SQUARE-COLOR-2)
          (rectangle SQUARE-SIDE SQUARE-SIDE "solid" SQUARE-COLOR-1)
          (rectangle SQUARE-SIDE SQUARE-SIDE "solid" SQUARE-COLOR-2)
          (rectangle SQUARE-SIDE SQUARE-SIDE "solid" SQUARE-COLOR-1)
          (rectangle SQUARE-SIDE SQUARE-SIDE "solid" SQUARE-COLOR-2)
          (rectangle SQUARE-SIDE SQUARE-SIDE "solid" SQUARE-COLOR-1)
          (rectangle SQUARE-SIDE SQUARE-SIDE "solid" SQUARE-COLOR-2)
          (rectangle SQUARE-SIDE SQUARE-SIDE "solid" SQUARE-COLOR-1)))

; Creating the chessboard
(define CHESSBOARD
  (above CHESSBOARD-ROW-2
         CHESSBOARD-ROW-1
         CHESSBOARD-ROW-2
         CHESSBOARD-ROW-1
         CHESSBOARD-ROW-2
         CHESSBOARD-ROW-1
         CHESSBOARD-ROW-2
         CHESSBOARD-ROW-1))

; Defining a scene with the empty chessboard
(define EMPTY-CHESSBOARD (overlay CHESSBOARD (empty-scene (* SQUARE-SIDE 8) (* SQUARE-SIDE 8))))

; Setting the images of the pieces
; Pawns
(define B-PAWN-IMAGE (scale/xy DIV-RATIO DIV-RATIO (bitmap "Images/Black Pieces/b-pawn.png"))) ; Black pawn
(define W-PAWN-IMAGE (scale/xy DIV-RATIO DIV-RATIO (bitmap "Images/White Pieces/w-pawn.png"))) ; White pawn

; Bishops
(define B-BISHOP-IMAGE (scale/xy DIV-RATIO DIV-RATIO (bitmap "Images/Black Pieces/b-bishop.png"))) ; Black bishop
(define W-BISHOP-IMAGE (scale/xy DIV-RATIO DIV-RATIO (bitmap "Images/White Pieces/w-bishop.png"))) ; White bishop

; Kings
(define B-KING-IMAGE (scale/xy DIV-RATIO DIV-RATIO (bitmap "Images/Black Pieces/b-king.png"))) ; Black king
(define W-KING-IMAGE (scale/xy DIV-RATIO DIV-RATIO (bitmap "Images/White Pieces/w-king.png"))) ; White king

; Queens
(define B-QUEEN-IMAGE (scale/xy DIV-RATIO DIV-RATIO (bitmap "Images/Black Pieces/b-queen.png"))) ; Black queen
(define W-QUEEN-IMAGE (scale/xy DIV-RATIO DIV-RATIO (bitmap "Images/White Pieces/w-queen.png"))) ; White queen

; Rooks
(define B-ROOK-IMAGE (scale/xy DIV-RATIO DIV-RATIO (bitmap "Images/Black Pieces/b-rook.png"))) ; Black rook
(define W-ROOK-IMAGE (scale/xy DIV-RATIO DIV-RATIO (bitmap "Images/White Pieces/w-rook.png"))) ; White rook

; Knights
(define B-KNIGHT-IMAGE (scale/xy DIV-RATIO DIV-RATIO (bitmap "Images/Black Pieces/b-knight.png"))) ; Black knight 
(define W-KNIGHT-IMAGE (scale/xy DIV-RATIO DIV-RATIO (bitmap "Images/White Pieces/w-knight.png"))) ; White knight

; Defining the images dimensions
(define pawn-width (image-width B-PAWN-IMAGE))   ; Pawn width
(define pawn-height (image-height B-PAWN-IMAGE)) ; Pawn height

(define bishop-width (image-width B-BISHOP-IMAGE))   ; Bishop width
(define bishop-height (image-height B-BISHOP-IMAGE)) ; Bishop height

(define king-width (image-width B-KING-IMAGE))   ; King width
(define king-height (image-height B-KING-IMAGE)) ; King height

(define queen-width (image-width B-QUEEN-IMAGE))   ; Queen width
(define queen-height (image-height B-QUEEN-IMAGE)) ; Queen height

(define rook-width (image-width B-ROOK-IMAGE))   ; Rook width
(define rook-height (image-height B-ROOK-IMAGE)) ; Rook height

(define knight-width (image-width B-KNIGHT-IMAGE))   ; Knight width
(define knight-height (image-height B-KNIGHT-IMAGE)) ; Knight height

; Defining the chessboard pieces
; White pawns
(define W-PAWN1 (make-piece "pawn" VERTICAL-MOVES #f 2 "white" #f W-PAWN-IMAGE pawn-width pawn-height #t))
(define W-PAWN2 (make-piece "pawn" VERTICAL-MOVES #f 2 "white" #f W-PAWN-IMAGE pawn-width pawn-height #t))
(define W-PAWN3 (make-piece "pawn" VERTICAL-MOVES #f 2 "white" #f W-PAWN-IMAGE pawn-width pawn-height #t))
(define W-PAWN4 (make-piece "pawn" VERTICAL-MOVES #f 2 "white" #f W-PAWN-IMAGE pawn-width pawn-height #t))
(define W-PAWN5 (make-piece "pawn" VERTICAL-MOVES #f 2 "white" #f W-PAWN-IMAGE pawn-width pawn-height #t))
(define W-PAWN6 (make-piece "pawn" VERTICAL-MOVES #f 2 "white" #f W-PAWN-IMAGE pawn-width pawn-height #t))
(define W-PAWN7 (make-piece "pawn" VERTICAL-MOVES #f 2 "white" #f W-PAWN-IMAGE pawn-width pawn-height #t))
(define W-PAWN8 (make-piece "pawn" VERTICAL-MOVES #f 2 "white" #f W-PAWN-IMAGE pawn-width pawn-height #t))

; White king
(define W-KING (make-piece "king" KING-QUEEN-MOVES #f 2 "white" #f W-KING-IMAGE king-width king-height #t))

; White queen
(define W-QUEEN (make-piece "queen" KING-QUEEN-MOVES #t 2 "white" #f W-QUEEN-IMAGE queen-width queen-height #t))

; White bishops
(define W-BISHOP1 (make-piece "bishop" DIAGONAL-MOVES #t 2 "white" #f W-BISHOP-IMAGE bishop-width bishop-height #t))
(define W-BISHOP2 (make-piece "bishop" DIAGONAL-MOVES #t 2 "white" #f W-BISHOP-IMAGE bishop-width bishop-height #t))

; White rooks
(define W-ROOK1 (make-piece "rook" ROOK-MOVES #t 2 "white" #f W-ROOK-IMAGE rook-width rook-height #t))
(define W-ROOK2 (make-piece "rook" ROOK-MOVES #t 2 "white" #f W-ROOK-IMAGE rook-width rook-height #t))

; White knights
(define W-KNIGHT1 (make-piece "knight" KNIGHT-MOVES #t 2 "white" #f W-KNIGHT-IMAGE knight-width knight-height #t))
(define W-KNIGHT2 (make-piece "knight" KNIGHT-MOVES #t 2 "white" #f W-KNIGHT-IMAGE knight-width knight-height #t))

; Black pawns
(define B-PAWN1 (make-piece "pawn" VERTICAL-MOVES #f 1 "black" #f B-PAWN-IMAGE pawn-width pawn-height #t))
(define B-PAWN2 (make-piece "pawn" VERTICAL-MOVES #f 1 "black" #f B-PAWN-IMAGE pawn-width pawn-height #t))
(define B-PAWN3 (make-piece "pawn" VERTICAL-MOVES #f 1 "black" #f B-PAWN-IMAGE pawn-width pawn-height #t))
(define B-PAWN4 (make-piece "pawn" VERTICAL-MOVES #f 1 "black" #f B-PAWN-IMAGE pawn-width pawn-height #t))
(define B-PAWN5 (make-piece "pawn" VERTICAL-MOVES #f 1 "black" #f B-PAWN-IMAGE pawn-width pawn-height #t))
(define B-PAWN6 (make-piece "pawn" VERTICAL-MOVES #f 1 "black" #f B-PAWN-IMAGE pawn-width pawn-height #t))
(define B-PAWN7 (make-piece "pawn" VERTICAL-MOVES #f 1 "black" #f B-PAWN-IMAGE pawn-width pawn-height #t))
(define B-PAWN8 (make-piece "pawn" VERTICAL-MOVES #f 1 "black" #f B-PAWN-IMAGE pawn-width pawn-height #t))

; Black king
(define B-KING (make-piece "king" KING-QUEEN-MOVES #t 1 "black" #f B-KING-IMAGE king-width king-height #t))

; Black queen
(define B-QUEEN (make-piece "queen" KING-QUEEN-MOVES #t 1 "black" #f B-QUEEN-IMAGE queen-width queen-height #t))

; Black bishops
(define B-BISHOP1 (make-piece "bishop" DIAGONAL-MOVES #t 1 "black" #f B-BISHOP-IMAGE  bishop-width bishop-height #t))
(define B-BISHOP2 (make-piece "bishop" DIAGONAL-MOVES #t 1  "black" #f B-BISHOP-IMAGE bishop-width bishop-height #t))

; Black rooks
(define B-ROOK1 (make-piece "rook" ROOK-MOVES #t 1 "black" #f B-ROOK-IMAGE rook-width rook-height #t))
(define B-ROOK2 (make-piece "rook" ROOK-MOVES #t 1 "black" #f B-ROOK-IMAGE rook-width rook-height #t))

; Black knights
(define B-KNIGHT1 (make-piece "knight" KNIGHT-MOVES #t 1 "black" #f B-KNIGHT-IMAGE knight-width knight-height #t))
(define B-KNIGHT2 (make-piece "knight" KNIGHT-MOVES #t 1 "black" #f B-KNIGHT-IMAGE knight-width knight-height #t))

(define BOARD-VECTOR
  (vector
    (vector B-ROOK1 B-KNIGHT1 B-BISHOP1 B-QUEEN B-KING B-BISHOP2 B-KNIGHT2 B-ROOK2)
    (vector B-PAWN1 B-PAWN2 B-PAWN3 B-PAWN4 B-PAWN5 B-PAWN6 B-PAWN7 B-PAWN8)
    (vector 0 0 0 0 0 0 0 0)
    (vector 0 0 0 0 0 0 0 0)
    (vector 0 0 0 0 0 0 0 0)
    (vector 0 0 0 0 0 0 0 0)
    (vector W-PAWN1 W-PAWN2 W-PAWN3 W-PAWN4 W-PAWN5 W-PAWN6 W-PAWN7 W-PAWN8)
    (vector W-ROOK1 W-KNIGHT1 W-BISHOP1 W-QUEEN W-KING W-BISHOP2 W-KNIGHT2 W-ROOK2)))
