// toml.hc — TOML v1.1.0 parser library

// ============================================================
// Types
// ============================================================

pub type Toml {
  TStr(value: string),
  TInt(value: int),
  TFloat(value: float),
  TBool(value: bool),
  TDatetime(value: string),
  TArray(items: list<Toml>),
  TTable(entries: list<(string, Toml)>)
}

// ============================================================
// Character helpers
// ============================================================

pub fun peek(s: string, pos: int) : string =>
  if pos >= str_length(s) { "" }
  else { s[pos:pos + 1] }

pub fun is_ws_char(c: string) : bool =>
  c == " " || c == "\t"

pub fun is_newline_char(c: string) : bool =>
  c == "\n" || c == "\r"

pub fun is_bare_key_char(c: string) : bool =>
  contains("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_", c)

pub fun is_digit(c: string) : bool =>
  contains("0123456789", c)

// ============================================================
// Scanning helpers
// ============================================================

pub fun skip_ws(s: string, pos: int) : int {
  if pos >= str_length(s) { pos }
  else if is_ws_char(peek(s, pos)) { skip_ws(s, pos + 1) }
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
  else if is_ws_char(peek(s, pos)) || is_newline_char(peek(s, pos)) {
    skip_ws_nl_comments(s, pos + 1)
  }
  else if peek(s, pos) == "#" {
    skip_ws_nl_comments(s, skip_to_eol(s, pos))
  }
  else { pos }
}

pub fun skip_comment_and_newline(s: string, pos: int) : result<int, string> {
  let p = skip_ws(s, pos)
  if p >= str_length(s) { Ok(p) }
  else if peek(s, p) == "#" { Ok(skip_newline(s, skip_to_eol(s, p))) }
  else if is_newline_char(peek(s, p)) { Ok(skip_newline(s, p)) }
  else { Err("expected newline or comment at position " + show(p)) }
}

// ============================================================
// Table helpers (for building nested tables)
// ============================================================

pub fun table_find(entries: list<(string, Toml)>, key: string) : maybe<Toml> {
  entries
    |> find((e) => e.0 == key)
    |> map_maybe((e) => e.1)
}

pub fun table_has(entries: list<(string, Toml)>, key: string) : bool =>
  any(entries, (e) => e.0 == key)

pub fun table_replace(entries: list<(string, Toml)>, key: string, value: Toml) : list<(string, Toml)> {
  map(entries, (e) => if e.0 == key { (key, value) } else { e })
}

pub fun table_insert(entries: list<(string, Toml)>, path: list<string>, value: Toml) : result<list<(string, Toml)>, string> {
  match path {
    [] => Err("empty key path"),
    [key] => table_insert_leaf(entries, key, value),
    [key, ..rest] => table_insert_nested(entries, key, rest, value)
  }
}

pub fun table_insert_leaf(entries: list<(string, Toml)>, key: string, value: Toml) : result<list<(string, Toml)>, string> {
  if table_has(entries, key) { Err("duplicate key: " + key) }
  else { Ok(entries + [(key, value)]) }
}

pub fun table_insert_nested(entries: list<(string, Toml)>, key: string, rest: list<string>, value: Toml) : result<list<(string, Toml)>, string> {
  match table_find(entries, key) {
    Some(TTable(sub)) => table_insert_into(entries, key, sub, rest, value),
    Some(_) => Err("key " + key + " is not a table"),
    None => table_insert_new(entries, key, rest, value)
  }
}

pub fun table_insert_into(entries: list<(string, Toml)>, key: string, sub: list<(string, Toml)>, rest: list<string>, value: Toml) : result<list<(string, Toml)>, string> {
  match table_insert(sub, rest, value) {
    Ok(new_sub) => Ok(table_replace(entries, key, TTable(new_sub))),
    Err(e) => Err(e)
  }
}

pub fun table_insert_new(entries: list<(string, Toml)>, key: string, rest: list<string>, value: Toml) : result<list<(string, Toml)>, string> {
  match table_insert([], rest, value) {
    Ok(new_sub) => Ok(entries + [(key, TTable(new_sub))]),
    Err(e) => Err(e)
  }
}

pub fun ensure_table(entries: list<(string, Toml)>, path: list<string>) : result<list<(string, Toml)>, string> {
  match path {
    [] => Ok(entries),
    [key, ..rest] => ensure_table_step(entries, key, rest)
  }
}

pub fun ensure_table_step(entries: list<(string, Toml)>, key: string, rest: list<string>) : result<list<(string, Toml)>, string> {
  match table_find(entries, key) {
    Some(TTable(sub)) => ensure_table_deep(entries, key, sub, rest),
    Some(_) => Err("key " + key + " is not a table"),
    None => ensure_table_create(entries, key, rest)
  }
}

pub fun ensure_table_deep(entries: list<(string, Toml)>, key: string, sub: list<(string, Toml)>, rest: list<string>) : result<list<(string, Toml)>, string> {
  match ensure_table(sub, rest) {
    Ok(new_sub) => Ok(table_replace(entries, key, TTable(new_sub))),
    Err(e) => Err(e)
  }
}

pub fun ensure_table_create(entries: list<(string, Toml)>, key: string, rest: list<string>) : result<list<(string, Toml)>, string> {
  match ensure_table([], rest) {
    Ok(new_sub) => Ok(entries + [(key, TTable(new_sub))]),
    Err(e) => Err(e)
  }
}

// ============================================================
// Key parsing
// ============================================================

pub fun parse_bare_key(s: string, pos: int) : result<(string, int), string> {
  let end_pos = scan_bare_key(s, pos)
  if end_pos == pos { Err("expected a key at position " + show(pos)) }
  else { Ok((s[pos:end_pos], end_pos)) }
}

pub fun scan_bare_key(s: string, pos: int) : int {
  if pos >= str_length(s) { pos }
  else if is_bare_key_char(peek(s, pos)) { scan_bare_key(s, pos + 1) }
  else { pos }
}

pub fun parse_key(s: string, pos: int) : result<(list<string>, int), string> {
  if peek(s, pos) == "\"" {
    match parse_basic_string(s, pos) {
      Err(e) => Err(e),
      Ok((k, p)) => parse_key_rest(s, skip_ws(s, p), [k])
    }
  }
  else if peek(s, pos) == "'" {
    match parse_literal_string(s, pos) {
      Err(e) => Err(e),
      Ok((k, p)) => parse_key_rest(s, skip_ws(s, p), [k])
    }
  }
  else {
    match parse_bare_key(s, pos) {
      Err(e) => Err(e),
      Ok((k, p)) => parse_key_rest(s, skip_ws(s, p), [k])
    }
  }
}

pub fun parse_key_rest(s: string, pos: int, keys: list<string>) : result<(list<string>, int), string> {
  if peek(s, pos) != "." { Ok((keys, pos)) }
  else {
    let dot_pos = skip_ws(s, pos + 1)
    match parse_key(s, dot_pos) {
      Err(e) => Err(e),
      Ok((new_keys, p)) => Ok((keys + new_keys, p))
    }
  }
}

// ============================================================
// String parsing
// ============================================================

pub fun parse_basic_string(s: string, pos: int) : result<(string, int), string> {
  if peek(s, pos) != "\"" { Err("expected '\"' at position " + show(pos)) }
  else { scan_basic_string(s, pos + 1, "") }
}

pub fun scan_basic_string(s: string, pos: int, acc: string) : result<(string, int), string> {
  if pos >= str_length(s) { Err("unterminated string") }
  else if peek(s, pos) == "\"" { Ok((acc, pos + 1)) }
  else if peek(s, pos) == "\\" { scan_basic_escape(s, pos + 1, acc) }
  else if peek(s, pos) == "\n" { Err("newline in basic string at position " + show(pos)) }
  else { scan_basic_string(s, pos + 1, acc + peek(s, pos)) }
}

pub fun scan_basic_escape(s: string, pos: int, acc: string) : result<(string, int), string> {
  if pos >= str_length(s) { Err("unterminated escape sequence") }
  else if peek(s, pos) == "n" { scan_basic_string(s, pos + 1, acc + "\n") }
  else if peek(s, pos) == "t" { scan_basic_string(s, pos + 1, acc + "\t") }
  else if peek(s, pos) == "r" { scan_basic_string(s, pos + 1, acc + "\r") }
  else if peek(s, pos) == "\\" { scan_basic_string(s, pos + 1, acc + "\\") }
  else if peek(s, pos) == "\"" { scan_basic_string(s, pos + 1, acc + "\"") }
  else { Err("invalid escape sequence: \\" + peek(s, pos)) }
}

pub fun parse_literal_string(s: string, pos: int) : result<(string, int), string> {
  if peek(s, pos) != "'" { Err("expected \"'\" at position " + show(pos)) }
  else { scan_literal_string(s, pos + 1, "") }
}

pub fun scan_literal_string(s: string, pos: int, acc: string) : result<(string, int), string> {
  if pos >= str_length(s) { Err("unterminated literal string") }
  else if peek(s, pos) == "'" { Ok((acc, pos + 1)) }
  else if peek(s, pos) == "\n" { Err("newline in literal string at position " + show(pos)) }
  else { scan_literal_string(s, pos + 1, acc + peek(s, pos)) }
}

// ============================================================
// Value parsing
// ============================================================

pub fun parse_value(s: string, pos: int) : result<(Toml, int), string> {
  if peek(s, pos) == "\"" {
    match parse_basic_string(s, pos) {
      Ok((v, p)) => Ok((TStr(v), p)),
      Err(e) => Err(e)
    }
  }
  else if peek(s, pos) == "'" {
    match parse_literal_string(s, pos) {
      Ok((v, p)) => Ok((TStr(v), p)),
      Err(e) => Err(e)
    }
  }
  else if peek(s, pos) == "[" { parse_array(s, pos) }
  else if peek(s, pos) == "{" { parse_inline_table(s, pos) }
  else { parse_bare_value(s, pos) }
}

pub fun scan_bare_token(s: string, pos: int, acc: string) : (string, int) {
  if pos >= str_length(s) { (acc, pos) }
  else if is_ws_char(peek(s, pos)) || is_newline_char(peek(s, pos)) || peek(s, pos) == "#" || peek(s, pos) == "," || peek(s, pos) == "]" || peek(s, pos) == "}" { (acc, pos) }
  else { scan_bare_token(s, pos + 1, acc + peek(s, pos)) }
}

pub fun parse_bare_value(s: string, pos: int) : result<(Toml, int), string> {
  let pair = scan_bare_token(s, pos, "")
  let token = pair.0
  let end_pos = pair.1
  if token == "" { Err("expected a value at position " + show(pos)) }
  else { classify_bare(token, end_pos) }
}

pub fun strip_underscores(s: string) : string =>
  replace(s, "_", "")

pub fun classify_bare(token: string, pos: int) : result<(Toml, int), string> {
  if token == "true" { Ok((TBool(true), pos)) }
  else if token == "false" { Ok((TBool(false), pos)) }
  else if token == "inf" || token == "+inf" { Ok((TFloat(1.0 / 0.0), pos)) }
  else if token == "-inf" { Ok((TFloat(0.0 - 1.0 / 0.0), pos)) }
  else if token == "nan" || token == "+nan" || token == "-nan" { Ok((TFloat(0.0 / 0.0), pos)) }
  else { classify_number(token, pos) }
}

pub fun classify_number(token: string, pos: int) : result<(Toml, int), string> {
  let cleaned = strip_underscores(token)
  match parse_int(cleaned) {
    Some(n) => Ok((TInt(n), pos)),
    None => classify_float_or_err(cleaned, token, pos)
  }
}

pub fun classify_float_or_err(cleaned: string, token: string, pos: int) : result<(Toml, int), string> {
  match parse_float(cleaned) {
    Some(f) => Ok((TFloat(f), pos)),
    None => Err("invalid value: " + token)
  }
}

// ============================================================
// Array parsing
// ============================================================

pub fun parse_array(s: string, pos: int) : result<(Toml, int), string> {
  if peek(s, pos) != "[" { Err("expected '[' at position " + show(pos)) }
  else { parse_array_items(s, skip_ws_nl_comments(s, pos + 1), []) }
}

pub fun parse_array_items(s: string, pos: int, acc: list<Toml>) : result<(Toml, int), string> {
  if pos >= str_length(s) { Err("unterminated array") }
  else if peek(s, pos) == "]" { Ok((TArray(acc), pos + 1)) }
  else { parse_array_item(s, pos, acc) }
}

pub fun parse_array_item(s: string, pos: int, acc: list<Toml>) : result<(Toml, int), string> {
  match parse_value(s, pos) {
    Err(e) => Err(e),
    Ok((v, p)) => {
      let p2 = skip_ws_nl_comments(s, p)
      if peek(s, p2) == "," { parse_array_items(s, skip_ws_nl_comments(s, p2 + 1), acc + [v]) }
      else { parse_array_items(s, p2, acc + [v]) }
    }
  }
}

// ============================================================
// Inline table parsing
// ============================================================

pub fun parse_inline_table(s: string, pos: int) : result<(Toml, int), string> {
  if peek(s, pos) != "{" { Err("expected opening brace at position " + show(pos)) }
  else { parse_inline_entries(s, skip_ws_nl_comments(s, pos + 1), []) }
}

pub fun parse_inline_entries(s: string, pos: int, acc: list<(string, Toml)>) : result<(Toml, int), string> {
  if pos >= str_length(s) { Err("unterminated inline table") }
  else if peek(s, pos) == "}" { Ok((TTable(acc), pos + 1)) }
  else { parse_inline_entry(s, pos, acc) }
}

pub fun parse_inline_entry(s: string, pos: int, acc: list<(string, Toml)>) : result<(Toml, int), string> {
  match parse_key(s, pos) {
    Err(e) => Err(e),
    Ok((keys, p1)) => parse_inline_entry_value(s, keys, skip_ws(s, p1), acc)
  }
}

pub fun parse_inline_entry_value(s: string, keys: list<string>, pos: int, acc: list<(string, Toml)>) : result<(Toml, int), string> {
  if peek(s, pos) != "=" { Err("expected '=' at position " + show(pos)) }
  else { parse_inline_entry_rhs(s, keys, skip_ws(s, pos + 1), acc) }
}

pub fun parse_inline_entry_rhs(s: string, keys: list<string>, pos: int, acc: list<(string, Toml)>) : result<(Toml, int), string> {
  match parse_value(s, pos) {
    Err(e) => Err(e),
    Ok((v, p)) => finish_inline_entry(s, keys, v, skip_ws_nl_comments(s, p), acc)
  }
}

pub fun finish_inline_entry(s: string, keys: list<string>, value: Toml, pos: int, acc: list<(string, Toml)>) : result<(Toml, int), string> {
  match table_insert(acc, keys, value) {
    Err(e) => Err(e),
    Ok(new_acc) => finish_inline_sep(s, pos, new_acc)
  }
}

pub fun finish_inline_sep(s: string, pos: int, acc: list<(string, Toml)>) : result<(Toml, int), string> {
  if peek(s, pos) == "," { parse_inline_entries(s, skip_ws_nl_comments(s, pos + 1), acc) }
  else { parse_inline_entries(s, pos, acc) }
}

// ============================================================
// Table header parsing
// ============================================================

pub fun parse_table_header(s: string, pos: int) : result<(list<string>, int), string> {
  if peek(s, pos) != "[" { Err("expected '[' at position " + show(pos)) }
  else { parse_table_header_key(s, skip_ws(s, pos + 1)) }
}

pub fun parse_table_header_key(s: string, pos: int) : result<(list<string>, int), string> {
  match parse_key(s, pos) {
    Err(e) => Err(e),
    Ok((keys, p)) => parse_table_header_close(s, skip_ws(s, p), keys)
  }
}

pub fun parse_table_header_close(s: string, pos: int, keys: list<string>) : result<(list<string>, int), string> {
  if peek(s, pos) != "]" { Err("expected ']' at position " + show(pos)) }
  else { Ok((keys, pos + 1)) }
}

// ============================================================
// Document parser
// ============================================================

pub fun toml_parse(input: string) : result<Toml, string> {
  parse_document(input, 0, [], [])
}

pub fun parse_document(input: string, pos: int, path: list<string>, root: list<(string, Toml)>) : result<Toml, string> {
  let p = skip_ws_nl_comments(input, pos)
  if p >= str_length(input) { Ok(TTable(root)) }
  else if peek(input, p) == "[" { parse_doc_table(input, p, root) }
  else { parse_doc_keyval(input, p, path, root) }
}

pub fun parse_doc_table(input: string, pos: int, root: list<(string, Toml)>) : result<Toml, string> {
  match parse_table_header(input, pos) {
    Err(e) => Err(e),
    Ok((path, p)) => continue_after_header(input, p, path, root)
  }
}

pub fun continue_after_header(input: string, pos: int, path: list<string>, root: list<(string, Toml)>) : result<Toml, string> {
  match skip_comment_and_newline(input, pos) {
    Err(e) => Err(e),
    Ok(p) => ensure_and_continue(input, p, path, root)
  }
}

pub fun ensure_and_continue(input: string, pos: int, path: list<string>, root: list<(string, Toml)>) : result<Toml, string> {
  match ensure_table(root, path) {
    Err(e) => Err(e),
    Ok(new_root) => parse_document(input, pos, path, new_root)
  }
}

pub fun parse_doc_keyval(input: string, pos: int, path: list<string>, root: list<(string, Toml)>) : result<Toml, string> {
  match parse_key(input, pos) {
    Err(e) => Err(e),
    Ok((keys, p1)) => parse_doc_equals(input, path, keys, skip_ws(input, p1), root)
  }
}

pub fun parse_doc_equals(input: string, path: list<string>, keys: list<string>, pos: int, root: list<(string, Toml)>) : result<Toml, string> {
  if peek(input, pos) != "=" { Err("expected '=' at position " + show(pos)) }
  else { parse_doc_value(input, path, keys, skip_ws(input, pos + 1), root) }
}

pub fun parse_doc_value(input: string, path: list<string>, keys: list<string>, pos: int, root: list<(string, Toml)>) : result<Toml, string> {
  match parse_value(input, pos) {
    Err(e) => Err(e),
    Ok((value, p)) => insert_doc_value(input, path, keys, value, p, root)
  }
}

pub fun insert_doc_value(input: string, path: list<string>, keys: list<string>, value: Toml, pos: int, root: list<(string, Toml)>) : result<Toml, string> {
  let full_path = path + keys
  match table_insert(root, full_path, value) {
    Err(e) => Err(e),
    Ok(new_root) => continue_after_value(input, pos, path, new_root)
  }
}

pub fun continue_after_value(input: string, pos: int, path: list<string>, root: list<(string, Toml)>) : result<Toml, string> {
  match skip_comment_and_newline(input, pos) {
    Err(e) => Err(e),
    Ok(p) => parse_document(input, p, path, root)
  }
}

// ============================================================
// Accessors
// ============================================================

pub fun toml_get(t: Toml, key: string) : maybe<Toml> {
  match t {
    TTable(entries) => table_find(entries, key),
    _ => None
  }
}

pub fun toml_str(t: Toml) : maybe<string> => match t {
  TStr(v) => Some(v),
  _ => None
}

pub fun toml_int(t: Toml) : maybe<int> => match t {
  TInt(v) => Some(v),
  _ => None
}

pub fun toml_float(t: Toml) : maybe<float> => match t {
  TFloat(v) => Some(v),
  _ => None
}

pub fun toml_bool(t: Toml) : maybe<bool> => match t {
  TBool(v) => Some(v),
  _ => None
}

pub fun toml_list(t: Toml) : maybe<list<Toml>> => match t {
  TArray(items) => Some(items),
  _ => None
}

pub fun toml_table(t: Toml) : maybe<list<(string, Toml)>> => match t {
  TTable(entries) => Some(entries),
  _ => None
}

// ============================================================
// Pipe-friendly API
// ============================================================

pub fun toml_ok(r: result<Toml, string>) : maybe<Toml> => match r {
  Ok(t) => Some(t),
  Err(_) => None
}

pub fun at(m: maybe<Toml>, key: string) : maybe<Toml> => match m {
  Some(t) => toml_get(t, key),
  None => None
}

pub fun nth(m: maybe<Toml>, index: int) : maybe<Toml> => match m {
  Some(TArray(items)) => list_nth(items, index),
  _ => None
}

pub fun list_nth(xs: list<Toml>, i: int) : maybe<Toml> => match xs {
  [] => None,
  [x, ..rest] => if i == 0 { Some(x) } else { list_nth(rest, i - 1) }
}

pub fun as_str(m: maybe<Toml>) : maybe<string> => match m {
  Some(t) => toml_str(t),
  None => None
}

pub fun as_int(m: maybe<Toml>) : maybe<int> => match m {
  Some(t) => toml_int(t),
  None => None
}

pub fun as_float(m: maybe<Toml>) : maybe<float> => match m {
  Some(t) => toml_float(t),
  None => None
}

pub fun as_bool(m: maybe<Toml>) : maybe<bool> => match m {
  Some(t) => toml_bool(t),
  None => None
}

pub fun as_list(m: maybe<Toml>) : maybe<list<Toml>> => match m {
  Some(t) => toml_list(t),
  None => None
}

pub fun as_table(m: maybe<Toml>) : maybe<list<(string, Toml)>> => match m {
  Some(t) => toml_table(t),
  None => None
}

// ============================================================
// Defaults
// ============================================================

pub fun str_or(m: maybe<Toml>, fallback: string) : string => match as_str(m) {
  Some(v) => v,
  None => fallback
}

pub fun int_or(m: maybe<Toml>, fallback: int) : int => match as_int(m) {
  Some(v) => v,
  None => fallback
}

pub fun float_or(m: maybe<Toml>, fallback: float) : float => match as_float(m) {
  Some(v) => v,
  None => fallback
}

pub fun bool_or(m: maybe<Toml>, fallback: bool) : bool => match as_bool(m) {
  Some(v) => v,
  None => fallback
}

// ============================================================
// Inspection
// ============================================================

pub fun has_key(m: maybe<Toml>, key: string) : bool => match m {
  Some(t) => is_some(toml_get(t, key)),
  None => false
}

pub fun keys(m: maybe<Toml>) : list<string> => match m {
  Some(TTable(entries)) => map(entries, (e) => e.0),
  _ => []
}

pub fun toml_length(m: maybe<Toml>) : int => match m {
  Some(TArray(items)) => length(items),
  Some(TTable(entries)) => length(entries),
  _ => 0
}

// ============================================================
// Display
// ============================================================

pub fun toml_show(t: Toml) : string => match t {
  TStr(v) => "\"" + v + "\"",
  TInt(v) => show(v),
  TFloat(v) => show(v),
  TBool(v) => if v { "true" } else { "false" },
  TDatetime(v) => v,
  TArray(items) => "[" + join(map(items, (i) => toml_show(i)), ", ") + "]",
  TTable(entries) => "{" + join(map(entries, (e) => e.0 + " = " + toml_show(e.1)), ", ") + "}"
}

pub fun make_indent(n: int) : string =>
  if n <= 0 { "" } else { "  " + make_indent(n - 1) }

pub fun toml_pretty(t: Toml, indent: int) : string {
  let pad = make_indent(indent)
  match t {
    TTable(entries) => join(map(entries, (e) => pretty_entry(e, indent)), "\n"),
    TArray(items) => join(map(items, (i) => pad + "- " + toml_show(i)), "\n"),
    _ => pad + toml_show(t)
  }
}

pub fun pretty_entry(entry: (string, Toml), indent: int) : string {
  let pad = make_indent(indent)
  match entry.1 {
    TTable(_) => pad + "[" + entry.0 + "]\n" + toml_pretty(entry.1, indent + 1),
    _ => pad + entry.0 + " = " + toml_show(entry.1)
  }
}
