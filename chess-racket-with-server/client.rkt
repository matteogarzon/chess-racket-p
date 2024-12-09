;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-advanced-reader.ss" "lang")((modname client) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #t #t none #f () #f)))
(require racket/tcp)
(require 2htdp/image)
(require racket/base)
(provide get-client-connection)
(define client-connection #f)
(define (get-client-connection) client-connection)
(define CHESS-COLOR "White") ;; default
(define client-did-both-connect #f)
(provide CHESS-COLOR)
(provide client-did-both-connect)
(provide start-client)
(require 2htdp/universe)
(require "logic.rkt")
(require "server.rkt") ; To get the connection structure

;;;;;;;;; CODE FOR THE CLIENT ;;;;;;;;;;;

;; Function to handle receiving moves
(define (handle-received-move move-data)
  (when (and (list? move-data) (= (length move-data) 4))
    (let ((from-pos (make-posn (first move-data) (second move-data)))
          (to-pos (make-posn (third move-data) (fourth move-data))))
      ; Invert the coordinates for the opponent's perspective
      (let ((inverted-from (make-posn (- 7 (posn-x from-pos)) (- 7 (posn-y from-pos))))
            (inverted-to (make-posn (- 7 (posn-x to-pos)) (- 7 (posn-y to-pos)))))
        (move-piece inverted-from inverted-to)))))

;; Function to start listening for moves
(define (start-move-listener in)
  (thread
   (lambda ()
     (let loop ()
       (let ((move-data (read in)))
         (handle-received-move move-data)
         (loop))))))

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


;; CONNECTING TO THE IP ADDRESS ;;

;; connect-ip: -> String
; the player connects to the specific ip address
; header: (define (connect-ip) "")

;; Template

; (define (connect-ip)
;  (... with-handlers ...
;       ... tcp-connect ...)))

(define (connect-ip)
  (displayln "Enter the server IP address")
  (let ((ip-address (read-line)))
    ip-address))

;; CONNECTING TO THE SERVER ;;

;; connect-to-server: String Port -> Port Port
; connects the client to the server
; header: (define (connect-to-server server-ip port) server-input server-output)

;; Template

; (define (connect-to-server server-ip port)
;  (... with-handlers ...
;      (... tcp-connect ... server-ip ... port ...)))

(define (connect-to-server server-ip port)
  (with-handlers
      ((exn:fail:network?
        (lambda (exception)
          (displayln "Unable to connect to the server")
          (exit))))
    (define-values (server-input server-output)
    (tcp-connect server-ip port))
    (values server-input server-output)))

;; SENDING MOVES TO THE SERVER ;;

;; send-move-to-server: Port Move -> void
; sends player's moves to the server
; header: (define (send-move-to-server server-input move) void)

;; Template

; (define (send-move-to-server server-input move)
;  (... with-handlers ...
;       (... move ... server-input ...)))

(define (send-move-to-server server-input move)
  (with-handlers
      ((exn:fail:network?
        (lambda (exception)
          (displayln "Unable to send the move")
          (exit))))
  (write move server-input)  ; sends the move
  (flush-output server-input)))

;; RECEIVING MOVES FROM THE SERVER ;;

;; receive-move-from-server: Port -> Move
; receives a move from the server
; header: (define (receive-move-from-server server-output) WHITE-PAWN-E4)

;; Template

; (define (receive-move-from-server server-output)
;  (... with-handlers ...
;       (cond
;         [... list? ...
;              (cond
;                [... in-bounds? ...]
;                [else ...]
;         [else ...])])))

;; Invert the move for the opponent's perspective
(define (invert-move move)
  (let ((before-move (first move))
        (after-move (second move)))
    (list (make-posn (- 7 (posn-x before-move)) (- 7 (posn-y before-move)))
          (make-posn (- 7 (posn-x after-move)) (- 7 (posn-y after-move))))))

;; receive-move-from-server: Port -> Move
(define (receive-move-from-server server-input)
  (with-handlers
      ((exn:fail:network?
        (lambda (exception)
          (displayln "Disconnected from the server")
          (exit))))
  (let ((input-data (read server-input)))
    (cond
      [(and (list? input-data) (= (length input-data) 4))
       (let ((before-move (make-posn (first input-data) (second input-data)))
             (after-move (make-posn (third input-data) (fourth input-data))))
         (cond
           [(and (in-bounds? before-move) (in-bounds? after-move))
            ;; Invert the move for the opponent's perspective
            (let ((inverted-move (invert-move (list before-move after-move))))
              ;; Apply the opponent's move to the local board
              (move-piece (first inverted-move) (second inverted-move))
              inverted-move)]
           [else 'invalid-move]))]
      [else 'invalid-move]))))

;; DISCONNECTING THE CLIENT FROM THE SERVER ;;

;; disconnect-client: Port Port -> void
; disconnects the client
; header: (define (disconnect-client server-output server-input) void)

;; Template

; (define (disconnect-client server-output server-input)
;  (... with-handlers ...
;  (cond
;    [... server-output ... server-input ... (... server-output ...)
;                                            (... server-input ...)]
;    [... server-output ... (... server-output ...)]
;    [... server-input ... (... server-input ...)])))

(define (disconnect-client server-output server-input)
  (with-handlers
      ((exn:fail:network?
        (lambda (exception)
          (displayln "Error while disconnecting the client"))))
    (cond
      [(and server-output server-input) ; both ports open
       (close-input-port server-output)
       (close-output-port server-input)]
      [server-output ; only input port open
       (close-input-port server-output)]
      [server-input ; only output port open
       (close-output-port server-input)])))

;; HANDLING A GAME SESSION ;;

;; handle-game-session: Port Port -> void
; handles a game session made of multiple games
; header: (define (handle-game-session server-output server-input) void)

;; Template

; (define (handle-game-session server-output server-input)
;  (... with-handlers ...
;    (... CHESS-COLOR ...)
;  (cond
;    [string=? ... server-input ...
;              (... handle-game ...)]
;    [string=? ... server-input ...
;              (... disconnect-client ...)]
;    [else
;     (... handle-game-session ...)])))

(define GAME-STATE "NO-GAME") ; can be either NO-GAME or GAME

(define (handle-game-session server-input server-output)
  (with-handlers
      ((exn:fail:network?
        (lambda (exception)
          (displayln "Connection error")
          (disconnect-client server-output server-input)
          (exit))))
    (let ((color (read server-output)))
      (displayln (string-append "Playing as " color))
      (set! CHESS-COLOR color)
      (let ((start-signal (read server-output)))
        (when (equal? start-signal 'game-start)
          (begin
            (displayln "Game is starting...")
            (vector-copy! BOARD-VECTOR 0 INITIAL-STATE)
            (set! GAME-STATE "GAME")
            ;; Start listening for moves in a separate thread
            (thread
             (lambda ()
               (let loop ()
                 (let ((move (receive-move-from-server server-input)))
                   (when (not (equal? move 'invalid-move))
                     (loop))))))))))))

;; STARTING THE CLIENT

;; start-client: -> void
; starts the client and manages its connection
; header: (define (start-client) void)

;; Template

; (define (start-client)
;  (... with-handlers ...
;  (... connect-ip ...)
;  (... connect-to-server ...)
;  (cond
;    [... server-input ... server-output ...
;     (... handle-game-session ...)]
;    [else ...])))

(define (start-client)
  (with-handlers
      ((exn:fail:network?
        (lambda (exception)
          (displayln "Unable to start the client")
          (exit))))
    (let ((ip-address (connect-ip)))
      (define-values (in out)
        (tcp-connect ip-address 1234))
      (cond
        [(and in out)
         (begin
         (displayln "Connected to the server")
         (set! client-did-both-connect #t))
         ; Read the color assignment from server
         (let ((color (read in)))
           (displayln (string-append "Playing as " color))
           (set! CHESS-COLOR color)
           (let ((start-signal (read in)))
             (when (equal? start-signal 'game-start)
               (displayln "Game is starting...")
               (handle-game-session in out))))]
        [else
         (displayln "Unable to connect to the server")
         (set! client-did-both-connect #f)
         (exit)]))))