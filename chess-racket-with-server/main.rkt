;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-advanced-reader.ss" "lang")((modname MAIN-P1) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #t #t none #f () #f)))
;%%%%%%%%%%%%%%%%%%%%;
;#### CHESS GAME ####;
;%%%%%%%%%%%%%%%%%%%%;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Libraries ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require 2htdp/image)
(require 2htdp/universe)
(require racket/base)
(provide INITIAL-STATE)
(provide handle-mouse)
(provide render)
(require "logic.rkt")
(require "server.rkt")
(require "client.rkt")

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
(define W-PAWN1 (make-piece "pawn" 
                           VERTICAL-MOVES
                           #f ; repeatable?
                           2  ; player (2 for white)
                           "white" 
                           #f ; selected?
                           W-PAWN-IMAGE 
                           pawn-width 
                           pawn-height 
                           #t)) ; present?
(define W-PAWN2 (make-piece "pawn" 
                           VERTICAL-MOVES
                           #f ; repeatable?
                           2  ; player (2 for white)
                           "white" 
                           #f ; selected?
                           W-PAWN-IMAGE 
                           pawn-width 
                           pawn-height 
                           #t)) ; present?
(define W-PAWN3 (make-piece "pawn" 
                           VERTICAL-MOVES
                           #f ; repeatable?
                           2  ; player (2 for white)
                           "white" 
                           #f ; selected?
                           W-PAWN-IMAGE 
                           pawn-width 
                           pawn-height 
                           #t)) ; present?
(define W-PAWN4 (make-piece "pawn" 
                           VERTICAL-MOVES
                           #f ; repeatable?
                           2  ; player (2 for white)
                           "white" 
                           #f ; selected?
                           W-PAWN-IMAGE 
                           pawn-width 
                           pawn-height 
                           #t)) ; present?
(define W-PAWN5 (make-piece "pawn" 
                           VERTICAL-MOVES
                           #f ; repeatable?
                           2  ; player (2 for white)
                           "white" 
                           #f ; selected?
                           W-PAWN-IMAGE 
                           pawn-width 
                           pawn-height 
                           #t)) ; present?
(define W-PAWN6 (make-piece "pawn" 
                           VERTICAL-MOVES
                           #f ; repeatable?
                           2  ; player (2 for white)
                           "white" 
                           #f ; selected?
                           W-PAWN-IMAGE 
                           pawn-width 
                           pawn-height 
                           #t)) ; present?
(define W-PAWN7 (make-piece "pawn" 
                           VERTICAL-MOVES
                           #f ; repeatable?
                           2  ; player (2 for white)
                           "white" 
                           #f ; selected?
                           W-PAWN-IMAGE 
                           pawn-width 
                           pawn-height 
                           #t)) ; present?
(define W-PAWN8 (make-piece "pawn" 
                           VERTICAL-MOVES
                           #f ; repeatable?
                           2  ; player (2 for white)
                           "white" 
                           #f ; selected?
                           W-PAWN-IMAGE 
                           pawn-width 
                           pawn-height 
                           #t)) ; present?

; White king
(define W-KING (make-piece "king" 
                           KING-QUEEN-MOVES
                           #f ; repeatable?
                           2  ; player (2 for white)
                           "white" 
                           #f ; selected?
                           W-KING-IMAGE 
                           king-width 
                           king-height 
                           #t)) ; present?

; White queen
(define W-QUEEN (make-piece "queen" 
                           KING-QUEEN-MOVES
                           #t ; repeatable?
                           2  ; player (2 for white)
                           "white" 
                           #f ; selected?
                           W-QUEEN-IMAGE 
                           queen-width 
                           queen-height 
                           #t)) ; present?

; White bishops
(define W-BISHOP1 (make-piece "bishop" 
                           DIAGONAL-MOVES
                           #t ; repeatable?
                           2  ; player (2 for white)
                           "white" 
                           #f ; selected?
                           W-BISHOP-IMAGE 
                           bishop-width 
                           bishop-height 
                           #t)) ; present?
(define W-BISHOP2 (make-piece "bishop" 
                           DIAGONAL-MOVES
                           #t ; repeatable?
                           2  ; player (2 for white)
                           "white" 
                           #f ; selected?
                           W-BISHOP-IMAGE 
                           bishop-width 
                           bishop-height 
                           #t)) ; present?

; White rooks
(define W-ROOK1 (make-piece "rook" 
                           ROOK-MOVES
                           #t ; repeatable?
                           2  ; player (2 for white)
                           "white" 
                           #f ; selected?
                           W-ROOK-IMAGE 
                           rook-width 
                           rook-height 
                           #t)) ; present?
(define W-ROOK2 (make-piece "rook" 
                           ROOK-MOVES
                           #t ; repeatable?
                           2  ; player (2 for white)
                           "white" 
                           #f ; selected?
                           W-ROOK-IMAGE 
                           rook-width 
                           rook-height 
                           #t)) ; present?

; White knights
(define W-KNIGHT1 (make-piece "knight" 
                           KNIGHT-MOVES
                           #t ; repeatable?
                           2  ; player (2 for white)
                           "white" 
                           #f ; selected?
                           W-KNIGHT-IMAGE 
                           knight-width 
                           knight-height 
                           #t)) ; present?
(define W-KNIGHT2 (make-piece "knight" 
                           KNIGHT-MOVES
                           #t ; repeatable?
                           2  ; player (2 for white)
                           "white" 
                           #f ; selected?
                           W-KNIGHT-IMAGE 
                           knight-width 
                           knight-height 
                           #t)) ; present?

; Black pawns
(define B-PAWN1 (make-piece "pawn" 
                           VERTICAL-MOVES
                           #f ; repeatable?
                           1  ; player (1 for black)
                           "black" 
                           #f ; selected?
                           B-PAWN-IMAGE 
                           pawn-width 
                           pawn-height 
                           #t)) ; present?
(define B-PAWN2 (make-piece "pawn" 
                           VERTICAL-MOVES
                           #f ; repeatable?
                           1  ; player (1 for black)
                           "black" 
                           #f ; selected?
                           B-PAWN-IMAGE 
                           pawn-width 
                           pawn-height 
                           #t)) ; present?
(define B-PAWN3 (make-piece "pawn" 
                           VERTICAL-MOVES
                           #f ; repeatable?
                           1  ; player (1 for black)
                           "black" 
                           #f ; selected?
                           B-PAWN-IMAGE 
                           pawn-width 
                           pawn-height 
                           #t)) ; present?
(define B-PAWN4 (make-piece "pawn" 
                           VERTICAL-MOVES
                           #f ; repeatable?
                           1  ; player (1 for black)
                           "black" 
                           #f ; selected?
                           B-PAWN-IMAGE 
                           pawn-width 
                           pawn-height 
                           #t)) ; present?
(define B-PAWN5 (make-piece "pawn" 
                           VERTICAL-MOVES
                           #f ; repeatable?
                           1  ; player (1 for black)
                           "black" 
                           #f ; selected?
                           B-PAWN-IMAGE 
                           pawn-width 
                           pawn-height 
                           #t)) ; present?
(define B-PAWN6 (make-piece "pawn" 
                           VERTICAL-MOVES
                           #f ; repeatable?
                           1  ; player (1 for black)
                           "black" 
                           #f ; selected?
                           B-PAWN-IMAGE 
                           pawn-width 
                           pawn-height 
                           #t)) ; present?
(define B-PAWN7 (make-piece "pawn" 
                           VERTICAL-MOVES
                           #f ; repeatable?
                           1  ; player (1 for black)
                           "black" 
                           #f ; selected?
                           B-PAWN-IMAGE 
                           pawn-width 
                           pawn-height 
                           #t)) ; present?
(define B-PAWN8 (make-piece "pawn" 
                           VERTICAL-MOVES
                           #f ; repeatable?
                           1  ; player (1 for black)
                           "black" 
                           #f ; selected?
                           B-PAWN-IMAGE 
                           pawn-width 
                           pawn-height 
                           #t)) ; present?

; Black king
(define B-KING (make-piece "king" 
                           KING-QUEEN-MOVES
                           #t ; repeatable?
                           1  ; player (1 for black)
                           "black" 
                           #f ; selected?
                           B-KING-IMAGE 
                           king-width 
                           king-height 
                           #t)) ; present?

; Black queen
(define B-QUEEN (make-piece "queen" 
                           KING-QUEEN-MOVES
                           #t ; repeatable?
                           1  ; player (1 for black)
                           "black" 
                           #f ; selected?
                           B-QUEEN-IMAGE 
                           queen-width 
                           queen-height 
                           #t)) ; present?

; Black bishops
(define B-BISHOP1 (make-piece "bishop" 
                           DIAGONAL-MOVES
                           #t ; repeatable?
                           1  ; player (1 for black)
                           "black" 
                           #f ; selected?
                           B-BISHOP-IMAGE 
                           bishop-width 
                           bishop-height 
                           #t)) ; present?
(define B-BISHOP2 (make-piece "bishop" 
                           DIAGONAL-MOVES
                           #t ; repeatable?
                           1  ; player (1 for black)
                           "black" 
                           #f ; selected?
                           B-BISHOP-IMAGE 
                           bishop-width 
                           bishop-height 
                           #t)) ; present?

; Black rooks
(define B-ROOK1 (make-piece "rook" 
                           ROOK-MOVES
                           #t ; repeatable?
                           1  ; player (1 for black)
                           "black" 
                           #f ; selected?
                           B-ROOK-IMAGE 
                           rook-width 
                           rook-height 
                           #t)) ; present?
(define B-ROOK2 (make-piece "rook" 
                           ROOK-MOVES
                           #t ; repeatable?
                           1  ; player (1 for black)
                           "black" 
                           #f ; selected?
                           B-ROOK-IMAGE 
                           rook-width 
                           rook-height 
                           #t)) ; present?

; Black knights
(define B-KNIGHT1 (make-piece "knight" 
                           KNIGHT-MOVES
                           #t ; repeatable?
                           1  ; player (1 for black)
                           "black" 
                           #f ; selected?
                           B-KNIGHT-IMAGE 
                           knight-width 
                           knight-height 
                           #t)) ; present?
(define B-KNIGHT2 (make-piece "knight" 
                           KNIGHT-MOVES
                           #t ; repeatable?
                           1  ; player (1 for black)
                           "black" 
                           #f ; selected?
                           B-KNIGHT-IMAGE 
                           knight-width 
                           knight-height 
                           #t)) ; present?

; Defining INITIAL-STATE
(define INITIAL-STATE 
  (vector
    ; Row 0 - Black Special Pieces row
    (vector B-ROOK1 B-KNIGHT1 B-BISHOP1 B-QUEEN B-KING B-BISHOP2 B-KNIGHT2 B-ROOK2)
    
    ; Row 1 - Black pawns
    (vector B-PAWN1 B-PAWN2 B-PAWN3 B-PAWN4 B-PAWN5 B-PAWN6 B-PAWN7 B-PAWN8)
    
    ; Rows 2-5 - Empty spaces
    (vector 0 0 0 0 0 0 0 0)
    (vector 0 0 0 0 0 0 0 0)
    (vector 0 0 0 0 0 0 0 0)
    (vector 0 0 0 0 0 0 0 0)
    
    ; Row 6 - White pawns
    (vector W-PAWN1 W-PAWN2 W-PAWN3 W-PAWN4 W-PAWN5 W-PAWN6 W-PAWN7 W-PAWN8)
    
    ; Row 7 - White Special Pieces row
    (vector W-ROOK1 W-KNIGHT1 W-BISHOP1 W-QUEEN W-KING W-BISHOP2 W-KNIGHT2 W-ROOK2)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Functions ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;; highlight-piece ;;;;;

;; Input/Output
; highlight-piece : Piece Scene Posn -> Scene
; Highlights a piece on the board if it's selected, otherwise renders normally
; header: (define (highlight-piece piece scene position) EMPTY-CHESSBOARD)

;; Constants for Examples
; Defining a black rook with 'selected?' set to #t
(define B-ROOK-D (make-piece "rook" 
                           ROOK-MOVES
                           #t ; repeatable?
                           1  ; player (1 for black)
                           "black" 
                           #t ; selected?
                           B-ROOK-IMAGE 
                           knight-width 
                           knight-height 
                           #t)) ; present?

;; Examples
(check-expect (highlight-piece B-ROOK1 EMPTY-CHESSBOARD (make-posn 0 0)) (place-image (piece-img B-ROOK1) 32 32 EMPTY-CHESSBOARD))
(check-expect (highlight-piece B-PAWN8 EMPTY-CHESSBOARD (make-posn 7 2)) (place-image (piece-img B-PAWN8) 480 160 EMPTY-CHESSBOARD))
(check-expect (highlight-piece B-ROOK-D EMPTY-CHESSBOARD (make-posn 0 0)) (place-image
                                                                           (overlay
                                                                            (overlay (rectangle SQUARE-SIDE SQUARE-SIDE "outline" "Gold")
                                                                                     (rectangle (- SQUARE-SIDE 1) (- SQUARE-SIDE 1) "outline" "Gold")
                                                                                     (rectangle (- SQUARE-SIDE 2) (- SQUARE-SIDE 2) "outline" "Gold")
                                                                                     (rectangle (- SQUARE-SIDE 3) (- SQUARE-SIDE 3) "outline" "Gold")
                                                                                     (rectangle (- SQUARE-SIDE 4) (- SQUARE-SIDE 4) "outline" "Gold"))
                                                                            (piece-img B-ROOK-D)) 32 32 EMPTY-CHESSBOARD))

;; Implementation
(define (highlight-piece piece scene position)
  (let ([img (if (piece-selected? piece)
                 (overlay 
                  (overlay  ; Multiple overlays to create thicker border
                   (rectangle SQUARE-SIDE SQUARE-SIDE "outline" "Gold")
                   (rectangle (- SQUARE-SIDE 1) (- SQUARE-SIDE 1) "outline" "Gold")
                   (rectangle (- SQUARE-SIDE 2) (- SQUARE-SIDE 2) "outline" "Gold")
                   (rectangle (- SQUARE-SIDE 3) (- SQUARE-SIDE 3) "outline" "Gold")
                   (rectangle (- SQUARE-SIDE 4) (- SQUARE-SIDE 4) "outline" "Gold"))
                  (piece-img piece))
                 (piece-img piece))])
    (place-image img
                (+ (* (posn-x position) SQUARE-SIDE) (/ SQUARE-SIDE 2))
                (+ (* (posn-y position) SQUARE-SIDE) (/ SQUARE-SIDE 2))
                scene)))

;;;;; vector-to-list-of-lists ;;;;;

;; Input/Output
; vector-to-list-of-lists : Vector<Vector<Any>> -> List<List<Any>>
; Converts a 2D vector into a list of lists
; header: (define (vector-to-list-of-lists vector-board) '())

;; Examples
(check-expect (vector-to-list-of-lists (vector (vector 1 2) (vector 3 4))) '((1 2) (3 4)))
(check-expect (vector-to-list-of-lists (vector (vector 2 1 4 3))) '((2 1 4 3)))

;; Implementation
(define (vector-to-list-of-lists vector-board)
  (map vector->list (vector->list vector-board)))

;;;;; render-chessboard ;;;;;

;; Input/Output
; render-chessboard : GameState -> Scene
; Renders the current state of the chessboard
; header: (define (render-chessboard state) EMPTY-CHESSBOARD)

;; Implementation
(define (render-chessboard state)
  (let* ([scene EMPTY-CHESSBOARD]
         [scene-with-pieces
          (foldl (lambda (row-idx scene)
                   (foldl (lambda (col-idx scene)
                            (let ([piece (vector-ref (vector-ref state row-idx) col-idx)])
                              (if (and (piece? piece) (piece-present? piece))
                                  (if (and (equal? (piece-type piece) "king")
                                         (king-in-check? (piece-color piece) state))
                                      ; Highlight king in check with red border
                                      (place-image 
                                       (overlay
                                        (overlay
                                         (rectangle SQUARE-SIDE SQUARE-SIDE "outline" "red")
                                         (rectangle (- SQUARE-SIDE 1) (- SQUARE-SIDE 1) "outline" "red")
                                         (rectangle (- SQUARE-SIDE 2) (- SQUARE-SIDE 2) "outline" "red")
                                         (rectangle (- SQUARE-SIDE 3) (- SQUARE-SIDE 3) "outline" "red")
                                         (rectangle (- SQUARE-SIDE 4) (- SQUARE-SIDE 4) "outline" "red"))
                                        (piece-img piece))
                                       (+ (* col-idx SQUARE-SIDE) (/ SQUARE-SIDE 2))
                                       (+ (* row-idx SQUARE-SIDE) (/ SQUARE-SIDE 2))
                                       scene)
                                      ; Normal piece rendering
                                      (highlight-piece piece scene (make-posn col-idx row-idx)))
                                  scene)))
                          scene
                          (build-list 8 values)))
                 scene
                 (build-list 8 values))])
    ; Add winning message if game is over
    (if game-over
        (place-image (text "Player 2 Wins!" 40 "red")
                    (* SQUARE-SIDE 4)  ; Center horizontally
                    (* SQUARE-SIDE 4)  ; Center vertically
                    scene-with-pieces)
        ; If game isn't over, continue with normal rendering
        (if selected-piece
            (let* ([valid-moves (get-valid-moves selected-piece selected-pos state)]
                   [check-path (if (and (not (equal? (piece-type selected-piece) "king"))
                                      (king-in-check? (piece-color selected-piece) state))
                                 (get-check-path state (piece-color selected-piece))
                                 '())])
              (foldl (lambda (move scene)
                      (place-image 
                       (cond
                         ; King moves that would still be in check
                         [(and (equal? (piece-type selected-piece) "king")
                               (would-be-in-check? selected-piece selected-pos move state))
                          (circle 8 "solid" "red")]
                         ; Moves that block the check
                         [(and (not (equal? (piece-type selected-piece) "king"))
                               (member move check-path)
                               (not (would-be-in-check? selected-piece selected-pos move state)))
                          (circle 8 "solid" "Green Yellow")]
                         ; All other valid moves
                         [else (circle 8 "solid" "gray")])
                       (+ (* (posn-x move) SQUARE-SIDE) (/ SQUARE-SIDE 2))
                       (+ (* (posn-y move) SQUARE-SIDE) (/ SQUARE-SIDE 2))
                       scene))
                    scene-with-pieces
                    valid-moves))
            scene-with-pieces))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; CHECKMATE FUNCTIONS ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;; find-king ;;;;;

;; Input/Output
; find-king : String GameState -> Posn
; Finds the position of the specified color's king
; header: (define (find-king color state) (make-posn 0 0))

;; Examples
(check-expect (find-king "white" (vector
                                 (vector B-ROOK1 B-KNIGHT1 B-BISHOP1 B-QUEEN B-KING B-BISHOP2 B-KNIGHT2 B-ROOK2)
                                 (vector B-PAWN1 B-PAWN2 B-PAWN3 B-PAWN4 B-PAWN5 B-PAWN6 B-PAWN7 B-PAWN8)
                                 (vector 0 0 0 0 0 0 0 0)
                                 (vector 0 0 0 0 0 0 0 0)
                                 (vector 0 0 0 0 W-KING 0 0 0) ; White king moved to center
                                 (vector 0 0 0 0 0 0 0 0)
                                 (vector W-PAWN1 W-PAWN2 W-PAWN3 W-PAWN4 W-PAWN5 W-PAWN6 W-PAWN7 W-PAWN8)
                                 (vector W-ROOK1 W-KNIGHT1 W-BISHOP1 W-QUEEN 0 W-BISHOP2 W-KNIGHT2 W-ROOK2)))
                         (make-posn 4 4)) ; Expect king at new position
(check-expect (find-king "black" INITIAL-STATE) (make-posn 4 0))

;; Implementation
(define (find-king color state)
  (let find-pos ([row 0])
    (if (< row 8)
        (let find-col ([col 0])
          (if (< col 8)
              (let ([piece (vector-ref (vector-ref state row) col)])
                (if (and (piece? piece)
                         (equal? (piece-type piece) "king")
                         (equal? (piece-color piece) color))
                    (make-posn col row)
                    (find-col (add1 col))))
              (find-pos (add1 row))))
        #f)))

;;;;; king-in-check? ;;;;;

; king-in-check? : Color GameState -> Boolean
; Determines if the specified color's king is in check
; header: (define (king-in-check? king-color state) #t)

;; Examples
(check-expect (king-in-check? "white" (vector
                                      (vector B-ROOK1 B-KNIGHT1 B-BISHOP1 B-QUEEN B-KING B-BISHOP2 B-KNIGHT2 B-ROOK2)
                                      (vector B-PAWN1 B-PAWN2 B-PAWN3 B-PAWN4 B-PAWN5 B-PAWN6 B-PAWN7 B-PAWN8)
                                      (vector 0 0 0 0 0 0 0 0)
                                      (vector 0 0 0 0 0 0 0 0)
                                      (vector 0 0 0 0 W-KING 0 0 0) ; White king moved to center
                                      (vector 0 0 0 0 0 0 0 0)
                                      (vector W-PAWN1 W-PAWN2 W-PAWN3 W-PAWN4 W-PAWN5 W-PAWN6 W-PAWN7 W-PAWN8)
                                      (vector W-ROOK1 W-KNIGHT1 W-BISHOP1 W-QUEEN 0 W-BISHOP2 W-KNIGHT2 W-ROOK2)))
              #f)
(check-expect (king-in-check? "white" (vector
                                      (vector B-ROOK1 B-KNIGHT1 B-BISHOP1 B-QUEEN B-KING B-BISHOP2 B-KNIGHT2 B-ROOK2)
                                      (vector B-PAWN1 B-PAWN2 B-PAWN3 B-PAWN4 B-PAWN5 B-PAWN6 B-PAWN7 B-PAWN8)
                                      (vector 0 0 0 0 W-KING 0 0 0)
                                      (vector 0 0 0 0 0 0 0 0)
                                      (vector 0 0 0 0 0 0 0 0)
                                      (vector 0 0 0 0 0 0 0 0)
                                      (vector W-PAWN1 W-PAWN2 W-PAWN3 W-PAWN4 W-PAWN5 W-PAWN6 W-PAWN7 W-PAWN8)
                                      (vector W-ROOK1 W-KNIGHT1 W-BISHOP1 W-QUEEN 0 W-BISHOP2 W-KNIGHT2 W-ROOK2)))
              #t)

;; Implementation
(define (king-in-check? king-color state)
  (let ([king-pos (find-king king-color state)])
    (let check-pieces ([row 0])
      (if (< row 8)
          (let check-col ([col 0])
            (if (< col 8)
                (let ([piece (vector-ref (vector-ref state row) col)])
                  (if (and (piece? piece)
                           (piece-present? piece)
                           (not (equal? (piece-color piece) king-color))
                           (member king-pos (get-valid-moves piece (make-posn col row) state)))
                      #t
                      (check-col (add1 col))))
                (check-pieces (add1 row))))
          #f))))

;;;;; get-attack-path ;;;;;

;; Input/Output
; get-attack-path : Posn Posn -> List<Posn>
; Returns the path between the attacking piece and the king
; header: (define (get-attack-path attacker-pos king-pos) (make-posn 0 0))

;; Examples
(check-expect (get-attack-path (make-posn 0 0) (make-posn 2 2))
              (list (make-posn 2 2) (make-posn 1 1) (make-posn 0 0)))

;; Implementation
(define (get-attack-path attacker-pos king-pos)
  (let* ([dx (- (posn-x king-pos) (posn-x attacker-pos))]
         [dy (- (posn-y king-pos) (posn-y attacker-pos))]
         [step-x (if (= dx 0) 0 (/ dx (abs dx)))]
         [step-y (if (= dy 0) 0 (/ dy (abs dy)))])
    (let loop ([current-pos attacker-pos]
               [path '()])
      (if (and (not (equal? current-pos king-pos))
               (in-bounds? current-pos))
          (let ([next-pos (make-posn (+ (posn-x current-pos) step-x)
                                    (+ (posn-y current-pos) step-y))])
            (loop next-pos (cons current-pos path)))
          (cons current-pos path)))))

;;;;; get-check-path ;;;;;

;; Input/Output
; get-check-path : GameState String -> List<Posn>
; Returns the path of squares that could block a check
; header: (define (get-check-path state king-color) '())

;; Examples
(check-expect (get-check-path "white" (vector
                                 (vector B-ROOK1 B-KNIGHT1 B-BISHOP1 B-QUEEN B-KING B-BISHOP2 B-KNIGHT2 B-ROOK2)
                                 (vector B-PAWN1 B-PAWN2 B-PAWN3 B-PAWN4 B-PAWN5 B-PAWN6 B-PAWN7 B-PAWN8)
                                 (vector 0 0 0 0 0 0 0 0)
                                 (vector 0 0 0 0 0 0 0 0)
                                 (vector 0 0 0 0 W-KING 0 0 0) ; White king moved to center
                                 (vector 0 0 0 0 0 0 0 0)
                                 (vector W-PAWN1 W-PAWN2 W-PAWN3 W-PAWN4 W-PAWN5 W-PAWN6 W-PAWN7 W-PAWN8)
                                 (vector W-ROOK1 W-KNIGHT1 W-BISHOP1 W-QUEEN 0 W-BISHOP2 W-KNIGHT2 W-ROOK2)))
                         '())
(check-expect (get-check-path "white" (vector
                                 (vector B-ROOK1 B-KNIGHT1 B-BISHOP1 0 B-KING B-BISHOP2 B-KNIGHT2 B-ROOK2)
                                 (vector B-PAWN1 B-PAWN2 B-PAWN3 B-PAWN4 B-PAWN5 B-PAWN6 B-PAWN7 B-PAWN8)
                                 (vector 0 0 0 0 0 0 0 0)
                                 (vector 0 0 0 0 B-QUEEN 0 0 0)
                                 (vector 0 0 0 0 0 0 0 0)
                                 (vector 0 0 W-KNIGHT1 0 W-KING 0 0 0)
                                 (vector W-PAWN1 W-PAWN2 W-PAWN3 W-PAWN4 W-PAWN5 W-PAWN6 W-PAWN7 W-PAWN8)
                                 (vector W-ROOK1 0 W-BISHOP1 W-QUEEN 0 W-BISHOP2 W-KNIGHT2 W-ROOK2)))
                         (list (make-posn 4 3) (make-posn 4 4)))

;; Implementation
(define (get-check-path king-color state)
  (let* ([king-pos (find-king king-color state)]
         [attacking-pieces 
          (filter (lambda (pos)
                   (let ([piece (vector-ref (vector-ref state (posn-y pos)) (posn-x pos))])
                     (and (piece? piece)
                          (piece-present? piece)
                          (not (equal? (piece-color piece) king-color))
                          (member king-pos (get-valid-moves piece pos state)))))
                 (build-list 64 
                           (lambda (i) 
                             (make-posn (remainder i 8) (quotient i 8)))))])
    (if (= (length attacking-pieces) 1) ; Only consider single attacker cases
        (let* ([attacker-pos (first attacking-pieces)]
               [dx (- (posn-x king-pos) (posn-x attacker-pos))]
               [dy (- (posn-y king-pos) (posn-y attacker-pos))]
               [step-x (if (= dx 0) 0 (/ dx (abs dx)))]
               [step-y (if (= dy 0) 0 (/ dy (abs dy)))]
               [steps (max (abs dx) (abs dy))]
               [path-positions
                (build-list (sub1 steps)
                           (lambda (i)
                             (make-posn (+ (posn-x attacker-pos) (* (add1 i) step-x))
                                      (+ (posn-y attacker-pos) (* (add1 i) step-y)))))])
          (cons attacker-pos path-positions))
        '())))

;;;;; would-be-in-check? ;;;;;

;; Input/Output
; would-be-in-check? : Piece Posn Posn GameState -> Boolean
; Checks if moving a piece would put its own king in check
; header: (define (would-be-in-check? piece orig-pos new-pos state) #t)

;; Examples
(check-expect (would-be-in-check? W-KING 
                                 (make-posn 4 5)
                                 (make-posn 4 4)
                                 (vector
                                  (vector B-ROOK1 B-KNIGHT1 B-BISHOP1 0 B-KING B-BISHOP2 B-KNIGHT2 B-ROOK2)
                                  (vector B-PAWN1 B-PAWN2 B-PAWN3 B-PAWN4 B-PAWN5 B-PAWN6 B-PAWN7 B-PAWN8)
                                  (vector 0 0 0 0 0 0 0 0)
                                  (vector 0 0 0 B-QUEEN 0 0 0 0)
                                  (vector 0 0 0 0 0 0 0 0)
                                  (vector 0 0 W-KNIGHT1 0 W-KING 0 0 0)
                                  (vector W-PAWN1 W-PAWN2 W-PAWN3 W-PAWN4 W-PAWN5 W-PAWN6 W-PAWN7 W-PAWN8)
                                  (vector W-ROOK1 0 W-BISHOP1 W-QUEEN 0 W-BISHOP2 W-KNIGHT2 W-ROOK2)))
              #t)
(check-expect (would-be-in-check? B-KING 
                                 (make-posn 4 3)
                                 (make-posn 4 4)
                                 (vector
                                  (vector B-ROOK1 B-KNIGHT1 B-BISHOP1 0 0 B-BISHOP2 B-KNIGHT2 B-ROOK2)
                                  (vector B-PAWN1 B-PAWN2 B-PAWN3 B-PAWN4 B-PAWN5 B-PAWN6 B-PAWN7 B-PAWN8)
                                  (vector 0 0 0 0 0 0 0 0)
                                  (vector 0 0 0 0 B-KING 0 0 0)
                                  (vector 0 0 0 0 0 0 0 0)
                                  (vector 0 0 W-KNIGHT1 0 W-KING 0 0 0)
                                  (vector W-PAWN1 W-PAWN2 W-PAWN3 W-PAWN4 W-PAWN5 W-PAWN6 W-PAWN7 W-PAWN8)
                                  (vector W-ROOK1 0 W-BISHOP1 W-QUEEN 0 W-BISHOP2 W-KNIGHT2 W-ROOK2)))
              #t)
(check-expect (would-be-in-check? B-KING (make-posn 4 5) (make-posn 5 5) (vector
                                 (vector B-ROOK1 B-KNIGHT1 B-BISHOP1 0 B-KING B-BISHOP2 B-KNIGHT2 B-ROOK2)
                                 (vector B-PAWN1 B-PAWN2 B-PAWN3 B-PAWN4 B-PAWN5 B-PAWN6 B-PAWN7 B-PAWN8)
                                 (vector 0 0 0 0 0 0 0 0)
                                 (vector 0 0 0 B-QUEEN 0 0 0 0)
                                 (vector 0 0 0 0 0 0 0 0)
                                 (vector 0 0 W-KNIGHT1 0 W-KING 0 0 0)
                                 (vector W-PAWN1 W-PAWN2 W-PAWN3 W-PAWN4 W-PAWN5 W-PAWN6 W-PAWN7 W-PAWN8)
                                 (vector W-ROOK1 0 W-BISHOP1 W-QUEEN 0 W-BISHOP2 W-KNIGHT2 W-ROOK2)))
              #f)

;; Implementation
(define (would-be-in-check? piece orig-pos new-pos state)
  (let* ([test-state (vector-copy-deep state)]
         [orig-row (posn-y orig-pos)]
         [orig-col (posn-x orig-pos)]
         [new-row (posn-y new-pos)]
         [new-col (posn-x new-pos)])
    ; Make the move on the test board
    (vector-set! (vector-ref test-state orig-row) orig-col 0)
    (vector-set! (vector-ref test-state new-row) new-col piece)
    ; Check if the king would be in check after this move
    (king-in-check? (piece-color piece) test-state)))

;;;;; vector-copy-deep ;;;;;

;; Input/Output
; vector-copy-deep : Vector -> Vector
; Creates a deep copy of a vector (including nested vectors)
; header: (define (vector-copy-deep v) (vector 0))

;; Examples
(check-expect (vector-copy-deep (vector 1 2 3)) (vector 1 2 3))
(check-expect (vector-copy-deep (vector (vector 2 4 3) (vector 1 8 3))) (vector (vector 2 4 3) (vector 1 8 3)))

;; Implementation
(define (vector-copy-deep v)
  (let* ([len (vector-length v)]
         [new-vec (make-vector len)])
    (define (copy-elements! i)
      (if (< i len)
          (begin
            (vector-set! new-vec i
                        (if (vector? (vector-ref v i))
                            (vector-copy-deep (vector-ref v i))
                            (vector-ref v i)))
            (copy-elements! (add1 i)))
          new-vec))
    (copy-elements! 0)))

;;;;; which-square? ;;;;;

;; Input/Output
; which-square? : Number Number -> Posn
; Converts mouse coordinates to board position
; header: (define (which-square? x y) (make-posn 0 0))

;; Examples
(check-expect (which-square? 65 65) (make-posn 1 1))
(check-expect (which-square? 32 32) (make-posn 0 0))

;; Implementation
(define (which-square? x y)
  (make-posn (floor (/ x SQUARE-SIDE))
             (floor (/ y SQUARE-SIDE))))

;;;;; same-color? ;;;;;

;; Input/Output
; same-color? : Piece Piece -> Boolean
; Determines if two pieces are the same color
; header: (define (same-color? dragged-piece piece) #t)

;; Examples
(check-expect (same-color? W-PAWN1 W-KING) #t)
(check-expect (same-color? W-PAWN1 B-KING) #f)

;; Implementation
(define (same-color? dragged-piece piece)
  (and (piece-present? dragged-piece)
       (piece-present? piece)
       (equal? (piece-color dragged-piece) (piece-color piece))))

;;;;; make-transparent ;;;;;

;; Input/Output
; make-transparent : Piece -> Piece
; Makes a piece transparent if it's not present on the board
; header: (define (make-transparent piece) B-PAWN1)

;; Constants for Examples
; Defining a black pawn with 'present?' set to #f
(define B-PAWN-NOT-P (make-piece (piece-type B-PAWN1)
                                 (piece-movement B-PAWN1)
                                 (piece-repeatable? B-PAWN1)
                                 (piece-player B-PAWN1)
                                 (piece-color B-PAWN1)
                                 (piece-selected? B-PAWN1)
                                 (piece-img B-PAWN1)
                                 (piece-width B-PAWN1)
                                 (piece-height B-PAWN1)
                                 #f))

; Defining a black pawn not visible
(define B-PAWN-NOT-V (make-piece (piece-type B-PAWN1)
                                 (piece-movement B-PAWN1)
                                 (piece-repeatable? B-PAWN1)
                                 (piece-player B-PAWN1)
                                 (piece-color B-PAWN1)
                                 (piece-selected? B-PAWN1)
                                 (rectangle 0 0 "solid" "transparent")
                                 (piece-width B-PAWN1)
                                 (piece-height B-PAWN1)
                                 #f))

;; Examples
(check-expect (make-transparent B-PAWN1) B-PAWN1)
(check-expect (make-transparent B-PAWN-NOT-P) B-PAWN-NOT-V)

;; Implementation
(define (make-transparent piece)
  (if (false? (piece-present? piece))
      (make-piece (piece-type piece)
                  (piece-movement piece)
                  (piece-repeatable? piece)
                  (piece-player piece)
                  (piece-color piece)
                  (piece-selected? piece)
                  (rectangle 0 0 "solid" "transparent")
                  (piece-width piece)
                  (piece-height piece)
                  (piece-present? piece))
      piece)) ; Return unchanged if present? is true

(define (start-move-listener connection)
  (thread
   (lambda ()
     (let loop ()
       (let ((move-data (read (connection-server-input connection))))
         (when (and (list? move-data) (= (length move-data) 4))
           (let ((from-pos (make-posn (first move-data) (second move-data)))
                 (to-pos (make-posn (third move-data) (fourth move-data))))
             ; Invert coordinates for opponent's perspective
             (let ((inverted-from (make-posn (- 7 (posn-x from-pos)) 
                                           (- 7 (posn-y from-pos))))
                   (inverted-to (make-posn (- 7 (posn-x to-pos)) 
                                         (- 7 (posn-y to-pos)))))
               ; Update the board with the inverted move
               (move-piece inverted-from inverted-to))))
         (loop))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; HANDLE MOUSE EVENTS ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Constants
(define selected-piece #f)
(define selected-pos #f)
(define game-over #f)

;;;;; handle-move ;;;;;

;; Implementation
(define (handle-move state target-pos)
  (let* ([target-row (posn-y target-pos)]
         [target-col (posn-x target-pos)]
         [target-piece (vector-ref (vector-ref state target-row) target-col)]
         [orig-row (posn-y selected-pos)]
         [orig-col (posn-x selected-pos)]
         [valid-moves (get-valid-moves selected-piece selected-pos state)])
    (if (and (piece? selected-piece)
             (member target-pos valid-moves)
             (or (not (piece? target-piece))
                 (not (same-color? selected-piece target-piece))))
        (begin
          ; Check if king is moving into check
          (when (and (equal? (piece-type selected-piece) "king")
                    (would-be-in-check? selected-piece selected-pos target-pos state))
            (set! game-over #t))
          
          ; Check for castling
          (if (and (equal? (piece-type selected-piece) "king")
                   (not (piece-selected? selected-piece)) ; King has not moved
                   (or (and (= target-col (+ orig-col 2)) ; Castling right
                            (let ([rook (vector-ref (vector-ref state orig-row) 7)])
                              (and (piece? rook)
                                   (equal? (piece-type rook) "rook")
                                   (not (piece-selected? rook))))) ; Rook has not moved
                       (and (= target-col (- orig-col 3)) ; Castling left
                            (let ([rook (vector-ref (vector-ref state orig-row) 0)])
                              (and (piece? rook)
                                   (equal? (piece-type rook) "rook")
                                   (not (piece-selected? rook))))))) ; Rook has not moved
              (begin
                ; Perform castling
                (let ([rook-col (if (= target-col (+ orig-col 2)) 7 0)]
                      [new-rook-col (if (= target-col (+ orig-col 2)) (- target-col 1) (+ target-col 1))])
                  ; Move king
                  (vector-set! (vector-ref state orig-row) orig-col 0)
                  (vector-set! (vector-ref state target-row) target-col
                             (struct-copy piece selected-piece
                                        [selected? #f])) ; Ensure king is not selected
                  ; Move rook
                  (let ([rook (vector-ref (vector-ref state orig-row) rook-col)])
                    (vector-set! (vector-ref state orig-row) rook-col 0)
                    (vector-set! (vector-ref state target-row) new-rook-col
                               (struct-copy piece rook
                                          [selected? #f])))))  ; Ensure rook is not selected
              ; Check for pawn promotion
              (if (and (equal? (piece-type selected-piece) "pawn")
                      (= target-row 0)) ; Pawn reached the opposite end
                  (begin
                    ; Clear original position
                    (vector-set! (vector-ref state orig-row) orig-col 0)
                    ; Place queen at target position
                    (vector-set! (vector-ref state target-row) target-col
                               (make-piece "queen"
                                         KING-QUEEN-MOVES
                                         #t ; repeatable?
                                         2  ; player (2 for white)
                                         "white"
                                         #f ; selected?
                                         W-QUEEN-IMAGE
                                         queen-width
                                         queen-height
                                         #t))) ; present?
                  ; Normal move
                  (begin
                    ; Clear original position
                    (vector-set! (vector-ref state orig-row) orig-col 0)
                    ; Move piece to new position with selected? set to false
                    (vector-set! (vector-ref state target-row) target-col
                               (struct-copy piece selected-piece
                                          [selected? #f])))))
          state)
        state)))

;;;;; get-valid-moves ;;;;;

;; Input/Output
; get-valid-moves : Piece Posn GameState -> List<Posn>
; Returns list of valid positions the piece can move to from current position
; header: (define (get-valid-moves piece pos state) '())

;; Examples
; a pawn at starting position should be able to move 1 or 2 squares forward
(check-expect (get-valid-moves W-PAWN1 (make-posn 0 6) (vector
                                 (vector B-ROOK1 B-KNIGHT1 B-BISHOP1 B-QUEEN B-KING B-BISHOP2 B-KNIGHT2 B-ROOK2)
                                 (vector B-PAWN1 B-PAWN2 B-PAWN3 B-PAWN4 B-PAWN5 B-PAWN6 B-PAWN7 B-PAWN8)
                                 (vector 0 0 0 0 0 0 0 0)
                                 (vector 0 0 0 0 0 0 0 0)
                                 (vector 0 0 0 0 0 0 0 0)
                                 (vector 0 0 0 0 0 0 0 0)
                                 (vector W-PAWN1 W-PAWN2 W-PAWN3 W-PAWN4 W-PAWN5 W-PAWN6 W-PAWN7 W-PAWN8)
                                 (vector W-ROOK1 W-KNIGHT1 W-BISHOP1 W-QUEEN W-KING W-BISHOP2 W-KNIGHT2 W-ROOK2)))
              (list (make-posn 0 5) (make-posn 0 4)))

; a rook at starting position shouldn't be able to move
(check-expect (get-valid-moves W-ROOK1 (make-posn 0 7) (vector
                                 (vector B-ROOK1 B-KNIGHT1 B-BISHOP1 B-QUEEN B-KING B-BISHOP2 B-KNIGHT2 B-ROOK2)
                                 (vector B-PAWN1 B-PAWN2 B-PAWN3 B-PAWN4 B-PAWN5 B-PAWN6 B-PAWN7 B-PAWN8)
                                 (vector 0 0 0 0 0 0 0 0)
                                 (vector 0 0 0 0 0 0 0 0)
                                 (vector 0 0 0 0 0 0 0 0)
                                 (vector 0 0 0 0 0 0 0 0)
                                 (vector W-PAWN1 W-PAWN2 W-PAWN3 W-PAWN4 W-PAWN5 W-PAWN6 W-PAWN7 W-PAWN8)
                                 (vector W-ROOK1 W-KNIGHT1 W-BISHOP1 W-QUEEN W-KING W-BISHOP2 W-KNIGHT2 W-ROOK2)))
              '())

;; Implementation
(define (get-valid-moves piece pos state)
  (let ([moves
         (cond
           [(equal? (piece-type piece) "pawn")
 (let* ([row (posn-y pos)]
        [col (posn-x pos)]
        [direction (if (equal? (piece-color piece) "white") -1 1)]
        [one-square (make-posn col (+ row direction))]
        [two-squares (make-posn col (+ row (* 2 direction)))]
        [capture-left (make-posn (- col 1) (+ row direction))]
        [capture-right (make-posn (+ col 1) (+ row direction))]
        [starting-row? (or (and (equal? (piece-color piece) "white") (= row 6))
                          (and (equal? (piece-color piece) "black") (= row 1)))]
        ; Check if one square ahead is empty
        [can-move-one? (and (in-bounds? one-square)
                           (not (piece? (vector-ref (vector-ref state (posn-y one-square)) 
                                                  (posn-x one-square)))))]
        ; Check if two squares ahead is empty and path is clear
        [can-move-two? (and starting-row?
                           can-move-one? ; Must be able to move one square first
                           (in-bounds? two-squares)
                           (not (piece? (vector-ref (vector-ref state (posn-y two-squares))
                                                  (posn-x two-squares)))))]
        ; Check diagonal captures
        [can-capture-left? (and (in-bounds? capture-left)
                               (let ([target-piece (vector-ref (vector-ref state (posn-y capture-left))
                                                             (posn-x capture-left))])
                                 (and (piece? target-piece)
                                      (not (equal? (piece-color piece)
                                                 (piece-color target-piece))))))]
        [can-capture-right? (and (in-bounds? capture-right)
                                (let ([target-piece (vector-ref (vector-ref state (posn-y capture-right))
                                                              (posn-x capture-right))])
                                  (and (piece? target-piece)
                                       (not (equal? (piece-color piece)
                                                  (piece-color target-piece))))))]
        [basic-moves (filter (lambda (m) (in-bounds? m))
                           (append
                            (if can-move-one? (list one-square) '())
                            (if can-move-two? (list two-squares) '())
                            (if can-capture-left? (list capture-left) '())
                            (if can-capture-right? (list capture-right) '())))])
   basic-moves)]
           
           [(equal? (piece-type piece) "knight")
            (let ([basic-moves
                   (map (lambda (dir) 
                         (make-posn (+ (posn-x pos) (posn-x dir))
                                  (+ (posn-y pos) (posn-y dir))))
                        KNIGHT-MOVES)])
              (filter (lambda (move)
                        (and (in-bounds? move)
                             (let ([piece-at-pos (vector-ref (vector-ref state (posn-y move)) 
                                                           (posn-x move))])
                               (or (not (piece? piece-at-pos))
                                   (not (equal? (piece-color piece-at-pos)
                                              (piece-color piece)))))))
                      basic-moves))]

           [(equal? (piece-type piece) "king")
            (let* ([basic-moves
                   (map (lambda (dir) 
                         (make-posn (+ (posn-x pos) (posn-x dir))
                                  (+ (posn-y pos) (posn-y dir))))
                        KING-QUEEN-MOVES)]
                   [castling-moves
                    (if (not (piece-selected? piece)) ; King hasn't moved
                        (let ([row (posn-y pos)])
                          (append
                           ; Kingside castling (right)
                           (if (and (= (posn-x pos) 4) ; King in initial position
                                  (let ([rook (vector-ref (vector-ref state row) 7)])
                                    (and (piece? rook)
                                         (equal? (piece-type rook) "rook")
                                         (not (piece-selected? rook))))
                                  ; Check if squares between king and rook are empty
                                  (not (piece? (vector-ref (vector-ref state row) 5)))
                                  (not (piece? (vector-ref (vector-ref state row) 6))))
                               (list (make-posn 6 row))
                               '())
                           ; Queenside castling (left)
                           (if (and (= (posn-x pos) 4) ; King in initial position
                                  (let ([rook (vector-ref (vector-ref state row) 0)])
                                    (and (piece? rook)
                                         (equal? (piece-type rook) "rook")
                                         (not (piece-selected? rook))))
                                  ; Check if squares between king and rook are empty
                                  (not (piece? (vector-ref (vector-ref state row) 3)))
                                  (not (piece? (vector-ref (vector-ref state row) 2)))
                                  (not (piece? (vector-ref (vector-ref state row) 1))))
                               (list (make-posn 1 row))
                               '())))
                        '())])
              (filter (lambda (move)
                       (and (in-bounds? move)
                            (let ([piece-at-pos (vector-ref (vector-ref state (posn-y move)) 
                                                          (posn-x move))])
                              (or (not (piece? piece-at-pos))
                                  (not (equal? (piece-color piece-at-pos)
                                             (piece-color piece)))))))
                     (append basic-moves castling-moves)))]
           
           [(equal? (piece-type piece) "queen")
            (calculate-blocked-moves pos KING-QUEEN-MOVES #t state)]
           
           [(equal? (piece-type piece) "bishop")
            (calculate-blocked-moves pos DIAGONAL-MOVES #t state)]
           
           [(equal? (piece-type piece) "rook")
            (calculate-blocked-moves pos ROOK-MOVES #t state)]
           
           [else '()])])  ; Default case returns empty list
    (filter in-bounds? moves)))

;;;;; calculate-blocked-moves ;;;;;

;; Input/Output
; calculate-blocked-moves : Posn List<Posn> Boolean GameState -> List<Posn>
; Calculates possible moves for pieces that can be blocked by other pieces
; header: (define (calculate-blocked-moves pos directions repeatable? state) '())

;; Implementation
(define (calculate-blocked-moves pos directions repeatable? state)
  (apply append
         (map (lambda (dir)
                (let loop ([current-pos pos] 
                          [moves '()])
                  (let* ([next-x (+ (posn-x current-pos) (posn-x dir))]
                         [next-y (+ (posn-y current-pos) (posn-y dir))]
                         [next-pos (make-posn next-x next-y)])
                    (cond
                      ; Out of bounds
                      [(not (in-bounds? next-pos))
                       moves]
                      ; Hit our own piece
                      [(let ([piece-at-pos (vector-ref (vector-ref state next-y) next-x)])
                         (and (piece? piece-at-pos)
                              (equal? (piece-color piece-at-pos)
                                     (piece-color (vector-ref (vector-ref state (posn-y pos)) (posn-x pos))))))
                       moves]
                      ; Hit opponent's piece
                      [(piece? (vector-ref (vector-ref state next-y) next-x))
                       (cons next-pos moves)]
                      ; Empty square and can continue
                      [repeatable?
                       (loop next-pos (cons next-pos moves))]
                      ; Empty square but can't continue
                      [else
                       (cons next-pos moves)]))))
              directions)))

;;;;; handle-mouse ;;;;;

;; Input/Output
; handle-mouse : GameState Number Number String -> GameState
; Handles mouse events for piece selection and movement
; headeer: (define (handle-mouse state x y event) ...)

(define current-connection #f)  ; Will store the active connection

;; Implementation
;; Add to your handle-mouse function where moves are made
(define (handle-mouse state x y event)
  (if game-over
      state
      (cond
        [(equal? event "button-down")
         (let* ([clicked-pos (which-square? x y)]
                [row (posn-y clicked-pos)]
                [col (posn-x clicked-pos)]
                [clicked-piece (vector-ref (vector-ref state row) col)])
           (cond
             [(and selected-piece 
                   (member clicked-pos (get-valid-moves selected-piece selected-pos state)))
              (begin
                (let ([new-state (handle-move state clicked-pos)])
                  ; Send move to other player
                  (when current-connection
                    (write (list (posn-x selected-pos) 
                               (posn-y selected-pos)
                               (posn-x clicked-pos)
                               (posn-y clicked-pos))
                          (connection-server-output current-connection))
                    (flush-output (connection-server-output current-connection)))
                  ; Deselect the piece after moving it
                  (vector-set! (vector-ref new-state (posn-y clicked-pos)) 
                             (posn-x clicked-pos)
                             (struct-copy piece (vector-ref (vector-ref new-state (posn-y clicked-pos)) 
                                                          (posn-x clicked-pos))
                                        [selected? #f]))
                  (set! selected-piece #f)
                  (set! selected-pos #f)
                  new-state))]
             ; If we clicked on our own piece (only white pieces)
             [(and (piece? clicked-piece) 
                   (piece-present? clicked-piece)
                   (equal? (piece-color clicked-piece) "white")) ; Only allow white pieces
              (begin
                ; Deselect previously selected piece if any
                (when (and selected-piece selected-pos)
                  (vector-set! (vector-ref state (posn-y selected-pos)) (posn-x selected-pos)
                             (struct-copy piece (vector-ref (vector-ref state (posn-y selected-pos)) 
                                                          (posn-x selected-pos))
                                        [selected? #f])))
                ; Select new piece
                (vector-set! (vector-ref state row) col
                           (struct-copy piece clicked-piece [selected? #t]))
                (set! selected-piece clicked-piece)
                (set! selected-pos clicked-pos)
                state)]
             ; If we clicked elsewhere, deselect
             [else
              (begin
                ; Deselect previously selected piece if any
                (when (and selected-piece selected-pos)
                  (vector-set! (vector-ref state (posn-y selected-pos)) (posn-x selected-pos)
                             (struct-copy piece (vector-ref (vector-ref state (posn-y selected-pos)) 
                                                          (posn-x selected-pos))
                                        [selected? #f])))
                (set! selected-piece #f)
                (set! selected-pos #f)
                state)]))]
        [else state])))

;;;;;;;;;;;;;;;;;;;;;;;
;;MODIFICHE DI MATTEO;;
;;;;;;;;;;;;;;;;;;;;;;;

(define GAME-STATE "NO-GAME") ; can be either NO-GAME or GAME

;; Constants for the welcome screen
(define WINDOW-WIDTH 512)
(define WINDOW-HEIGHT 512)
(define TEXT-BACKGROUND-WIDTH 300) 
(define TEXT-BACKGROUND-HEIGHT 80)
(define TEXT-BACKGROUND-COLOR "lightblue")
(define TEXT-COLOR "black")
(define NETWORK-STATE 'waiting)

;; Create the welcome screen elements
(define TITLE-TEXT (text "Welcome to Chess!" 40 TEXT-COLOR))
(define AUTHORS-TEXT (text "By Leonardo Longhi, Loris Vasirani & Matteo Garzon" 20 TEXT-COLOR))

(define INSTRUCTIONS-TEXT
   (above
    (text "Instructions:" 24 TEXT-COLOR)
    (text "• Press 'h' to host a game." 18 TEXT-COLOR)
    (text "• Press 'j' to join a game." 18 TEXT-COLOR)
    (text "• During the game, press 'q' and Enter to leave." 18 TEXT-COLOR)))

;; Main welcome screen scene
(define (render-welcome state)
  (place-images
   (list TITLE-TEXT
         AUTHORS-TEXT
         INSTRUCTIONS-TEXT)
   (list (make-posn (/ WINDOW-WIDTH 2) 150)
         (make-posn (/ WINDOW-WIDTH 2) 180)
         (make-posn (/ WINDOW-WIDTH 2) (/ WINDOW-HEIGHT 2)))
   (empty-scene WINDOW-WIDTH WINDOW-HEIGHT "azure")))


(define (render-exit state)
  (place-image
   (text "Press 'y' to end the game.\nTo resume, press 'n'." 
         24 
         TEXT-COLOR)
   (/ WINDOW-WIDTH 2)
   (/ WINDOW-HEIGHT 2)
   (empty-scene WINDOW-WIDTH WINDOW-HEIGHT "honeydew")))

(define (reset-chessboard)
  (begin
    (set! selected-piece #f)
    (set! selected-pos #f)
    (set! game-over #f)
    (vector-copy! BOARD-VECTOR 0 INITIAL-STATE)))

; end-game
; also disconnects!!!! + resets the chessboard
(define (end-game)
  (begin
    (set! GAME-STATE "NO-GAME")
    (reset-chessboard)
    (when (or (equal? NETWORK-STATE "SERVER")
              (equal? NETWORK-STATE "CLIENT"))
      (set! NETWORK-STATE 'waiting))))

(define (start-game)
  (cond
    [(equal? NETWORK-STATE "SERVER")
     (when server-did-both-connect
       (begin
         (set! GAME-STATE "GAME")
         (vector-copy! BOARD-VECTOR 0 INITIAL-STATE)
         (start-move-listener current-connection)))]
    [(equal? NETWORK-STATE "CLIENT")
     (when client-did-both-connect
       (begin
         (set! GAME-STATE "GAME")
         (vector-copy! BOARD-VECTOR 0 INITIAL-STATE)
         (start-move-listener current-connection)))]))

(define (exit-game)
  (begin
    (set! GAME-STATE "END-CONFIRMATION")
    (displayln "Exiting the game. Please confirm.")
    ;; Additional cleanup logic can be added here if needed
    ))

;; INPUT/OUTPUT
; handle-key: AppState KeyEvent -> AppState
; modify state 's' in response to 'key' being pressed
; header: (define (handle-key s key) s)

(define (handle-key state key)
  (cond
    [(and (string=? GAME-STATE "GAME" ) (string=? key "q")) ; shows exit prompt
     (begin
       (exit-game)
       state)] 
    [(and (string=? GAME-STATE "END-CONFIRMATION") (string=? key "y")) ; ends game
     (begin
       (end-game)
       state)] 
    [(and (string=? GAME-STATE "END-CONFIRMATION") (string=? key "n")) ; resumes game
     (begin
       (start-game)
       state)] 
  [(and (string=? GAME-STATE "NO-GAME") (equal? key "h"))
     (begin
       (thread (lambda () 
                (start-server)
                ; Set the connection after server starts
                (set! current-connection (get-server-connection))))
       (set! NETWORK-STATE "SERVER")
       (start-game)
       state)]
    [(and (string=? GAME-STATE "NO-GAME") (equal? key "j"))
     (begin
       (thread (lambda () 
                (start-client)
                ; Set the connection after client starts
                (set! current-connection (get-client-connection))))
       (set! NETWORK-STATE "CLIENT")
       (start-game)
       state)]
    [else state]))

(define (render state)
  (cond
    [(string=? "GAME" GAME-STATE) 
     (render-chessboard state)]
    [(and (equal? NETWORK-STATE "SERVER") server-did-both-connect)
     (begin
       (start-game)
       (render-chessboard state))]
    [(and (equal? NETWORK-STATE "CLIENT") client-did-both-connect)
     (begin
       (start-game)
       (render-chessboard state))]
    [(string=? "END-CONFIRMATION" GAME-STATE) 
     (render-exit state)]
    [else 
     (render-welcome state)]))

; Run the program
(big-bang INITIAL-STATE
  (name "Chess")
  (on-mouse handle-mouse)
  (on-key handle-key)
  (to-draw render))