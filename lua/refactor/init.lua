local Range = require("refactor.range")
local Action = require("refactor.action")
local Cursor = require("refactor.cursor")
local Lenses = require("refactor.lenses")

local M = {
  lenses = Lenses.new(),
}

M.lenses:register_many({
  require("tests.example.extract_match"),
  require("tests.example.inline_function"),
  require("tests.example.inline_var"),
  require("tests.example.rename"),
  require("tests.example.swap_parameter"),
})

function M.spike()
  local buffer = vim.api.nvim_get_current_buf()
  local cursor = Cursor.from_vim(vim.api.nvim_win_get_cursor(0))
  local range = Range.from_cursors(cursor, cursor)
  local refactors = M.lenses:suggestions(buffer, range)

  vim.ui.select(
    vim.tbl_map(function(refactor)
      return refactor.description()
    end, refactors),
    { prompt = "Refactor" },
    function(_, idx)
      if idx then
        Action.apply_many(refactors[idx].apply(buffer, range))
      end
    end
  )
end

return M
