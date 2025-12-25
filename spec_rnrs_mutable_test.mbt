///|
test "r6rs libraries: mutable-pairs" {
  let program = (
    (
      #|(import (rnrs mutable-pairs))
      #|(let ((p (cons 1 2)))
      #|  (set-car! p 3)
      #|  (set-cdr! p 4)
      #|  p)
    )
  )
  inspect(value_to_string(eval_program(program)), content="(3 . 4)")
}
