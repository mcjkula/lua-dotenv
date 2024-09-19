local M = {}

function M.get(key, default)
  local value = os.getenv(key)
  if value == nil then
    return default
  end
  return value
end

function M.load_dotenv(file_path)
  for line in io.lines(file_path or ".env") do
    local key, value = line:match("^(%w+)%s*=%s*(.+)$")
    if key and value then
      value = value:gsub("^[\"'](.-)[\"\']$", "%1")
      os.setenv(key, value)
    end
  end
end

return M
