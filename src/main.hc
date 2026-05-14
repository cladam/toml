import "./toml"

fun main() {
  let doc = TTable([("name", TStr("toml-lib"))])
  match doc {
    TTable(entries) => {
      println("table with " + show(length(entries)) + " entries")
    },
    _ => println("not a table")
  }
}
