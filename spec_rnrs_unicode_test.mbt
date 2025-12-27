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

test "r6rs libraries: unicode categories" {
  let program = (
    (
      #|(import (rnrs unicode))
      #|(list (char-general-category #\A)
      #|      (char-general-category #\a)
      #|      (char-general-category #\5)
      #|      (char-general-category #\space)
      #|      (char-general-category #\newline)
      #|      (char-general-category #\x28)
      #|      (char-general-category #\x29)
      #|      (char-general-category #\x2D)
      #|      (char-general-category #\x5F)
      #|      (char-general-category #\x24)
      #|      (char-general-category #\x2B)
      #|      (char-general-category #\x2E))
    )
  )
  inspect(
    value_to_string(eval_program(program)),
    content="(Lu Ll Nd Zs Cc Ps Pe Pd Pc Sc Sm Po)",
  )
}
