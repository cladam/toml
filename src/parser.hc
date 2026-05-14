// parser.hc — TOML parser (bare keys + basic string values)
import "./toml_types"

// ============================================================
// Character helpers
// ============================================================

pub fun peek(s: string, pos: int) : string =>
  if pos >= str_length(s) { "" }
  else { s[pos:pos + 1] }

pub fun is_ws(c: string) : bool =>
  c == " " || c == "\t"

pub fun is_newline(c: string) : bool =>
  c == "\n" || c == "\r"

pub fun is_bare_key_char(c: string) : bool =>
  contains("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_", c)

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
  else if peek(s, p) == "#" { Ok(skip_newline(s, skip_to_eol(s, p))) }
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
  else { Ok((s[pos:end_pos], end_pos)) }
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
  else if peek(s, pos) == "\\" { scan_basic_string(s, pos + 1, acc + "\\") }
  else if peek(s, pos) == "\"" { scan_basic_string(s, pos + 1, acc + "\"") }
  else { Err("invalid escape sequence: \\" + peek(s, pos)) }
}

// ============================================================
// Value parsing (only basic strings + bare values for now)
// ============================================================

pub fun parse_value(s: string, pos: int) : result<(Toml, int), string> {
  if peek(s, pos) == "\"" { parse_value_str(s, pos + 1, "") }
  else { parse_value_bare(s, pos, "") }
}

pub fun parse_value_str(s: string, pos: int, acc: string) : result<(Toml, int), string> {
  if pos >= str_length(s) { Err("unterminated string") }
  else if peek(s, pos) == "\"" { Ok((TStr(acc), pos + 1)) }
  else if peek(s, pos) == "\\" { parse_value_str_esc(s, pos + 1, acc) }
  else if peek(s, pos) == "\n" { Err("newline in basic string at position " + show(pos)) }
  else { parse_value_str(s, pos + 1, acc + peek(s, pos)) }
}

pub fun parse_value_str_esc(s: string, pos: int, acc: string) : result<(Toml, int), string> {
  if pos >= str_length(s) { Err("unterminated escape sequence") }
  else if peek(s, pos) == "n" { parse_value_str(s, pos + 1, acc + "\n") }
  else if peek(s, pos) == "t" { parse_value_str(s, pos + 1, acc + "\t") }
  else if peek(s, pos) == "r" { parse_value_str(s, pos + 1, acc + "\r") }
  else if peek(s, pos) == "\\" { parse_value_str(s, pos + 1, acc + "\\") }
  else if peek(s, pos) == "\"" { parse_value_str(s, pos + 1, acc + "\"") }
  else { Err("invalid escape sequence: \\" + peek(s, pos)) }
}

pub fun parse_value_bare(s: string, pos: int, acc: string) : result<(Toml, int), string> {
  if pos >= str_length(s) { finish_bare(acc, pos) }
  else if is_ws(peek(s, pos)) || is_newline(peek(s, pos)) || peek(s, pos) == "#" || peek(s, pos) == "," || peek(s, pos) == "]" || peek(s, pos) == "}" { finish_bare(acc, pos) }
  else { parse_value_bare(s, pos + 1, acc + peek(s, pos)) }
}

pub fun finish_bare(token: string, pos: int) : result<(Toml, int), string> {
  if token == "" { Err("expected a value at position " + show(pos)) }
  else { Ok((classify_bare(token), pos)) }
}


pub fun classify_bare(token: string) : Toml {
  if token == "true" { TBool(true) }
  else if token == "false" { TBool(false) }
  else { classify_number(token) }
}

pub fun classify_number(token: string) : Toml {
  let cleaned = replace(token, "_", "")
  match parse_int(cleaned) {
    Some(n) => TInt(n),
    None => classify_as_float(cleaned, token)
  }
}

pub fun classify_as_float(cleaned: string, token: string) : Toml {
  match parse_float(cleaned) {
    Some(f) => TFloat(f),
    None => TStr(token)
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
      match table_set(sub, rest, value) {
        Ok(new_sub) => Ok(table_replace(entries, key, TTable(new_sub))),
        Err(e) => Err(e)
      }
    },
    Some(_) => Err("key " + key + " is not a table"),
    None => {
      match table_set([], rest, value) {
        Ok(new_sub) => Ok(entries + [(key, TTable(new_sub))]),
        Err(e) => Err(e)
      }
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
          match ensure_table(sub, rest) {
            Ok(new_sub) => Ok(table_replace(entries, key, TTable(new_sub))),
            Err(e) => Err(e)
          }
        },
        Some(_) => Err("key " + key + " is not a table"),
        None => {
          match ensure_table([], rest) {
            Ok(new_sub) => Ok(entries + [(key, TTable(new_sub))]),
            Err(e) => Err(e)
          }
        }
      }
    }
  }
}

// ============================================================
// Table header parsing
// ============================================================

pub fun parse_table_header(s: string, pos: int) : result<(list<string>, int), string> {
  // pos is at '['
  let p = skip_ws(s, pos + 1)
  match parse_header_key(s, p) {
    Err(e) => Err(e),
    Ok((keys, p2)) => {
      let p3 = skip_ws(s, p2)
      if peek(s, p3) != "]" { Err("expected ']' at position " + show(p3)) }
      else { Ok((keys, p3 + 1)) }
    }
  }
}

pub fun parse_header_key(s: string, pos: int) : result<(list<string>, int), string> {
  match parse_bare_key(s, pos) {
    Err(e) => Err(e),
    Ok((k, p)) => parse_header_key_rest(s, skip_ws(s, p), [k])
  }
}

pub fun parse_header_key_rest(s: string, pos: int, keys: list<string>) : result<(list<string>, int), string> {
  if peek(s, pos) != "." { Ok((keys, pos)) }
  else {
    let p = skip_ws(s, pos + 1)
    match parse_bare_key(s, p) {
      Err(e) => Err(e),
      Ok((k, p2)) => parse_header_key_rest(s, skip_ws(s, p2), keys + [k])
    }
  }
}

// ============================================================
// Document parser
// ============================================================

pub fun toml_parse(input: string) : result<Toml, string> {
  parse_doc(input, 0, [], [])
}

// path = current table path (e.g. ["server"] when inside [server])
pub fun parse_doc(input: string, pos: int, path: list<string>, root: list<(string, Toml)>) : result<Toml, string> {
  let p = skip_ws_nl_comments(input, pos)
  if p >= str_length(input) { Ok(TTable(root)) }
  else if peek(input, p) == "[" { parse_doc_table(input, p, root) }
  else { parse_doc_keyval(input, p, path, root) }
}

pub fun parse_doc_table(input: string, pos: int, root: list<(string, Toml)>) : result<Toml, string> {
  match parse_table_header(input, pos) {
    Err(e) => Err(e),
    Ok((path, p)) => {
      match expect_eol(input, p) {
        Err(e) => Err(e),
        Ok(p2) => {
          match ensure_table(root, path) {
            Err(e) => Err(e),
            Ok(new_root) => parse_doc(input, p2, path, new_root)
          }
        }
      }
    }
  }
}

pub fun parse_doc_keyval(input: string, pos: int, path: list<string>, root: list<(string, Toml)>) : result<Toml, string> {
  match parse_bare_key(input, pos) {
    Err(e) => Err(e),
    Ok((key, p1)) => {
      let p2 = skip_ws(input, p1)
      if peek(input, p2) != "=" { Err("expected '=' at position " + show(p2)) }
      else {
        let p3 = skip_ws(input, p2 + 1)
        match parse_value(input, p3) {
          Err(e) => Err(e),
          Ok((value, p4)) => {
            let full_path = path + [key]
            match table_set(root, full_path, value) {
              Err(e) => Err(e),
              Ok(new_root) => {
                match expect_eol(input, p4) {
                  Err(e) => Err(e),
                  Ok(p5) => parse_doc(input, p5, path, new_root)
                }
              }
            }
          }
        }
      }
    }
  }
}
