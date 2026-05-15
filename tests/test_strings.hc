import "../src/toml"

// ============================================================
// Basic string tests
// ============================================================

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

test "backspace escape" {
  match toml_parse("val = \"a\\bb\"") {
    Ok(doc) => {
      match toml_get(doc, "val") {
        Some(TStr(v)) => assert(str_length(v) == 3),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "form feed escape" {
  match toml_parse("val = \"a\\fb\"") {
    Ok(doc) => {
      match toml_get(doc, "val") {
        Some(TStr(v)) => assert(str_length(v) == 3),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "escape character escape" {
  match toml_parse("val = \"a\\eb\"") {
    Ok(doc) => {
      match toml_get(doc, "val") {
        Some(TStr(v)) => assert(str_length(v) == 3),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
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


