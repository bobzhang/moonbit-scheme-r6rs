# lexer

Reader and token utilities used by the parser.

## Entry points

- make_reader to create a reader
- read_token to scan the next token
- read_string to parse string literals

## Example

```mbt
///|
let reader = @lexer.make_reader("(+ 1 2)")

///|
let tok = @lexer.read_token(reader)
```
