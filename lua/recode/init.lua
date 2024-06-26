local Range = require("recode.range")
local Action = require("recode.action")
local Cursor = require("recode.cursor")
local Lenses = require("recode.lenses")

local M = {
  lenses = Lenses.new(),
}

local function get_range()
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "" or vim.fn.visualmode() ~= "" then
    local _, start_row, start_col, _ = unpack(vim.fn.getpos("'<"))
    local _, end_row, end_col, _ = unpack(vim.fn.getpos("'>"))
    return Range.from_vim({ start_row - 1, start_col - 1, end_row - 1, end_col - 1 })
  else
    local vim_cursor = vim.api.nvim_win_get_cursor(0)
    local cursor = Cursor.from_vim(vim_cursor)
    return Range.from_cursor(cursor)
  end
end

function M.register(refactors)
  M.lenses:register_many(refactors)
end

function M.run()
  local buffer = vim.api.nvim_get_current_buf()
  local range = get_range()
  local refactors = M.lenses:suggestions(buffer, range)

  if #refactors == 0 then
    return
  end

  vim.ui.select(
    vim.tbl_map(function(refactor)
      return refactor.description()
    end, refactors),
    { prompt = "Refactor" },
    function(_, idx)
      if idx then
        local opts = refactors[idx].prompt()
        Action.apply_many(refactors[idx].apply(buffer, range, opts))
      end
    end
  )
end

return M
