---@diagnostic disable: need-check-nil

local Parser = require("recode.parser")
local Node = require("recode.node")
local Lsp = require("recode.lsp")
local Action = require("recode.action")

---@class RustInlineVar : Refactor
local M = {}

function M.description()
  return "Rust inline var"
end

function M.prompt()
  return {}
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

function M.apply(buffer, range)
  local nodes = Parser.get_nodes(
    buffer,
    "rust",
    [[ ; query
      ((function_item body: ((block) @block)) @fun)
      ((identifier) @identifier)
    ]]
  )

  local identifier = vim.tbl_filter(function(node)
    return node.range:contains_range(range) and node.type == "identifier"
  end, nodes)[1]

  local definition = Lsp.definition(buffer, identifier.range:beginning())
  local definition_dummy_node = Node.dummy(definition.range)

  local new_nodes = Parser.get_nodes(
    definition.file,
    "rust",
    [[ ; query
      ((let_declaration
        pattern: ((identifier) @identifier)
        value: (_) @value) @declaration)
    ]]
  )

  local fun = definition_dummy_node:find_smallest_outside(new_nodes, "declaration")
  local value = fun:find_inside(new_nodes, "value")[1]

  return {
    Action.replace(buffer, identifier.range, value.text),
  }
end

return M
