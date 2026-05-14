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
