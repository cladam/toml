import "../src/toml"

// ============================================================
// Array tests
// ============================================================

test "simple integer array" {
  match toml_parse("nums = [1, 2, 3]") {
    Ok(doc) => {
      match toml_get(doc, "nums") {
        Some(TArray(items)) => assert(length(items) == 3),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "string array" {
  match toml_parse("colors = [\"red\", \"green\", \"blue\"]") {
    Ok(doc) => {
      match toml_get(doc, "colors") {
        Some(TArray(items)) => assert(length(items) == 3),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "empty array" {
  match toml_parse("empty = []") {
    Ok(doc) => {
      match toml_get(doc, "empty") {
        Some(TArray(items)) => assert(length(items) == 0),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "trailing comma" {
  match toml_parse("a = [1, 2, 3,]") {
    Ok(doc) => {
      match toml_get(doc, "a") {
        Some(TArray(items)) => assert(length(items) == 3),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "multi-line array" {
  let input = "a = [\n  1,\n  2,\n  3\n]"
  match toml_parse(input) {
    Ok(doc) => {
      match toml_get(doc, "a") {
        Some(TArray(items)) => assert(length(items) == 3),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "mixed-type array" {
  match toml_parse("mix = [1, \"two\", true]") {
    Ok(doc) => {
      match toml_get(doc, "mix") {
        Some(TArray(items)) => assert(length(items) == 3),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "nested array" {
  match toml_parse("matrix = [[1, 2], [3, 4]]") {
    Ok(doc) => {
      match toml_get(doc, "matrix") {
        Some(TArray(items)) => assert(length(items) == 2),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "array with comments" {
  let input = "a = [\n  # first\n  1,\n  # second\n  2\n]"
  match toml_parse(input) {
    Ok(doc) => {
      match toml_get(doc, "a") {
        Some(TArray(items)) => assert(length(items) == 2),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "unterminated array" {
  match toml_parse("a = [1, 2") {
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
