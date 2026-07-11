// parser.hc — TOML parser (bare keys + basic string values)
import "./toml_types"
from "std/datetime" import { datetime_kind }

// ============================================================
// Character helpers
// ============================================================

pub fun peek(s: string, pos: int) : string =>
  if pos >= str_length(s) { "" }
  else { s[pos: pos + 1] }

pub fun is_ws(c: string) : bool =>
  c == " " || c == "\t"

pub fun is_newline(c: string) : bool =>
  c == "\n" || c == "\r"

pub fun is_digit_str(c: string) : bool =>
  contains("0123456789", c)

pub fun is_control_char(c: string) : bool {
  if str_length(c) != 1 { false }
  else {
    match chars(c) {
      [ch] => {
        let n = ord(ch)
        if n == 9 { false }
        else if n == 10 { false }
        else if n == 13 { false }
        else if n >= 0 && n <= 31 { true }
        else if n == 127 { true }
        else { false }
      },
      _ => false
    }
  }
}

pub fun is_bare_key_char(c: string) : bool =>
  contains("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_", c)

pub fun is_hex_char(c: string) : bool =>
  contains("0123456789abcdefABCDEF", c)

pub fun hex_digit_val(c: string) : int => match c {
  "0" => 0, "1" => 1, "2" => 2, "3" => 3, "4" => 4,
  "5" => 5, "6" => 6, "7" => 7, "8" => 8, "9" => 9,
  "a" | "A" => 10, "b" | "B" => 11, "c" | "C" => 12,
  "d" | "D" => 13, "e" | "E" => 14, _ => 15
}

// Parse exactly n hex digits starting at pos, return (codepoint, new_pos) or error
pub fun parse_hex_digits(s: string, pos: int, n: int, acc: int) : result<(int, int), string> {
  if n == 0 { Ok((acc, pos)) }
  else if pos >= str_length(s) { Err("unexpected end in unicode escape") }
  else if is_hex_char(peek(s, pos)) {
    parse_hex_digits(s, pos + 1, n - 1, acc * 16 + hex_digit_val(peek(s, pos)))
  }
  else { Err("invalid hex digit in unicode escape: " + peek(s, pos)) }
}

// ============================================================
// Scanning helpers
// ============================================================

pub fun skip_ws(s: string, pos: int) : int {
  if pos >= str_length(s) { pos }
  else if is_ws(peek(s, pos)) { skip_ws(s, pos + 1) }
  else { pos }
}

pub fun skip_to_eol(s: string, pos: int) : int {
  if pos >= str_length(s) { pos }
  else if peek(s, pos) == "\n" { pos }
  else if peek(s, pos) == "\r" { pos }
  else { skip_to_eol(s, pos + 1) }
}

pub fun scan_comment(s: string, pos: int) : result<int, string> {
  if pos >= str_length(s) { Ok(pos) }
  else if peek(s, pos) == "\n" { Ok(pos) }
  else if peek(s, pos) == "\r" { Ok(pos) }
  else if is_control_char(peek(s, pos)) { Err("control character in comment at position " + show(pos)) }
  else { scan_comment(s, pos + 1) }
}

pub fun skip_newline(s: string, pos: int) : int {
  if pos >= str_length(s) { pos }
  else if peek(s, pos) == "\r" && peek(s, pos + 1) == "\n" { pos + 2 }
  else if peek(s, pos) == "\n" { pos + 1 }
  else { pos }
}

pub fun skip_ws_nl_comments(s: string, pos: int) : int {
  if pos >= str_length(s) { pos }
  else if is_ws(peek(s, pos)) || is_newline(peek(s, pos)) {
    skip_ws_nl_comments(s, pos + 1)
  }
  else if peek(s, pos) == "#" {
    skip_ws_nl_comments(s, skip_to_eol(s, pos))
  }
  else { pos }
}

// Expect newline, comment+newline, or EOF after a value
pub fun expect_eol(s: string, pos: int) : result<int, string> {
  let p = skip_ws(s, pos)
  if p >= str_length(s) { Ok(p) }
  else if peek(s, p) == "#" {
    let end = scan_comment(s, p + 1)?
    Ok(skip_newline(s, end))
  }
  else if is_newline(peek(s, p)) { Ok(skip_newline(s, p)) }
  else { Err("expected newline or comment at position " + show(p)) }
}

// ============================================================
// Bare key parsing
// ============================================================

pub fun scan_bare_key(s: string, pos: int) : int {
  if pos >= str_length(s) { pos }
  else if is_bare_key_char(peek(s, pos)) { scan_bare_key(s, pos + 1) }
  else { pos }
}

pub fun parse_bare_key(s: string, pos: int) : result<(string, int), string> {
  let end_pos = scan_bare_key(s, pos)
  if end_pos == pos { Err("expected a key at position " + show(pos)) }
  else { Ok((s[pos: end_pos], end_pos)) }
}

// Dispatch: bare key, "quoted key", or 'literal key'
pub fun parse_key(s: string, pos: int) : result<(string, int), string> {
  if peek(s, pos) == "\"" { parse_basic_string(s, pos) }
  else if peek(s, pos) == "\'" { parse_literal_key(s, pos + 1, "") }
  else { parse_bare_key(s, pos) }
}

pub fun parse_literal_key(s: string, pos: int, acc: string) : result<(string, int), string> {
  if pos >= str_length(s) { Err("unterminated literal key") }
  else if peek(s, pos) == "\'" { Ok((acc, pos + 1)) }
  else if peek(s, pos) == "\n" { Err("newline in literal key at position " + show(pos)) }
  else { parse_literal_key(s, pos + 1, acc + peek(s, pos)) }
}

// ============================================================
// Basic string parsing ("...")
// ============================================================

pub fun parse_basic_string(s: string, pos: int) : result<(string, int), string> {
  if peek(s, pos) != "\"" { Err("expected '\"' at position " + show(pos)) }
  else { scan_basic_string(s, pos + 1, "") }
}

pub fun scan_basic_string(s: string, pos: int, acc: string) : result<(string, int), string> {
  if pos >= str_length(s) { Err("unterminated string") }
  else if peek(s, pos) == "\"" { Ok((acc, pos + 1)) }
  else if peek(s, pos) == "\\" { scan_escape(s, pos + 1, acc) }
  else if peek(s, pos) == "\n" { Err("newline in basic string at position " + show(pos)) }
  else { scan_basic_string(s, pos + 1, acc + peek(s, pos)) }
}

pub fun scan_escape(s: string, pos: int, acc: string) : result<(string, int), string> {
  if pos >= str_length(s) { Err("unterminated escape sequence") }
  else if peek(s, pos) == "n" { scan_basic_string(s, pos + 1, acc + "\n") }
  else if peek(s, pos) == "t" { scan_basic_string(s, pos + 1, acc + "\t") }
  else if peek(s, pos) == "r" { scan_basic_string(s, pos + 1, acc + "\r") }
  else if peek(s, pos) == "b" { scan_basic_string(s, pos + 1, acc + char_to_string(chr(8))) }
  else if peek(s, pos) == "f" { scan_basic_string(s, pos + 1, acc + char_to_string(chr(12))) }
  else if peek(s, pos) == "e" { scan_basic_string(s, pos + 1, acc + char_to_string(chr(27))) }
  else if peek(s, pos) == "\\" { scan_basic_string(s, pos + 1, acc + "\\") }
  else if peek(s, pos) == "\"" { scan_basic_string(s, pos + 1, acc + "\"") }
  else if peek(s, pos) == "x" { scan_key_unicode(s, pos + 1, 2, acc) }
  else if peek(s, pos) == "u" { scan_key_unicode(s, pos + 1, 4, acc) }
  else if peek(s, pos) == "U" { scan_key_unicode(s, pos + 1, 8, acc) }
  else { Err("invalid escape sequence: \\" + peek(s, pos)) }
}

pub fun scan_key_unicode(s: string, pos: int, n: int, acc: string) : result<(string, int), string> {
  let (cp, p) = parse_hex_digits(s, pos, n, 0)?
  scan_basic_string(s, p, acc + char_to_string(chr(cp)))
}

// ============================================================
// Literal string parsing ('...')
// ============================================================

pub fun parse_literal_string(s: string, pos: int, acc: string) : result<(Toml, int), string> {
  if pos >= str_length(s) { Err("unterminated literal string") }
  else if peek(s, pos) == "'" { Ok((TStr(acc), pos + 1)) }
  else if peek(s, pos) == "\n" { Err("newline in literal string at position " + show(pos)) }
  else if is_control_char(peek(s, pos)) { Err("control character in literal string at position " + show(pos)) }
  else { parse_literal_string(s, pos + 1, acc + peek(s, pos)) }
}

// ============================================================
// Value parsing
// ============================================================

pub fun parse_value(s: string, pos: int) : result<(Toml, int), string> {
  if peek(s, pos) == "\"" && peek(s, pos + 1) == "\"" && peek(s, pos + 2) == "\"" {
    parse_ml_basic_string(s, pos + 3, "")
  }
  else if peek(s, pos) == "\'" && peek(s, pos + 1) == "\'" && peek(s, pos + 2) == "\'" {
    parse_ml_literal_string(s, pos + 3, "")
  }
  else if peek(s, pos) == "\"" { parse_value_str(s, pos + 1, "") }
  else if peek(s, pos) == "\'" { parse_literal_string(s, pos + 1, "") }
  else if peek(s, pos) == "[" { parse_array(s, pos + 1, []) }
  else if peek(s, pos) == "{" { parse_inline_table(s, pos + 1, []) }
  else { parse_value_bare(s, pos, "") }
}

pub fun parse_value_str(s: string, pos: int, acc: string) : result<(Toml, int), string> {
  if pos >= str_length(s) { Err("unterminated string") }
  else if peek(s, pos) == "\"" { Ok((TStr(acc), pos + 1)) }
  else if peek(s, pos) == "\\" { parse_value_str_esc(s, pos + 1, acc) }
  else if peek(s, pos) == "\n" { Err("newline in basic string at position " + show(pos)) }
  else if is_control_char(peek(s, pos)) { Err("control character in string at position " + show(pos)) }
  else { parse_value_str(s, pos + 1, acc + peek(s, pos)) }
}

pub fun parse_value_str_esc(s: string, pos: int, acc: string) : result<(Toml, int), string> {
  if pos >= str_length(s) { Err("unterminated escape sequence") }
  else if peek(s, pos) == "n" { parse_value_str(s, pos + 1, acc + "\n") }
  else if peek(s, pos) == "t" { parse_value_str(s, pos + 1, acc + "\t") }
  else if peek(s, pos) == "r" { parse_value_str(s, pos + 1, acc + "\r") }
  else if peek(s, pos) == "b" { parse_value_str(s, pos + 1, acc + char_to_string(chr(8))) }
  else if peek(s, pos) == "f" { parse_value_str(s, pos + 1, acc + char_to_string(chr(12))) }
  else if peek(s, pos) == "e" { parse_value_str(s, pos + 1, acc + char_to_string(chr(27))) }
  else if peek(s, pos) == "\\" { parse_value_str(s, pos + 1, acc + "\\") }
  else if peek(s, pos) == "\"" { parse_value_str(s, pos + 1, acc + "\"") }
  else if peek(s, pos) == "x" { value_unicode_esc(s, pos + 1, 2, acc) }
  else if peek(s, pos) == "u" { value_unicode_esc(s, pos + 1, 4, acc) }
  else if peek(s, pos) == "U" { value_unicode_esc(s, pos + 1, 8, acc) }
  else { Err("invalid escape sequence: \\" + peek(s, pos)) }
}

pub fun value_unicode_esc(s: string, pos: int, n: int, acc: string) : result<(Toml, int), string> {
  let (cp, p) = parse_hex_digits(s, pos, n, 0)?
  parse_value_str(s, p, acc + char_to_string(chr(cp)))
}

// ============================================================
// Multi-line basic string parsing ("""...""")
// ============================================================

// Entry: pos is right after the opening """
// Trim a single newline immediately after opening """
pub fun parse_ml_basic_string(s: string, pos: int, acc: string) : result<(Toml, int), string> {
  if pos >= str_length(s) { Err("unterminated multi-line basic string") }
  else if peek(s, pos) == "\n" { scan_ml_basic(s, pos + 1, acc) }
  else if peek(s, pos) == "\r" && peek(s, pos + 1) == "\n" { scan_ml_basic(s, pos + 2, acc) }
  else { scan_ml_basic(s, pos, acc) }
}

pub fun scan_ml_basic(s: string, pos: int, acc: string) : result<(Toml, int), string> {
  if pos >= str_length(s) { Err("unterminated multi-line basic string") }
  else if peek(s, pos) == "\"" && peek(s, pos + 1) == "\"" && peek(s, pos + 2) == "\"" {
    Ok((TStr(acc), pos + 3))
  }
  else if peek(s, pos) == "\\" { scan_ml_basic_esc(s, pos + 1, acc) }
  else if peek(s, pos) == "\r" && peek(s, pos + 1) == "\n" { scan_ml_basic(s, pos + 2, acc + "\n") }
  else if peek(s, pos) == "\r" { scan_ml_basic(s, pos + 1, acc + "\n") }
  else if is_control_char(peek(s, pos)) { Err("control character in multi-line string at position " + show(pos)) }
  else { scan_ml_basic(s, pos + 1, acc + peek(s, pos)) }
}

pub fun scan_ml_basic_esc(s: string, pos: int, acc: string) : result<(Toml, int), string> {
  if pos >= str_length(s) { Err("unterminated escape sequence") }
  else if peek(s, pos) == "n" { scan_ml_basic(s, pos + 1, acc + "\n") }
  else if peek(s, pos) == "t" { scan_ml_basic(s, pos + 1, acc + "\t") }
  else if peek(s, pos) == "r" { scan_ml_basic(s, pos + 1, acc + "\r") }
  else if peek(s, pos) == "b" { scan_ml_basic(s, pos + 1, acc + char_to_string(chr(8))) }
  else if peek(s, pos) == "f" { scan_ml_basic(s, pos + 1, acc + char_to_string(chr(12))) }
  else if peek(s, pos) == "e" { scan_ml_basic(s, pos + 1, acc + char_to_string(chr(27))) }
  else if peek(s, pos) == "\\" { scan_ml_basic(s, pos + 1, acc + "\\") }
  else if peek(s, pos) == "\"" { scan_ml_basic(s, pos + 1, acc + "\"") }
  else if peek(s, pos) == "x" { ml_unicode_esc(s, pos + 1, 2, acc) }
  else if peek(s, pos) == "u" { ml_unicode_esc(s, pos + 1, 4, acc) }
  else if peek(s, pos) == "U" { ml_unicode_esc(s, pos + 1, 8, acc) }
  else if is_newline(peek(s, pos)) { scan_ml_basic_line_end(s, pos, acc) }
  else { Err("invalid escape sequence: \\" + peek(s, pos)) }
}

pub fun ml_unicode_esc(s: string, pos: int, n: int, acc: string) : result<(Toml, int), string> {
  let (cp, p) = parse_hex_digits(s, pos, n, 0)?
  scan_ml_basic(s, p, acc + char_to_string(chr(cp)))
}

// Line-ending backslash: skip whitespace + newlines until next non-ws char
pub fun scan_ml_basic_line_end(s: string, pos: int, acc: string) : result<(Toml, int), string> {
  if pos >= str_length(s) { scan_ml_basic(s, pos, acc) }
  else if is_ws(peek(s, pos)) || is_newline(peek(s, pos)) { scan_ml_basic_line_end(s, pos + 1, acc) }
  else { scan_ml_basic(s, pos, acc) }
}

// ============================================================
// Multi-line literal string parsing ('''...''')
// ============================================================

// Entry: pos is right after the opening '''
// Trim a single newline immediately after opening '''
pub fun parse_ml_literal_string(s: string, pos: int, acc: string) : result<(Toml, int), string> {
  if pos >= str_length(s) { Err("unterminated multi-line literal string") }
  else if peek(s, pos) == "\n" { scan_ml_literal(s, pos + 1, acc) }
  else if peek(s, pos) == "\r" && peek(s, pos + 1) == "\n" { scan_ml_literal(s, pos + 2, acc) }
  else { scan_ml_literal(s, pos, acc) }
}

pub fun scan_ml_literal(s: string, pos: int, acc: string) : result<(Toml, int), string> {
  if pos >= str_length(s) { Err("unterminated multi-line literal string") }
  else if peek(s, pos) == "\'" && peek(s, pos + 1) == "\'" && peek(s, pos + 2) == "\'" {
    Ok((TStr(acc), pos + 3))
  }
  else if peek(s, pos) == "\r" && peek(s, pos + 1) == "\n" { scan_ml_literal(s, pos + 2, acc + "\n") }
  else if peek(s, pos) == "\r" { scan_ml_literal(s, pos + 1, acc + "\n") }
  else if is_control_char(peek(s, pos)) { Err("control character in multi-line literal string at position " + show(pos)) }
  else { scan_ml_literal(s, pos + 1, acc + peek(s, pos)) }
}

pub fun is_oct_char(c: string) : bool =>
  contains("01234567", c)

pub fun is_bin_char(c: string) : bool =>
  c == "0" || c == "1"

pub fun oct_digit_val(c: string) : int => match c {
  "0" => 0, "1" => 1, "2" => 2, "3" => 3,
  "4" => 4, "5" => 5, "6" => 6, _ => 7
}

pub fun parse_hex_int(s: string, pos: int, acc: int) : result<Toml, string> {
  if pos >= str_length(s) {
    if pos == 2 { Err("expected hex digits after 0x") }
    else { Ok(TInt(acc)) }
  }
  else if is_hex_char(peek(s, pos)) {
    parse_hex_int(s, pos + 1, acc * 16 + hex_digit_val(peek(s, pos)))
  }
  else { Err("invalid hex digit: " + peek(s, pos)) }
}

pub fun parse_oct_int(s: string, pos: int, acc: int) : result<Toml, string> {
  if pos >= str_length(s) {
    if pos == 2 { Err("expected octal digits after 0o") }
    else { Ok(TInt(acc)) }
  }
  else if is_oct_char(peek(s, pos)) {
    parse_oct_int(s, pos + 1, acc * 8 + oct_digit_val(peek(s, pos)))
  }
  else { Err("invalid octal digit: " + peek(s, pos)) }
}

pub fun parse_bin_int(s: string, pos: int, acc: int) : result<Toml, string> {
  if pos >= str_length(s) {
    if pos == 2 { Err("expected binary digits after 0b") }
    else { Ok(TInt(acc)) }
  }
  else if is_bin_char(peek(s, pos)) {
    let v = if peek(s, pos) == "1" { 1 } else { 0 }
    parse_bin_int(s, pos + 1, acc * 2 + v)
  }
  else { Err("invalid binary digit: " + peek(s, pos)) }
}

pub fun has_leading_zero(s: string) : bool {
  let first = peek(s, 0)
  let second = peek(s, 1)
  if str_length(s) < 2 { false }
  else if first == "0" && second != "." && second != "" && second != "e" && second != "E" { true }
  else if first != "+" && first != "-" { false }
  else if str_length(s) < 3 { false }
  else if peek(s, 1) == "0" && peek(s, 2) != "." && peek(s, 2) != "" && peek(s, 2) != "e" && peek(s, 2) != "E" { true }
  else { false }
}

pub fun parse_value_bare(s: string, pos: int, acc: string) : result<(Toml, int), string> {
  if pos >= str_length(s) { finish_bare(acc, pos) }
  else if peek(s, pos) == " " && str_length(acc) == 10 && is_date_prefix(acc) && is_digit_str(peek(s, pos + 1)) {
    parse_value_bare(s, pos + 1, acc + "T")
  }
  else if is_ws(peek(s, pos)) || is_newline(peek(s, pos)) || peek(s, pos) == "#" || peek(s, pos) == "," || peek(s, pos) == "]" || peek(s, pos) == "}" { finish_bare(acc, pos) }
  else { parse_value_bare(s, pos + 1, acc + peek(s, pos)) }
}

pub fun is_date_prefix(s: string) : bool =>
  str_length(s) == 10 && peek(s, 4) == "-" && peek(s, 7) == "-"

pub fun finish_bare(token: string, pos: int) : result<(Toml, int), string> {
  let cleaned = replace(token, "_", "")
  if token == "" { Err("expected a value at position " + show(pos)) }
  else if token == "true" { Ok((TBool(true), pos)) }
  else if token == "false" { Ok((TBool(false), pos)) }
  else if token == "inf" || token == "+inf" { Ok((TFloat(1.0 / 0.0), pos)) }
  else if token == "-inf" { Ok((TFloat(0.0 - 1.0 / 0.0), pos)) }
  else if token == "nan" || token == "+nan" || token == "-nan" { Ok((TFloat(0.0 / 0.0), pos)) }
  else if datetime_kind(token) != "invalid" { Ok((TDatetime(token), pos)) }
  else if starts_with(cleaned, "0x") || starts_with(cleaned, "0X") {
    let v = parse_hex_int(cleaned, 2, 0)?
    Ok((v, pos))
  }
  else if starts_with(cleaned, "0o") || starts_with(cleaned, "0O") {
    let v = parse_oct_int(cleaned, 2, 0)?
    Ok((v, pos))
  }
  else if starts_with(cleaned, "0b") || starts_with(cleaned, "0B") {
    let v = parse_bin_int(cleaned, 2, 0)?
    Ok((v, pos))
  }
  else if has_leading_zero(cleaned) {
    Err("leading zeros not allowed: " + token)
  }
  else if contains(cleaned, "e") || contains(cleaned, "E") || contains(cleaned, ".") {
    match parse_float(cleaned) {
      Some(f) => Ok((TFloat(f), pos)),
      None => Err("invalid value: " + token)
    }
  }
  else {
    match parse_int(cleaned) {
      Some(n) => Ok((TInt(n), pos)),
      None => {
        match parse_float(cleaned) {
          Some(f) => Ok((TFloat(f), pos)),
          None => Err("invalid value: " + token)
        }
      }
    }
  }
}

// ============================================================
// Array parsing
// ============================================================

pub fun parse_array(s: string, pos: int, items: list<Toml>) : result<(Toml, int), string> {
  let p = skip_ws_nl_comments(s, pos)
  if p >= str_length(s) { Err("unterminated array") }
  else if peek(s, p) == "]" { Ok((TArray(items), p + 1)) }
  else {
    let (val, p2) = parse_value(s, p)?
    let p3 = skip_ws_nl_comments(s, p2)
    if p3 >= str_length(s) { Err("unterminated array") }
    else if peek(s, p3) == "]" { Ok((TArray(items + [val]), p3 + 1)) }
    else if peek(s, p3) == "," { parse_array(s, p3 + 1, items + [val]) }
    else { Err("expected ',' or ']' in array at position " + show(p3)) }
  }
}

// ============================================================
// Inline table parsing
// ============================================================

pub fun parse_inline_table(s: string, pos: int, entries: list<(string, Toml)>) : result<(Toml, int), string> {
  let p = skip_ws_nl_comments(s, pos)
  if p >= str_length(s) { Err("unterminated inline table") }
  else if peek(s, p) == "}" { Ok((TTable(entries), p + 1)) }
  else {
    let (key, val, p2) = parse_inline_kv(s, p)?
    if any(entries, (e) => e.0 == key) { Err("duplicate key: " + key) }
    else {
      let new_entries = entries + [(key, val)]
      let p3 = skip_ws_nl_comments(s, p2)
      if p3 >= str_length(s) { Err("unterminated inline table") }
      else if peek(s, p3) == "}" { Ok((TTable(new_entries), p3 + 1)) }
      else if peek(s, p3) == "," { parse_inline_table(s, p3 + 1, new_entries) }
      else { Err("expected ',' or '}' in inline table at position " + show(p3)) }
    }
  }
}

pub fun parse_inline_kv(s: string, pos: int) : result<(string, Toml, int), string> {
  let (keys, p1) = parse_dotted_key(s, pos)?
  let p2 = skip_ws(s, p1)
  if peek(s, p2) != "=" { Err("expected '=' in inline table at position " + show(p2)) }
  else {
    let p3 = skip_ws(s, p2 + 1)
    let (val, p4) = parse_value(s, p3)?
    match keys {
      [single] => Ok((single, val, p4)),
      _ => {
        let (k, nested) = build_nested(keys, val)?
        Ok((k, nested, p4))
      }
    }
  }
}

pub fun build_nested(keys: list<string>, val: Toml) : result<(string, Toml), string> {
  match keys {
    [] => Err("empty key path"),
    [single] => Ok((single, val)),
    [first, ..rest] => {
      let (k, inner) = build_nested(rest, val)?
      Ok((first, TTable([(k, inner)])))
    }
  }
}

// ============================================================
// Table helpers (nested insertion)
// ============================================================

pub fun table_find(entries: list<(string, Toml)>, key: string) : maybe<Toml> {
  entries
    |> find((e) => e.0 == key)
    |> map_maybe((e) => e.1)
}

pub fun table_replace(entries: list<(string, Toml)>, key: string, value: Toml) : list<(string, Toml)> {
  map(entries, (e) => if e.0 == key { (key, value) } else { e })
}

pub fun table_set(entries: list<(string, Toml)>, path: list<string>, value: Toml) : result<list<(string, Toml)>, string> {
  match path {
    [] => Err("empty key path"),
    [key] => table_set_leaf(entries, key, value),
    [key, ..rest] => table_set_nested(entries, key, rest, value)
  }
}

pub fun table_set_leaf(entries: list<(string, Toml)>, key: string, value: Toml) : result<list<(string, Toml)>, string> {
  if any(entries, (e) => e.0 == key) { Err("duplicate key: " + key) }
  else { Ok(entries + [(key, value)]) }
}

pub fun table_set_nested(entries: list<(string, Toml)>, key: string, rest: list<string>, value: Toml) : result<list<(string, Toml)>, string> {
  match table_find(entries, key) {
    Some(TTable(sub)) => {
      let new_sub = table_set(sub, rest, value)?
      Ok(table_replace(entries, key, TTable(new_sub)))
    },
    Some(TArray(items)) => {
      let new_items = last_table_set(items, rest, value)?
      Ok(table_replace(entries, key, TArray(new_items)))
    },
    Some(_) => Err("key " + key + " is not a table"),
    None => {
      let new_sub = table_set([], rest, value)?
      Ok(entries + [(key, TTable(new_sub))])
    }
  }
}

// Set a value in the last table of an array of tables
pub fun last_table_set(items: list<Toml>, path: list<string>, value: Toml) : result<list<Toml>, string> {
  match items {
    [] => Err("empty array of tables"),
    [TTable(sub)] => {
      let new_sub = table_set(sub, path, value)?
      Ok([TTable(new_sub)])
    },
    [other] => Err("last element is not a table"),
    [head, ..rest] => {
      let new_rest = last_table_set(rest, path, value)?
      Ok([head] + new_rest)
    }
  }
}

// Ensure a path of tables exists (for [table] headers)
pub fun ensure_table(entries: list<(string, Toml)>, path: list<string>) : result<list<(string, Toml)>, string> {
  match path {
    [] => Ok(entries),
    [key, ..rest] => {
      match table_find(entries, key) {
        Some(TTable(sub)) => {
          let new_sub = ensure_table(sub, rest)?
          Ok(table_replace(entries, key, TTable(new_sub)))
        },
        Some(TArray(items)) => {
          let new_items = last_table_ensure(items, rest)?
          Ok(table_replace(entries, key, TArray(new_items)))
        },
        Some(_) => Err("key " + key + " is not a table"),
        None => {
          let new_sub = ensure_table([], rest)?
          Ok(entries + [(key, TTable(new_sub))])
        }
      }
    }
  }
}

// Ensure a table path exists in the last element of an array of tables
pub fun last_table_ensure(items: list<Toml>, path: list<string>) : result<list<Toml>, string> {
  match items {
    [] => Err("empty array of tables"),
    [TTable(sub)] => {
      let new_sub = ensure_table(sub, path)?
      Ok([TTable(new_sub)])
    },
    [other] => Err("last element is not a table"),
    [head, ..rest] => {
      let new_rest = last_table_ensure(rest, path)?
      Ok([head] + new_rest)
    }
  }
}

// Append a new empty table to an array of tables at the given path
pub fun array_table_append(entries: list<(string, Toml)>, path: list<string>, aot: list<string>, full_pk: string) : result<list<(string, Toml)>, string> {
  match path {
    [] => Err("empty array-of-tables path"),
    [key] => {
      match table_find(entries, key) {
        Some(TArray(items)) => {
          if any(aot, (a) => a == full_pk) { Ok(table_replace(entries, key, TArray(items + [TTable([])]))) }
          else { Err("key " + key + " is already defined as a static array") }
        },
        Some(TTable(_)) => Err("key " + key + " is a table, not an array of tables"),
        Some(_) => Err("key " + key + " is not an array of tables"),
        None => Ok(entries + [(key, TArray([TTable([])]))])
      }
    },
    [key, ..rest] => {
      match table_find(entries, key) {
        Some(TTable(sub)) => {
          let new_sub = array_table_append(sub, rest, aot, full_pk)?
          Ok(table_replace(entries, key, TTable(new_sub)))
        },
        Some(TArray(items)) => {
          let new_items = last_table_array_append(items, rest, aot, full_pk)?
          Ok(table_replace(entries, key, TArray(new_items)))
        },
        Some(_) => Err("key " + key + " is not a table"),
        None => {
          let new_sub = array_table_append([], rest, aot, full_pk)?
          Ok(entries + [(key, TTable(new_sub))])
        }
      }
    }
  }
}

// Append into the last table of an array of tables
pub fun last_table_array_append(items: list<Toml>, path: list<string>, aot: list<string>, full_pk: string) : result<list<Toml>, string> {
  match items {
    [] => Err("empty array of tables"),
    [TTable(sub)] => {
      let new_sub = array_table_append(sub, path, aot, full_pk)?
      Ok([TTable(new_sub)])
    },
    [other] => Err("last element is not a table"),
    [head, ..rest] => {
      let new_rest = last_table_array_append(rest, path, aot, full_pk)?
      Ok([head] + new_rest)
    }
  }
}

// ============================================================
// Table header parsing
// ============================================================

pub fun parse_table_header(s: string, pos: int) : result<(list<string>, int), string> {
  // pos is at '['
  let p = skip_ws(s, pos + 1)
  let (keys, p2) = parse_header_key(s, p)?
  let p3 = skip_ws(s, p2)
  if peek(s, p3) != "]" { Err("expected ']' at position " + show(p3)) }
  else { Ok((keys, p3 + 1)) }
}

// Parse [[key.path]] — pos is at first '['
pub fun parse_array_table_header(s: string, pos: int) : result<(list<string>, int), string> {
  // pos is at first '[', pos+1 is at second '['
  let p = skip_ws(s, pos + 2)
  let (keys, p2) = parse_header_key(s, p)?
  let p3 = skip_ws(s, p2)
  if peek(s, p3) != "]" { Err("expected ']]' at position " + show(p3)) }
  else if peek(s, p3 + 1) != "]" { Err("expected ']]' at position " + show(p3)) }
  else { Ok((keys, p3 + 2)) }
}

pub fun parse_header_key(s: string, pos: int) : result<(list<string>, int), string> {
  let (k, p) = parse_key(s, pos)?
  parse_header_key_rest(s, skip_ws(s, p), [k])
}

pub fun parse_header_key_rest(s: string, pos: int, keys: list<string>) : result<(list<string>, int), string> {
  if peek(s, pos) != "." { Ok((keys, pos)) }
  else {
    let p = skip_ws(s, pos + 1)
    let (k, p2) = parse_key(s, p)?
    parse_header_key_rest(s, skip_ws(s, p2), keys + [k])
  }
}

// ============================================================
// Document parser
// ============================================================

pub fun toml_parse(input: string) : result<Toml, string> {
  parse_doc(input, 0, [], [], [], [], [])
}

pub fun path_key(path: list<string>) : string =>
  join(path, ".")

// ============================================================
// Line number helpers
// ============================================================

pub fun count_newlines(input: string, i: int, end_pos: int, line: int) : int {
  if i >= end_pos { line }
  else if peek(input, i) == "\r" && peek(input, i + 1) == "\n" {
    count_newlines(input, i + 2, end_pos, line + 1)
  }
  else if peek(input, i) == "\n" {
    count_newlines(input, i + 1, end_pos, line + 1)
  }
  else if peek(input, i) == "\r" {
    count_newlines(input, i + 1, end_pos, line + 1)
  }
  else { count_newlines(input, i + 1, end_pos, line) }
}

pub fun extend_path_key(acc: string, key: string) : string =>
  if acc == "" { key } else { acc + "." + key }

pub fun has_inline_prefix(remaining: list<string>, acc: string, inlines: list<string>) : bool {
  match remaining {
    [] => false,
    [key, ..rest] => {
      let pk = extend_path_key(acc, key)
      if any(inlines, (i) => i == pk) { true }
      else { has_inline_prefix(rest, pk, inlines) }
    }
  }
}

pub fun maybe_add_inline(value: Toml, pk: string, inlines: list<string>) : list<string> {
  match value {
    TTable(_) => [pk] + inlines,
    _ => inlines
  }
}

// path = current table path (e.g. ["server"] when inside [server])
// defined = list of explicitly-defined table path keys
// aot = list of array-of-tables path keys
pub fun parse_doc(input: string, pos: int, path: list<string>, root: list<(string, Toml)>, defined: list<string>, aot: list<string>, inlines: list<string>) : result<Toml, string> {
  let p = skip_ws_nl_comments(input, pos)
  if p >= str_length(input) { Ok(TTable(root)) }
  else if peek(input, p) == "[" && peek(input, p + 1) == "[" {
    parse_doc_array_table(input, p, root, defined, aot, inlines)
  }
  else if peek(input, p) == "[" { parse_doc_table(input, p, root, defined, aot, inlines) }
  else { parse_doc_keyval(input, p, path, root, defined, aot, inlines) }
}

pub fun parse_doc_table(input: string, pos: int, root: list<(string, Toml)>, defined: list<string>, aot: list<string>, inlines: list<string>) : result<Toml, string> {
  match parse_table_header(input, pos) {
    Err(e) => Err("line " + show(count_newlines(input, 0, pos, 1)) + ": " + e),
    Ok((path, p)) => {
      let pk = path_key(path)
      if has_inline_prefix(path, "", inlines) {
        Err("line " + show(count_newlines(input, 0, pos, 1)) + ": " + "cannot add to inline table: " + pk)
      }
      else if any(defined, (d) => d == pk) {
        Err("line " + show(count_newlines(input, 0, pos, 1)) + ": " + "duplicate table: [" + pk + "]")
      }
      else {
        match expect_eol(input, p) {
          Err(e) => Err("line " + show(count_newlines(input, 0, pos, 1)) + ": " + e),
          Ok(p2) => {
            match ensure_table(root, path) {
              Err(e) => Err("line " + show(count_newlines(input, 0, pos, 1)) + ": " + e),
              Ok(new_root) => parse_doc(input, p2, path, new_root, [pk] + defined, aot, inlines)
            }
          }
        }
      }
    }
  }
}

pub fun clear_sub_defined(defined: list<string>, pfx: string) : list<string> =>
  filter(defined, (d) => !starts_with(d, pfx))

pub fun parse_doc_array_table(input: string, pos: int, root: list<(string, Toml)>, defined: list<string>, aot: list<string>, inlines: list<string>) : result<Toml, string> {
  match parse_array_table_header(input, pos) {
    Err(e) => Err("line " + show(count_newlines(input, 0, pos, 1)) + ": " + e),
    Ok((path, p)) => {
      let pk = path_key(path)
      if has_inline_prefix(path, "", inlines) {
        Err("line " + show(count_newlines(input, 0, pos, 1)) + ": " + "cannot add to inline table: " + pk)
      }
      else if any(defined, (d) => d == pk) {
        Err("line " + show(count_newlines(input, 0, pos, 1)) + ": " + "cannot define [[" + pk + "]] — already defined as [" + pk + "]")
      }
      else {
        match expect_eol(input, p) {
          Err(e) => Err("line " + show(count_newlines(input, 0, pos, 1)) + ": " + e),
          Ok(p2) => {
            match array_table_append(root, path, aot, pk) {
              Err(e) => Err("line " + show(count_newlines(input, 0, pos, 1)) + ": " + e),
              Ok(new_root) => parse_doc(input, p2, path, new_root, clear_sub_defined(defined, pk + "."), [pk] + aot, clear_sub_defined(inlines, pk + "."))
            }
          }
        }
      }
    }
  }
}

pub fun parse_dotted_key(s: string, pos: int) : result<(list<string>, int), string> {
  let (k, p) = parse_key(s, pos)?
  parse_dotted_key_rest(s, skip_ws(s, p), [k])
}

pub fun parse_dotted_key_rest(s: string, pos: int, keys: list<string>) : result<(list<string>, int), string> {
  if peek(s, pos) != "." { Ok((keys, pos)) }
  else {
    let p = skip_ws(s, pos + 1)
    let (k, p2) = parse_key(s, p)?
    parse_dotted_key_rest(s, skip_ws(s, p2), keys + [k])
  }
}

pub fun parse_doc_keyval(input: string, pos: int, path: list<string>, root: list<(string, Toml)>, defined: list<string>, aot: list<string>, inlines: list<string>) : result<Toml, string> {
  match parse_dotted_key(input, pos) {
    Err(e) => Err("line " + show(count_newlines(input, 0, pos, 1)) + ": " + e),
    Ok((keys, p1)) => {
      let p2 = skip_ws(input, p1)
      if peek(input, p2) != "=" { Err("line " + show(count_newlines(input, 0, pos, 1)) + ": " + "expected '=' after key") }
      else {
        let p3 = skip_ws(input, p2 + 1)
        match parse_value(input, p3) {
          Err(e) => Err("line " + show(count_newlines(input, 0, pos, 1)) + ": " + e),
          Ok((value, p4)) => {
            let full_path = path + keys
            let fpk = path_key(full_path)
            let new_inlines = maybe_add_inline(value, fpk, inlines)
            if has_inline_prefix(full_path, "", inlines) {
              Err("line " + show(count_newlines(input, 0, pos, 1)) + ": " + "cannot add to inline table: " + fpk)
            }
            else {
              match table_set(root, full_path, value) {
                Err(e) => Err("line " + show(count_newlines(input, 0, pos, 1)) + ": " + e),
                Ok(new_root) => {
                  match expect_eol(input, p4) {
                    Err(e) => Err("line " + show(count_newlines(input, 0, pos, 1)) + ": " + e),
                    Ok(p5) => parse_doc(input, p5, path, new_root, defined, aot, new_inlines)
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
