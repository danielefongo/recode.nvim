local mock = require("luassert.mock")
local helpers = require("tests.helpers")
local Action = require("recode.action")
local Cursor = require("recode.cursor")
local Range = require("recode.range")
local RustExtractMatch = require("tests.example.extract_match")
local RustInlineFunction = require("tests.example.inline_function")
local RustInlineVar = require("tests.example.inline_var")
local RustRename = require("tests.example.rename")
local RustSwapParameter = require("tests.example.swap_parameter")

describe("rust", function()
  helpers.setup()
  local buffer = helpers.buf_with_file("lua/tests/example/src/lsp.rs", "rust")

  it("extract", function()
    local input_mock = mock(vim.fn, true)
    input_mock.input = function()
      return "extracted"
    end

    local actions = helpers.with_lsp(RustExtractMatch.apply, buffer, Range.new(5, 0, 10, 100))
    mock.revert(input_mock)

    assert.are.same({
      Action.insert(buffer, Cursor.new(14, 1), "\n\n" .. [[
fn extracted(param1: i32, param3: i32) -> _ {
  match param1 {
        1 => 1,
        _ => add_one(param3),
    }
}]]),
      Action.remove(buffer, Range.new(5, 12, 8, 5)),
      Action.insert(buffer, Cursor.new(5, 12), [[extracted(param1, param3)]]),
    }, actions)
  end)

  it("rename", function()
    local input_mock = mock(vim.fn, true)
    input_mock.input = function()
      return "renamed"
    end

    local actions = helpers.with_lsp(RustRename.apply, buffer, Range.new(7, 21, 7, 21))
    mock.revert(input_mock)

    assert.are.same({
      Action.remove(vim.fn.getcwd() .. "/lua/tests/example/src/lsp.rs", Range.new(7, 21, 7, 27)),
      Action.insert(vim.fn.getcwd() .. "/lua/tests/example/src/lsp.rs", Cursor.new(7, 21), "renamed"),
      Action.remove(vim.fn.getcwd() .. "/lua/tests/example/src/lsp.rs", Range.new(3, 8, 3, 14)),
      Action.insert(vim.fn.getcwd() .. "/lua/tests/example/src/lsp.rs", Cursor.new(3, 8), "renamed"),
    }, actions)
  end)

  it("swap parameter", function()
    local input_mock = mock(vim.fn, true)
    local count = 1
    input_mock.input = function()
      local out = tostring(count)
      count = count + 1
      return out
    end

    local actions = helpers.with_lsp(RustSwapParameter.apply, buffer, Range.new(7, 21, 7, 21))
    mock.revert(input_mock)

    assert.are.same({
      Action.replace(buffer, Range.new(2, 32, 2, 43), "param1: i32"),
      Action.replace(buffer, Range.new(2, 19, 2, 30), "param2: i32"),
      Action.replace(vim.fn.getcwd() .. "/lua/tests/example/src/lib.rs", Range.new(6, 19, 6, 20), "1"),
      Action.replace(vim.fn.getcwd() .. "/lua/tests/example/src/lib.rs", Range.new(6, 16, 6, 17), "2"),
    }, actions)
  end)

  it("inline function", function()
    local actions = helpers.with_lsp(RustInlineFunction.apply, buffer, Range.new(7, 15, 7, 15))
    assert.are.same({
      Action.replace(
        buffer,
        Range.new(7, 13, 7, 28),
        [[{
    let param3_2 = 4;
    param3 + 1
}]]
      ),
    }, actions)
  end)

  it("inline var", function()
    local actions = helpers.with_lsp(RustInlineVar.apply, buffer, Range.new(7, 21, 7, 21))
    assert.are.same({
      Action.replace(buffer, Range.new(7, 21, 7, 27), "3"),
    }, actions)
  end)
end)
