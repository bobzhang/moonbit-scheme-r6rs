///|
test "r6rs bitwise: basic ops" {
  inspect(
    value_to_string(
      eval_program(
        (
          #|(bitwise-and)
        ),
      ),
    ),
    content="-1",
  )
  inspect(
    value_to_string(
      eval_program(
        (
          #|(bitwise-ior)
        ),
      ),
    ),
    content="0",
  )
  inspect(
    value_to_string(
      eval_program(
        (
          #|(bitwise-xor)
        ),
      ),
    ),
    content="0",
  )
  inspect(
    value_to_string(
      eval_program(
        (
          #|(bitwise-and 6 3)
        ),
      ),
    ),
    content="2",
  )
  inspect(
    value_to_string(
      eval_program(
        (
          #|(bitwise-ior 6 3)
        ),
      ),
    ),
    content="7",
  )
  inspect(
    value_to_string(
      eval_program(
        (
          #|(bitwise-xor 6 3)
        ),
      ),
    ),
    content="5",
  )
  inspect(
    value_to_string(
      eval_program(
        (
          #|(bitwise-and -1 5)
        ),
      ),
    ),
    content="5",
  )
  inspect(
    value_to_string(
      eval_program(
        (
          #|(bitwise-xor -1 1)
        ),
      ),
    ),
    content="-2",
  )
  inspect(
    value_to_string(
      eval_program(
        (
          #|(bitwise-not 0)
        ),
      ),
    ),
    content="-1",
  )
  inspect(
    value_to_string(
      eval_program(
        (
          #|(bitwise-not -1)
        ),
      ),
    ),
    content="0",
  )
  inspect(
    value_to_string(
      eval_program(
        (
          #|(bitwise-if 3 8 4)
        ),
      ),
    ),
    content="4",
  )
  inspect(
    value_to_string(
      eval_program(
        (
          #|(arithmetic-shift 3 2)
        ),
      ),
    ),
    content="12",
  )
  inspect(
    value_to_string(
      eval_program(
        (
          #|(arithmetic-shift 13 -2)
        ),
      ),
    ),
    content="3",
  )
  inspect(
    value_to_string(
      eval_program(
        (
          #|(arithmetic-shift -7 -1)
        ),
      ),
    ),
    content="-4",
  )
}

///|
test "r6rs bitwise: counts and bits" {
  inspect(
    value_to_string(
      eval_program(
        (
          #|(bitwise-bit-count 0)
        ),
      ),
    ),
    content="0",
  )
  inspect(
    value_to_string(
      eval_program(
        (
          #|(bitwise-bit-count 7)
        ),
      ),
    ),
    content="3",
  )
  inspect(
    value_to_string(
      eval_program(
        (
          #|(bitwise-bit-count -2)
        ),
      ),
    ),
    content="1",
  )
  inspect(
    value_to_string(
      eval_program(
        (
          #|(bitwise-length 0)
        ),
      ),
    ),
    content="0",
  )
  inspect(
    value_to_string(
      eval_program(
        (
          #|(bitwise-length 7)
        ),
      ),
    ),
    content="3",
  )
  inspect(
    value_to_string(
      eval_program(
        (
          #|(bitwise-length -2)
        ),
      ),
    ),
    content="1",
  )
  inspect(
    value_to_string(
      eval_program(
        (
          #|(bitwise-first-bit-set 0)
        ),
      ),
    ),
    content="-1",
  )
  inspect(
    value_to_string(
      eval_program(
        (
          #|(bitwise-first-bit-set 10)
        ),
      ),
    ),
    content="1",
  )
  inspect(
    value_to_string(
      eval_program(
        (
          #|(bitwise-first-bit-set -2)
        ),
      ),
    ),
    content="1",
  )
  inspect(
    value_to_string(
      eval_program(
        (
          #|(bitwise-bit-set? 10 1)
        ),
      ),
    ),
    content="#t",
  )
  inspect(
    value_to_string(
      eval_program(
        (
          #|(bitwise-bit-set? 10 0)
        ),
      ),
    ),
    content="#f",
  )
  inspect(
    value_to_string(
      eval_program(
        (
          #|(bitwise-bit-set? -2 0)
        ),
      ),
    ),
    content="#f",
  )
  inspect(
    value_to_string(
      eval_program(
        (
          #|(bitwise-bit-set? -2 1)
        ),
      ),
    ),
    content="#t",
  )
  inspect(
    value_to_string(
      eval_program(
        (
          #|(bitwise-copy-bit 0 1 1)
        ),
      ),
    ),
    content="2",
  )
  inspect(
    value_to_string(
      eval_program(
        (
          #|(bitwise-copy-bit 3 0 0)
        ),
      ),
    ),
    content="2",
  )
}

///|
test "r6rs bitwise: bit fields" {
  inspect(
    value_to_string(
      eval_program(
        (
          #|(bitwise-bit-field 54 1 4)
        ),
      ),
    ),
    content="3",
  )
  inspect(
    value_to_string(
      eval_program(
        (
          #|(bitwise-copy-bit-field 0 1 4 13)
        ),
      ),
    ),
    content="10",
  )
  inspect(
    value_to_string(
      eval_program(
        (
          #|(bitwise-rotate-bit-field 13 0 4 1)
        ),
      ),
    ),
    content="11",
  )
  inspect(
    value_to_string(
      eval_program(
        (
          #|(bitwise-rotate-bit-field 13 0 4 -1)
        ),
      ),
    ),
    content="14",
  )
  inspect(
    value_to_string(
      eval_program(
        (
          #|(bitwise-reverse-bit-field 13 0 4)
        ),
      ),
    ),
    content="11",
  )
}

///|
test "r6rs bitwise: edge cases" {
  inspect(
    value_to_string(eval_program("(bitwise-bit-field 54 2 2)")),
    content="0",
  )
  inspect(
    value_to_string(eval_program("(bitwise-copy-bit-field 7 2 2 1)")),
    content="7",
  )
  inspect(
    value_to_string(eval_program("(bitwise-rotate-bit-field 7 2 2 1)")),
    content="7",
  )
  inspect(
    value_to_string(eval_program("(bitwise-reverse-bit-field 7 2 2)")),
    content="7",
  )
  let err_field = try? eval_program("(bitwise-bit-field 1 3 2)")
  inspect(err_field is Err(_), content="true")
  let err_neg = try? eval_program("(bitwise-bit-field 1 -1 2)")
  inspect(err_neg is Err(_), content="true")
  let err_copy_field =
    try? eval_program("(bitwise-copy-bit-field 1 3 2 0)")
  inspect(err_copy_field is Err(_), content="true")
  let err_rotate =
    try? eval_program("(bitwise-rotate-bit-field 1 3 2 1)")
  inspect(err_rotate is Err(_), content="true")
  let err_reverse =
    try? eval_program("(bitwise-reverse-bit-field 1 3 2)")
  inspect(err_reverse is Err(_), content="true")
  let err_copy = try? eval_program("(bitwise-copy-bit 0 1 12345678901234567890)")
  inspect(err_copy is Err(_), content="true")
}
