# toml

A TOML parser library for [hica](https://github.com/cladam/hica).
Full implementation of [TOML v1.1.0](https://toml.io/en/v1.1.0) — 129 tests across 9 test files.

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

Everything in the TOML v1.1.0 spec:

- **Keys**: bare, quoted (basic & literal), dotted, empty quoted
- **Strings**: basic, literal, multi-line (both kinds), all escape sequences (`\n`, `\t`, `\r`, `\\`, `\"`, `\b`, `\f`, `\e`), unicode escapes (`\xHH`, `\uHHHH`, `\UHHHHHHHH`), line ending backslash
- **Numbers**: integers (decimal, hex, octal, binary, underscores), floats (fractional, exponent, underscores), special values (`inf`, `nan`)
- **Booleans**: `true`, `false`
- **Date-times**: offset date-time, local date-time, local date, local time, fractional seconds, space delimiter, seconds omitted
- **Tables**: standard, nested, implicit super-table creation, dotted keys inside tables, out-of-order super-table definition
- **Inline tables**: basic, nested, dotted keys, trailing comma (v1.1.0), multi-line (v1.1.0), self-containment enforcement
- **Arrays**: basic, mixed-type, multi-line, trailing commas, nested, comments inside
- **Array of tables**: basic, nested, sub-tables under array elements, conflict detection
- **Comments**: full-line, inline, control character rejection
- **Whitespace**: CRLF and LF newlines, tab as whitespace
- **Error handling**: line numbers in error messages, duplicate key/table rejection, unterminated string/array/table detection

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

Returns `Ok(TTable(...))` on success or `Err("line N: message")` on failure.

## API

### Direct accessors

```rust
toml_get(t: Toml, key: string) : maybe<Toml>
toml_str(t: Toml, key: string) : string
toml_int(t: Toml, key: string) : int
toml_float(t: Toml, key: string) : float
toml_bool(t: Toml, key: string) : bool
toml_list(t: Toml, key: string) : list<Toml>
toml_table(t: Toml, key: string) : list<(string, Toml)>
```

### Pipe-friendly navigation

```rust
let doc = toml_ok(toml_parse(input))

// Chain with |> or dot notation
doc.at("server").at("port").as_int
doc.at("database").at("ports").nth(0).as_int

// Available: toml_ok, at, nth, as_str, as_int, as_float, as_bool, as_list, as_table, as_datetime
```

### Defaults

```rust
str_or(maybe_toml, "default")
int_or(maybe_toml, 0)
float_or(maybe_toml, 0.0)
bool_or(maybe_toml, false)
```

### Inspection

```rust
has_key(t: Toml, key: string) : bool
keys(t: Toml) : list<string>
toml_length(t: Toml) : int
```

### Display

```rust
toml_show(t: Toml) : string    // Compact single-line
toml_pretty(t: Toml) : string  // Pretty-printed
```

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
  api.hc           # Accessors, pipe-friendly navigation, defaults, inspection
  display.hc       # toml_show, toml_pretty
examples/
  basic_parsing.hc
  read_config.hc
  simple.toml
  config.toml
tests/
  test_basics.hc          # 24 tests — types, flat key/value, error line numbers
  test_strings.hc         # 24 tests — escapes, unicode, multi-line, control chars
  test_keys.hc            #  9 tests — quoted, dotted, empty keys
  test_numbers.hc         # 15 tests — int, float, hex, octal, binary, special
  test_datetimes.hc       # 17 tests — offset, local, date, time, fractional
  test_tables.hc          # 10 tests — standard, nested, duplicates
  test_inline_tables.hc   # 13 tests — inline, nested, trailing comma, self-containment
  test_arrays.hc          #  9 tests — basic, mixed, multi-line, nested
  test_array_tables.hc    #  8 tests — basic, nested, sub-tables, conflicts
```

## Running Tests

```sh
# Run all tests
for f in tests/test_*.hc; do hica test "$f"; done

# Run a single test file
hica test tests/test_basics.hc
```

## License

MIT
