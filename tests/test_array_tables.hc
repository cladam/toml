import "../src/toml"

// ============================================================
// Basic array of tables
// ============================================================

test "basic array of tables" {
  let input = "[[products]]\nname = \"Hammer\"\n\n[[products]]\nname = \"Nail\""
  match toml_parse(input) {
    Ok(doc) => {
      match toml_get(doc, "products") {
        Some(TArray(items)) => assert(length(items) == 2),
        _ => assert(false)
      }
    },
    Err(e) => {

      assert(false)
    }
  }
}

test "array of tables value access" {
  let input = "[[products]]\nname = \"Hammer\"\nsku = 738594937\n\n[[products]]\nname = \"Nail\"\nsku = 284758393"
  match toml_parse(input) {
    Ok(doc) => {
      let d = Some(doc)
      let first_name = d.at("products").nth(0).at("name")
      match first_name {
        Some(TStr(v)) => assert(v == "Hammer"),
        _ => assert(false)
      }
      let second_name = d.at("products").nth(1).at("name")
      match second_name {
        Some(TStr(v)) => assert(v == "Nail"),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "single array of tables element" {
  let input = "[[items]]\nval = 1"
  match toml_parse(input) {
    Ok(doc) => {
      match toml_get(doc, "items") {
        Some(TArray(items)) => {
          assert(length(items) == 1)
          match items {
            [TTable(entries)] => assert(length(entries) == 1),
            _ => assert(false)
          }
        },
        _ => assert(false)
      }
    },
    Err(e) => {

      assert(false)
    }
  }
}

// ============================================================
// Nested array of tables
// ============================================================

test "nested array of tables" {
  let input = "[[fruits]]\nname = \"apple\"\n\n[[fruits.varieties]]\nname = \"red delicious\"\n\n[[fruits.varieties]]\nname = \"granny smith\""
  match toml_parse(input) {
    Ok(doc) => {
      let d = Some(doc)
      let fruits = d.at("fruits")
      match fruits {
        Some(TArray(items)) => {
          assert(length(items) == 1)
          match items {
            [TTable(sub)] => {
              let varieties = Some(TTable(sub)).at("varieties")
              match varieties {
                Some(TArray(vars)) => assert(length(vars) == 2),
                _ => assert(false)
              }
            },
            _ => assert(false)
          }
        },
        _ => assert(false)
      }
    },
    Err(e) => {

      assert(false)
    }
  }
}

// ============================================================
// Sub-tables under array elements
// ============================================================

test "sub-table under array element" {
  let input = "[[fruits]]\nname = \"apple\"\n\n[fruits.physical]\ncolor = \"red\"\nshape = \"round\""
  match toml_parse(input) {
    Ok(doc) => {
      let d = Some(doc)
      let apple = d.at("fruits").nth(0)
      let color = apple.at("physical").at("color")
      match color {
        Some(TStr(v)) => assert(v == "red"),
        _ => assert(false)
      }
    },
    Err(e) => {

      assert(false)
    }
  }
}

// ============================================================
// Conflict detection
// ============================================================

test "static array then array-of-tables rejected" {
  let input = "fruits = []\n[[fruits]]\nname = \"apple\""
  match toml_parse(input) {
    Ok(_) => assert(false),
    Err(_) => assert(true)
  }
}

test "table then array-of-tables rejected" {
  let input = "[products]\nname = \"x\"\n[[products]]\nname = \"y\""
  match toml_parse(input) {
    Ok(_) => assert(false),
    Err(_) => assert(true)
  }
}

test "multiple array elements with sub-tables" {
  let input = "[[fruits]]\nname = \"apple\"\n\n[fruits.physical]\ncolor = \"red\"\n\n[[fruits]]\nname = \"banana\"\n\n[fruits.physical]\ncolor = \"yellow\""
  match toml_parse(input) {
    Ok(doc) => {
      let d = Some(doc)
      let banana = d.at("fruits").nth(1)
      let color = banana.at("physical").at("color")
      match color {
        Some(TStr(v)) => assert(v == "yellow"),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}
