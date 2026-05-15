import "../src/toml"

fun main() {
  match read_file("examples/unicode_escapes.toml") {
    Ok(content) => {
      match toml_parse(content) {
        Ok(doc) => {
          let d = Some(doc)
          println("=== Unicode Escapes in TOML ===")
          println("")

          // Basic string escapes
          println("greeting:  " + str_or(d.at("greeting"), ""))
          println("smiley:    " + str_or(d.at("smiley"), ""))
          println("copyright: " + str_or(d.at("copyright"), ""))
          println("tab_char:  " + str_or(d.at("tab_char"), ""))
          let bell = str_or(d.at("hex_bell"), "")
          println("hex_bell:  (bell character, length=" + show(str_length(bell)) + ")")
          println("newline:   " + str_or(d.at("newline_embedded"), ""))
          println("")

          // Symbol table
          println("=== Symbols ===")
          let sym = d.at("symbols")
          println("bullet: " + str_or(sym.at("bullet"), ""))
          println("arrow:  " + str_or(sym.at("arrow"), ""))
          println("check:  " + str_or(sym.at("check"), ""))
          println("cross:  " + str_or(sym.at("cross"), ""))
          println("")

          // Multi-line with unicode
          println("=== Multi-line with unicode ===")
          println(str_or(d.at("multi_line").at("poem"), ""))
        },
        Err(e) => println("parse error: " + e)
      }
    },
    Err(e) => println("file error: " + e)
  }
}
