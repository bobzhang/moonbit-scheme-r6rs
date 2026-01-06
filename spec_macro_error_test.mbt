///|
test "r6rs macro: non-procedure transformer" {
  let bad = try? eval_program("(define-syntax bad (+ 1 2))")
  match bad {
    Err(err) => inspect(err, content="EvalError(\"type error: procedure expected\")")
    _ => fail("expected transformer type error")
  }
}

///|
test "r6rs macro: invalid identifier-syntax rule" {
  let bad = try? eval_program(
    "(define-syntax bad (identifier-syntax (x) (y)))",
  )
  match bad {
    Err(err) => inspect(err, content="EvalError(\"invalid identifier-syntax\")")
    _ => fail("expected identifier-syntax error")
  }
}

///|
test "r6rs macro: invalid with-syntax bindings" {
  let program =
    #|(begin
    #|  (define-syntax bad
    #|    (lambda (stx)
    #|      (syntax-case stx ()
    #|        ((_ x) (with-syntax ((x)) #'x)))))
    #|  (bad 1))
  let bad = try? eval_program(program)
  match bad {
    Err(err) => inspect(err, content="EvalError(\"invalid with-syntax\")")
    _ => fail("expected with-syntax error")
  }
}

///|
test "r6rs macro: with-syntax requires datum" {
  let program =
    #|(begin
    #|  (define-syntax bad
    #|    (lambda (stx)
    #|      (syntax-case stx ()
    #|        ((_)
    #|         (with-syntax ((x (lambda (y) y)))
    #|           #'x)))))
    #|  (bad))
  let bad = try? eval_program(program)
  match bad {
    Err(err) => inspect(err, content="EvalError(\"type error: datum expected\")")
    _ => fail("expected datum error")
  }
}

///|
test "r6rs macro: invalid syntax-case clause" {
  let program =
    #|(begin
    #|  (define-syntax bad
    #|    (lambda (stx)
    #|      (syntax-case stx ()
    #|        (()))))
    #|  (bad 1))
  let bad = try? eval_program(program)
  match bad {
    Err(err) => inspect(err, content="EvalError(\"invalid syntax-case clause\")")
    _ => fail("expected syntax-case clause error")
  }
}

///|
test "r6rs macro: invalid syntax-rules literals" {
  let bad = try? eval_program(
    "(define-syntax bad (syntax-rules (1) ((bad) 1)))",
  )
  match bad {
    Err(err) => inspect(err, content="EvalError(\"invalid syntax-rules\")")
    _ => fail("expected syntax-rules error")
  }
}
