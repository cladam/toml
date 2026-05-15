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

test "multi-line inline table" {
  let input = "contact = \u007B\nname = \"Alice\",\nemail = \"alice@example.com\"\n\u007D"
  match toml_parse(input) {
    Ok(doc) => {
      let d = Some(doc)
      let name = str_or(d.at("contact").at("name"), "")
      let email = str_or(d.at("contact").at("email"), "")
      assert(name == "Alice")
      assert(email == "alice@example.com")
    },
    Err(_) => assert(false)
  }
}

test "inline table rejects dotted key addition" {
  let input = "a = \u007Bb = 1\u007D\na.c = 2"
  match toml_parse(input) {
    Ok(_) => assert(false),
    Err(e) => assert(contains(e, "inline"))
  }
}

test "inline table rejects table header" {
  let input = "a = \u007Bb = 1\u007D\n[a]\nc = 2"
  match toml_parse(input) {
    Ok(_) => assert(false),
    Err(e) => assert(contains(e, "inline"))
  }
}

test "inline table rejects sub-table header" {
  let input = "a = \u007Bb = 1\u007D\n[a.c]"
  match toml_parse(input) {
    Ok(_) => assert(false),
    Err(e) => assert(contains(e, "inline"))
  }
}

test "sibling keys alongside inline table allowed" {
  let input = "a = \u007Bb = 1\u007D\nc = 2"
  match toml_parse(input) {
    Ok(doc) => {
      let d = Some(doc)
      let r = int_or(d.at("c"), 0)
      assert(r == 2)
    },
    Err(_) => assert(false)
  }
}
