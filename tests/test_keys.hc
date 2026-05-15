import "../src/toml"

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
// Dotted key tests
// ============================================================

test "simple dotted key" {
  match toml_parse("server.host = \"localhost\"") {
    Ok(doc) => {
      match toml_get(doc, "server") {
        Some(s) => {
          match toml_get(s, "host") {
            Some(TStr(v)) => assert(v == "localhost"),
            _ => assert(false)
          }
        },
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "multi-level dotted key" {
  match toml_parse("a.b.c = 42") {
    Ok(doc) => {
      match toml_get(doc, "a") {
        Some(a) => {
          match toml_get(a, "b") {
            Some(b) => {
              match toml_get(b, "c") {
                Some(TInt(v)) => assert(v == 42),
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

test "dotted key with quoted segment" {
  match toml_parse("server.\"my host\" = \"localhost\"") {
    Ok(doc) => {
      match toml_get(doc, "server") {
        Some(s) => {
          match toml_get(s, "my host") {
            Some(TStr(v)) => assert(v == "localhost"),
            _ => assert(false)
          }
        },
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "multiple dotted keys share table" {
  let input = "fruit.name = \"apple\"\nfruit.color = \"red\""
  match toml_parse(input) {
    Ok(doc) => {
      match toml_get(doc, "fruit") {
        Some(TTable(entries)) => assert(length(entries) == 2),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "empty quoted key" {
  match toml_parse("\"\" = \"blank\"") {
    Ok(doc) => {
      match toml_get(doc, "") {
        Some(TStr(v)) => assert(v == "blank"),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

