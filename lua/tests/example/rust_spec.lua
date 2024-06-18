local helpers = require("tests.helpers")
local Range = require("recode.range")
local RustExtractMatch = require("tests.example.extract_match")
local RustInlineFunction = require("tests.example.inline_function")
local RustInlineVar = require("tests.example.inline_var")
local RustRename = require("tests.example.rename")
local RustSwapParameter = require("tests.example.swap_parameter")

local function register_buffer(buffers, filename, text)
  buffers[filename] = helpers.buf_with_fake_file(filename, "rust", text)
  return buffers[filename]
end

local function apply_actions(buffers, actions)
  for _, buffer in pairs(buffers) do
    helpers.buf_apply_actions(buffer, actions)
  end
end

describe("rust", function()
  helpers.setup()

  local buffers = {}

  after_each(function()
    for _, buffer in pairs(buffers) do
      vim.api.nvim_buf_delete(buffer, { force = false, unload = true })
    end
    buffers = {}
  end)

  it("extract", function()
    local main = register_buffer(
      buffers,
      "lua/tests/example/src/code.rs",
      [[
use crate::common::add_one;

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
}]]
    )

    local actions = helpers.with_lsp(RustExtractMatch.apply, main, Range.new(5, 0, 10, 100), { name = "extracted" })

    apply_actions(buffers, actions)

    assert.are.same(
      [[
use crate::common::add_one;

pub fn my_function(param1: i32, param2: i32) {
    let param3: i32 = 3;
    let param4: i32 = 3;
    let x = extracted(param1, param3);
    match 1 {
        1 => 1,
        _ => add_one(param4),
    };
    let add_one: fn(i32) -> i32 = |_| 42;
}

fn extracted(param1: i32, param3: i32) -> _ {
  match param1 {
        1 => 1,
        _ => add_one(param3),
    }
}]],
      helpers.buf_read(main)
    )
  end)

  it("rename", function()
    local main = register_buffer(
      buffers,
      "lua/tests/example/src/code.rs",
      [[
pub fn my_function(param1: i32, param2: i32) {
  let param2 = param2 + 1;
}]]
    )

    local actions = helpers.with_lsp(RustRename.apply, main, Range.new(1, 15, 1, 16), { name = "renamed" })

    apply_actions(buffers, actions)

    assert.are.same(
      [[
pub fn my_function(param1: i32, renamed: i32) {
  let param2 = renamed + 1;
}]],
      helpers.buf_read(main)
    )
  end)

  it("swap parameter", function()
    local lib = register_buffer(
      buffers,
      "lua/tests/example/src/user.rs",
      [[
use crate::code;
pub fn main() {
  let _ = code::my_function(1, 2);
}]]
    )

    local main = register_buffer(
      buffers,
      "lua/tests/example/src/code.rs",
      [[
pub fn my_function(param1: i32, param2: i32) {
  let param2 = param2 + 1;
}]]
    )

    local actions = helpers.with_lsp(RustSwapParameter.apply, main, Range.new(1, 0, 1, 0), { from = 1, to = 2 })

    apply_actions(buffers, actions)

    assert.are.same(
      [[
pub fn my_function(param2: i32, param1: i32) {
  let param2 = param2 + 1;
}]],
      helpers.buf_read(main)
    )

    assert.are.same(
      [[
use crate::code;
pub fn main() {
  let _ = code::my_function(2, 1);
}]],
      helpers.buf_read(lib)
    )
  end)

  it("inline function", function()
    local main = register_buffer(
      buffers,
      "lua/tests/example/src/code.rs",
      [[
use crate::shared::add_one;

pub fn my_function(param1: i32, param2: i32) {
    add_one(param3);
}
]]
    )

    register_buffer(
      buffers,
      "lua/tests/example/src/shared.rs",
      [[
pub fn add_one(param1: i32) -> i32 {
    let param3 = 4;
    param1 + 1
}]]
    )

    local actions = helpers.with_lsp(RustInlineFunction.apply, main, Range.new(3, 4, 3, 4), { from = 1, to = 2 })

    apply_actions(buffers, actions)

    assert.are.same(
      [[
use crate::shared::add_one;

pub fn my_function(param1: i32, param2: i32) {
    {
    let param3_2 = 4;
    param3 + 1
};
}
]],
      helpers.buf_read(main)
    )
  end)

  it("inline var", function()
    local main = register_buffer(
      buffers,
      "lua/tests/example/src/code.rs",
      [[
use crate::common::add_one;

pub fn my_function() {
    let var1: i32 = 1;
    let var2: i32 = var1 + 2;
}]]
    )

    local actions = helpers.with_lsp(RustInlineVar.apply, main, Range.new(4, 20, 4, 20))

    apply_actions(buffers, actions)

    assert.are.same(
      [[
use crate::common::add_one;

pub fn my_function() {
    let var1: i32 = 1;
    let var2: i32 = 1 + 2;
}]],
      helpers.buf_read(main)
    )
  end)
end)
