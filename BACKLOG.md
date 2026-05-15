# TOML Parser Backlog

Status tracking against [TOML v1.1.0](https://toml.io/en/v1.1.0) spec.

## Legend

- [x] Implemented and tested
- [ ] Not started
- [-] Partial

---

## Keys

- [x] Bare keys (`key = "value"`)
- [x] Quoted keys — basic string keys (`"key" = "value"`)
- [x] Quoted keys — literal string keys (`'key' = "value"`)
- [x] Dotted keys (`physical.color = "orange"`)
- [x] Dotted keys creating implicit tables
- [x] Empty quoted keys (`"" = "blank"`)
- [x] Duplicate key rejection

## Data Types — Strings

- [x] Basic strings (`"hello"`)
- [x] Escape sequences (`\n`, `\t`, `\r`, `\\`, `\"`, `\b`, `\f`, `\e`)
- [x] Unicode escapes (`\xHH`, `\uHHHH`, `\UHHHHHHHH`)
- [x] Multi-line basic strings (`"""..."""`)
- [x] Multi-line newline trimming (newline after opening `"""`)
- [x] Line ending backslash (trailing `\` trims whitespace)
- [x] Literal strings (`'...'`)
- [x] Multi-line literal strings (`'''...'''`)
- [x] Reject invalid escape sequences
- [x] Reject control characters in strings

## Data Types — Numbers

- [x] Integers (decimal, with sign)
- [x] Integers with underscores (`1_000`)
- [x] Hex integers (`0xDEADBEEF`)
- [x] Octal integers (`0o755`)
- [x] Binary integers (`0b11010110`)
- [x] Leading zero rejection
- [x] Floats (decimal, with sign)
- [x] Floats (exponent `5e+22`, `1e06`)
- [x] Floats (fractional + exponent `6.626e-34`)
- [x] Floats with underscores
- [x] Special floats (`inf`, `nan`, `+inf`, `-inf`, `+nan`, `-nan`)

## Data Types — Other

- [x] Booleans (`true`, `false`)
- [x] Offset date-time (`1979-05-27T07:32:00Z`, `1979-05-27T00:32:00-07:00`)
- [x] Offset date-time with space delimiter (`1979-05-27 07:32:00Z`)
- [x] Offset date-time seconds omitted (`1979-05-27 07:32Z`)
- [x] Local date-time (`1979-05-27T07:32:00`)
- [x] Local date (`1979-05-27`)
- [x] Local time (`07:32:00`)
- [x] Local time seconds omitted (`07:32`)
- [x] Fractional seconds (`00:32:00.999999`)

## Tables

- [x] Standard tables (`[table]`)
- [x] Nested tables (`[a.b.c]`)
- [x] Implicit super-table creation
- [x] Dotted keys inside tables
- [x] Empty tables
- [x] Duplicate table rejection
- [x] Table/key conflict detection (can't redefine key as table)
- [x] Out-of-order super-table definition (`[x.y.z]` then `[x]`)

## Inline Tables

- [x] Basic inline tables (`{ key = "val" }`)
- [x] Nested inline tables
- [x] Dotted keys in inline tables
- [x] Trailing comma (v1.1.0)
- [x] Multi-line inline tables (v1.1.0)
- [x] Inline table self-containment (no external additions)

## Arrays

- [x] Basic arrays (`[1, 2, 3]`)
- [x] Mixed-type arrays
- [x] Multi-line arrays
- [x] Trailing commas
- [x] Nested arrays
- [x] Comments inside arrays

## Array of Tables

- [x] Basic array of tables (`[[products]]`)
- [x] Nested array of tables (`[[fruits.varieties]]`)
- [x] Sub-tables under array elements (`[fruits.physical]`)
- [x] Static array conflict rejection (`fruits = []` then `[[fruits]]`)
- [x] Table/array-of-tables conflict rejection

## Comments

- [x] Full-line comments (`# ...`)
- [x] Inline comments (`key = "val" # ...`)
- [x] Reject control characters in comments

## Whitespace & Structure

- [x] Whitespace around keys and values
- [x] Whitespace around table headers
- [x] Empty lines between sections
- [x] CRLF and LF newline support
- [x] Tab as whitespace

## Error Handling

- [x] Empty input detection
- [x] Missing value after `=`
- [x] Unterminated strings
- [x] Unterminated arrays/inline tables
- [x] Invalid escape sequence reporting
- [x] Duplicate key error messages
- [x] Line number in error messages

## API

- [x] `toml_parse(input) : result<Toml, string>`
- [x] Direct accessors: `toml_get`, `toml_str`, `toml_int`, `toml_float`, `toml_bool`, `toml_list`, `toml_table`
- [x] Pipe-friendly: `toml_ok`, `at`, `nth`, `as_str`, `as_int`, `as_float`, `as_bool`, `as_list`, `as_table`
- [x] Defaults: `str_or`, `int_or`, `float_or`, `bool_or`
- [x] Inspection: `has_key`, `keys`, `toml_length`
- [x] Display: `toml_show`, `toml_pretty`

## Tests

- [x] Key/value pair tests
- [x] String tests (all four kinds + escapes + control char rejection)
- [x] Number tests (int bases, floats, specials)
- [x] Boolean tests
- [x] Date-time tests
- [x] Table tests (standard, nested, implicit)
- [x] Inline table tests
- [x] Array tests
- [x] Array of tables tests
- [x] Comment tests
- [x] API tests (navigation, defaults, inspection)
- [x] Error tests (malformed input)
- [x] Display tests (toml_show, toml_pretty)

---

## Implementation Order

Recommended build sequence, each step produces a commit-worthy increment:

1. **Toml type + skeleton parser** — type definition, `toml_parse` returning empty table
2. **Bare key/value pairs** — bare keys, `=`, basic string values
3. **All string types** — basic, literal, multi-line basic, multi-line literal, escapes
4. **Numbers** — integers (decimal, hex, octal, binary), floats, specials
5. **Booleans**
6. **Standard tables** — `[table]`, nested `[a.b.c]`
7. **Dotted keys** — implicit table creation
8. **Arrays** — value arrays with mixed types
9. **Inline tables** — `{ key = val }`
10. **Array of tables** — `[[array]]`
11. **Comments** — full-line and inline
12. **Date-times** — all four datetime types
13. **API layer** — pipe-friendly navigation, defaults, inspection, display
14. **Error messages** — line numbers, clear diagnostics
15. **Validation** — duplicate keys, table conflicts, self-containment rules
