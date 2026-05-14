import "../src/toml"

test "TStr holds a string" {
  let t = TStr("hello")
  match t {
    TStr(v) => assert(v == "hello"),
    _ => assert(false)
  }
}

test "TInt holds an integer" {
  let t = TInt(42)
  match t {
    TInt(v) => assert(v == 42),
    _ => assert(false)
  }
}

test "TBool holds a boolean" {
  let t = TBool(true)
  match t {
    TBool(v) => assert(v == true),
    _ => assert(false)
  }
}

test "TTable holds entries" {
  let t = TTable([("key", TStr("val"))])
  match t {
    TTable(entries) => assert(length(entries) == 1),
    _ => assert(false)
  }
}

test "TArray holds items" {
  let t = TArray([TInt(1), TInt(2)])
  match t {
    TArray(items) => assert(length(items) == 2),
    _ => assert(false)
  }
}
