local helpers = require("tests.helpers")
local Lsp = require("recode.lsp")
local Range = require("recode.range")
local Cursor = require("recode.cursor")

describe("lsp", function()
  helpers.setup()
  local buf, win = helpers.buf_with_file("./lua/tests/example/src/lsp.rs", "rust")

  describe("definition", function()
    it("same file", function()
      local definition = helpers.with_lsp(Lsp.definition, buf, Cursor.new(5, 18))

      assert.are.same({
        range = Range.new(2, 19, 2, 25),
        file = string.format("%s/lua/tests/example/src/lsp.rs", vim.fn.getcwd()),
      }, definition)
    end)

    it("other file", function()
      local definition = helpers.with_lsp(Lsp.definition, buf, Cursor.new(7, 13))

      assert.are.same({
        range = Range.new(0, 0, 3, 1),
        file = string.format("%s/lua/tests/example/src/common.rs", vim.fn.getcwd()),
      }, definition)
    end)
  end)

  describe("references", function()
    it("same file", function()
      local references = helpers.with_lsp(Lsp.references, buf, Cursor.new(5, 18))

      assert.are.same({
        {
          range = Range.new(5, 18, 5, 24),
          file = string.format("%s/lua/tests/example/src/lsp.rs", vim.fn.getcwd()),
        },
        {
          range = Range.new(2, 19, 2, 25),
          file = string.format("%s/lua/tests/example/src/lsp.rs", vim.fn.getcwd()),
        },
      }, references)
    end)

    it("other file", function()
      local references = helpers.with_lsp(Lsp.references, buf, Cursor.new(7, 13))

      assert.are.same({
        {
          range = Range.new(0, 19, 0, 26),
          file = string.format("%s/lua/tests/example/src/lsp.rs", vim.fn.getcwd()),
        },
        {
          range = Range.new(7, 13, 7, 20),
          file = string.format("%s/lua/tests/example/src/lsp.rs", vim.fn.getcwd()),
        },
        {
          range = Range.new(11, 13, 11, 20),
          file = string.format("%s/lua/tests/example/src/lsp.rs", vim.fn.getcwd()),
        },
        {
          range = Range.new(0, 7, 0, 14),
          file = string.format("%s/lua/tests/example/src/common.rs", vim.fn.getcwd()),
        },
      }, references)
    end)
  end)

  describe("incoming calls", function()
    it("same file", function()
      local references = helpers.with_lsp(Lsp.incoming_calls, buf, Cursor.new(7, 14))

      assert.are.same({
        {
          range = Range.new(7, 13, 7, 20),
          file = string.format("%s/lua/tests/example/src/lsp.rs", vim.fn.getcwd()),
        },
        {
          range = Range.new(11, 13, 11, 20),
          file = string.format("%s/lua/tests/example/src/lsp.rs", vim.fn.getcwd()),
        },
      }, references)
    end)

    it("other file", function()
      local references = helpers.with_lsp(Lsp.incoming_calls, buf, Cursor.new(2, 7))

      assert.are.same({
        {
          range = Range.new(6, 4, 6, 15),
          file = string.format("%s/lua/tests/example/src/lib.rs", vim.fn.getcwd()),
        },
      }, references)
    end)
  end)
end)
