// api.hc — Accessors, pipe-friendly navigation, defaults, and inspection
import "./toml_types"

// ============================================================
// Direct accessors
// ============================================================

pub fun toml_get(t: Toml, key: string) : maybe<Toml> {
  match t {
    TTable(entries) => {
      entries
        |> find((e) => e.0 == key)
        |> map_maybe((e) => e.1)
    },
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

pub fun toml_datetime(t: Toml) : maybe<string> => match t {
  TDatetime(v) => Some(v),
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

pub fun as_datetime(m: maybe<Toml>) : maybe<string> => match m {
  Some(t) => toml_datetime(t),
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

pub fun datetime_or(m: maybe<Toml>, fallback: string) : string => match as_datetime(m) {
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
