import "../src/toml"

test "offset datetime with Z" {
  let input = "dt = 1979-05-27T07:32:00Z"
  match toml_parse(input) {
    Ok(doc) => {
      let v = Some(doc).at("dt").as_datetime
      match v {
        Some(s) => assert(s == "1979-05-27T07:32:00Z"),
        None => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "offset datetime with numeric offset" {
  let input = "dt = 1979-05-27T00:32:00-07:00"
  match toml_parse(input) {
    Ok(doc) => {
      let v = Some(doc).at("dt").as_datetime
      match v {
        Some(s) => assert(s == "1979-05-27T00:32:00-07:00"),
        None => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "offset datetime with positive offset" {
  let input = "dt = 1979-05-27T07:32:00+05:30"
  match toml_parse(input) {
    Ok(doc) => {
      let v = Some(doc).at("dt").as_datetime
      match v {
        Some(s) => assert(s == "1979-05-27T07:32:00+05:30"),
        None => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "offset datetime with fractional seconds" {
  let input = "dt = 1979-05-27T00:32:00.999999-07:00"
  match toml_parse(input) {
    Ok(doc) => {
      let v = Some(doc).at("dt").as_datetime
      match v {
        Some(s) => assert(s == "1979-05-27T00:32:00.999999-07:00"),
        None => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "offset datetime with space delimiter" {
  let input = "dt = 1979-05-27 07:32:00Z"
  match toml_parse(input) {
    Ok(doc) => {
      let v = Some(doc).at("dt").as_datetime
      match v {
        Some(s) => assert(s == "1979-05-27T07:32:00Z"),
        None => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "local datetime" {
  let input = "dt = 1979-05-27T07:32:00"
  match toml_parse(input) {
    Ok(doc) => {
      let v = Some(doc).at("dt").as_datetime
      match v {
        Some(s) => assert(s == "1979-05-27T07:32:00"),
        None => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "local datetime with fractional seconds" {
  let input = "dt = 1979-05-27T00:32:00.5"
  match toml_parse(input) {
    Ok(doc) => {
      let v = Some(doc).at("dt").as_datetime
      match v {
        Some(s) => assert(s == "1979-05-27T00:32:00.5"),
        None => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "local date" {
  let input = "ld = 1979-05-27"
  match toml_parse(input) {
    Ok(doc) => {
      let v = Some(doc).at("ld").as_datetime
      match v {
        Some(s) => assert(s == "1979-05-27"),
        None => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "local time" {
  let input = "lt = 07:32:00"
  match toml_parse(input) {
    Ok(doc) => {
      let v = Some(doc).at("lt").as_datetime
      match v {
        Some(s) => assert(s == "07:32:00"),
        None => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "local time with fractional seconds" {
  let input = "lt = 00:32:00.999999"
  match toml_parse(input) {
    Ok(doc) => {
      let v = Some(doc).at("lt").as_datetime
      match v {
        Some(s) => assert(s == "00:32:00.999999"),
        None => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "datetime kind is preserved" {
  let input = "d = 2024-05-15\ndt = 2024-05-15T10:30:00\nodt = 2024-05-15T10:30:00Z\nt = 10:30:00"
  match toml_parse(input) {
    Ok(doc) => {
      let d = Some(doc)
      let dk = d.at("d").as_datetime
      let dtk = d.at("dt").as_datetime
      let odtk = d.at("odt").as_datetime
      let tk = d.at("t").as_datetime
      match dk {
        Some(v) => assert(datetime_kind(v) == "local-date"),
        None => assert(false)
      }
      match dtk {
        Some(v) => assert(datetime_kind(v) == "local-datetime"),
        None => assert(false)
      }
      match odtk {
        Some(v) => assert(datetime_kind(v) == "offset-datetime"),
        None => assert(false)
      }
      match tk {
        Some(v) => assert(datetime_kind(v) == "local-time"),
        None => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "multiple datetimes in table" {
  let input = "[event]\nname = \"launch\"\ndate = 2024-01-15\ntime = 09:00:00\nstart = 2024-01-15T09:00:00Z"
  match toml_parse(input) {
    Ok(doc) => {
      let d = Some(doc)
      let name = str_or(d.at("event").at("name"), "")
      assert(name == "launch")
      match d.at("event").at("date").as_datetime {
        Some(v) => assert(v == "2024-01-15"),
        None => assert(false)
      }
      match d.at("event").at("time").as_datetime {
        Some(v) => assert(v == "09:00:00"),
        None => assert(false)
      }
      match d.at("event").at("start").as_datetime {
        Some(v) => assert(v == "2024-01-15T09:00:00Z"),
        None => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "local time seconds omitted" {
  let input = "lt = 07:32"
  match toml_parse(input) {
    Ok(doc) => {
      let v = Some(doc).at("lt").as_datetime
      match v {
        Some(s) => assert(s == "07:32"),
        None => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "offset datetime seconds omitted with Z" {
  let input = "dt = 1979-05-27T07:32Z"
  match toml_parse(input) {
    Ok(doc) => {
      let v = Some(doc).at("dt").as_datetime
      match v {
        Some(s) => assert(s == "1979-05-27T07:32Z"),
        None => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "offset datetime seconds omitted with offset" {
  let input = "dt = 1979-05-27T07:32+02:00"
  match toml_parse(input) {
    Ok(doc) => {
      let v = Some(doc).at("dt").as_datetime
      match v {
        Some(s) => assert(s == "1979-05-27T07:32+02:00"),
        None => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "local datetime seconds omitted" {
  let input = "dt = 1979-05-27T07:32"
  match toml_parse(input) {
    Ok(doc) => {
      let v = Some(doc).at("dt").as_datetime
      match v {
        Some(s) => assert(s == "1979-05-27T07:32"),
        None => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "space-delimited seconds omitted" {
  let input = "dt = 1979-05-27 07:32Z"
  match toml_parse(input) {
    Ok(doc) => {
      let v = Some(doc).at("dt").as_datetime
      match v {
        Some(s) => assert(s == "1979-05-27T07:32Z"),
        None => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}
