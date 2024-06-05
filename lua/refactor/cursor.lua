---@class Cursor
---@field line integer
---@field col integer
local M = {}
M.__index = M

---@alias VimCursor table {line, col}, with col 0 based

--- @return table
function M:to_vim()
  return { self.line + 1, self.col }
end

--- @return Cursor
--- @param cursor VimCursor
function M.from_vim(cursor)
  return M.new(cursor[1] - 1, cursor[2])
end

--- @return Cursor
--- @param line integer
--- @param col integer
function M.new(line, col)
  local self = setmetatable({}, M)

  self.line = line
  self.col = col

  return self
end

return M
