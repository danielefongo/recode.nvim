local helpers = require("tests.helpers")
local Lsp = require("refactor.lsp")
local Range = require("refactor.range")

describe("lsp", function()
  helpers.setup()

  describe("same file", function()
    it("definition", function()
      local buf, win = helpers.buf_with_file("./lua/tests/example/src/lsp.rs", "rust")
      vim.api.nvim_win_set_cursor(win, { 6, 18 })

      local definition = helpers.async(600, Lsp.definition, win, buf)

      assert.are.same({
        range = Range.new(2, 15, 2, 21),
        file = string.format("%s/lua/tests/example/src/lsp.rs", vim.fn.getcwd()),
      }, definition)
    end)

    it("references", function()
      local buf, win = helpers.buf_with_file("./lua/tests/example/src/lsp.rs", "rust")
      vim.api.nvim_win_set_cursor(win, { 6, 18 })

      local references = helpers.async(600, Lsp.references, win, buf)

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
      local buf, win = helpers.buf_with_file("./lua/tests/example/src/lsp.rs", "rust")
      vim.api.nvim_win_set_cursor(win, { 8, 13 })

      local definition = helpers.async(600, Lsp.definition, win, buf)

      assert.are.same({
        range = Range.new(0, 0, 2, 1),
        file = string.format("%s/lua/tests/example/src/common.rs", vim.fn.getcwd()),
      }, definition)
    end)

    it("references", function()
      local buf, win = helpers.buf_with_file("./lua/tests/example/src/lsp.rs", "rust")
      vim.api.nvim_win_set_cursor(win, { 8, 13 })

      local references = helpers.async(600, Lsp.references, win, buf)

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
