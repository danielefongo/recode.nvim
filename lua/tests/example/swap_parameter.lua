---@diagnostic disable: need-check-nil

local Parser = require("refactor.parser")
local Cursor = require("refactor.cursor")
local Node = require("refactor.node")
local Lsp = require("refactor.lsp")
local Action = require("refactor.action")

---@class RustSwapParameter : Refactor
local M = {}

function M.description()
  return "Rust swap parameter"
end

function M.is_valid(source, range)
  local nodes = Parser.get_nodes(
    source,
    "rust",
    [[ ; query
      ((function_item name: (_) @name) @fun)
      ((parameter pattern: (identifier)) @param)
    ]]
  )

  local fun = Node.dummy(range):find_outside(nodes, "fun")[1]
  local params = fun:find_inside(nodes, "param")
  return #params > 1
end

function M.apply(source, range)
  local from = tonumber(vim.fn.input("From: "))
  local to = tonumber(vim.fn.input("To: "))

  local nodes = Parser.get_nodes(
    source,
    "rust",
    [[ ; query
      ((function_item name: (_) @name) @fun)
      ((parameter pattern: (identifier)) @param)
    ]]
  )

  local fun = Node.dummy(range):find_outside(nodes, "fun")[1]
  local name = fun:find_inside(nodes, "name")[1]
  local params = fun:find_inside(nodes, "param")

  local from_param = params[from]
  local to_param = params[to]

  local actions = {
    Action.replace(source, to_param.range, from_param.text),
    Action.replace(source, from_param.range, to_param.text),
  }

  local calls = Lsp.incoming_calls(source, name.range:beginning())

  for _, call in pairs(calls) do
    local call_nodes = Parser.get_nodes(
      call.file,
      "rust",
      [[ ; query
       ((call_expression
         function: (_)
         arguments: (arguments (_) @param)) @call)
      ]]
    )

    local function_call = Node.dummy(call.range):find_smallest_outside(call_nodes, "call")
    local args = function_call:find_inside(call_nodes, "param")

    local from_arg = args[from]
    local to_arg = args[to]

    actions[#actions + 1] = Action.replace(call.file, to_arg.range, from_arg.text)
    actions[#actions + 1] = Action.replace(call.file, from_arg.range, to_arg.text)
  end

  return actions
end

return M
