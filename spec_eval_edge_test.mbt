///|
test "r6rs eval: empty binding forms" {
  let program =
    #|(list
    #|  (let () 1)
    #|  (let* () 2)
    #|  (letrec () 3)
    #|  (letrec* () 4)
    #|  (let-values () 5)
    #|  (let*-values () 6)
    #|  (parameterize () 7))
  inspect(value_to_string(eval_program(program)), content="(1 2 3 4 5 6 7)")
}

///|
test "r6rs eval: invalid binding shapes" {
  let bad_let = try? eval_program("(let ((x)) x)")
  match bad_let {
    Err(err) => inspect(err, content="EvalError(\"type error: binding expected\")")
    _ => fail("expected binding error")
  }

  let bad_values = try? eval_program("(let-values ((x 1 2)) x)")
  match bad_values {
    Err(err) => inspect(err, content="EvalError(\"invalid let-values\")")
    _ => fail("expected let-values error")
  }

  let bad_param = try? eval_program("(parameterize ((current-output-port)) 1)")
  match bad_param {
    Err(err) => inspect(err, content="EvalError(\"invalid parameterize\")")
    _ => fail("expected parameterize error")
  }
}

///|
test "r6rs eval: invalid guard and case" {
  let bad_guard = try? eval_program("(guard () 1)")
  match bad_guard {
    Err(err) => inspect(err, content="EvalError(\"invalid guard\")")
    _ => fail("expected guard error")
  }

  let bad_case = try? eval_program(
    "(case 1 ((1) => (lambda (x) x) 2) (else 0))",
  )
  match bad_case {
    Err(err) => inspect(err, content="EvalError(\"invalid case\")")
    _ => fail("expected case error")
  }
}

///|
test "r6rs eval: invalid quasisyntax splicing" {
  let bad = try? eval_program("(quasisyntax (unsyntax-splicing 1))")
  match bad {
    Err(err) =>
      inspect(err, content="EvalError(\"unsyntax-splicing not in list context\")")
    _ => fail("expected unsyntax-splicing error")
  }
}

///|
test "r6rs eval: invalid import set" {
  let bad = try? eval_program("(import (for (rnrs)))")
  match bad {
    Err(err) => inspect(err, content="EvalError(\"invalid import set\")")
    _ => fail("expected import set error")
  }
}

///|
test "r6rs eval: invalid library name" {
  let bad = try? eval_program("(import (1))")
  match bad {
    Err(err) => inspect(err, content="EvalError(\"invalid library name\")")
    _ => fail("expected library name error")
  }
}
