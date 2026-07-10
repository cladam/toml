// display.hc — TOML display and pretty-printing
import "./toml_types"

// ============================================================
// Compact display
// ============================================================

pub fun toml_show(t: Toml) : string => match t {
  TStr(v) => "\"" + v + "\"",
  TInt(v) => show(v),
  TFloat(v) => show(v),
  TBool(v) => if v { "true" } else { "false" },
  TDatetime(v) => v,
  TArray(items) => "[" + join(map(items, toml_show), ", ") + "]",
  TTable(entries) => join(["{", join(map(entries, (e) => e.0 + " = " + toml_show(e.1)), ", "), "}"], "")
}

// ============================================================
// Pretty-printing
// ============================================================

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
