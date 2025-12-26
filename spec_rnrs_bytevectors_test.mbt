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

///|
test "r6rs libraries: bytevector integer refs" {
  let program = (
    (
      #|(import (rnrs bytevectors))
      #|(let ((bv #vu8(1 2 3 4 255 255 255 255)))
      #|  (list (bytevector-u16-ref bv 0 (endianness big))
      #|        (bytevector-u16-ref bv 0 (endianness little))
      #|        (bytevector-s16-ref bv 4 (endianness big))
      #|        (bytevector-u32-ref bv 0 (endianness big))
      #|        (bytevector-u32-ref bv 0 (endianness little))
      #|        (bytevector-s32-ref bv 4 (endianness big))
      #|        (bytevector-uint-ref bv 0 (endianness big) 2)
      #|        (bytevector-sint-ref bv 4 (endianness little) 2)))
    )
  )
  inspect(
    value_to_string(eval_program(program)),
    content="(258 513 -1 16909060 67305985 -1 258 -1)",
  )
}

///|
test "r6rs libraries: bytevector integer set!" {
  let program = (
    (
      #|(import (rnrs bytevectors))
      #|(list
      #|  (let ((bv (make-bytevector 4 0)))
      #|    (bytevector-u16-set! bv 0 (endianness big) 258)
      #|    (bytevector-u16-set! bv 2 (endianness little) 772)
      #|    (bytevector->u8-list bv))
      #|  (let ((bv (make-bytevector 2 0)))
      #|    (bytevector-s16-set! bv 0 (endianness big) -1)
      #|    (bytevector->u8-list bv)))
    )
  )
  inspect(
    value_to_string(eval_program(program)),
    content="((1 2 4 3) (255 255))",
  )
}

///|
test "r6rs libraries: bytevector native endianness" {
  let program = (
    (
      #|(import (rnrs bytevectors))
      #|(let ((bv #vu8(1 2)))
      #|  (list (eq? (endianness big) 'big)
      #|        (= (bytevector-u16-native-ref bv 0)
      #|           (bytevector-u16-ref bv 0 (native-endianness)))))
    )
  )
  inspect(value_to_string(eval_program(program)), content="(#t #t)")
}
