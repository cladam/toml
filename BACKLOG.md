# TOML Parser Backlog

Status tracking against [TOML v1.1.0](https://toml.io/en/v1.1.0) spec.

## Legend

- [x] Implemented
- [ ] Not started
- [-] Partial

---

## Keys

- [ ] Bare keys (`key = "value"`)
- [ ] Quoted keys — basic string keys (`"key" = "value"`)
- [ ] Quoted keys — literal string keys (`'key' = "value"`)
- [ ] Dotted keys (`physical.color = "orange"`)
- [ ] Dotted keys creating implicit tables
- [ ] Empty quoted keys (`"" = "blank"`)
- [ ] Duplicate key rejection

## Data Types — Strings

- [ ] Basic strings (`"hello"`)
- [ ] Escape sequences (`\n`, `\t`, `\\`, `\"`, `\b`, `\f`, `\r`, `\e`)
- [ ] Unicode escapes (`\xHH`, `\uHHHH`, `\UHHHHHHHH`)
- [ ] Multi-line basic strings (`"""..."""`)
- [ ] Multi-line newline trimming (newline after opening `"""`)
- [ ] Line ending backslash (trailing `\` trims whitespace)
- [ ] Literal strings (`'...'`)
- [ ] Multi-line literal strings (`'''...'''`)
- [ ] Reject invalid escape sequences
- [ ] Reject control characters in strings

## Data Types — Numbers

- [ ] Integers (decimal, with sign)
- [ ] Integers with underscores (`1_000`)
- [ ] Hex integers (`0xDEADBEEF`)
- [ ] Octal integers (`0o755`)
- [ ] Binary integers (`0b11010110`)
- [ ] Leading zero rejection
- [ ] Floats (decimal, with sign)
- [ ] Floats (exponent `5e+22`, `1e06`)
- [ ] Floats (fractional + exponent `6.626e-34`)
- [ ] Floats with underscores
- [ ] Special floats (`inf`, `+inf`, `-inf`, `nan`, `+nan`, `-nan`)

## Data Types — Other

- [ ] Booleans (`true`, `false`)
- [ ] Offset date-time (`1979-05-27T07:32:00Z`, `1979-05-27T00:32:00-07:00`)
- [ ] Offset date-time with space delimiter (`1979-05-27 07:32:00Z`)
- [ ] Offset date-time seconds omitted (`1979-05-27 07:32Z`)
- [ ] Local date-time (`1979-05-27T07:32:00`)
- [ ] Local date (`1979-05-27`)
- [ ] Local time (`07:32:00`)
- [ ] Local time seconds omitted (`07:32`)
- [ ] Fractional seconds (`00:32:00.999999`)

## Tables

- [ ] Standard tables (`[table]`)
- [ ] Nested tables (`[a.b.c]`)
- [ ] Implicit super-table creation
- [ ] Dotted keys inside tables
- [ ] Empty tables
- [ ] Duplicate table rejection
- [ ] Table/key conflict detection (can't redefine key as table)
- [ ] Out-of-order super-table definition (`[x.y.z]` then `[x]`)

## Inline Tables

- [ ] Basic inline tables (`{ key = "val" }`)
- [ ] Nested inline tables
- [ ] Dotted keys in inline tables
- [ ] Trailing comma (v1.1.0)
- [ ] Multi-line inline tables (v1.1.0)
- [ ] Inline table self-containment (no external additions)

## Arrays

- [ ] Basic arrays (`[1, 2, 3]`)
- [ ] Mixed-type arrays
- [ ] Multi-line arrays
- [ ] Trailing commas
- [ ] Nested arrays
- [ ] Comments inside arrays

## Array of Tables

- [ ] Basic array of tables (`[[products]]`)
- [ ] Nested array of tables (`[[fruits.varieties]]`)
- [ ] Sub-tables under array elements (`[fruits.physical]`)
- [ ] Static array conflict rejection (`fruits = []` then `[[fruits]]`)
- [ ] Table/array-of-tables conflict rejection

## Comments

- [ ] Full-line comments (`# ...`)
- [ ] Inline comments (`key = "val" # ...`)
- [ ] Reject control characters in comments

## Whitespace & Structure

- [ ] Whitespace around keys and values
- [ ] Whitespace around table headers
- [ ] Empty lines between sections
- [ ] CRLF and LF newline support
- [ ] Tab as whitespace (not in indentation context)

## Error Handling

- [ ] Empty input detection
- [ ] Missing value after `=`
- [ ] Unterminated strings
- [ ] Unterminated arrays/inline tables
- [ ] Invalid escape sequence reporting
- [ ] Duplicate key error messages
- [ ] Line number in error messages

## API

- [ ] `toml_parse(input) : result<Toml, string>`
- [ ] Direct accessors: `toml_get`, `toml_str`, `toml_int`, `toml_float`, `toml_bool`, `toml_list`, `toml_table`
- [ ] Pipe-friendly: `toml_ok`, `at`, `nth`, `as_str`, `as_int`, `as_float`, `as_bool`, `as_list`, `as_table`
- [ ] Defaults: `str_or`, `int_or`, `float_or`, `bool_or`
- [ ] Inspection: `has_key`, `keys`, `toml_length`
- [ ] Display: `toml_show`, `toml_pretty`

## Tests

- [ ] Key/value pair tests
- [ ] String tests (all four kinds + escapes)
- [ ] Number tests (int bases, floats, specials)
- [ ] Boolean tests
- [ ] Date-time tests
- [ ] Table tests (standard, nested, implicit)
- [ ] Inline table tests
- [ ] Array tests
- [ ] Array of tables tests
- [ ] Comment tests
- [ ] API tests (navigation, defaults, inspection)
- [ ] Error tests (malformed input)

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
