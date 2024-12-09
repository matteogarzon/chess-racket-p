;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-advanced-reader.ss" "lang")((modname server) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #t #t none #f () #f)))
(require racket/tcp)
(require 2htdp/image)
(require racket/base)
(require "logic.rkt")
(require racket/udp)
(provide receive-and-forward-move)
(provide start-server)
(provide server-did-both-connect)
(provide get-server-connection)
(define server-connection #f)
(define (get-server-connection) server-connection)
(define server-did-both-connect #f)
;; Define the connection structure
(provide (struct-out connection))

;;;;;;;;;; CODE FOR THE SERVER ;;;;;;;;;;;;;


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


;; DATA TYPE DEFINITIONS ;;

; a Move is a List<Posn>: (list (make-posn before-column before-row) (make-posn after-column after-row))

; Examples

(define WHITE-PAWN-E4 (list (make-posn 4 6) (make-posn 4 4)))
(define BLACK-BISHOP-C4 (list (make-posn 5 0) (make-posn 2 4)))

; a Port is one of:
; - #false, if it's closed
; - a Number, if it's open

; a Color is a String and is one of:
; - "White"
; - "Black"
; color of the player's pieces

; a Connection is a Structure (make-connection server-input server-output color) where:
; - server-input: Port, the server receives the data when Number
; - server-output: Port, the server sends the data when Number
; - color: Color
; interpretation: the connection of a player to the server
(define-struct connection [server-input server-output color] #:transparent)

; Examples

(define C1 (make-connection 23 27 "White"))
(define C2 (make-connection 109 228 "Black"))

;; PLAYERS BEFORE CONNECTING ;;

(define initial-white-connection (make-connection #false #false "White"))
(define initial-black-connection (make-connection #false #false "Black"))

;; OBTAINING THE IP ADDRESS ;;

;; obtain-ip: -> String
; obtains the IP address of the server
; header: (define (obtain-ip) "")

;; Template

; (define (obtain-ip)
;  (... with-handlers ...
;       (begin
;         (... udp-connect! ...)
;         (... udp-close ...))))

(define (obtain-ip)
  (let ((socket (udp-open-socket))) ; `udp-open-socket`: returns a socket that connects and sends data
    (with-handlers ; `with-handlers`: built-in function for handling exceptions, that in this case are network errors
        ((exn:fail:network? ; `exn:fail:network?`: checks if an exception is related to the network
          (lambda (exception)
            (exit)))) ; if so, it exits the program
      (begin
        (udp-connect! socket "8.8.8.8" 53) ; `udp-connect!`: connects the socket to the ip address and the port
                                           ; 8.8.8.8 and 53: IP address and port used by DNS, specifically 8.8.8.8 referers to Google's DNS
                                           ; and it allows us to obtain the IP address of the computer
        (let ([local-ip (let-values ([(local-ip local-port remote-ip remote-port) 
                                     (udp-addresses socket #true)])
                          local-ip)])
          (udp-close socket)
          local-ip)))))

;; CONNECTION MANAGEMENT ;;

;; connection-management: Port Port Color -> Connection
; manages the player's connection by informing that they connected and outputting the ports and giving a color to the player who connected
; header: (define (connection-management server-input server-output color) (make-connection #false #false "White"))

;; Template

; (define (connection-management server-input server-output color)
;  (... with-handlers...
;  (begin
; (... color ... server-output ...)
; (... server-input ... server-output ... color ...))

;; connection-management: Port Port Color -> Connection
(define (connection-management server-input server-output color)
  (with-handlers
      ((exn:fail:network?
        (lambda (exception)
          (displayln (string-append "Connection error for the " color " player"))
          (close-input-port server-input)
          (close-output-port server-output)
          (exit))))
    (begin
      (displayln (string-append color " is connected")) ; Make sure this line executes
      (set! server-did-both-connect #t)
      (write color server-output) ; Send player's color to the client
      (flush-output server-output) ; Ensure the data is sent immediately
      (make-connection server-input server-output color))))

;; PLAYER'S CONNECTION ;;

; player-connection: TCP-Listener String String -> (values Connection Connection)
; accepts and handles the connection of the players
; header: (define (player-connection listener first-color second-color) (make-connection #false #false "White") (make-connection #false #false "Black"))

;; Template

; (define (player-connection listener color)
;  (... with-handlers ...
;       (local ...
;         (begin ...
;          ))))

(define (player-connection listener first-color second-color)
  (with-handlers
      ((exn:fail:network?
        (lambda (exception)
          (displayln "Connection error. Unable to connect the players")
          (tcp-close listener)
          (exit))))
    (let* ([first-connection (let-values ([(in out) (tcp-accept listener)])
                              (displayln (string-append "Accepting " first-color " player..."))
                              (connection-management in out first-color))]
           [second-connection (let-values ([(in out) (tcp-accept listener)])
                              (displayln (string-append "Accepting " second-color " player..."))
                              (connection-management in out second-color))])
      (begin
        (displayln "Both players connected")
        (set! server-did-both-connect #t)
        (values first-connection second-connection)))))
      
;; RECEIVING PLAYER'S MOVES ;;

;; receive-move: Connection Color -> Any
; receives the player's moves
; header: (define (receive-move connection color) (list (make-posn 0 0) (make-posn 2 2)))

;; Template

; (define (receive-move client color)
;  (... with-handlers ...)
;  (cond
;    [... list? ...]
;    (cond
;      [... in-bounds? ...]
;      [else ...])
;    [equal? ... 'quit ...]
;    [else ...]))
    
(define (receive-move connection color)
    (with-handlers
        ((exn:fail:network?
          (lambda (exception)
            (displayln (string-append color " got disconnected")) 'disconnect))) ; in case of a network error, the function signals that the player got disconnected
      (let ((input-data (read (connection-server-input connection)))) ; reads the data of the input port
        (cond
  [(and (list? input-data) (= (length input-data) 4)) ; if the data is a list (specifically a list with 4 elements),
   (let ((before-move (make-posn (first input-data) (second input-data)))
         (after-move (make-posn (third input-data) (fourth input-data))))
     (cond
       [(and (in-bounds? before-move) (in-bounds? after-move)) ; and the position is valid,
        (list before-move after-move)] ; it outputs the positions before and after the move
       [else 'invalid-move]))]
  [(equal? input-data 'quit) (displayln (string-append color " has quit the game")) 'quit] ; if the player quits, the function signals it
  [else 'invalid-move])))) ; otherwise, the move is indicated as invalid

;; CHECKING IF THE MOVES ARE VALID ;;

;; check-move: Move Color -> Boolean
; checks if a move is a valid chess move and if the moving player is correct
; header: (define (check-move move color) #true)

;; Template

; (define (check-move move color)
;  (cond
;    [... piece ...]
;    [... piece-type ... move ...]
;    [... piece-color ...]
;    [else ... move ...]))

(define (check-move move color)
  (let ((starting-piece (get-piece (first move)))) ; gets the piece at the starting position
    (cond
      [(not (= (length move) 2)) #false] ; checks if the move contains an initial and a final position
      [(not (piece? starting-piece)) #false] ; if there isn't any piece, the move is not valid
      [(not (equal? (piece-color starting-piece) color)) #false] ; checks if the color of the moving player is correct
      [(equal? (piece-type starting-piece) "pawn") ; if the piece is a pawn
       (member (second move) (possible-pawn-moves (list (get-piece (second move))) ; gets the possible moves
                              (first move)))] ; and checks if it's a valid move for the pawn
      [else ; otherwise, if the piece is not a pawn
       (member (second move) (apply append
                                         (calculate-all-moves
                                          (first move) (piece-movement starting-piece) (piece-repeatable? starting-piece))))]))) ; the function checks if its move is valid

;; INTERPRETING THE MOVES

;; interpret-move: Connection Color Connection Color Move -> Boolean
; interprets the moves according to the input received
; header: (define (interpret-move moving-player moving-color opponent-player opponent-color move) #false)

;; Template

; (define (interpret-move moving-player moving-color opponent-player opponent-color move)
;  (... with-handlers ...
;  (cond
;    [... move ...]
;    [... move ...]
;    [... move ... moving-color ...]
;    [else
;      (begin (... move-piece ...)
;             (... write ... opponent-player ...))])))

(define (interpret-move moving-player moving-color opponent-player opponent-color move)
  (with-handlers
      ((exn:fail:network?
        (lambda (exception)
          (displayln (string-append "Connection error while interpreting the move of the " moving-color " player"))
          (close-connection moving-player opponent-player #false)
          (exit))))
  (cond
    [(equal? move 'disconnect)
     (displayln (string-append moving-color " got disconnected")) #false] ; if the player making the move gets disconnected, the function signals it and the game ends
    [(equal? move 'quit)
     (displayln (string-append opponent-color " wins for opponent's quitting")) #false] ; if the player making the move quits, the opponent wins
    [(false? (check-move move moving-color)) 'invalid-move #true] ; if the move is not valid, the function signals it and the game continues
    [else
     (begin
       (move-piece (first move) (second move)) ; moves the piece according to the player's move
       (write move (connection-server-input opponent-player)) ; the move is sent to the opponent
     (flush-output (connection-server-input opponent-player)) ; `flush-output`: guarantees that the data is immediately sent to `opponent-player` in case of a buffer
     #true)]))) ; the game continues

;; Examples

(check-expect (interpret-move C1 "White" C2 "Black" 'quit) #false)

;; receive-and-forward-move: Connection Connection -> Boolean
;; Receives a move from one player and forwards it to the other
(define (receive-and-forward-move from-connection to-connection)
  (let ((move-data (read (connection-server-input from-connection))))
    (when (and (list? move-data) (= (length move-data) 4))
      ; Forward the move to the other player
      (write move-data (connection-server-output to-connection))
      (flush-output (connection-server-output to-connection))
      #t)))

;; MANAGING A SINGLE GAME ;;

;; game-management: Connection Connection -> void
; manages a single game between the two players
; header: (define (game-management white-connection black-connection) void)

;; Template

; (define (game-management white-connection black-connection)
;  (... with-handlers ...
;  (cond
;   [equal? ... white-move ...]
;    [... check-move ...
;         (begin
;           (... move-piece ...)
;           (... white-move ... connection-server-output ... black-connection ...))
;           (cond
;             [equal? ...
;              (... interpret-move ...)]
;            [... check-move ...
;                  (begin
;                    (... move-piece ...)
;                    (... connection-server-output ... white-connection ...))
;                    (... game-management ...)]
;             [else
;              ... game-management ...])]
;    [else
;    ... game-management ...])))

;; Modify game-management to use the new function
(define (game-management white-connection black-connection)
  (with-handlers
      ((exn:fail:network?
        (lambda (exception)
          (displayln "Connection error during game")
          (close-connection white-connection black-connection #false)
          (exit))))
    (begin
      (vector-copy! BOARD-VECTOR 0 INITIAL-STATE)
      (set! server-did-both-connect #t)
      
      ;; Start the game loop
      (let game-loop ()
        (when (or (receive-and-forward-move white-connection black-connection)
                 (receive-and-forward-move black-connection white-connection))
          (game-loop))))))

; End of White player moves

;; CLOSING THE CONNECTION ;;

;; close-connection: Connection Connection TCP listener -> void
; closes the active connections
; header: (define (close-connection white-connection black-connection listener) void)

;; Template

; (define (close-connection white-connection black-connection listener)
;  (... with-handlers ...
;  (cond
;    [... white-connection ... (... close-input-port ....)])
;  (cond
;    [... white-connection ... (... close-output-port ...)])
;  (cond
;    [... black-connection ... (... close-input-port ...)])
;  (cond
;    [... black-connection ... (... close-output-port ...)])
;  (cond
;    [... listener ... (... tcp-close ...)])))

(define (close-connection white-connection black-connection listener)
  (with-handlers
      ((exn:fail:network?
        (lambda (exception)
          (displayln "Error while closing the connection. Forcing the closing"))))
  (cond
    [(connection-server-input white-connection)
     (close-input-port (connection-server-input white-connection))]) ; `close-input-port`: built-in function that closes the input port
  (cond
    [(connection-server-output white-connection)
     (close-output-port (connection-server-output white-connection))]) ; `close-output-port`: same, but closes the output port
  (cond
    [(connection-server-input black-connection)
     (close-input-port (connection-server-input black-connection))])
  (cond
    [(connection-server-output black-connection)
     (close-output-port (connection-server-output black-connection))])
  (cond
    [listener
     (tcp-close listener)]))) ; `tcp-close`: shuts down the server associated with `listener`

;; HANDLING A GAME SESSION ;;

;; game-session: Connection Connection TCP listener -> void
; handles a game session made of multiple games
; header: (define (game-session black-connection white-connection listener) void)

;; Template

; (define (game-session black-connection white-connection listener)
;  (... with-handlers ...
;       (... game-management ...)
;       (cond
;         [string=? ...
;          (... game-session ...)]
;         [string=? ...
;          (... close-connection ...)]
;         [else
;          (... game-session ...)])))

(define (game-session black-connection white-connection listener)
  (with-handlers
      ((exn:fail:network?
        (lambda (exception)
          (displayln "Connection error")
          (close-connection white-connection black-connection listener)
          (exit))))
    (local ; reset-board: ->void
      ((define (reset-board)
         (vector-copy! BOARD-VECTOR 0 INITIAL-STATE)))
      (begin
        (reset-board)
    (game-management white-connection black-connection)
    (displayln "Game ended. Do you want to play again? (yes/no)")
    (let ((answer (read-line))) ; `read-line`: built-in function that reads what the player writes
      (cond
        [(string=? answer "yes")
         (reset-board)
         (game-session black-connection white-connection listener)]
        [(string=? answer "no")
         (close-connection white-connection black-connection listener)]
        [else
         (displayln "Invalid answer. Type 'yes' or 'no'")
         (game-session black-connection white-connection listener)]))))))

;; ALLOWING MULTIPLE GAMES ;;

;; multiple-games: TCP listener -> void
; allows to play as many games as wanted
; header: (define (multiple-games listener) void)

;; Template

; (define (multiple-games listener)
;  (... with-handlers ...
;       (... player-connection ...)
;       (... game-session ...)))

(define (multiple-games listener)
  (let-values ([(black-connection white-connection) (player-connection listener "Black" "White")])
    (begin
      (displayln "Both players connected - initializing game...")
      (set! server-did-both-connect #t)
      ;; Initialize game state
      (vector-copy! BOARD-VECTOR 0 INITIAL-STATE)
      ;; Start game management
      (game-management white-connection black-connection))))
  
;; STARTING THE SERVER ;;

;; start-server: -> void
; starts the server and manages players' connection
; header: (define (start-server) void)

;; Template

; (define (start-server)
;  (... with-handlers ...)
;  (thread
;   (local
;     (cond
;       [... read-line ...]
;       [else ...])
;     (... multiple-games ...))))

(define (start-server)
  (with-handlers
      ((exn:fail:network?
        (lambda (exception)
          (displayln "Port already in use")
          (exit)))) ; if the port is already in use, the program gets closed
    (let ((listener (tcp-listen 1234 2 #true)) ; the `listener` waits for connections on port 1234,
                                               ; allowing maximum 2 players to try to connect
                                               ; and allowing reuse of the port right after the server terminated
          (ip-address (obtain-ip)))
      (displayln (string-append "Server started on IP address " ip-address " and Port 1234"))
      (displayln "Digit 'q' and press Enter to terminate the server")
      (thread ; monitors in parallel to the rest of the function if the player wants to quit
       (local ; player-quit: -> void
         ((define (player-quit)
         (cond
           [(equal? (read-line) "q")
            (displayln "Terminating the server")
            (tcp-close listener) ; if the player wants to quit, the server is closed and
            (exit)] ; the program gets closed
         [else (player-quit)]))) ; otherwise, it keeps monitoring if the player wants to quit
         player-quit)) ; gives the function for the `thread`
    (multiple-games listener))))