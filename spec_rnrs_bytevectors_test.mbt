///|
test "r6rs libraries: bytevectors" {
  let program = (
    (
      #|(import (rnrs bytevectors))
      #|(bytevector->u8-list (bytevector 1 2 3))
    )
  )
  inspect(value_to_string(eval_program(program)), content="(1 2 3)")
}
