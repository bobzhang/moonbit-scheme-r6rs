///|
test "large program: quicksort with macro" {
  let program = (
    (
      #|(let-syntax ((when
      #|               (syntax-rules ()
      #|                 ((_ test expr ...)
      #|                  (if test (begin expr ...) #f)))))
      #|  (define (quicksort lst)
      #|    (if (null? lst)
      #|        '()
      #|        (let* ((pivot (car lst))
      #|               (rest (cdr lst))
      #|               (smaller (filter (lambda (x) (< x pivot)) rest))
      #|               (greater (filter (lambda (x) (>= x pivot)) rest)))
      #|          (append (quicksort smaller) (list pivot) (quicksort greater)))))
      #|  (define (sorted? lst)
      #|    (cond ((null? lst) #t)
      #|          ((null? (cdr lst)) #t)
      #|          ((<= (car lst) (cadr lst)) (sorted? (cdr lst)))
      #|          (else #f)))
      #|  (let ((result (quicksort '(3 1 4 1 5 9 2 6 5 3 5)))
      #|        (ok #t))
      #|    (when (not (sorted? result)) (set! ok #f))
      #|    (list ok result)))
    )
  )
  inspect(
    value_to_string(eval_program(program)),
    content="(#t (1 1 2 3 3 4 5 5 5 6 9))",
  )
}

///|
test "large program: n-queens count" {
  let program = (
    (
      #|(let ()
      #|  (define (enumerate-interval low high)
      #|    (if (> low high)
      #|        '()
      #|        (cons low (enumerate-interval (+ low 1) high))))
      #|  (define (adjoin-position new-row rest)
      #|    (cons new-row rest))
      #|  (define (safe? positions)
      #|    (let ((row (car positions)))
      #|      (define (iter rest dist)
      #|        (cond ((null? rest) #t)
      #|              ((or (= row (car rest))
      #|                   (= (- row dist) (car rest))
      #|                   (= (+ row dist) (car rest)))
      #|               #f)
      #|              (else (iter (cdr rest) (+ dist 1)))))
      #|      (iter (cdr positions) 1)))
      #|  (define (queen-cols k n)
      #|    (if (= k 0)
      #|        (list '())
      #|        (filter safe?
      #|                (apply append
      #|                       (map (lambda (rest-of-queens)
      #|                              (map (lambda (new-row)
      #|                                     (adjoin-position new-row rest-of-queens))
      #|                                   (enumerate-interval 1 n)))
      #|                            (queen-cols (- k 1) n))))))
      #|  (length (queen-cols 7 7)))
    )
  )
  inspect(value_to_string(eval_program(program)), content="40")
}

///|
test "large program: prime sum" {
  let program = (
    (
      #|(let ()
      #|  (define (range low high)
      #|    (if (> low high)
      #|        '()
      #|        (cons low (range (+ low 1) high))))
      #|  (define (sieve lst)
      #|    (if (null? lst)
      #|        '()
      #|        (let ((p (car lst)))
      #|          (cons p
      #|                (sieve
      #|                  (filter (lambda (x) (not (= 0 (modulo x p))))
      #|                          (cdr lst)))))))
      #|  (define primes (sieve (range 2 100)))
      #|  (apply + primes))
    )
  )
  inspect(value_to_string(eval_program(program)), content="1060")
}

///|
test "large program: takeuchi recursion" {
  let program = (
    (
      #|(let ()
      #|  (define (tak x y z)
      #|    (if (not (< y x))
      #|        z
      #|        (tak (tak (- x 1) y z)
      #|             (tak (- y 1) z x)
      #|             (tak (- z 1) x y))))
      #|  (tak 18 12 6))
    )
  )
  inspect(value_to_string(eval_program(program)), content="7")
}

///|
test "large program: tree sum" {
  let program = (
    (
      #|(let ()
      #|  (define (tree-sum t)
      #|    (cond ((null? t) 0)
      #|          ((pair? t) (+ (tree-sum (car t)) (tree-sum (cdr t))))
      #|          (else t)))
      #|  (tree-sum '(1 (2 (3 4) 5) (6 7) 8)))
    )
  )
  inspect(value_to_string(eval_program(program)), content="36")
}

///|
test "large program: matrix multiply" {
  let program = (
    (
      #|(let ()
      #|  (define (transpose m)
      #|    (if (null? (car m))
      #|        '()
      #|        (cons (map car m) (transpose (map cdr m)))))
      #|  (define (dot v w)
      #|    (apply + (map * v w)))
      #|  (define (matmul a b)
      #|    (let ((cols (transpose b)))
      #|      (map (lambda (row)
      #|             (map (lambda (col) (dot row col)) cols))
      #|           a)))
      #|  (matmul '((1 2 3) (4 5 6)) '((7 8) (9 10) (11 12))))
    )
  )
  inspect(value_to_string(eval_program(program)), content="((58 64) (139 154))")
}

///|
test "large program: call/cc early exit" {
  let program = (
    (
      #|(let ()
      #|  (define (find-negative tree)
      #|    (call/cc
      #|      (lambda (exit)
      #|        (define (walk t)
      #|          (cond ((null? t) #f)
      #|                ((pair? t) (begin (walk (car t)) (walk (cdr t))))
      #|                ((< t 0) (exit t))
      #|                (else #f)))
      #|        (walk tree)
      #|        #f)))
      #|  (find-negative '(1 (2 3) (4 (-5 6)) 7)))
    )
  )
  inspect(value_to_string(eval_program(program)), content="-5")
}
