local helpers = require("tests.helpers")
local Lsp = require("recode.lsp")
local Range = require("recode.range")
local Cursor = require("recode.cursor")

describe("lsp", function()
  helpers.setup()
  local code
  local shared
  local user

  before_each(function()
    code = helpers.buf_with_fake_file(
      "lua/tests/example/src/code.rs",
      "rust",
      [[
use crate::shared::add_one;

pub fn my_function(param1: i32, param2: i32) {
    let param3: i32 = 3;
    let param4: i32 = 3;
    let x = match param1 {
        1 => 1,
        _ => add_one(param3),
    };
    match 1 {
        1 => 1,
        _ => add_one(param4),
    };
    let add_one: fn(i32) -> i32 = |_| 42;
}
]]
    )

    shared = helpers.buf_with_fake_file(
      "lua/tests/example/src/shared.rs",
      "rust",
      [[
pub fn add_one(param1: i32) -> i32 {
    let param3 = 4;
    param1 + 1
}]]
    )

    user = helpers.buf_with_fake_file(
      "lua/tests/example/src/user.rs",
      "rust",
      [[
use crate::code;
pub fn main() {
  let _ = code::my_function(1, 2);
}]]
    )
  end)

  after_each(function()
    vim.api.nvim_buf_delete(code, { force = true })
    vim.api.nvim_buf_delete(shared, { force = true })
    vim.api.nvim_buf_delete(user, { force = true })
  end)

  describe("definition", function()
    it("same file", function()
      local definition = helpers.with_lsp(Lsp.definition, code, Cursor.new(5, 18))

      assert.are.same({
        range = Range.new(2, 19, 2, 25),
        file = string.format("%s/lua/tests/example/src/code.rs", vim.fn.getcwd()),
      }, definition)
    end)

    it("other file", function()
      local definition = helpers.with_lsp(Lsp.definition, code, Cursor.new(7, 13))

      assert.are.same({
        range = Range.new(0, 0, 3, 1),
        file = string.format("%s/lua/tests/example/src/shared.rs", vim.fn.getcwd()),
      }, definition)
    end)
  end)

  describe("references", function()
    it("same file", function()
      local references = helpers.with_lsp(Lsp.references, code, Cursor.new(5, 18))

      assert.are.same({
        {
          range = Range.new(5, 18, 5, 24),
          file = string.format("%s/lua/tests/example/src/code.rs", vim.fn.getcwd()),
        },
        {
          range = Range.new(2, 19, 2, 25),
          file = string.format("%s/lua/tests/example/src/code.rs", vim.fn.getcwd()),
        },
      }, references)
    end)

    it("other file", function()
      local references = helpers.with_lsp(Lsp.references, code, Cursor.new(7, 13))

      assert.are.same({
        {
          range = Range.new(0, 19, 0, 26),
          file = string.format("%s/lua/tests/example/src/code.rs", vim.fn.getcwd()),
        },
        {
          range = Range.new(7, 13, 7, 20),
          file = string.format("%s/lua/tests/example/src/code.rs", vim.fn.getcwd()),
        },
        {
          range = Range.new(11, 13, 11, 20),
          file = string.format("%s/lua/tests/example/src/code.rs", vim.fn.getcwd()),
        },
        {
          range = Range.new(0, 7, 0, 14),
          file = string.format("%s/lua/tests/example/src/shared.rs", vim.fn.getcwd()),
        },
      }, references)
    end)
  end)

  describe("incoming calls", function()
    it("same file", function()
      local references = helpers.with_lsp(Lsp.incoming_calls, code, Cursor.new(7, 14))

      assert.are.same({
        {
          range = Range.new(7, 13, 7, 20),
          file = string.format("%s/lua/tests/example/src/code.rs", vim.fn.getcwd()),
        },
        {
          range = Range.new(11, 13, 11, 20),
          file = string.format("%s/lua/tests/example/src/code.rs", vim.fn.getcwd()),
        },
      }, references)
    end)

    it("other file", function()
      local references = helpers.with_lsp(Lsp.incoming_calls, code, Cursor.new(2, 7))

      assert.are.same({
        {
          range = Range.new(2, 16, 2, 27),
          file = string.format("%s/lua/tests/example/src/user.rs", vim.fn.getcwd()),
        },
      }, references)
    end)
  end)
end)
