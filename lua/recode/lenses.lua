---@class Lenses
---@field refactors Refactor[]
local M = {}
M.__index = M

---@return Lenses
function M.new()
  local self = setmetatable({}, M)
  self.refactors = {}
  return self
end

---@param refactor Refactor
---@return Lenses
function M:register(refactor)
  return self:register_many({ refactor })
end

---@param refactors Refactor[]
---@return Lenses
function M:register_many(refactors)
  for _, refactor in pairs(refactors) do
    self.refactors[#self.refactors + 1] = refactor
  end
  return self
end

---@param source number
---@param range Range
---@return Refactor[]
function M:suggestions(source, range)
  return vim.tbl_filter(function(refactor)
    return refactor.is_valid(source, range)
  end, self.refactors)
end

---@return Refactor[]
function M:all()
  return self.refactors
end

return M
