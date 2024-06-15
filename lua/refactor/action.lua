local Range = require("refactor.range")

---@alias Source string | number

---@class Action
---@field source Source
---@field range Range
---@field text string
local M = {}
M.__index = M

---@return Action
---@param source Source
---@param cursor Cursor
---@param text string
function M.insert(source, cursor, text)
  local self = setmetatable({}, M)

  self.source = source
  self.range = Range.from_cursor(cursor)
  self.text = text

  return self
end

---@return Action
---@param source Source
---@param range Range
function M.remove(source, range)
  local self = setmetatable({}, M)

  self.source = source
  self.range = range
  self.text = ""

  return self
end

---@return Action
---@param source Source
---@param range Range
function M.replace(source, range, text)
  local self = setmetatable({}, M)

  self.source = source
  self.range = range
  self.text = text

  return self
end

---@return boolean
---@param action Action
function M:compare(action)
  return action.range:compare(self.range)
end

---@return nil
function M:apply()
  local create_new_buffer = false

  ---@type number
  local buf

  if type(self.source) == "number" then
    buf = tonumber(self.source) or 0
  else
    local file_path = self.source
    buf = vim.fn.bufnr(file_path)

    if buf == -1 then
      buf = vim.api.nvim_create_buf(false, true)
      create_new_buffer = true

      vim.api.nvim_buf_call(buf, function()
        vim.cmd("silent edit " .. file_path)
      end)
    end
  end

  local text = vim.split(self.text, "\n")

  vim.api.nvim_buf_set_text(
    buf,
    self.range.start_line,
    self.range.start_col,
    self.range.end_line,
    self.range.end_col,
    text
  )

  if create_new_buffer then
    vim.api.nvim_buf_call(buf, function()
      vim.cmd("silent write")
    end)
  end
end

---@return nil
---@param actions Action[]
function M.apply_many(actions)
  table.sort(actions, M.compare)
  for _, action in pairs(actions) do
    action:apply()
  end
end

return M
