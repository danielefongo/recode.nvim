---@class Lenses
---@field recodes Refactor[]
local M = {}
M.__index = M

---@return Lenses
function M.new()
  local self = setmetatable({}, M)
  self.recodes = {}
  return self
end

---@param recode Refactor
---@return Lenses
function M:register(recode)
  return self:register_many({ recode })
end

---@param recodes Refactor[]
---@return Lenses
function M:register_many(recodes)
  for _, recode in pairs(recodes) do
    self.recodes[#self.recodes + 1] = recode
  end
  return self
end

---@param source number
---@param range Range
---@return Refactor[]
function M:suggestions(source, range)
  return vim.tbl_filter(function(recode)
    return recode.is_valid(source, range)
  end, self.recodes)
end

---@return Refactor[]
function M:all()
  return self.recodes
end

return M
