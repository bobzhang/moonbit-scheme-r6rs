# parser

Datum parser for Scheme source text, built on the lexer reader.

## Entry points

- parse_program parses all top-level forms
- parse_number_token parses number literals

## Example

```mbt
///|
let forms = @parser.parse_program("(+ 1 2)")
```
