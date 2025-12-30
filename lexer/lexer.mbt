///|
using @core {type Datum, type ParseError, unicode_char_foldcase}

///|
pub(all) struct Reader {
  chars : Array[Char]
  mut pos : Int
  mut fold_case : Bool
  labels : Map[Int, Ref[Datum]]
}

///|
/// Create a reader over the given source string.
pub fn make_reader(src : String) -> Reader {
  let chars : Array[Char] = []
  for ch in src {
    chars.push(ch)
  }
  { chars, pos: 0, fold_case: false, labels: Map::new() }
}

///|
/// Peek the next character without consuming it.
pub fn Reader::peek(self : Reader) -> Char? {
  if self.pos < self.chars.length() {
    Some(self.chars[self.pos])
  } else {
    None
  }
}

///|
/// Consume and return the next character.
pub fn Reader::next(self : Reader) -> Char? {
  let ch = self.peek()
  match ch {
    Some(_) => self.pos = self.pos + 1
    None => ()
  }
  ch
}

///|
fn is_delim(ch : Char) -> Bool {
  if ch.is_ascii_whitespace() {
    true
  } else {
    ch == '(' ||
    ch == ')' ||
    ch == '\'' ||
    ch == '`' ||
    ch == ',' ||
    ch == '"' ||
    ch == ';'
  }
}

///|
/// Skip whitespace and comments, leaving the next token ready to read.
pub fn Reader::skip_ws_and_comments(self : Reader) -> Unit raise ParseError {
  while true {
    match self.peek() {
      Some(ch) if ch.is_ascii_whitespace() => {
        self.pos = self.pos + 1
        continue
      }
      Some(';') => {
        // Line comment
        self.pos = self.pos + 1
        while true {
          match self.peek() {
            Some('\n') => {
              self.pos = self.pos + 1
              break
            }
            Some(_) => {
              self.pos = self.pos + 1
              continue
            }
            None => break
          }
        }
        continue
      }
      Some('#') =>
        if self.pos + 1 < self.chars.length() && self.chars[self.pos + 1] == '|' {
          skip_block_comment(self)
          continue
        } else {
          break
        }
      _ => break
    }
  }
}

///|
fn skip_block_comment(r : Reader) -> Unit raise ParseError {
  r.pos = r.pos + 2
  let mut depth = 1
  while depth > 0 {
    if r.pos >= r.chars.length() {
      raise @core.ParseError("unterminated block comment")
    }
    if r.chars[r.pos] == '#' &&
      r.pos + 1 < r.chars.length() &&
      r.chars[r.pos + 1] == '|' {
      depth = depth + 1
      r.pos = r.pos + 2
      continue
    }
    if r.chars[r.pos] == '|' &&
      r.pos + 1 < r.chars.length() &&
      r.chars[r.pos + 1] == '#' {
      depth = depth - 1
      r.pos = r.pos + 2
      continue
    }
    r.pos = r.pos + 1
  }
}

///|
/// Return true if the reader is positioned at an ellipsis token.
pub fn Reader::is_ellipsis_start(self : Reader) -> Bool {
  if self.pos + 2 >= self.chars.length() {
    false
  } else if self.chars[self.pos] == '.' &&
    self.chars[self.pos + 1] == '.' &&
    self.chars[self.pos + 2] == '.' {
    if self.pos + 3 >= self.chars.length() {
      true
    } else {
      is_delim(self.chars[self.pos + 3])
    }
  } else {
    false
  }
}

///|
/// Return true if the reader is positioned at a vector literal start.
pub fn Reader::is_vector_start(self : Reader) -> Bool {
  self.pos + 1 < self.chars.length() && self.chars[self.pos + 1] == '('
}

///|
/// Return true if the reader is positioned at a bytevector literal start.
pub fn Reader::is_bytevector_start(self : Reader) -> Bool {
  if self.pos + 4 >= self.chars.length() {
    false
  } else {
    let mut ok = self.chars[self.pos + 1] == 'v'
    ok = ok && self.chars[self.pos + 2] == 'u'
    ok = ok && self.chars[self.pos + 3] == '8'
    ok = ok && self.chars[self.pos + 4] == '('
    ok
  }
}

///|
/// Read the next token from the reader.
pub fn Reader::read_token(self : Reader) -> String raise ParseError {
  let chars : Array[Char] = []
  let mut in_bar = false
  let mut started = false
  let mut fold_case = self.fold_case
  while true {
    match self.peek() {
      Some(ch) => {
        if !in_bar && is_delim(ch) {
          break
        }
        started = true
        self.pos = self.pos + 1
        if !in_bar && chars.is_empty() && ch == '#' {
          if self.pos < self.chars.length() && self.chars[self.pos] == '\\' {
            fold_case = false
          }
        }
        if in_bar {
          if ch == '|' {
            in_bar = false
          } else if ch == '\\' {
            chars.push(read_identifier_escape(self))
          } else {
            chars.push(ch)
          }
        } else if ch == '|' {
          in_bar = true
        } else if ch == '\\' {
          if chars.length() == 1 && chars[0] == '#' {
            chars.push(ch)
          } else {
            let escaped = read_identifier_escape(self)
            chars.push(
              if fold_case {
                unicode_char_foldcase(escaped)
              } else {
                escaped
              },
            )
          }
        } else {
          let next_char = if fold_case { unicode_char_foldcase(ch) } else { ch }
          chars.push(next_char)
        }
        continue
      }
      _ => break
    }
  }
  if in_bar {
    raise @core.ParseError("unterminated identifier")
  }
  if !started {
    raise @core.ParseError("expected token")
  }
  String::from_array(chars)
}

///|
fn read_identifier_escape(r : Reader) -> Char raise ParseError {
  match r.next() {
    Some('x') | Some('X') => read_hex_escape(r)
    Some(ch) => ch
    None => raise @core.ParseError("unterminated identifier")
  }
}

///|
/// Convert a digit character to its numeric value.
pub fn digit_value(ch : Char) -> Int? {
  if ch.is_ascii_digit() {
    Some(ch.to_int() - '0'.to_int())
  } else if ch.is_ascii_lowercase() {
    Some(ch.to_int() - 'a'.to_int() + 10)
  } else if ch.is_ascii_uppercase() {
    Some(ch.to_int() - 'A'.to_int() + 10)
  } else {
    None
  }
}

///|
/// Read a string literal, handling escapes.
pub fn Reader::read_string(self : Reader) -> String raise ParseError {
  let chars : Array[Char] = []
  while true {
    match self.next() {
      None => raise @core.ParseError("unterminated string")
      Some('"') => break
      Some('\\') =>
        match self.next() {
          Some('\n') => skip_string_line_continuation(self)
          Some('\r') => {
            if self.peek() == Some('\n') {
              self.pos = self.pos + 1
            }
            skip_string_line_continuation(self)
          }
          Some('n') => chars.push('\n')
          Some('t') => chars.push('\t')
          Some('r') => chars.push('\r')
          Some('a') => chars.push('\u{7}')
          Some('b') => chars.push('\u{8}')
          Some('v') => chars.push('\u{0b}')
          Some('f') => chars.push('\u{0c}')
          Some('x') | Some('X') => chars.push(read_hex_escape(self))
          Some('"') => chars.push('"')
          Some('\\') => chars.push('\\')
          Some(ch) => chars.push(ch)
          None => raise @core.ParseError("unterminated string")
        }
      Some(ch) => chars.push(ch)
    }
  }
  String::from_array(chars)
}

///|
fn skip_string_line_continuation(r : Reader) -> Unit {
  while true {
    match r.peek() {
      Some(ch) if ch.is_ascii_whitespace() => {
        r.pos = r.pos + 1
        continue
      }
      _ => break
    }
  }
}

///|
fn read_hex_escape(r : Reader) -> Char raise ParseError {
  let mut acc = 0
  let mut has_digit = false
  while true {
    match r.next() {
      None => raise @core.ParseError("unterminated string")
      Some(';') => {
        if !has_digit {
          raise @core.ParseError("invalid hex escape")
        }
        match acc.to_char() {
          Some(ch) => return ch
          None => raise @core.ParseError("invalid hex escape")
        }
      }
      Some(ch) =>
        match digit_value(ch) {
          Some(digit) if digit < 16 => {
            acc = acc * 16 + digit
            has_digit = true
          }
          _ => raise @core.ParseError("invalid hex escape")
        }
    }
  }
  raise @core.ParseError("invalid hex escape")
}
