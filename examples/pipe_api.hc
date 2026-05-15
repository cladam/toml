// pipe_api.hc — Pipe-friendly API for navigating TOML documents
import "../src/toml"

fun main() {
  let input = "[server]\nhost = \"localhost\"\nport = 8080\n\n[database]\nname = \"mydb\"\nmax_connections = 10"

  match toml_parse(input) {
    Ok(doc) => {
      // Pipe-friendly navigation with dot notation
      let host = Some(doc).at("server").at("host").as_str
      let port = Some(doc).at("server").at("port").as_int
      let db_name = Some(doc).at("database").at("name").as_str

      println("host: " + show_maybe(host))
      println("port: " + show_maybe_int(port))
      println("db:   " + show_maybe(db_name))

      // Missing keys return None
      let missing = Some(doc).at("server").at("ssl").as_bool
      println("ssl:  " + show_maybe_bool(missing))
    },
    Err(e) => println("parse error: " + e)
  }
}

fun show_maybe(m: maybe<string>) : string => match m {
  Some(v) => v,
  None => "<none>"
}

fun show_maybe_int(m: maybe<int>) : string => match m {
  Some(v) => show(v),
  None => "<none>"
}

fun show_maybe_bool(m: maybe<bool>) : string => match m {
  Some(v) => show(v),
  None => "<none>"
}
