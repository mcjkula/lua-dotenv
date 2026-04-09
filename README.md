# lua-dotenv

A minimal, correct Lua module for loading `.env` files. Zero dependencies, Lua 5.1+ compatible.

## Installation

```sh
luarocks install lua-dotenv
```

## Quick start

```
# .env
DATABASE_URL=postgresql://user:password@localhost:5432/mydb
DEBUG=true
MAX_CONNECTIONS=100
```

```lua
local dotenv = require("lua-dotenv")

dotenv.load()  -- loads .env from the current directory

local db_url  = dotenv.get("DATABASE_URL")
local debug_mode = dotenv.get("DEBUG")
local max_conn = dotenv.get("MAX_CONNECTIONS", "50")  -- "50" is the default
```

## API

### `dotenv.load([file_path])` → `true` | `false, err`

Loads variables from `file_path`. Defaults to `.env` in the current working directory.

Returns `true` on success, or `false` plus an error string if the file cannot be opened.

```lua
local ok, err = dotenv.load("/path/to/.env")
if not ok then
  print("could not load config:", err)
end
```

Subsequent calls to `load()` are additive — new keys are added and conflicting keys are overwritten. Use `reset()` between loads when you need isolation.

### `dotenv.get(key [, default])` → value | default | nil

Returns the value for `key` using this priority chain:

1. Variables loaded by `load()` or set by `set()`
2. `os.getenv(key)` (system environment)
3. `default` (if provided)
4. `nil`

```lua
dotenv.get("PORT")           -- nil if not set anywhere
dotenv.get("PORT", "8080")   -- "8080" if not set anywhere
```

### `dotenv.set(key, value)`

Sets a variable directly. Useful for tests or computed values. Pass `nil` as the value to remove a key.

```lua
dotenv.set("ENV", "production")
dotenv.set("OLD_KEY", nil)   -- removes OLD_KEY from loaded vars
```

### `dotenv.reset()`

Clears all variables loaded by `load()` or set by `set()`. Does not affect the real process environment.

```lua
dotenv.reset()
```

## `.env` file format

```sh
# full-line comments are ignored
  # indented comments too

PLAIN=value
SPACED  =  value with spaces     # inline comments are stripped
QUOTED="value with # hash inside"
SINGLE='also works'
EMPTY=                            # stored as empty string ""
export SHELL_COMPAT=works         # export prefix is stripped
URL=https://example.com?a=1&b=2  # = signs in values are fine
COLOR=#FF0000                     # bare # with no preceding space is NOT a comment
```

Rules:
- Keys must be `[A-Za-z0-9_]` only. Lines that don't match are silently skipped.
- Inline comments (`# ...`) are only stripped from **unquoted** values, and only when the `#` is preceded by whitespace.
- Matching quotes (`"..."` or `'...'`) are stripped. Mismatched or unclosed quotes are left as-is.
- Trailing whitespace is trimmed from unquoted values.
- Both Unix (`\n`) and Windows (`\r\n`) line endings are supported.

## Backward compatibility

`dotenv.load_dotenv()` is a deprecated alias for `load()`. It will be removed in a future major version.

## License

MIT — see [LICENSE](LICENSE).
