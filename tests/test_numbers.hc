import "../src/toml"

// ============================================================
// Hex integer tests
// ============================================================

test "hex integer 0xDEADBEEF" {
  match toml_parse("val = 0xDEADBEEF") {
    Ok(doc) => {
      match toml_get(doc, "val") {
        Some(TInt(v)) => assert(v == 3735928559),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "hex integer 0xff" {
  match toml_parse("val = 0xff") {
    Ok(doc) => {
      match toml_get(doc, "val") {
        Some(TInt(v)) => assert(v == 255),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "hex integer with underscores" {
  match toml_parse("val = 0xdead_beef") {
    Ok(doc) => {
      match toml_get(doc, "val") {
        Some(TInt(v)) => assert(v == 3735928559),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

// ============================================================
// Octal integer tests
// ============================================================

test "octal integer 0o755" {
  match toml_parse("val = 0o755") {
    Ok(doc) => {
      match toml_get(doc, "val") {
        Some(TInt(v)) => assert(v == 493),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "octal integer 0o77" {
  match toml_parse("val = 0o77") {
    Ok(doc) => {
      match toml_get(doc, "val") {
        Some(TInt(v)) => assert(v == 63),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

// ============================================================
// Binary integer tests
// ============================================================

test "binary integer 0b11010110" {
  match toml_parse("val = 0b11010110") {
    Ok(doc) => {
      match toml_get(doc, "val") {
        Some(TInt(v)) => assert(v == 214),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "binary integer 0b0" {
  match toml_parse("val = 0b0") {
    Ok(doc) => {
      match toml_get(doc, "val") {
        Some(TInt(v)) => assert(v == 0),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "binary integer with underscores" {
  match toml_parse("val = 0b1111_0000") {
    Ok(doc) => {
      match toml_get(doc, "val") {
        Some(TInt(v)) => assert(v == 240),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

// ============================================================
// Leading zero rejection
// ============================================================

test "leading zero rejected" {
  match toml_parse("val = 042") {
    Ok(_) => assert(false),
    Err(e) => assert(contains(e, "leading zeros"))
  }
}

test "leading zero with sign rejected" {
  match toml_parse("val = +042") {
    Ok(_) => assert(false),
    Err(e) => assert(contains(e, "leading zeros"))
  }
}

test "single zero is valid" {
  match toml_parse("val = 0") {
    Ok(doc) => {
      match toml_get(doc, "val") {
        Some(TInt(v)) => assert(v == 0),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "zero float 0.0 is valid" {
  match toml_parse("val = 0.0") {
    Ok(doc) => {
      match toml_get(doc, "val") {
        Some(TFloat(v)) => assert(v == 0.0),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

// ============================================================
// Exponent float tests
// ============================================================

test "exponent float 5e+22" {
  match toml_parse("val = 5e+22") {
    Ok(doc) => {
      match toml_get(doc, "val") {
        Some(TFloat(_)) => assert(true),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "exponent float 1e06" {
  match toml_parse("val = 1e06") {
    Ok(doc) => {
      match toml_get(doc, "val") {
        Some(TFloat(_)) => assert(true),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "fractional exponent float 6.626e-34" {
  match toml_parse("val = 6.626e-34") {
    Ok(doc) => {
      match toml_get(doc, "val") {
        Some(TFloat(_)) => assert(true),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}
