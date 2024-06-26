---@class Refactor
local M = {}

---@return string
function M.description() end

---@return table
function M.prompt() end

---@param source number
---@param range Range
---@return boolean
function M.is_valid(source, range) end

---@param source number
---@param range Range
---@return Action[]
function M.apply(source, range, opts) end
