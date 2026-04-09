package.preload["lua-dotenv"] = function()  -- use local dotenv.lua, not any installed version
  return dofile("dotenv.lua")
end

local dotenv

local function env_file(content)
  local path = os.tmpname()
  local f = assert(io.open(path, "w"))
  f:write(content)
  f:close()
  return path
end

describe("lua-dotenv", function()

  before_each(function()
    package.loaded["lua-dotenv"] = nil
    dotenv = require("lua-dotenv")
  end)

  describe("load()", function()

    it("returns true on success", function()
      local ok = dotenv.load(env_file("KEY=val\n"))
      assert.is_true(ok)
    end)

    it("returns false and an error string when file is missing", function()
      local ok, err = dotenv.load("/tmp/this_file_should_not_exist_lua_dotenv.env")
      assert.is_false(ok)
      assert.is_string(err)
    end)

    it("defaults to .env in the current directory", function()
      local ok = dotenv.load()
      assert.is_boolean(ok)  -- file may or may not exist
    end)

    it("is additive across multiple calls", function()
      dotenv.load(env_file("A=first\n"))
      dotenv.load(env_file("B=second\n"))
      assert.equal("first",  dotenv.get("A"))
      assert.equal("second", dotenv.get("B"))
    end)

    it("second load overwrites a duplicate key", function()
      dotenv.load(env_file("KEY=original\n"))
      dotenv.load(env_file("KEY=overwritten\n"))
      assert.equal("overwritten", dotenv.get("KEY"))
    end)

  end)

  describe("load_dotenv() alias", function()

    it("is still callable (backward compat)", function()
      local ok = dotenv.load_dotenv(env_file("COMPAT=yes\n"))
      assert.is_true(ok)
      assert.equal("yes", dotenv.get("COMPAT"))
    end)

  end)

  describe("get()", function()

    it("returns the loaded value", function()
      dotenv.load(env_file("NAME=Alice\n"))
      assert.equal("Alice", dotenv.get("NAME"))
    end)

    it("returns the default when key is absent", function()
      assert.equal("fallback", dotenv.get("NO_SUCH_KEY", "fallback"))
    end)

    it("returns nil when key is absent and no default given", function()
      assert.is_nil(dotenv.get("NO_SUCH_KEY"))
    end)

    it("falls back to os.getenv for keys not in the file", function()
      local expected = os.getenv("PATH")
      if expected then  -- PATH is always set in a normal shell environment
        assert.equal(expected, dotenv.get("PATH"))
      end
    end)

    it("loaded value takes priority over os.getenv", function()
      if os.getenv("PATH") then
        dotenv.load(env_file("PATH=custom_value\n"))
        assert.equal("custom_value", dotenv.get("PATH"))
      end
    end)

    it("returns empty string for explicitly empty values (not nil)", function()
      dotenv.load(env_file("EMPTY=\n"))
      -- empty string ~= nil, so the default must not apply
      assert.equal("", dotenv.get("EMPTY", "should-not-appear"))
    end)

  end)

  describe("set()", function()

    it("stores a value retrievable by get()", function()
      dotenv.set("INJECTED", "hello")
      assert.equal("hello", dotenv.get("INJECTED"))
    end)

    it("set(key, nil) removes the key so os.getenv fallback applies", function()
      dotenv.set("MYKEY", "value")
      dotenv.set("MYKEY", nil)
      assert.is_nil(dotenv.get("MYKEY"))
    end)

    it("programmatic set takes priority over os.getenv", function()
      if os.getenv("PATH") then
        dotenv.set("PATH", "overridden")
        assert.equal("overridden", dotenv.get("PATH"))
      end
    end)

  end)

  describe("reset()", function()

    it("clears all loaded variables", function()
      dotenv.load(env_file("SECRET=abc\n"))
      dotenv.reset()
      assert.is_nil(dotenv.get("SECRET"))
    end)

    it("clears programmatically set variables", function()
      dotenv.set("FOO", "bar")
      dotenv.reset()
      assert.is_nil(dotenv.get("FOO"))
    end)

  end)

  describe("parsing", function()

    local function load(content)
      dotenv.load(env_file(content))
    end

    it("parses a plain KEY=value line", function()
      load("KEY=value\n")
      assert.equal("value", dotenv.get("KEY"))
    end)

    it("allows whitespace around the = sign", function()
      load("KEY  =  value\n")
      assert.equal("value", dotenv.get("KEY"))
    end)

    it("handles values that contain = signs (e.g. URLs)", function()
      load("URL=https://example.com?a=1&b=2\n")
      assert.equal("https://example.com?a=1&b=2", dotenv.get("URL"))
    end)

    it("strips double-quoted values", function()
      load('DQUOTE="hello world"\n')
      assert.equal("hello world", dotenv.get("DQUOTE"))
    end)

    it("strips single-quoted values", function()
      load("SQUOTE='hello world'\n")
      assert.equal("hello world", dotenv.get("SQUOTE"))
    end)

    it("does NOT strip mismatched quotes", function()
      load('MIXED="hello world\'\n')
      local v = dotenv.get("MIXED")
      assert.is_string(v)
      assert.not_equal("hello world", v)
    end)

    it("stores empty value as empty string (not nil)", function()
      load("EMPTY=\n")
      assert.equal("", dotenv.get("EMPTY"))
    end)

    it("trims trailing whitespace from unquoted values", function()
      load("KEY=value   \n")
      assert.equal("value", dotenv.get("KEY"))
    end)

    it("strips inline comments (whitespace + # + rest)", function()
      load("PORT=8080 # default port\n")
      assert.equal("8080", dotenv.get("PORT"))
    end)

    it("does NOT strip # that is part of the value (no preceding space)", function()
      load("COLOR=#FF0000\n")
      assert.equal("#FF0000", dotenv.get("COLOR"))
    end)

    it("does NOT strip # inside a double-quoted value", function()
      load('MSG="hello # world"\n')
      assert.equal("hello # world", dotenv.get("MSG"))
    end)

    it("skips blank lines", function()
      load("\n\nKEY=value\n\n")
      assert.equal("value", dotenv.get("KEY"))
    end)

    it("skips full-line comments starting with #", function()
      load("# this is a comment\nFOO=bar\n")
      assert.equal("bar", dotenv.get("FOO"))
    end)

    it("skips indented comments", function()
      load("   # indented comment\nFOO=baz\n")
      assert.equal("baz", dotenv.get("FOO"))
    end)

    it("handles export KEY=value prefix", function()
      load("export FOO=bar\n")
      assert.equal("bar", dotenv.get("FOO"))
    end)

    it("handles export with multiple spaces", function()
      load("export   FOO=bar\n")
      assert.equal("bar", dotenv.get("FOO"))
    end)

    it("handles Windows CRLF line endings", function()
      load("CRLF=value\r\n")
      assert.equal("value", dotenv.get("CRLF"))
    end)

    it("handles values with spaces when unquoted", function()
      load("GREETING=Hello World\n")
      assert.equal("Hello World", dotenv.get("GREETING"))
    end)

    it("ignores lines with keys containing hyphens", function()
      load("MY-KEY=value\n")
      assert.is_nil(dotenv.get("MY-KEY"))
    end)

    it("accepts numeric keys", function()
      load("KEY123=numval\n")
      assert.equal("numval", dotenv.get("KEY123"))
    end)

  end)

end)
