///|
test "r6rs libraries: syntax-case make-variable-transformer" {
  let program = (
    (
      #|(begin
      #|  (import (rnrs syntax-case))
      #|  (define storage 1)
      #|  (define-syntax counter
      #|    (make-variable-transformer
      #|      (syntax-rules (set! storage)
      #|        ((set! counter v) (set! storage v))
      #|        (counter storage))))
      #|  (list counter
      #|        (begin (set! counter 5) counter)
      #|        (procedure? (make-variable-transformer (lambda (x) x)))))
    )
  )
  inspect(value_to_string(eval_program(program)), content="(1 5 #t)")
}
