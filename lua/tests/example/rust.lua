---@diagnostic disable: need-check-nil

local parser = require("refactor.parser")
local Cursor = require("refactor.cursor")
local Node = require("refactor.node")
local Lsp = require("refactor.lsp")
local action = require("refactor.action")
local M = {}

local function exact_word_pattern(text)
  return "%f[%w]" .. text:gsub("([^%w])", "%%%1") .. "%f[%W]"
end

function M.extract_match(source, range, opts)
  local query = [[ ; query
      ((function_item body: ((block) @block)) @fun)
      ((match_expression) @match (#has-ancestor? @match function_item))
      ((identifier) @identifier (#has-ancestor? @identifier match_expression))
      ((identifier) @declaration (#has-parent? @declaration let_declaration))
      ((identifier) @declaration (#has-parent? @declaration parameter))
    ]]

  local nodes = parser.get_nodes(source, "rust", query)
  local range_dummy = Node.dummy(range)

  local fun = Node.dummy(range):find_outside(nodes, "fun")[1]
  local matches = fun:find_inside(nodes, "match")
  local match = range_dummy:find_largest_inside(matches)
  local identifiers = match:find_inside(nodes, "identifier")

  local needed_declarations = fun:find_inside(nodes, nil, function(node)
    if node.type ~= "declaration" then
      return false
    end

    return not match.range:contains_range(node.range)
      and not match.range:compare(node.range)
      and (#vim.tbl_filter(function(identifier)
        return node.text == identifier.text
      end, identifiers) > 0)
  end)

  return {
    action.insert(
      source,
      Cursor.new(fun.range.end_line, fun.range.end_col),
      string.format(
        [[


fn %s(%s) -> _ {
  %s
}]],
        opts.name or "fun",
        table.concat(
          vim.tbl_map(function(var)
            local type = vim.treesitter.get_node_text(var.node:next_named_sibling(), source)
            local text = vim.treesitter.get_node_text(var.node, source)

            return text .. ": " .. type
          end, needed_declarations),
          ", "
        ),
        vim.treesitter.get_node_text(match.node, source)
      )
    ),
    action.remove(source, match.range),
    action.insert(
      source,
      Cursor.new(match.range.start_line, match.range.start_col),
      string.format(
        "%s(%s)",
        opts.name or "fun",
        table.concat(
          vim.tbl_map(function(var)
            return vim.treesitter.get_node_text(var.node, source)
          end, needed_declarations),
          ", "
        )
      )
    ),
  }
end

function M.rename(source, range, opts)
  local references = Lsp.references(source, Cursor.new(range.start_line, range.start_col))

  local actions = {}
  for _, reference in pairs(references or {}) do
    actions[#actions + 1] = action.remove(reference.file, reference.range)
    actions[#actions + 1] =
      action.insert(reference.file, Cursor.new(reference.range.start_line, reference.range.start_col), opts.name)
  end

  return actions
end

function M.swap(source, range, opts)
  local from = opts.from
  local to = opts.to

  local nodes = parser.get_nodes(
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
    action.replace(source, to_param.range, from_param.text),
    action.replace(source, from_param.range, to_param.text),
  }

  local calls = Lsp.incoming_calls(source, name.range:beginning())

  for _, call in pairs(calls) do
    local call_nodes = parser.get_nodes(
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

    actions[#actions + 1] = action.replace(call.file, to_arg.range, from_arg.text)
    actions[#actions + 1] = action.replace(call.file, from_arg.range, to_arg.text)
  end

  return actions
end

function M.inline_function(buffer, range)
  local nodes = parser.get_nodes(
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

  local function_nodes = parser.get_nodes(
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
    action.replace(buffer, call.range, body_string),
  }
end

function M.inline_var(buffer, range)
  local nodes = parser.get_nodes(
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

  local new_nodes = parser.get_nodes(
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
    action.replace(buffer, identifier.range, value.text),
  }
end

return M
