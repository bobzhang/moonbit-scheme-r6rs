///|
test "r6rs libraries: enums" {
  let program = (
    (
      #|(import (rnrs enums))
      #|(let ((colors (make-enumeration '(red green))))
      #|  (enum-set->list colors))
    )
  )
  inspect(value_to_string(eval_program(program)), content="(red green)")
}
