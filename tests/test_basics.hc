import "../src/toml"

// ============================================================
// Type constructor tests
// ============================================================

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
// Parser tests — flat key/value pairs
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
// Special float tests
// ============================================================

test "positive infinity" {
  match toml_parse("val = inf") {
    Ok(doc) => {
      match toml_get(doc, "val") {
        Some(TFloat(_)) => assert(true),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "explicit positive infinity" {
  match toml_parse("val = +inf") {
    Ok(doc) => {
      match toml_get(doc, "val") {
        Some(TFloat(_)) => assert(true),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "negative infinity" {
  match toml_parse("val = -inf") {
    Ok(doc) => {
      match toml_get(doc, "val") {
        Some(TFloat(_)) => assert(true),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "nan value" {
  match toml_parse("val = nan") {
    Ok(doc) => {
      match toml_get(doc, "val") {
        Some(TFloat(_)) => assert(true),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "positive nan" {
  match toml_parse("val = +nan") {
    Ok(doc) => {
      match toml_get(doc, "val") {
        Some(TFloat(_)) => assert(true),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "negative nan" {
  match toml_parse("val = -nan") {
    Ok(doc) => {
      match toml_get(doc, "val") {
        Some(TFloat(_)) => assert(true),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "invalid bare value is rejected" {
  match toml_parse("key = notavalue") {
    Ok(_) => assert(false),
    Err(e) => assert(contains(e, "invalid"))
  }
}