///|
test "r6rs char and string primitives" {
  inspect(value_to_string(eval_program("#\\a")), content="#\\a")
  inspect(value_to_string(eval_program("#\\space")), content="#\\space")
  inspect(value_to_string(eval_program("#\\newline")), content="#\\newline")
  inspect(value_to_string(eval_program("(char? #\\a)")), content="#t")
  inspect(value_to_string(eval_program("(char? \"a\")")), content="#f")
  inspect(value_to_string(eval_program("(string? \"hi\")")), content="#t")
  inspect(value_to_string(eval_program("(string-length \"hi\")")), content="2")
  inspect(value_to_string(eval_program("(string-append \"a\" \"b\" \"c\")")), content="\"abc\"")
  inspect(value_to_string(eval_program("(string-append)")), content="\"\"")
  inspect(value_to_string(eval_program("(string-ref \"hi\" 0)")), content="#\\h")
  inspect(value_to_string(eval_program("(string-ref \"hi\" 1)")), content="#\\i")
  inspect(value_to_string(eval_program("(string->list \"hi\")")), content="(#\\h #\\i)")
  inspect(value_to_string(eval_program("(list->string '(#\\h #\\i))")), content="\"hi\"")
  inspect(value_to_string(eval_program("(list->string '())")), content="\"\"")
  inspect(value_to_string(eval_program("(char=? #\\a #\\a #\\a)")), content="#t")
  inspect(value_to_string(eval_program("(char<? #\\a #\\b #\\c)")), content="#t")
  inspect(value_to_string(eval_program("(char>? #\\c #\\b #\\a)")), content="#t")
  inspect(value_to_string(eval_program("(char<=? #\\a #\\a #\\b)")), content="#t")
  inspect(value_to_string(eval_program("(char>=? #\\c #\\c #\\b)")), content="#t")
  inspect(value_to_string(eval_program("(char-ci=? #\\A #\\a)")), content="#t")
  inspect(value_to_string(eval_program("(char-ci<? #\\A #\\b)")), content="#t")
  inspect(value_to_string(eval_program("(string=? \"hi\" \"hi\")")), content="#t")
  inspect(value_to_string(eval_program("(string<? \"a\" \"ab\")")), content="#t")
  inspect(value_to_string(eval_program("(string>? \"b\" \"a\")")), content="#t")
  inspect(value_to_string(eval_program("(string<=? \"a\" \"a\" \"b\")")), content="#t")
  inspect(value_to_string(eval_program("(string>=? \"c\" \"c\" \"b\")")), content="#t")
  inspect(value_to_string(eval_program("(string-ci=? \"A\" \"a\")")), content="#t")
  inspect(value_to_string(eval_program("(string-ci<? \"a\" \"B\")")), content="#t")
}

///|
test "r6rs string-ref: errors" {
  let out_of_range = try? eval_program("(string-ref \"a\" 1)")
  match out_of_range {
    Err(err) => inspect(err, content="EvalError(\"index out of range\")")
    _ => fail("expected EvalError for out of range")
  }

  let bad_char_list = try? eval_program("(list->string '(#\\a 1))")
  match bad_char_list {
    Err(err) => inspect(err, content="EvalError(\"type error: char expected\")")
    _ => fail("expected EvalError for non-char list->string")
  }
}

///|
test "r6rs char/string compare: errors" {
  let bad_char = try? eval_program("(char=? #\\a \"a\")")
  match bad_char {
    Err(err) => inspect(err, content="EvalError(\"type error: char expected\")")
    _ => fail("expected EvalError for non-char")
  }

  let bad_string = try? eval_program("(string<? \"a\" #\\b)")
  match bad_string {
    Err(err) => inspect(err, content="EvalError(\"type error: string expected\")")
    _ => fail("expected EvalError for non-string")
  }
}
