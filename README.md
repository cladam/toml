# toml

A TOML parser library for [hica](https://github.com/cladam/hica).
Targets [TOML v1.1.0](https://toml.io/en/v1.1.0), built incrementally with tests for every feature.

> **Work in progress** — core parsing works (keys, strings, numbers, booleans, tables). Arrays, inline tables, date-times, and the API/display modules are not yet implemented. See [BACKLOG.md](BACKLOG.md) for full status.

## Installation

Add as a git submodule to your hica project:

```sh
git submodule add https://github.com/cladam/toml.git lib/toml
```

Then import the library:

```rust
import "./lib/toml/src/toml"
```

## Supported TOML

- **Keys**: bare (`key`), quoted (`"key"`, `'key'`), dotted (`a.b.c`)
- **Basic strings**: `"hello"` with escape sequences (`\n`, `\t`, `\r`, `\\`, `\"`)
- **Literal strings**: `'no\escapes'` — backslashes are literal
- **Integers**: decimal with optional sign and underscores (`1_000`, `-42`)
- **Floats**: decimal with optional sign and underscores, special values (`inf`, `nan`)
- **Booleans**: `true`, `false`
- **Tables**: standard (`[table]`), nested (`[a.b.c]`), implicit super-table creation
- **Comments**: full-line (`# ...`) and inline (`key = "val" # ...`)
- **Duplicate key rejection**: clear error messages

## Types

```rust
pub type Toml {
  TStr(value: string),
  TInt(value: int),
  TFloat(value: float),
  TBool(value: bool),
  TDatetime(value: string),
  TArray(items: list<Toml>),
  TTable(entries: list<(string, Toml)>)
}
```

## Parsing

```rust
toml_parse(input: string) : result<Toml, string>
```

Returns `Ok(TTable(...))` on success or `Err(message)` on failure.

## Examples

See the [examples/](examples/) directory for runnable programs:

- [basic_parsing.hc](examples/basic_parsing.hc): Read a TOML file and extract values
- [read_config.hc](examples/read_config.hc): Read a config file and list top-level keys

Run an example:

```sh
hica run examples/basic_parsing.hc
```

## Project Structure

```
src/
  toml.hc          # Barrel module — import this
  toml_types.hc    # Toml type definition
  parser.hc        # TOML parser, toml_parse entry point
  main.hc          # Demo program
examples/
  basic_parsing.hc
  read_config.hc
  simple.toml
  config.toml
tests/
  test_basics.hc   # Type tests + flat key/value parsing
  test_strings.hc  # Basic strings, escapes, literal strings
  test_keys.hc     # Quoted keys, dotted keys
  test_tables.hc   # Table headers, nested tables
```

## Running Tests

```sh
hica test tests/test_basics.hc
hica test tests/test_strings.hc
hica test tests/test_keys.hc
hica test tests/test_tables.hc
```

## License

MIT
