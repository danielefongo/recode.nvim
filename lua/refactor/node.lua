---@class Node
---@field type string
---@field range Range
---@field node TSNode
---@field text string
local M = {}
M.__index = M

---@return Node[]
---@param nodes Node[]
---@param lambda function
---@param filter function | nil
local function filter_nodes(nodes, lambda, filter)
  local filter_fun = filter or function(_)
    return true
  end

  return vim.tbl_filter(function(node)
    return lambda(node) and filter_fun(node)
  end, nodes)
end

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

---@return Node
---@param range Range
---@param node_type string | nil
function M.dummy(range, node_type)
  local self = setmetatable({}, M)

  self.range = range
  self.type = node_type or ""

  return self
end

---@return Node[]
---@param nodes Node[]
---@param node_type string
---@param filter function | nil
function M:find_inside(nodes, node_type, filter)
  return filter_nodes(nodes, function(node)
    return self.range:contains_range(node.range) and node.type == node_type
  end, filter)
end

---@return Node[]
---@param nodes Node[]
---@param node_type string
---@param filter function | nil
function M:find_outside(nodes, node_type, filter)
  return filter_nodes(nodes, function(node)
    return node.range:contains_range(self.range) and node.type == node_type
  end, filter)
end

return M
