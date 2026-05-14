import "../src/toml"

// ============================================================
// Table tests
// ============================================================

test "simple table header" {
  let input = "[server]\nhost = \"localhost\"\nport = 8080"
  match toml_parse(input) {
    Ok(doc) => {
      match toml_get(doc, "server") {
        Some(TTable(entries)) => assert(length(entries) == 2),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "nested table value access" {
  let input = "[server]\nhost = \"localhost\""
  match toml_parse(input) {
    Ok(doc) => {
      let server = toml_get(doc, "server")
      match server {
        Some(s) => {
          match toml_get(s, "host") {
            Some(TStr(v)) => assert(v == "localhost"),
            _ => assert(false)
          }
        },
        None => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "multiple tables" {
  let input = "[server]\nport = 8080\n\n[database]\nname = \"mydb\""
  match toml_parse(input) {
    Ok(TTable(entries)) => assert(length(entries) == 2),
    _ => assert(false)
  }
}

test "nested table header" {
  let input = "[a.b]\nkey = \"val\""
  match toml_parse(input) {
    Ok(doc) => {
      match toml_get(doc, "a") {
        Some(a) => {
          match toml_get(a, "b") {
            Some(b) => {
              match toml_get(b, "key") {
                Some(TStr(v)) => assert(v == "val"),
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

test "root keys before table" {
  let input = "title = \"My App\"\n\n[server]\nport = 3000"
  match toml_parse(input) {
    Ok(doc) => {
      match toml_get(doc, "title") {
        Some(TStr(v)) => assert(v == "My App"),
        _ => assert(false)
      }
      match toml_get(doc, "server") {
        Some(TTable(_)) => assert(true),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "empty table" {
  let input = "[empty]\n[other]\nkey = 1"
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
