# core

Core runtime data types and Unicode utilities used across the interpreter.

## Highlights

- Datum, Value, and Primitive definitions
- Runtime type records and continuations
- Unicode category and normalization helpers

## Examples

```mbt
///|
let folded = @core.unicode_string_foldcase("StraSSE")

///|
let nfc = @core.unicode_string_normalize_nfc("e\u{301}")
```
