---@diagnostic disable: need-check-nil

local Parser = require("refactor.parser")
local Node = require("refactor.node")
local Lsp = require("refactor.lsp")
local Action = require("refactor.action")

---@class RustInlineFunction : Refactor
local M = {}

local function exact_word_pattern(text)
  return "%f[%w]" .. text:gsub("([^%w])", "%%%1") .. "%f[%W]"
end

function M.description()
  return "Rust inline function"
end

function M.is_valid(buffer, range)
  local nodes = Parser.get_nodes(
    buffer,
    "rust",
    [[ ; query
       ((call_expression
         function: ((_) @fun)
         arguments: (arguments (_) @argument)) @call)
    ]]
  )

  return Node.dummy(range):find_smallest_outside(nodes, "call") ~= nil
end

function M.apply(buffer, range)
  local nodes = Parser.get_nodes(
    buffer,
    "rust",
    [[ ; query
       ((call_expression
         function: ((_) @fun)
         arguments: (arguments (_) @argument)) @call)
    ]]
  )

  local call = Node.dummy(range):find_smallest_outside(nodes, "call")

  local call_function = call:find_inside(nodes, "fun")[1]
  local call_arguments = call:find_inside(nodes, "argument")

  local function_definition = Lsp.definition(buffer, call_function.range:beginning())

  local function_nodes = Parser.get_nodes(
    function_definition.file,
    "rust",
    [[ ; query
      ((function_item body: ((block) @block)) @fun)
      ((identifier) @identifier (#has-ancestor? @identifier function_item))
      ((identifier) @param (#has-parent? @param parameter))
  ]]
  )
  local function_dummy_node = Node.dummy(function_definition.range)
  local function_body = function_dummy_node:find_inside(function_nodes, "block")[1]
  local function_params = function_dummy_node:find_inside(function_nodes, "param")
  local function_duplicated_vars = function_dummy_node:find_inside(function_nodes, "identifier", function(node)
    return (#vim.tbl_filter(function(id)
      return id.text == node.text
    end, call_arguments) > 0)
  end)

  local body_string = function_body.text
  for _, duplicated_var in pairs(function_duplicated_vars) do
    local pattern = exact_word_pattern(duplicated_var.text)
    body_string = string.gsub(body_string, pattern, duplicated_var.text .. "_2")
  end

  for i, call_argument in ipairs(call_arguments) do
    local pattern = exact_word_pattern(function_params[i].text)
    body_string = string.gsub(body_string, pattern, call_argument.text)
  end

  return {
    Action.replace(buffer, call.range, body_string),
  }
end

return M
