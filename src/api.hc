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

pub fun at(m: maybe<Toml>, key: string) : maybe<Toml> =>
  m |> and_then((t) => toml_get(t, key))

pub fun nth(m: maybe<Toml>, index: int) : maybe<Toml> =>
  as_list(m) |> and_then((items) => list_nth(items, index))

pub fun list_nth(xs: list<Toml>, i: int) : maybe<Toml> => match xs {
  [] => None,
  [x, ..rest] => if i == 0 { Some(x) } else { list_nth(rest, i - 1) }
}

pub fun as_str(m: maybe<Toml>) : maybe<string> =>
  m |> and_then((t) => toml_str(t))

pub fun as_int(m: maybe<Toml>) : maybe<int> =>
  m |> and_then((t) => toml_int(t))

pub fun as_float(m: maybe<Toml>) : maybe<float> =>
  m |> and_then((t) => toml_float(t))

pub fun as_bool(m: maybe<Toml>) : maybe<bool> =>
  m |> and_then((t) => toml_bool(t))

pub fun as_datetime(m: maybe<Toml>) : maybe<string> =>
  m |> and_then((t) => toml_datetime(t))

pub fun as_list(m: maybe<Toml>) : maybe<list<Toml>> =>
  m |> and_then((t) => toml_list(t))

pub fun as_table(m: maybe<Toml>) : maybe<list<(string, Toml)>> =>
  m |> and_then((t) => toml_table(t))

// ============================================================
// Defaults
// ============================================================

pub fun str_or(m: maybe<Toml>, fallback: string) : string =>
  unwrap_maybe_or(as_str(m), fallback)

pub fun int_or(m: maybe<Toml>, fallback: int) : int =>
  unwrap_maybe_or(as_int(m), fallback)

pub fun float_or(m: maybe<Toml>, fallback: float) : float =>
  unwrap_maybe_or(as_float(m), fallback)

pub fun bool_or(m: maybe<Toml>, fallback: bool) : bool =>
  unwrap_maybe_or(as_bool(m), fallback)

pub fun datetime_or(m: maybe<Toml>, fallback: string) : string =>
  unwrap_maybe_or(as_datetime(m), fallback)

// ============================================================
// Inspection
// ============================================================

pub fun has_key(m: maybe<Toml>, key: string) : bool =>
  is_some(at(m, key))

pub fun keys(m: maybe<Toml>) : list<string> => match m {
  Some(TTable(entries)) => map(entries, (e) => e.0),
  _ => []
}

pub fun toml_length(m: maybe<Toml>) : int => match m {
  Some(TArray(items)) => length(items),
  Some(TTable(entries)) => length(entries),
  _ => 0
}
