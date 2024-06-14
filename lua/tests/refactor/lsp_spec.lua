local helpers = require("tests.helpers")
local Lsp = require("refactor.lsp")
local Range = require("refactor.range")
local Cursor = require("refactor.cursor")

describe("lsp", function()
  helpers.setup()
  local buf, win = helpers.buf_with_file("./lua/tests/example/src/lsp.rs", "rust")

  describe("same file", function()
    it("definition", function()
      local definition = helpers.with_lsp(Lsp.definition, buf, Cursor.new(5, 18))

      assert.are.same({
        range = Range.new(2, 15, 2, 21),
        file = string.format("%s/lua/tests/example/src/lsp.rs", vim.fn.getcwd()),
      }, definition)
    end)

    it("references", function()
      local references = helpers.with_lsp(Lsp.references, buf, Cursor.new(5, 18))

      assert.are.same({
        {
          range = Range.new(5, 18, 5, 24),
          file = string.format("%s/lua/tests/example/src/lsp.rs", vim.fn.getcwd()),
        },
        {
          range = Range.new(2, 15, 2, 21),
          file = string.format("%s/lua/tests/example/src/lsp.rs", vim.fn.getcwd()),
        },
      }, references)
    end)
  end)

  describe("other file", function()
    it("definition", function()
      local definition = helpers.with_lsp(Lsp.definition, buf, Cursor.new(7, 13))

      assert.are.same({
        range = Range.new(0, 0, 2, 1),
        file = string.format("%s/lua/tests/example/src/common.rs", vim.fn.getcwd()),
      }, definition)
    end)

    it("references", function()
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
end)
