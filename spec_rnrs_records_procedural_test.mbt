///|
test "r6rs libraries: records procedural" {
  let program =
    #|(import (rnrs records procedural))
    #|(define rtd
    #|  (make-record-type-descriptor 'point #f #f #f #f
    #|    '#((mutable x))))
    #|(record-type-descriptor? rtd)
  inspect(value_to_string(eval_program(program)), content="#t")
}

///|
test "r6rs libraries: records procedural errors" {
  let bad_desc = try? eval_program(
    (
      #|(begin
      #|  (import (rnrs records procedural))
      #|  (make-record-constructor-descriptor 1 #f #f))
    ),
  )
  inspect(bad_desc is Err(_), content="true")
  let bad_arity = try? eval_program(
    (
      #|(begin
      #|  (import (rnrs records procedural))
      #|  (define rtd
      #|    (make-record-type-descriptor 'point #f #f #f #f
      #|      '#((mutable x))))
      #|  (define rcd (make-record-constructor-descriptor rtd #f #f))
      #|  (define ctor (record-constructor rcd))
      #|  (ctor))
    ),
  )
  inspect(bad_arity is Err(_), content="true")
}
