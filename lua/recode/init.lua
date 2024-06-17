local Range = require("recode.range")
local Action = require("recode.action")
local Cursor = require("recode.cursor")
local Lenses = require("recode.lenses")

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

function M.spike()
  local buffer = vim.api.nvim_get_current_buf()
  local range = get_range()
  local recodes = M.lenses:suggestions(buffer, range)

  if #recodes == 0 then
    return
  end

  vim.ui.select(
    vim.tbl_map(function(recode)
      return recode.description()
    end, recodes),
    { prompt = "Refactor" },
    function(_, idx)
      if idx then
        Action.apply_many(recodes[idx].apply(buffer, range))
      end
    end
  )
end

return M
