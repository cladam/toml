// inspect_and_display.hc — Inspection and display functions
import "../src/toml"

fun main() {
  let input = "[server]\nhost = \"localhost\"\nport = 8080\n\n[database]\nname = \"mydb\"\ntags = [\"fast\", \"reliable\"]"

  match toml_parse(input) {
    Ok(doc) => {
      // Inspection: has_key, keys, toml_length
      println("has 'server': " + show(has_key(Some(doc), "server")))
      println("has 'cache':  " + show(has_key(Some(doc), "cache")))
      println("top-level keys: " + join(keys(Some(doc)), ", "))
      println("server keys:    " + join(keys(Some(doc).at("server")), ", "))
      println("tags count:     " + show(toml_length(Some(doc).at("database").at("tags"))))

      // Display: toml_show (compact)
      println("")
      println("compact: " + toml_show(doc))

      // Display: toml_pretty (indented)
      println("")
      println("pretty:")
      println(toml_pretty(doc, 0))
    },
    Err(e) => println("parse error: " + e)
  }
}
