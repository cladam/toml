import "../src/toml"

test "TStr holds a string" {
  let t = TStr("hello")
  match t {
    TStr(v) => assert(v == "hello"),
    _ => assert(false)
  }
}

test "TInt holds an integer" {
  let t = TInt(42)
  match t {
    TInt(v) => assert(v == 42),
    _ => assert(false)
  }
}

test "TBool holds a boolean" {
  let t = TBool(true)
  match t {
    TBool(v) => assert(v == true),
    _ => assert(false)
  }
}

test "TTable holds entries" {
  let t = TTable([("key", TStr("val"))])
  match t {
    TTable(entries) => assert(length(entries) == 1),
    _ => assert(false)
  }
}

test "TArray holds items" {
  let t = TArray([TInt(1), TInt(2)])
  match t {
    TArray(items) => assert(length(items) == 2),
    _ => assert(false)
  }
}

// ============================================================
// Parser tests — bare key/value pairs
// ============================================================

test "empty input parses to empty table" {
  match toml_parse("") {
    Ok(TTable(entries)) => assert(length(entries) == 0),
    _ => assert(false)
  }
}

test "whitespace-only input" {
  match toml_parse("  \n\n  ") {
    Ok(TTable(entries)) => assert(length(entries) == 0),
    _ => assert(false)
  }
}

test "comment-only input" {
  match toml_parse("# just a comment\n# another") {
    Ok(TTable(entries)) => assert(length(entries) == 0),
    _ => assert(false)
  }
}

test "bare key with string value" {
  match toml_parse("name = \"hello\"") {
    Ok(doc) => {
      match toml_get(doc, "name") {
        Some(TStr(v)) => assert(v == "hello"),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "bare key with integer value" {
  match toml_parse("port = 8080") {
    Ok(doc) => {
      match toml_get(doc, "port") {
        Some(TInt(v)) => assert(v == 8080),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "bare key with boolean value" {
  match toml_parse("flag = true") {
    Ok(doc) => {
      match toml_get(doc, "flag") {
        Some(TBool(v)) => assert(v == true),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "multiple key/value pairs" {
  let input = "name = \"app\"\nport = 3000\ndebug = false"
  match toml_parse(input) {
    Ok(TTable(entries)) => assert(length(entries) == 3),
    Ok(_) => assert(false),
    Err(_) => assert(false)
  }
}

test "inline comment after value" {
  match toml_parse("key = \"value\" # comment") {
    Ok(doc) => {
      match toml_get(doc, "key") {
        Some(TStr(v)) => assert(v == "value"),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "escape sequences in strings" {
  match toml_parse("msg = \"hello\\nworld\"") {
    Ok(doc) => {
      match toml_get(doc, "msg") {
        Some(TStr(v)) => assert(v == "hello\nworld"),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "duplicate key is rejected" {
  match toml_parse("a = 1\na = 2") {
    Ok(_) => assert(false),
    Err(e) => assert(contains(e, "duplicate"))
  }
}

test "missing value after equals" {
  match toml_parse("key = ") {
    Ok(_) => assert(false),
    Err(_) => assert(true)
  }
}

// ============================================================
// Literal string tests
// ============================================================

test "literal string value" {
  let input = "path = \'C:\\Users\\docs\'"
  match toml_parse(input) {
    Ok(doc) => {
      match toml_get(doc, "path") {
        Some(TStr(v)) => assert(v == "C:\\Users\\docs"),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "literal string preserves backslashes" {
  let input = "regex = \'\\d+\\.\\d+\'"
  match toml_parse(input) {
    Ok(doc) => {
      match toml_get(doc, "regex") {
        Some(TStr(v)) => assert(v == "\\d+\\.\\d+"),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "literal string with double quotes inside" {
  let input = "str = \'He said \"hi\"\'"
  match toml_parse(input) {
    Ok(doc) => {
      match toml_get(doc, "str") {
        Some(TStr(v)) => assert(v == "He said \"hi\""),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "empty literal string" {
  let input = "empty = \'\'"
  match toml_parse(input) {
    Ok(doc) => {
      match toml_get(doc, "empty") {
        Some(TStr(v)) => assert(v == ""),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

// ============================================================
// Quoted key tests
// ============================================================

test "basic quoted key" {
  match toml_parse("\"my key\" = 42") {
    Ok(doc) => {
      match toml_get(doc, "my key") {
        Some(TInt(v)) => assert(v == 42),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "literal quoted key" {
  match toml_parse("\'my key\' = 42") {
    Ok(doc) => {
      match toml_get(doc, "my key") {
        Some(TInt(v)) => assert(v == 42),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "quoted key with special chars" {
  match toml_parse("\"key.with.dots\" = true") {
    Ok(doc) => {
      match toml_get(doc, "key.with.dots") {
        Some(TBool(v)) => assert(v == true),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "quoted key in table header" {
  match toml_parse("[\"my section\"]\nval = 1") {
    Ok(doc) => {
      match toml_get(doc, "my section") {
        Some(TTable(entries)) => assert(length(entries) == 1),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

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
