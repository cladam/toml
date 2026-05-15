// defaults.hc — Using default values for missing or wrong-type keys
import "../src/toml"

fun main() {
  let input = "name = \"my-app\"\nport = 3000\ndebug = true"

  match toml_parse(input) {
    Ok(doc) => {
      // str_or / int_or / bool_or provide fallbacks
      let name = str_or(Some(doc).at("name"), "unnamed")
      let port = int_or(Some(doc).at("port"), 8080)
      let debug = bool_or(Some(doc).at("debug"), false)

      // Missing keys get the default
      let host = str_or(Some(doc).at("host"), "0.0.0.0")
      let timeout = int_or(Some(doc).at("timeout"), 30)

      println("name:    " + name)
      println("port:    " + show(port))
      println("debug:   " + show(debug))
      println("host:    " + host)
      println("timeout: " + show(timeout))
    },
    Err(e) => println("parse error: " + e)
  }
}
