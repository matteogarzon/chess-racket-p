;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-advanced-reader.ss" "lang")((modname main) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #t #t none #f () #f)))
;%%%%%%%%%%%%%%%%%%%%;
;#### CHESS GAME ####;
;%%%%%%%%%%%%%%%%%%%%;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Libraries ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Require
(require 2htdp/image)
(require 2htdp/universe)
(require racket/base)
(require "logic.rkt")

; Provide
(provide INITIAL-STATE)
(provide handle-mouse)
(provide render)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Data Type ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; a Piece is a structure:
; where:
;   type           :    String         ; The type of piece (e.g., "pawn", "king")
;   movements      :    List<Posn>     ; List of possible movement directions
;   repeatable?    :    Boolean        ; Whether the piece can repeat its movement
;   color          :    String         ; "black" or "white"
;   selected?      :    Boolean        ; Whether piece is currently selected
;   img            :    Image          ; Visual representation
;   width          :    Number         ; Width of piece image
;   height         :    Number         ; Height of piece image
;   present?       :    Boolean        ; Whether piece is still in play
; interpretation: a piece of the chessboard with his own type, movement-state,
; repeatable-state, color, selected-state, image, width, height, and present-state
(define-struct piece [type movement repeatable? color selected? img width height present?] #:transparent)

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
(define SQUARE-COLOR-1 "light blue") ; Color 1
(define SQUARE-COLOR-2 "white")      ; Color 2

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
; When the first square is color 1
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
(define B-PAWN-IMAGE (scale/xy DIV-RATIO DIV-RATIO (bitmap "Images/Black Pieces/b-pawn.png"))) ; Black pawn
(define W-PAWN-IMAGE (scale/xy DIV-RATIO DIV-RATIO (bitmap "Images/White Pieces/w-pawn.png"))) ; White pawn

(define B-BISHOP-IMAGE (scale/xy DIV-RATIO DIV-RATIO (bitmap "Images/Black Pieces/b-bishop.png"))) ; Black bishop
(define W-BISHOP-IMAGE (scale/xy DIV-RATIO DIV-RATIO (bitmap "Images/White Pieces/w-bishop.png"))) ; White bishop

(define B-KING-IMAGE (scale/xy DIV-RATIO DIV-RATIO (bitmap "Images/Black Pieces/b-king.png"))) ; Black king
(define W-KING-IMAGE (scale/xy DIV-RATIO DIV-RATIO (bitmap "Images/White Pieces/w-king.png"))) ; White king

(define B-QUEEN-IMAGE (scale/xy DIV-RATIO DIV-RATIO (bitmap "Images/Black Pieces/b-queen.png"))) ; Black queen
(define W-QUEEN-IMAGE (scale/xy DIV-RATIO DIV-RATIO (bitmap "Images/White Pieces/w-queen.png"))) ; White queen

(define B-ROOK-IMAGE (scale/xy DIV-RATIO DIV-RATIO (bitmap "Images/Black Pieces/b-rook.png"))) ; Black rook
(define W-ROOK-IMAGE (scale/xy DIV-RATIO DIV-RATIO (bitmap "Images/White Pieces/w-rook.png"))) ; White rook

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
(define W-PAWN1 (make-piece "pawn" VERTICAL-MOVES #f "white" #f W-PAWN-IMAGE pawn-width pawn-height #t))
(define W-PAWN2 (make-piece "pawn" VERTICAL-MOVES #f "white" #f W-PAWN-IMAGE pawn-width pawn-height #t))
(define W-PAWN3 (make-piece "pawn" VERTICAL-MOVES #f "white" #f W-PAWN-IMAGE pawn-width pawn-height #t))
(define W-PAWN4 (make-piece "pawn" VERTICAL-MOVES #f "white" #f W-PAWN-IMAGE pawn-width pawn-height #t))
(define W-PAWN5 (make-piece "pawn" VERTICAL-MOVES #f "white" #f W-PAWN-IMAGE pawn-width pawn-height #t))
(define W-PAWN6 (make-piece "pawn" VERTICAL-MOVES #f "white" #f W-PAWN-IMAGE pawn-width pawn-height #t))
(define W-PAWN7 (make-piece "pawn" VERTICAL-MOVES #f "white" #f W-PAWN-IMAGE pawn-width pawn-height #t))
(define W-PAWN8 (make-piece "pawn" VERTICAL-MOVES #f "white" #f W-PAWN-IMAGE pawn-width pawn-height #t))

; White king
(define W-KING (make-piece "king" KING-QUEEN-MOVES #f "white" #f W-KING-IMAGE king-width king-height #t))

; White queen
(define W-QUEEN (make-piece "queen" KING-QUEEN-MOVES #t "white" #f W-QUEEN-IMAGE queen-width queen-height #t))

; White bishops
(define W-BISHOP1 (make-piece "bishop" DIAGONAL-MOVES #t "white" #f W-BISHOP-IMAGE bishop-width bishop-height #t))
(define W-BISHOP2 (make-piece "bishop" DIAGONAL-MOVES #t "white" #f W-BISHOP-IMAGE bishop-width bishop-height #t))

; White rooks
(define W-ROOK1 (make-piece "rook" ROOK-MOVES #t "white" #f W-ROOK-IMAGE rook-width rook-height #t))
(define W-ROOK2 (make-piece "rook" ROOK-MOVES #t "white" #f W-ROOK-IMAGE rook-width rook-height #t))

; White knights
(define W-KNIGHT1 (make-piece "knight" KNIGHT-MOVES #t "white" #f W-KNIGHT-IMAGE knight-width knight-height #t))
(define W-KNIGHT2 (make-piece "knight" KNIGHT-MOVES #t "white" #f W-KNIGHT-IMAGE knight-width knight-height #t))

; Black pawns
(define B-PAWN1 (make-piece "pawn" VERTICAL-MOVES #f "black" #f B-PAWN-IMAGE pawn-width pawn-height #t))
(define B-PAWN2 (make-piece "pawn" VERTICAL-MOVES #f "black" #f B-PAWN-IMAGE pawn-width pawn-height #t))
(define B-PAWN3 (make-piece "pawn" VERTICAL-MOVES #f "black" #f B-PAWN-IMAGE pawn-width pawn-height #t))
(define B-PAWN4 (make-piece "pawn" VERTICAL-MOVES #f "black" #f B-PAWN-IMAGE pawn-width pawn-height #t))
(define B-PAWN5 (make-piece "pawn" VERTICAL-MOVES #f "black" #f B-PAWN-IMAGE pawn-width pawn-height #t))
(define B-PAWN6 (make-piece "pawn" VERTICAL-MOVES #f "black" #f B-PAWN-IMAGE pawn-width pawn-height #t))
(define B-PAWN7 (make-piece "pawn" VERTICAL-MOVES #f "black" #f B-PAWN-IMAGE pawn-width pawn-height #t))
(define B-PAWN8 (make-piece "pawn" VERTICAL-MOVES #f "black" #f B-PAWN-IMAGE pawn-width pawn-height #t))

; Black king
(define B-KING (make-piece "king" KING-QUEEN-MOVES #t "black" #f B-KING-IMAGE king-width king-height #t))

; Black queen
(define B-QUEEN (make-piece "queen" KING-QUEEN-MOVES #t "black" #f B-QUEEN-IMAGE queen-width queen-height #t))

; Black bishops
(define B-BISHOP1 (make-piece "bishop" DIAGONAL-MOVES #t "black" #f B-BISHOP-IMAGE  bishop-width bishop-height #t))
(define B-BISHOP2 (make-piece "bishop" DIAGONAL-MOVES #t  "black" #f B-BISHOP-IMAGE bishop-width bishop-height #t))

; Black rooks
(define B-ROOK1 (make-piece "rook" ROOK-MOVES #t "black" #f B-ROOK-IMAGE rook-width rook-height #t))
(define B-ROOK2 (make-piece "rook" ROOK-MOVES #t "black" #f B-ROOK-IMAGE rook-width rook-height #t))

; Black knights
(define B-KNIGHT1 (make-piece "knight" KNIGHT-MOVES #t "black" #f B-KNIGHT-IMAGE knight-width knight-height #t))
(define B-KNIGHT2 (make-piece "knight" KNIGHT-MOVES #t "black" #f B-KNIGHT-IMAGE knight-width knight-height #t))

; Defining the iniital state of the game
(define INITIAL-STATE 
  (vector
    (vector B-ROOK1 B-KNIGHT1 B-BISHOP1 B-QUEEN B-KING B-BISHOP2 B-KNIGHT2 B-ROOK2)
    (vector B-PAWN1 B-PAWN2 B-PAWN3 B-PAWN4 B-PAWN5 B-PAWN6 B-PAWN7 B-PAWN8)
    (vector 0 0 0 0 0 0 0 0)
    (vector 0 0 0 0 0 0 0 0)
    (vector 0 0 0 0 0 0 0 0)
    (vector 0 0 0 0 0 0 0 0)
    (vector W-PAWN1 W-PAWN2 W-PAWN3 W-PAWN4 W-PAWN5 W-PAWN6 W-PAWN7 W-PAWN8)
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
(define B-ROOK-S (make-piece "rook" 
                           ROOK-MOVES
                           #t ; repeatable?
                           "black" 
                           #t ; selected?
                           B-ROOK-IMAGE 
                           knight-width 
                           knight-height 
                           #t)) ; present?

;; Examples
(check-expect (highlight-piece B-ROOK1 EMPTY-CHESSBOARD (make-posn 0 0)) (place-image (piece-img B-ROOK1) 32 32 EMPTY-CHESSBOARD))
(check-expect (highlight-piece B-PAWN8 EMPTY-CHESSBOARD (make-posn 7 2)) (place-image (piece-img B-PAWN8) 480 160 EMPTY-CHESSBOARD))
(check-expect (highlight-piece B-ROOK-S EMPTY-CHESSBOARD (make-posn 0 0)) (place-image
                                                                           (overlay
                                                                            (overlay (rectangle SQUARE-SIDE SQUARE-SIDE "outline" "Gold")
                                                                                     (rectangle (- SQUARE-SIDE 1) (- SQUARE-SIDE 1) "outline" "Gold")
                                                                                     (rectangle (- SQUARE-SIDE 2) (- SQUARE-SIDE 2) "outline" "Gold")
                                                                                     (rectangle (- SQUARE-SIDE 3) (- SQUARE-SIDE 3) "outline" "Gold")
                                                                                     (rectangle (- SQUARE-SIDE 4) (- SQUARE-SIDE 4) "outline" "Gold"))
                                                                            (piece-img B-ROOK-S)) 32 32 EMPTY-CHESSBOARD))

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

;;;;; CHECKMATE FUNCTIONS ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
        (place-image (text (get-winner-text) 40 "red")
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

;;;;; get-winner-text ;;;;;

;; Input/Output
; get-winner-text : Void -> String
; returns the text of who won the game based on the turn color.
; header: (define (get-winner-text) "Player 1 wins!")

;; Implementation
(define (get-winner-text)
  (cond
    [(string=? "white" turn-color) "Player 1 wins!"]
    [else "Player 2 wins!"]))

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
                                  (vector 0 0 0 0 0 0 0 0)
                                  (vector 0 0 0 B-QUEEN 0 0 0 0)  ; Queen moved to create check
                                  (vector 0 0 W-KNIGHT1 0 W-KING 0 0 0)
                                  (vector W-PAWN1 W-PAWN2 W-PAWN3 W-PAWN4 W-PAWN5 W-PAWN6 W-PAWN7 W-PAWN8)
                                  (vector W-ROOK1 0 W-BISHOP1 W-QUEEN 0 W-BISHOP2 W-KNIGHT2 W-ROOK2)))
              #t)
(check-expect (would-be-in-check? B-KING 
                                 (make-posn 4 3)
                                 (make-posn 4 4)
                                 (vector
                                  (vector 0 0 0 0 0 0 0 0)
                                  (vector 0 0 0 0 0 0 0 0)
                                  (vector 0 0 0 0 0 0 0 0)
                                  (vector 0 0 0 0 B-KING 0 0 0)  ; Black king at (4,3)
                                  (vector 0 0 0 0 0 0 0 W-QUEEN) ; White queen at (7,4)
                                  (vector 0 0 0 0 0 0 0 0)
                                  (vector 0 0 0 0 0 0 0 0)
                                  (vector 0 0 0 0 0 0 0 0)))
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
    ; Clear original position
    (vector-set! (vector-ref test-state orig-row) orig-col 0)
    ; Place piece in new position
    (vector-set! (vector-ref test-state new-row) new-col 
                 (make-piece (piece-type piece)
                            (piece-movement piece)
                            (piece-repeatable? piece)
                            (piece-color piece)
                            #t ; mark as moved
                            (piece-img piece)
                            (piece-width piece)
                            (piece-height piece)
                            #t))
    ; Check if the king would be in check after this move
    (king-in-check? (piece-color piece) test-state)))

;;;;; vector-copy-deep ;;;;;

;; Input/Output
; vector-copy-deep : Vector<Any> -> Vector<Any>
; Helper function to deep copy a vector (needed for the test board)
; header: (define (vector-copy-deep v) v)

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

; which-square? : Number Number -> Posn
; Converts mouse coordinates to board position
; header: (define (which-square? Piece) (make-posn 1 1))

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

;;;;; CHECKMATE FUNCTIONS ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Constants
(define turn-color "white")
(define selected-piece #f)
(define selected-pos #f)
(define game-over #f)

;;;;; handle-move ;;;;;

;; Input/Output
; handle-move : GameState Posn -> GameState
; Moves a selected piece to the target position if the move is valid
; header: (define (handle-move state target-pos) state)

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
          ; Check for castling
          (if (and (equal? (piece-type selected-piece) "king")
                   (not (piece-selected? selected-piece))
                   (or (and (= target-col (+ orig-col 2))
                            (let ([rook (vector-ref (vector-ref state orig-row) 7)])
                              (and (piece? rook)
                                   (equal? (piece-type rook) "rook")
                                   (not (piece-selected? rook)))))
                       (and (= target-col (- orig-col 3))
                            (let ([rook (vector-ref (vector-ref state orig-row) 0)])
                              (and (piece? rook)
                                   (equal? (piece-type rook) "rook")
                                   (not (piece-selected? rook)))))))
              (begin
                ; Perform castling
                (let ([rook-col (if (= target-col (+ orig-col 2)) 7 0)]
                      [new-rook-col (if (= target-col (+ orig-col 2)) (- target-col 1) (+ target-col 1))])
                  ; Move king with selected? set to #f
                  (vector-set! (vector-ref state orig-row) orig-col 0)
                  (vector-set! (vector-ref state target-row) target-col
                               (make-piece (piece-type selected-piece)
                                           (piece-movement selected-piece)
                                           (piece-repeatable? selected-piece)
                                           (piece-color selected-piece)
                                           #f ; set selected? to false
                                           (piece-img selected-piece)
                                           (piece-width selected-piece)
                                           (piece-height selected-piece)
                                           #t))
                  ; Move rook with selected? set to #f
                  (let ([rook (vector-ref (vector-ref state orig-row) rook-col)])
                    (vector-set! (vector-ref state orig-row) rook-col 0)
                    (vector-set! (vector-ref state target-row) new-rook-col
                                 (make-piece (piece-type rook)
                                             (piece-movement rook)
                                             (piece-repeatable? rook)
                                             (piece-color rook)
                                             #f ; set selected? to false
                                             (piece-img rook)
                                             (piece-width rook)
                                             (piece-height rook)
                                             #t)))
                  (change-turn)))
              ; Normal move or promotion
              (begin
                (vector-set! (vector-ref state orig-row) orig-col 0)
                (let ([new-piece 
                      (if (and (equal? (piece-type selected-piece) "pawn")
                              (or (and (equal? (piece-color selected-piece) "white")
                                      (= target-row 0))
                                  (and (equal? (piece-color selected-piece) "black")
                                      (= target-row 7))))
                          (make-piece "queen"
                                    KING-QUEEN-MOVES
                                    #t
                                    (piece-color selected-piece)
                                    #f ; set selected? to false
                                    (if (equal? (piece-color selected-piece) "white")
                                        W-QUEEN-IMAGE
                                        B-QUEEN-IMAGE)
                                    queen-width
                                    queen-height
                                    #t)
                          (make-piece (piece-type selected-piece)
                                    (piece-movement selected-piece)
                                    (piece-repeatable? selected-piece)
                                    (piece-color selected-piece)
                                    #f ; set selected? to false
                                    (piece-img selected-piece)
                                    (piece-width selected-piece)
                                    (piece-height selected-piece)
                                    #t))])
                  (vector-set! (vector-ref state target-row) target-col new-piece)
                  (change-turn))))
          state)
        state)))

(define (change-turn)
  (cond
    [(string=? turn-color "white") (set! turn-color "black")]
    [else (set! turn-color "white")]))

;;;;; get-valid-moves ;;;;;

;; Input/Output
; get-valid-moves : Piece Posn GameState -> List<Posn>
; Returns a list of all valid positions where the given piece can move
; header: (define (get-valid-moves piece pos state) '())

;; Examples
; Testing pawn moves
(check-expect (get-valid-moves W-PAWN1 
                              (make-posn 0 6) 
                              INITIAL-STATE)
              (list (make-posn 0 5) (make-posn 0 4))) ; Can move one or two squares forward from starting position

; Testing king moves (no castling available)
(check-expect (get-valid-moves W-KING 
                              (make-posn 4 7) 
                              INITIAL-STATE)
              '()) ; No valid moves at start as surrounded by own pieces

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
; Calculates valid moves for pieces that can be blocked by other pieces
; header: (define (calculate-blocked-moves pos directions repeatable? state) '())

;; Examples
(check-expect (calculate-blocked-moves (make-posn 0 0) 
                                     (list (make-posn 1 1)) 
                                     #f 
                                     (vector (vector 0 0) (vector 0 0)))
              (list (make-posn 1 1)))

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
; Where:
;   - state: current game state
;   - x: x-coordinate of mouse click
;   - y: y-coordinate of mouse click
;   - event: type of mouse event ("button-down", "button-up", etc.)
; header: (define (handle-mouse state x y event) INITIAL-STATE)

;; Examples
; Clicking on empty square when no piece selected
(check-expect (begin 
                (set! selected-piece #f)
                (set! selected-pos #f)
                (set! turn-color "white")
                (handle-mouse INITIAL-STATE 
                            (* 4 SQUARE-SIDE) ; x coordinate (center of board)
                            (* 4 SQUARE-SIDE) ; y coordinate (center of board)
                            "button-down"))
              INITIAL-STATE)

; Clicking on white piece during white's turn
(check-expect (begin 
                (set! selected-piece #f)
                (set! selected-pos #f)
                (set! turn-color "white")
                (set! game-over #f)
                (let ([result (handle-mouse INITIAL-STATE 
                                          (* 1 SQUARE-SIDE) ; x coordinate (knight position)
                                          (* 7 SQUARE-SIDE) ; y coordinate (bottom row)
                                          "button-down")])
                  (and (equal? selected-piece W-KNIGHT1)
                      (equal? selected-pos (make-posn 1 7))
                      (equal? result INITIAL-STATE))))
              #t)


;; Implmentation
(define (handle-mouse state x y event)
  (if game-over
      state  ; If game is over, don't allow any more moves
      (cond
        [(equal? event "button-down")
         (let* ([clicked-pos (which-square? x y)]
                [row (posn-y clicked-pos)]
                [col (posn-x clicked-pos)]
                [clicked-piece (vector-ref (vector-ref state row) col)])
           (cond
             ; If we have a selected piece and clicked on a valid move position
             [(and selected-piece 
                   (member clicked-pos (get-valid-moves selected-piece selected-pos state)))
              (begin
                (let ([new-state (handle-move state clicked-pos)]
                      [moving-color (piece-color selected-piece)])
                  ; Check if after the move, the king of the moving player is still in check
                  (when (king-in-check? moving-color new-state)
                    (set! game-over #t))
                  ; Deselect the piece after moving
                  (set! selected-piece #f)
                  (set! selected-pos #f)
                  new-state))]
             ; If we clicked on our own piece
             [(and (piece? clicked-piece) 
                   (piece-present? clicked-piece)
                   (equal? (piece-color clicked-piece) turn-color))
              (begin
                ; First deselect the previously selected piece if there is one
                (when selected-piece
                      (let ([prev-row (posn-y selected-pos)]
                            [prev-col (posn-x selected-pos)])
                        (vector-set! (vector-ref state prev-row) prev-col
                                   (make-piece (piece-type selected-piece)
                                             (piece-movement selected-piece)
                                             (piece-repeatable? selected-piece)
                                             (piece-color selected-piece)
                                             #f  ; Set selected? to false
                                             (piece-img selected-piece)
                                             (piece-width selected-piece)
                                             (piece-height selected-piece)
                                             (piece-present? selected-piece)))))
                ; Then select the new piece
                (vector-set! (vector-ref state row) col
                            (make-piece (piece-type clicked-piece)
                                      (piece-movement clicked-piece)
                                      (piece-repeatable? clicked-piece)
                                      (piece-color clicked-piece)
                                      #t  ; Set selected? to true
                                      (piece-img clicked-piece)
                                      (piece-width clicked-piece)
                                      (piece-height clicked-piece)
                                      (piece-present? clicked-piece)))
                ; Update the selected piece reference
                (set! selected-piece clicked-piece)
                (set! selected-pos clicked-pos)
                state)]
             ; If we clicked elsewhere, deselect any previously selected piece
             [else
              (begin
                (when selected-piece
                      (let ([prev-row (posn-y selected-pos)]
                            [prev-col (posn-x selected-pos)])
                        (vector-set! (vector-ref state prev-row) prev-col
                                   (make-piece (piece-type selected-piece)
                                             (piece-movement selected-piece)
                                             (piece-repeatable? selected-piece)
                                             (piece-color selected-piece)
                                             #f  ; Set selected? to false
                                             (piece-img selected-piece)
                                             (piece-width selected-piece)
                                             (piece-height selected-piece)
                                             (piece-present? selected-piece)))))
                (set! selected-piece #f)
                (set! selected-pos #f)
                state)]))]
        [else state])))


;;;;; RENDERING ;;;;;
;;;;;;;;;;;;;;;;;;;;;

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
  (overlay
   (above
    (text "Instructions:" 24 TEXT-COLOR)
    (text "• Press 'g' to begin the game." 18 TEXT-COLOR)
    (text "• Press 'q' to end the game anytime." 18 TEXT-COLOR))
   (rectangle TEXT-BACKGROUND-WIDTH TEXT-BACKGROUND-HEIGHT "solid" TEXT-BACKGROUND-COLOR)))

;;;;; render-welcome ;;;;;

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

;;;;; render-exit ;;;;;

(define (render-exit state)
  (place-image
   (text "Press 'y' to end the game.\nTo resume, press 'n'." 
         24 
         TEXT-COLOR)
   (/ WINDOW-WIDTH 2)
   (/ WINDOW-HEIGHT 2)
   (empty-scene WINDOW-WIDTH WINDOW-HEIGHT "honeydew")))

;;;;; end-game ;;;;;

; end-game : void
(define (end-game)
 (begin
   (set! GAME-STATE "NO-GAME")
   (reset-chessboard)))

(define (start-game)
 (set! GAME-STATE "GAME"))

(define (exit-game)
 (set! GAME-STATE "END-CONFIRMATION"))

; Copy of the initial state, so that it can be restored before a new game.
(define BOARD-STATE (vector-copy-deep INITIAL-STATE))

;;;;; reset-chessboard ;;;;;

;; Input/Output
; reset-chessboard : Void -> Void
; Resets the chessboard to its initial state
; header: (define (reset-chessboard) (void))

;; Examples
(check-expect (begin 
                (set! selected-piece W-PAWN1)
                (set! selected-pos (make-posn 0 6))
                (set! game-over #t)
                (reset-chessboard)
                (list selected-piece selected-pos game-over))
              (list #f #f #f))

;; Implementation
(define (reset-chessboard)
  (begin
    (set! selected-piece #f)
    (set! selected-pos #f)
    (set! game-over #f)
    (vector-copy! INITIAL-STATE 0 BOARD-STATE)))

;;;;; handle-key ;;;;;

;; Input/Output
; handle-key : GameState String -> GameState
; Handles keyboard input for game control
; header: (define (handle-key state key) state)

;; Examples
(check-expect (begin (set! GAME-STATE "GAME") (handle-key INITIAL-STATE "q") GAME-STATE) "END-CONFIRMATION")
(check-expect (begin (set! GAME-STATE "NO-GAME") (handle-key INITIAL-STATE "g") GAME-STATE) "GAME")

;; Implementation
(define (handle-key state key)
  (cond
    [(and (string=? GAME-STATE "GAME" ) (string=? key "q")) (begin (exit-game) state)] ; shows exit prompt (doesn't end game!)
    [(and (string=? GAME-STATE "END-CONFIRMATION") (string=? key "y")) (begin (end-game) state)] ; ends game + disconnects? 
    [(and (string=? GAME-STATE "END-CONFIRMATION") (string=? key "n")) (begin (start-game) state)] ; resumes game
    [(and (string=? GAME-STATE "NO-GAME") (string=? key "g")) (begin (start-game) state)] ; starts game
    [else state]))

;;;;; render ;;;;;

;; Input/Output
; render : GameState -> Scene
; Renders the appropriate screen based on game state
; header: (define (render state) (empty-scene 0 0))

;; Examples
(check-expect (begin (set! GAME-STATE "NO-GAME") 
                    (render INITIAL-STATE))
              (render-welcome INITIAL-STATE))
(check-expect (begin (set! GAME-STATE "END-CONFIRMATION") 
                    (render INITIAL-STATE))
              (render-exit INITIAL-STATE))

;; Implementation
(define (render state)
  (cond
    [(string=? "GAME" GAME-STATE) (render-chessboard state)]
    [(string=? "END-GAME" GAME-STATE) (render-welcome state)]
    [(string=? "END-CONFIRMATION" GAME-STATE) (render-exit state)]
    [else (render-welcome state)]))


(big-bang INITIAL-STATE
  (name "Chess")
  (on-mouse handle-mouse)
  (on-key handle-key)
  (to-draw render))