local Range = require("refactor.range")

---@class Action
---@field type "insert"|"remove"
---@field source number
---@field range Range
---@field text string
local M = {}
M.__index = M

---@return Action
---@param source number
---@param cursor Cursor
---@param text string
function M.insert(source, cursor, text)
  local self = setmetatable({}, M)

  self.type = "insert"
  self.source = source
  self.range = Range.from_cursor(cursor)
  self.text = text

  return self
end

---@return Action
---@param source number
---@param range Range
function M.remove(source, range)
  local self = setmetatable({}, M)

  self.type = "remove"
  self.source = source
  self.range = range
  self.text = ""

  return self
end

---@return boolean
---@param action Action
function M:compare(action)
  return action.range:compare(self.range)
end

---@return nil
function M:apply()
  if type(self.source) == "number" then
    local text = {}
    if self.type == "insert" then
      text = vim.split(self.text, "\n")
    end

    vim.api.nvim_buf_set_text(
      self.source,
      self.range.start_line,
      self.range.start_col,
      self.range.end_line,
      self.range.end_col,
      text
    )
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
