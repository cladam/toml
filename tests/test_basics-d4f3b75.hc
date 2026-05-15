import "../src/toml"

// ============================================================
// Parse basics
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

// ============================================================
// String values
// ============================================================

test "basic string value" {
  match toml_parse("key = \"hello\"") {
    Ok(doc) => {
      let r = Some(doc) |> at("key") |> as_str
      assert(r == Some("hello"))
    },
    Err(_) => assert(false)
  }
}

test "basic string with escape sequences" {
  match toml_parse("key = \"hello\\nworld\"") {
    Ok(doc) => {
      let r = Some(doc) |> at("key") |> as_str
      assert(r == Some("hello\nworld"))
    },
    Err(_) => assert(false)
  }
}

test "basic string with tab escape" {
  match toml_parse("key = \"col1\\tcol2\"") {
    Ok(doc) => {
      let r = Some(doc) |> at("key") |> as_str
      assert(r == Some("col1\tcol2"))
    },
    Err(_) => assert(false)
  }
}

test "basic string with escaped quote" {
  match toml_parse("key = \"say \\\"hi\\\"\"") {
    Ok(doc) => {
      let r = Some(doc) |> at("key") |> as_str
      assert(r == Some("say \"hi\""))
    },
    Err(_) => assert(false)
  }
}

test "literal string value" {
  match toml_parse("path = 'C:\\Users\\file'") {
    Ok(doc) => {
      let r = Some(doc) |> at("path") |> as_str
      assert(r == Some("C:\\Users\\file"))
    },
    Err(_) => assert(false)
  }
}

test "empty basic string" {
  match toml_parse("key = \"\"") {
    Ok(doc) => {
      let r = Some(doc) |> at("key") |> as_str
      assert(r == Some(""))
    },
    Err(_) => assert(false)
  }
}

test "empty literal string" {
  match toml_parse("key = ''") {
    Ok(doc) => {
      let r = Some(doc) |> at("key") |> as_str
      assert(r == Some(""))
    },
    Err(_) => assert(false)
  }
}

// ============================================================
// Integer values
// ============================================================

test "positive integer" {
  match toml_parse("port = 8080") {
    Ok(doc) => {
      let r = Some(doc) |> at("port") |> as_int
      assert(r == Some(8080))
    },
    Err(_) => assert(false)
  }
}

test "negative integer" {
  match toml_parse("offset = -17") {
    Ok(doc) => {
      let r = Some(doc) |> at("offset") |> as_int
      assert(r == Some(-17))
    },
    Err(_) => assert(false)
  }
}

test "zero" {
  match toml_parse("val = 0") {
    Ok(doc) => {
      let r = Some(doc) |> at("val") |> as_int
      assert(r == Some(0))
    },
    Err(_) => assert(false)
  }
}

test "integer with plus sign" {
  match toml_parse("val = +99") {
    Ok(doc) => {
      let r = Some(doc) |> at("val") |> as_int
      assert(r == Some(99))
    },
    Err(_) => assert(false)
  }
}

// ============================================================
// Boolean values
// ============================================================

test "true value" {
  match toml_parse("flag = true") {
    Ok(doc) => {
      let r = Some(doc) |> at("flag") |> as_bool
      assert(r == Some(true))
    },
    Err(_) => assert(false)
  }
}

test "false value" {
  match toml_parse("flag = false") {
    Ok(doc) => {
      let r = Some(doc) |> at("flag") |> as_bool
      assert(r == Some(false))
    },
    Err(_) => assert(false)
  }
}

// ============================================================
// Float values
// ============================================================

test "float value" {
  match toml_parse("pi = 3.14") {
    Ok(doc) => {
      let r = Some(doc) |> at("pi") |> as_float
      assert(is_some(r))
    },
    Err(_) => assert(false)
  }
}

test "negative float" {
  match toml_parse("val = -0.5") {
    Ok(doc) => {
      let r = Some(doc) |> at("val") |> as_float
      assert(is_some(r))
    },
    Err(_) => assert(false)
  }
}

// ============================================================
// Tables
// ============================================================

test "simple table" {
  let input = "[server]\nhost = \"localhost\"\nport = 8080"
  match toml_parse(input) {
    Ok(doc) => {
      let host = Some(doc) |> at("server") |> at("host") |> as_str
      let port = Some(doc) |> at("server") |> at("port") |> as_int
      assert(host == Some("localhost"))
      assert(port == Some(8080))
    },
    Err(_) => assert(false)
  }
}

test "nested table" {
  let input = "[a.b]\nkey = \"val\""
  match toml_parse(input) {
    Ok(doc) => {
      let r = Some(doc) |> at("a") |> at("b") |> at("key") |> as_str
      assert(r == Some("val"))
    },
    Err(_) => assert(false)
  }
}

test "multiple tables" {
  let input = "[server]\nhost = \"localhost\"\n\n[database]\nname = \"mydb\""
  match toml_parse(input) {
    Ok(doc) => {
      let host = Some(doc) |> at("server") |> at("host") |> as_str
      let name = Some(doc) |> at("database") |> at("name") |> as_str
      assert(host == Some("localhost"))
      assert(name == Some("mydb"))
    },
    Err(_) => assert(false)
  }
}

test "root-level and table key/values" {
  let input = "title = \"My App\"\n\n[server]\nport = 3000"
  match toml_parse(input) {
    Ok(doc) => {
      let title = Some(doc) |> at("title") |> as_str
      let port = Some(doc) |> at("server") |> at("port") |> as_int
      assert(title == Some("My App"))
      assert(port == Some(3000))
    },
    Err(_) => assert(false)
  }
}

// ============================================================
// Dotted keys
// ============================================================

test "dotted key creates nested table" {
  match toml_parse("fruit.name = \"banana\"") {
    Ok(doc) => {
      let r = Some(doc) |> at("fruit") |> at("name") |> as_str
      assert(r == Some("banana"))
    },
    Err(_) => assert(false)
  }
}

test "multiple dotted keys" {
  let input = "physical.color = \"orange\"\nphysical.shape = \"round\""
  match toml_parse(input) {
    Ok(doc) => {
      let color = Some(doc) |> at("physical") |> at("color") |> as_str
      let shape = Some(doc) |> at("physical") |> at("shape") |> as_str
      assert(color == Some("orange"))
      assert(shape == Some("round"))
    },
    Err(_) => assert(false)
  }
}

// ============================================================
// Comments
// ============================================================

test "inline comment" {
  match toml_parse("key = \"value\" # this is a comment") {
    Ok(doc) => {
      let r = Some(doc) |> at("key") |> as_str
      assert(r == Some("value"))
    },
    Err(_) => assert(false)
  }
}

test "comment before key/value" {
  let input = "# comment\nkey = 42"
  match toml_parse(input) {
    Ok(doc) => {
      let r = Some(doc) |> at("key") |> as_int
      assert(r == Some(42))
    },
    Err(_) => assert(false)
  }
}

// ============================================================
// Arrays
// ============================================================

test "integer array" {
  match toml_parse("nums = [1, 2, 3]") {
    Ok(doc) => {
      let r = Some(doc) |> at("nums") |> as_list
      match r {
        Some(items) => assert(length(items) == 3),
        None => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "string array" {
  match toml_parse("colors = [\"red\", \"green\", \"blue\"]") {
    Ok(doc) => {
      let first = Some(doc) |> at("colors") |> nth(0) |> as_str
      assert(first == Some("red"))
    },
    Err(_) => assert(false)
  }
}

test "empty array" {
  match toml_parse("empty = []") {
    Ok(doc) => {
      let r = Some(doc) |> at("empty") |> as_list
      match r {
        Some(items) => assert(length(items) == 0),
        None => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

// ============================================================
// Inline tables
// ============================================================

test "simple inline table" {
  let input = join(["name = ", "{", "first = \"Tom\", last = \"Preston\"", "}"], "")
  match toml_parse(input) {
    Ok(doc) => {
      let first = Some(doc) |> at("name") |> at("first") |> as_str
      let last = Some(doc) |> at("name") |> at("last") |> as_str
      assert(first == Some("Tom"))
      assert(last == Some("Preston"))
    },
    Err(_) => assert(false)
  }
}

test "empty inline table" {
  let input = join(["empty = ", "{", "}"], "")
  match toml_parse(input) {
    Ok(doc) => {
      let r = Some(doc) |> at("empty") |> as_table
      match r {
        Some(entries) => assert(length(entries) == 0),
        None => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

// ============================================================
// API tests
// ============================================================

test "has_key returns true for existing key" {
  match toml_parse("name = \"test\"") {
    Ok(doc) => assert(has_key(Some(doc), "name") == true),
    Err(_) => assert(false)
  }
}

test "has_key returns false for missing key" {
  match toml_parse("name = \"test\"") {
    Ok(doc) => assert(has_key(Some(doc), "missing") == false),
    Err(_) => assert(false)
  }
}

test "keys returns table keys" {
  match toml_parse("a = 1\nb = 2\nc = 3") {
    Ok(doc) => {
      let k = keys(Some(doc))
      assert(length(k) == 3)
    },
    Err(_) => assert(false)
  }
}

test "toml_length counts entries" {
  match toml_parse("a = 1\nb = 2") {
    Ok(doc) => assert(toml_length(Some(doc)) == 2),
    Err(_) => assert(false)
  }
}

test "str_or returns value when present" {
  match toml_parse("name = \"hello\"") {
    Ok(doc) => {
      let r = Some(doc) |> at("name") |> str_or("default")
      assert(r == "hello")
    },
    Err(_) => assert(false)
  }
}

test "str_or returns fallback when missing" {
  match toml_parse("name = \"hello\"") {
    Ok(doc) => {
      let r = Some(doc) |> at("missing") |> str_or("default")
      assert(r == "default")
    },
    Err(_) => assert(false)
  }
}

test "int_or returns value when present" {
  match toml_parse("port = 8080") {
    Ok(doc) => {
      let r = Some(doc) |> at("port") |> int_or(0)
      assert(r == 8080)
    },
    Err(_) => assert(false)
  }
}

// ============================================================
// Error tests
// ============================================================

test "duplicate key is rejected" {
  let input = "name = \"first\"\nname = \"second\""
  match toml_parse(input) {
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
// Display
// ============================================================

test "toml_show string" {
  let r = toml_show(TStr("hello"))
  assert(r == "\"hello\"")
}

test "toml_show int" {
  let r = toml_show(TInt(42))
  assert(r == "42")
}

test "toml_show bool" {
  let r = toml_show(TBool(true))
  assert(r == "true")
}
