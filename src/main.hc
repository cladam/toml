import "./toml"

fun main() {
  let input = "[server]\nhost = \"localhost\"\nport = 8080\ndebug = true\n\n[database]\nname = \"mydb\"\nmax_conns = 10"

  match toml_parse(input) {
    Ok(doc) => {
      println("Parsed TOML:")
      println(toml_pretty(doc, 0))
      println("")
      let m = Some(doc)
      let host = m |> at("server") |> at("host") |> str_or("unknown")
      let port = m |> at("server") |> at("port") |> int_or(0)
      let debug = m |> at("server") |> at("debug") |> bool_or(false)
      println("host: " + host)
      println("port: " + show(port))
      println("debug: " + show(debug))
    },
    Err(e) => println("Error: " + e)
  }
}
