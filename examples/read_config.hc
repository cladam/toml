import "../src/toml"

fun main() {
  match read_file("examples/config.toml") {
    Ok(content) => {
      match toml_parse(content) {
        Ok(TTable(entries)) => {
          println("parsed " + show(length(entries)) + " top-level keys")
          foreach(entries, (e) => println("  " + e.0))
        },
        Ok(_) => println("unexpected result"),
        Err(e) => println("parse error: " + e)
      }
    },
    Err(e) => println("file error: " + e)
  }
}
