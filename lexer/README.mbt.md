# lexer

Reader and token utilities used by the parser.

## Entry points

- make_reader to create a reader
- Reader::read_token to scan the next token
- Reader::read_string to parse string literals

## Example

```mbt
///|
let reader = @lexer.make_reader("(+ 1 2)")

///|
let tok = reader.read_token()
```

```mbt check
///|
test "reader helpers" {
  inspect(digit_value('9'), content="Some(9)")
  let r = make_reader("#(1 2)")
  inspect(r.is_vector_start(), content="true")
}
```
