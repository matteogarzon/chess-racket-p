;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-advanced-reader.ss" "lang")((modname logic) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #t #t none #f () #f)))
(require racket/base)
(require 2htdp/image)
(require 2htdp/universe)

(provide get-piece)
(provide piece-movement)
(provide piece-repeatable?)
(provide move-piece-board)
(provide is-there-piece?)
(provide is-there-opponent-piece?)
(provide my-piece?)
(provide in-bounds?)
(provide piece)
(provide set-null)

(provide DIAGONAL-MOVES)
(provide KNIGHT-MOVES)
(provide KING-QUEEN-MOVES)
(provide VERTICAL-MOVES)
(provide ROOK-MOVES)

(require "piece.rkt")

(define DIAGONAL-MOVES (list (make-posn 1 1) (make-posn 1 -1) (make-posn -1 1) (make-posn -1 -1)))
(define VERTICAL-MOVES (list (make-posn 1 0) (make-posn -1 0)))
(define HORIZONTAL-MOVES (list (make-posn 0 1) (make-posn 0 -1)))
(define KNIGHT-MOVES (list (make-posn 2 1) (make-posn 2 -1) (make-posn -2 1) (make-posn -2 -1) (make-posn 1 2) (make-posn 1 -2) (make-posn -1 2) (make-posn -1 -2)))
(define KING-QUEEN-MOVES (append DIAGONAL-MOVES VERTICAL-MOVES HORIZONTAL-MOVES))
(define ROOK-MOVES (append VERTICAL-MOVES HORIZONTAL-MOVES))

; in-bounds : Posn -> Boolean
; checks if position is inside chess board
; header: (define (in-bounds? (make-posn 5 5) #true))
(define (in-bounds? pos)
  (and (>= (posn-x pos) 0)
       (< (posn-x pos) 8)
       (>= (posn-y pos) 0)
       (< (posn-y pos) 8)))

(check-expect (in-bounds? (make-posn 8 8)) #false)
(check-expect (in-bounds? (make-posn 7 8)) #false)
(check-expect (in-bounds? (make-posn 0 0)) #true)
(check-expect (in-bounds? (make-posn 5 4)) #true)

; move-piece : Posn Posn -> void
; moves piece from original posn position to new position, and mutates the board accordingly
(define (move-piece-board chessboard current-posn new-posn)
  (begin
    (set-piece chessboard new-posn)
    (set-null chessboard current-posn)))

;; HELPER FUNCTIONS FOR 'move-piece-vector'
; set-piece: Posn -> void
(define (set-piece chessboard position)
  (vector-set! (vector-ref chessboard (posn-y position)) (posn-x position) (get-piece position)))

; set-null : Posn -> void
(define (set-null chessboard position)
    (vector-set! (vector-ref chessboard (posn-y position)) (posn-x position) 0))


; checkmate : Posn -> Void
; checks for checkmate, if so, end game.
(define (checkmate position)
  (cond
    [(equal? "king" (piece-type (get-piece position))) 
     (displayln "CHECKMATE! Press q to return to home screen.")]
    [else (void)]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;; HELPER FUNCTIONS ;;;;;

; get-piece : Posn -> Maybe<Piece>
(define (get-piece position)
  (vector-ref (vector-ref BOARD-VECTOR (posn-y position)) (posn-x position)))

; my-piece? : Piece -> Boolean
; checks if piece is of the local player, based on the player number on piece
(define (my-piece? piece)
  (cond
    [(equal? (piece-player piece) 1) #true]
    [else #false]))

; is-there-piece? : Posn -> Boolean
; checks whether there's a piece in the specified position
(define (is-there-piece? position)
  (cond
    [(piece? (get-piece position)) #true]
    [else #false]))

(check-expect (is-there-piece? (make-posn 1 1)) #true)
(check-expect (is-there-piece? (make-posn 5 5)) #false)
(check-expect (is-there-piece? (make-posn 7 7)) #true)

(define (is-there-opponent-piece? position)
  (cond
    [(and (in-bounds? position) (piece? (get-piece position)) (= 2 (piece-player (get-piece position)))) #true]
    [else #false]))