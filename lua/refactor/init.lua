local Range = require("refactor.range")
local Action = require("refactor.action")
local Cursor = require("refactor.cursor")
local Rust = require("tests.example.rust")

local M = {}

local function with_cursor(fun, ...)
  local buffer = vim.api.nvim_get_current_buf()
  local cursor = Cursor.from_vim(vim.api.nvim_win_get_cursor(0))

  local actions = fun(buffer, Range.from_cursors(cursor, cursor), ...)
  Action.apply_many(actions)
end

function M.inline_function()
  with_cursor(Rust.inline_function)
end

function M.inline_var()
  with_cursor(Rust.inline_var)
end

function M.swap_params(first_idx, sedond_idx)
  with_cursor(Rust.swap, { from = first_idx, to = sedond_idx })
end

function M.rename(name)
  with_cursor(Rust.rename, { name = name })
end

return M
