import "../src/toml"

// ============================================================
// Inline table tests
// ============================================================

test "basic inline table" {
  let input: string = "point = \u007Bx = 1, y = 2\u007D"
  match toml_parse(input) {
    Ok(doc) => {
      match toml_get(doc, "point") {
        Some(TTable(entries)) => assert(length(entries) == 2),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "inline table value access" {
  let input: string = "point = \u007Bx = 1, y = 2\u007D"
  match toml_parse(input) {
    Ok(doc) => {
      match toml_get(doc, "point") {
        Some(pt) => {
          match toml_get(pt, "x") {
            Some(TInt(v)) => assert(v == 1),
            _ => assert(false)
          }
        },
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "empty inline table" {
  let input: string = "empty = \u007B\u007D"
  match toml_parse(input) {
    Ok(doc) => {
      match toml_get(doc, "empty") {
        Some(TTable(entries)) => assert(length(entries) == 0),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "inline table with string values" {
  let input: string = "name = \u007Bfirst = \"Tom\", last = \"Smith\"\u007D"
  match toml_parse(input) {
    Ok(doc) => {
      match toml_get(doc, "name") {
        Some(n) => {
          match toml_get(n, "first") {
            Some(TStr(v)) => assert(v == "Tom"),
            _ => assert(false)
          }
        },
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "trailing comma in inline table" {
  let input: string = "p = \u007Bx = 1, y = 2,\u007D"
  match toml_parse(input) {
    Ok(doc) => {
      match toml_get(doc, "p") {
        Some(TTable(entries)) => assert(length(entries) == 2),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "dotted key in inline table" {
  let input: string = "fruit = \u007Bapple.color = \"red\"\u007D"
  match toml_parse(input) {
    Ok(doc) => {
      match toml_get(doc, "fruit") {
        Some(f) => {
          match toml_get(f, "apple") {
            Some(a) => {
              match toml_get(a, "color") {
                Some(TStr(v)) => assert(v == "red"),
                _ => assert(false)
              }
            },
            _ => assert(false)
          }
        },
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "nested inline table" {
  let input: string = "a = \u007Bb = \u007Bc = 1\u007D\u007D"
  match toml_parse(input) {
    Ok(doc) => {
      match toml_get(doc, "a") {
        Some(a) => {
          match toml_get(a, "b") {
            Some(b) => {
              match toml_get(b, "c") {
                Some(TInt(v)) => assert(v == 1),
                _ => assert(false)
              }
            },
            _ => assert(false)
          }
        },
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "unterminated inline table" {
  let input: string = "a = \u007Bx = 1"
  match toml_parse(input) {
    Ok(_) => assert(false),
    Err(e) => assert(contains(e, "unterminated"))
  }
}

// ============================================================
// Helpers (until api.hc exists)
// ============================================================

fun toml_get(t: Toml, key: string) : maybe<Toml> {
  match t {
    TTable(entries) => {
      entries
        |> find((e) => e.0 == key)
        |> map_maybe((e) => e.1)
    },
    _ => None
  }
}
