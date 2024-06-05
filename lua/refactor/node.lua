---@class Node
---@field type string
---@field range Range
---@field node TSNode
---@field text string
local M = {}
M.__index = M

---@return Node
---@param type string
---@param range Range
---@param node TSNode
---@param text string
function M.new(type, range, node, text)
  local self = setmetatable({}, M)

  self.type = type
  self.range = range
  self.node = node
  self.text = text

  return self
end

return M
