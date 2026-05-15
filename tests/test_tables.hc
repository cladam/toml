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
// Table validation tests
// ============================================================

test "duplicate table rejected" {
  let input = "[a]\nkey = 1\n[a]\nother = 2"
  match toml_parse(input) {
    Ok(_) => assert(false),
    Err(e) => assert(contains(e, "duplicate table"))
  }
}

test "duplicate nested table rejected" {
  let input = "[a.b]\nkey = 1\n[a.b]\nother = 2"
  match toml_parse(input) {
    Ok(_) => assert(false),
    Err(e) => assert(contains(e, "duplicate table"))
  }
}

test "out-of-order super-table allowed" {
  let input = "[a.b.c]\nx = 1\n[a]\ny = 2"
  match toml_parse(input) {
    Ok(doc) => {
      match toml_get(doc, "a") {
        Some(TTable(entries)) => assert(length(entries) == 2),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "out-of-order super-table with value access" {
  let input = "[a.b]\nx = 1\n[a]\ny = 2"
  match toml_parse(input) {
    Ok(doc) => {
      let a = Some(doc).at("a")
      let y_val = a.at("y")
      match y_val {
        Some(TInt(v)) => assert(v == 2),
        _ => assert(false)
      }
      let bx = a.at("b").at("x")
      match bx {
        Some(TInt(v)) => assert(v == 1),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}
