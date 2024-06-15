local Cursor = require("refactor.cursor")

---@class Range
---@field start_line integer
---@field start_col integer
---@field end_line integer
---@field end_col integer
local M = {}
M.__index = M

---@alias TreesitterRange table {start_line, start_col, end_line, end_col}, 0 based

---@return boolean
---@param cursor Cursor
function M:contains_cursor(cursor)
  if cursor.line < self.start_line or cursor.line > self.end_line then
    return false
  elseif cursor.line == self.start_line and cursor.col < self.start_col then
    return false
  elseif cursor.line == self.end_line and cursor.col >= self.end_col then
    return false
  end
  return true
end

---@return boolean
---@param range Range
function M:contains_range(range)
  if vim.deep_equal(self, range) then
    return false
  end
  if
    range.start_line < self.start_line or (range.start_line == self.start_line and range.start_col < self.start_col)
  then
    return false
  end
  if range.end_line > self.end_line or (range.end_line == self.end_line and range.end_col > self.end_col) then
    return false
  end
  return true
end

---@return boolean
---@param range Range
function M:compare(range)
  local self_range = self:to_vim()
  local other_range = range:to_vim()
  for i = 1, #self_range do
    if self_range[i] < other_range[i] then
      return true
    elseif self_range[i] > other_range[i] then
      return false
    end
  end
  return false
end

---@return Range
---@param opts TreesitterRange
function M.from_vim(opts)
  return M.new(unpack(opts))
end

---@return Range
---@param cursor Cursor
function M.from_cursor(cursor)
  return M.new(cursor.line, cursor.col, cursor.line, cursor.col)
end

---@return TreesitterRange
function M:to_vim()
  return { self.start_line, self.start_col, self.end_line, self.end_col }
end

---@return Cursor
function M:beginning()
  return Cursor.new(self.start_line, self.start_col)
end

---@return Cursor
function M:ending()
  return Cursor.new(self.end_line, self.end_col)
end

---@return string
function M:to_string()
  return string.format(
    "[%s]",
    table.concat({
      self.start_line,
      self.start_col,
      self.end_line,
      self.end_col,
    }, ", ")
  )
end

---@return Range
---@param start_line integer
---@param start_col integer
---@param end_line integer
---@param end_col integer
function M.new(start_line, start_col, end_line, end_col)
  local self = setmetatable({}, M)

  self.start_line = start_line
  self.start_col = start_col
  self.end_line = end_line
  self.end_col = end_col

  return self
end

return M
