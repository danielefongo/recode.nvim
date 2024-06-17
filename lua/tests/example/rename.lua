---@diagnostic disable: need-check-nil

local Action = require("recode.action")
local Cursor = require("recode.cursor")
local Lsp = require("recode.lsp")
local Node = require("recode.node")
local Parser = require("recode.parser")

---@class RustRename : Refactor
local M = {}

function M.description()
  return "Rust rename"
end

function M.is_valid(source, range)
  local nodes = Parser.get_nodes(
    source,
    "rust",
    [[ ; query
      ((identifier) @identifier)
    ]]
  )

  return Node.dummy(range):find_smallest_outside(nodes, "identifier") ~= nil
end

function M.apply(source, range)
  local name = vim.fn.input("Name: ")

  local references = Lsp.references(source, Cursor.new(range.start_line, range.start_col))

  local actions = {}
  for _, reference in pairs(references or {}) do
    actions[#actions + 1] = Action.remove(reference.file, reference.range)
    actions[#actions + 1] =
      Action.insert(reference.file, Cursor.new(reference.range.start_line, reference.range.start_col), name)
  end

  return actions
end

return M
