local helpers = require("tests.helpers")
local Action = require("recode.action")
local Range = require("recode.range")
local Cursor = require("recode.cursor")

describe("action", function()
  helpers.setup()

  local function assert_text_in_buf(buffer, text)
    assert.are.same(text, table.concat(vim.api.nvim_buf_get_lines(buffer, 0, -1, true), "\n"))
  end

  local function assert_text_in_file(file, text)
    assert.are.same(text, io.open(file, "r"):read("*a"))
  end

  describe("insert", function()
    it("buffer", function()
      local buffer = helpers.buf_with_text([[
simple text
inside a buffer
]])

      Action.insert(buffer, Cursor.new(1, 9), "modified "):apply()

      assert_text_in_buf(
        buffer,
        [[
simple text
inside a modified buffer
]]
      )
    end)

    it("file", function()
      local filename = helpers.temp_file([[
simple text
inside a buffer
]])

      Action.insert(filename, Cursor.new(1, 9), "modified "):apply()

      assert_text_in_file(
        filename,
        [[
simple text
inside a modified buffer
]]
      )
    end)

    it("opened file", function()
      local filename = helpers.temp_file([[
simple text
inside a buffer
]])

      local buffer = helpers.buf_with_file(filename, "text")

      Action.insert(filename, Cursor.new(1, 9), "modified "):apply()

      assert_text_in_file(
        filename,
        [[
simple text
inside a buffer
]]
      )

      assert_text_in_buf(
        buffer,
        [[
simple text
inside a modified buffer]]
      )
    end)
  end)

  describe("remove", function()
    it("buffer", function()
      local buffer = helpers.buf_with_text([[
simple text
inside a <remove this> buffer
]])

      Action.remove(buffer, Range.new(1, 9, 1, 23)):apply()

      assert_text_in_buf(
        buffer,
        [[
simple text
inside a buffer
]]
      )
    end)

    it("file", function()
      local filename = helpers.temp_file([[
simple text
inside a <remove this> buffer
]])

      Action.remove(filename, Range.new(1, 9, 1, 23)):apply()

      assert_text_in_file(
        filename,
        [[
simple text
inside a buffer
]]
      )
    end)

    it("opened file", function()
      local filename = helpers.temp_file([[
simple text
inside a <remove this> buffer
]])
      local buffer = helpers.buf_with_file(filename, "text")

      Action.remove(filename, Range.new(1, 9, 1, 23)):apply()

      assert_text_in_file(
        filename,
        [[
simple text
inside a <remove this> buffer
]]
      )

      assert_text_in_buf(
        buffer,
        [[
simple text
inside a buffer]]
      )
    end)
  end)

  describe("many", function()
    it("already in order", function()
      local buffer = helpers.buf_with_text([[
simple text
inside a buffer
]])

      Action.apply_many({
        Action.insert(buffer, Cursor.new(1, 9), "modified "),
        Action.insert(buffer, Cursor.new(1, 8), "n extra"),
      })

      assert_text_in_buf(
        buffer,
        [[
simple text
inside an extra modified buffer
]]
      )
    end)

    it("not in order", function()
      local buffer = helpers.buf_with_text([[
simple text
inside a buffer
]])

      Action.apply_many({
        Action.insert(buffer, Cursor.new(1, 8), "n extra"),
        Action.insert(buffer, Cursor.new(1, 9), "modified "),
      })

      assert_text_in_buf(
        buffer,
        [[
simple text
inside an extra modified buffer
]]
      )
    end)

    it("remove and insert", function()
      local buffer = helpers.buf_with_text([[
simple text
inside a buffer
]])

      Action.apply_many({
        Action.insert(buffer, Cursor.new(0, 6), " changed"),
        Action.remove(buffer, Range.new(0, 6, 1, 8)),
      })

      assert_text_in_buf(
        buffer,
        [[
simple changed buffer
]]
      )
    end)
  end)

  describe("replace", function()
    it("buffer", function()
      local buffer = helpers.buf_with_text([[
simple text
inside a buffer
]])

      Action.replace(buffer, Range.new(0, 0, 0, 6), "a"):apply()

      assert_text_in_buf(
        buffer,
        [[
a text
inside a buffer
]]
      )
    end)

    it("file", function()
      local filename = helpers.temp_file([[
simple text
inside a buffer
]])

      Action.replace(filename, Range.new(0, 0, 0, 6), "a"):apply()

      assert_text_in_file(
        filename,
        [[
a text
inside a buffer
]]
      )
    end)

    it("opened file", function()
      local filename = helpers.temp_file([[
simple text
inside a buffer
]])

      local buffer = helpers.buf_with_file(filename, "text")

      Action.replace(filename, Range.new(0, 0, 0, 6), "a"):apply()

      assert_text_in_file(
        filename,
        [[
simple text
inside a buffer
]]
      )

      assert_text_in_buf(
        buffer,
        [[
a text
inside a buffer]]
      )
    end)
  end)
end)
