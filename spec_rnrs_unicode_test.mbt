///|
test "r6rs libraries: unicode" {
  let program = (
    (
      #|(import (rnrs unicode))
      #|(string-upcase "aB")
    )
  )
  inspect(value_to_string(eval_program(program)), content="\"AB\"")
}
