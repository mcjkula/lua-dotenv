local M = {}
local _vars = {}

local function parse_line(line)
  line = line:gsub("\r$", "")  -- strip \r for CRLF files on Unix

  if line:match("^%s*$") or line:match("^%s*#") then
    return nil
  end

  line = line:match("^%s*export%s+(.+)$") or line

  local key, raw = line:match("^([%w_]+)%s*=%s*(.*)$")
  if not key then return nil end

  raw = raw:match("^(.-)%s*$")

  local q = raw:sub(1, 1)
  if q == '"' or q == "'" then
    local inner = raw:match("^" .. q .. "(.-)" .. q .. "$")  -- matched quotes only
    if inner then return key, inner end
    -- mismatched/unclosed quote: fall through to unquoted handling
  end

  return key, raw:match("^(.-)%s+#.*$") or raw
end

function M.load(file_path)
  file_path = file_path or ".env"
  local file, err = io.open(file_path, "r")
  if not file then
    return false, err
  end
  for line in file:lines() do
    local key, value = parse_line(line)
    if key then _vars[key] = value end
  end
  file:close()
  return true
end

M.load_dotenv = M.load  -- deprecated: use load()

function M.get(key, default)
  local value = _vars[key]
  if value ~= nil then return value end
  value = os.getenv(key)
  if value ~= nil then return value end
  return default
end

function M.set(key, value)
  _vars[key] = value
end

function M.reset()
  _vars = {}
end

return M
