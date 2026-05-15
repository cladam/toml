import "../src/toml"

fun main() {
  match read_file("examples/simple.toml") {
    Ok(content) => {
      match toml_parse(content) {
        Ok(doc) => {
          let title = toml_get(doc, "title")
          let version = toml_get(doc, "version")
          let debug = toml_get(doc, "debug")
          let retries = toml_get(doc, "max_retries")

          println("title:   " + show_val(title))
          println("version: " + show_val(version))
          println("debug:   " + show_val(debug))
          println("retries: " + show_val(retries))
        },
        Err(e) => println("parse error: " + e)
      }
    },
    Err(e) => println("file error: " + e)
  }
}

fun show_val(m: maybe<Toml>) : string {
  match m {
    Some(TStr(v)) => v,
    Some(TInt(v)) => show(v),
    Some(TBool(v)) => show(v),
    Some(TFloat(v)) => show(v),
    Some(_) => "<complex>",
    None => "<missing>"
  }
}
