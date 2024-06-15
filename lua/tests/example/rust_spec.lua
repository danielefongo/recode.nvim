local helpers = require("tests.helpers")
local rust = require("tests.example.rust")
local range = require("refactor.range")
local cursor = require("refactor.cursor")
local action = require("refactor.action")

describe("rust", function()
  helpers.setup()
  local buffer = helpers.buf_with_file("lua/tests/example/src/lsp.rs", "rust")

  it("extract", function()
    local actions = helpers.with_lsp(rust.extract_match, buffer, range.new(5, 0, 10, 100), { name = "extracted" })
    assert.are.same({
      action.insert(buffer, cursor.new(14, 1), "\n\n" .. [[
fn extracted(param1: i32, param3: i32) -> _ {
  match param1 {
        1 => 1,
        _ => add_one(param3),
    }
}]]),
      action.remove(buffer, range.new(5, 12, 8, 5)),
      action.insert(buffer, cursor.new(5, 12), [[extracted(param1, param3)]]),
    }, actions)
  end)

  it("rename", function()
    local actions = helpers.with_lsp(rust.rename, buffer, range.new(7, 21, 7, 21), { name = "renamed" })
    assert.are.same({
      action.remove(vim.fn.getcwd() .. "/lua/tests/example/src/lsp.rs", range.new(7, 21, 7, 27)),
      action.insert(vim.fn.getcwd() .. "/lua/tests/example/src/lsp.rs", cursor.new(7, 21), "renamed"),
      action.remove(vim.fn.getcwd() .. "/lua/tests/example/src/lsp.rs", range.new(3, 8, 3, 14)),
      action.insert(vim.fn.getcwd() .. "/lua/tests/example/src/lsp.rs", cursor.new(3, 8), "renamed"),
    }, actions)
  end)

  it("swap", function()
    local actions = helpers.with_lsp(rust.swap, buffer, range.new(7, 21, 7, 21), { from = 1, to = 2 })
    assert.are.same({
      action.replace(buffer, range.new(2, 32, 2, 43), "param1: i32"),
      action.replace(buffer, range.new(2, 19, 2, 30), "param2: i32"),
      action.replace(vim.fn.getcwd() .. "/lua/tests/example/src/lib.rs", range.new(6, 19, 6, 20), "1"),
      action.replace(vim.fn.getcwd() .. "/lua/tests/example/src/lib.rs", range.new(6, 16, 6, 17), "2"),
    }, actions)
  end)

  it("inline function", function()
    local actions = helpers.with_lsp(rust.inline_function, buffer, range.new(7, 15, 7, 15))
    assert.are.same({
      action.replace(
        buffer,
        range.new(7, 13, 7, 28),
        [[{
    let param3_2 = 4;
    param3 + 1
}]]
      ),
    }, actions)
  end)

  it("inline var", function()
    local actions = helpers.with_lsp(rust.inline_var, buffer, range.new(7, 21, 7, 21))
    assert.are.same({
      action.replace(buffer, range.new(7, 21, 7, 27), "3"),
    }, actions)
  end)
end)
