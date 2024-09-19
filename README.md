# Lua-Dotenv

lua-dotenv is a simple Lua module that allows you to load environment variables from a .env file into your Lua environment. It provides an easy way to manage configuration in your Lua projects.

## Features

- Load environment variables from a .env file
- Access environment variables with fallback default values
- Simple and lightweight implementation
- Compatible with Lua 5.1 and above

## Requirements

- Lua >= 5.1

## Installation

Using LuaRocks:

```luarocks install lua-dotenv```

## Usage

1. Create a .env file:

By default, lua-dotenv looks for the .env file in ~/.config/.env. You can also specify a custom location when loading the file.

Example .env file content:

DATABASE_URL=postgresql://user:password@localhost:5432/mydb
DEBUG=true
MAX_CONNECTIONS=100

2. In your Lua script:

local dotenv = require("lua-dotenv")

-- Load variables from default .env file location (~/.config/.env)
dotenv.load_dotenv()

-- Or, specify a custom .env file location
-- dotenv.load_dotenv("/path/to/your/.env")

-- Access environment variables
local db_url = dotenv.get("DATABASE_URL")
local debug_mode = dotenv.get("DEBUG")
local max_conn = dotenv.get("MAX_CONNECTIONS", "50")  -- "50" is the default value

print("Database URL:", db_url)
print("Debug mode:", debug_mode)
print("Max connections:", max_conn)

## Functions

- dotenv.load_dotenv(file_path): Loads environment variables from the specified file path. If no path is provided, it defaults to ~/.config/.env.
- dotenv.get(key, default): Retrieves the value of the environment variable specified by key. If the variable is not set, it returns the default value.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
