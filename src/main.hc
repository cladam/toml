import "./toml"

fun main() {
  match read_file("hica.ini") {
    Err(e) => println("read error: " + e),
    Ok(input) => {
      match toml_parse(input) {
        Err(e) => println("parse error: " + e),
        Ok(doc) => {
          let d = Some(doc)
          println("name:    " + str_or(d.at("project").at("name"), "?"))
          println("version: " + str_or(d.at("project").at("version"), "?"))
          println("license: " + str_or(d.at("project").at("license"), "?"))
          println("entry:   " + str_or(d.at("project").at("entry"), "?"))
        }
      }
    }
  }
}
