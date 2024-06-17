---@diagnostic disable: need-check-nil

local Parser = require("recode.parser")
local Cursor = require("recode.cursor")
local Node = require("recode.node")
local Action = require("recode.action")

---@class RustExtractMatch : Refactor
local M = {}

function M.description()
  return "Rust extract match"
end

function M.is_valid(source, range)
  local nodes = Parser.get_nodes(
    source,
    "rust",
    [[ ; query
      ((function_item body: ((block) @block)) @fun)
      ((match_expression) @match (#has-ancestor? @match function_item))
      ((identifier) @identifier (#has-ancestor? @identifier match_expression))
      ((identifier) @declaration (#has-parent? @declaration let_declaration))
      ((identifier) @declaration (#has-parent? @declaration parameter))
    ]]
  )
  local range_dummy = Node.dummy(range)

  local fun = Node.dummy(range):find_outside(nodes, "fun")[1]
  local matches = fun:find_inside(nodes, "match")
  return range_dummy:find_largest_inside(matches) ~= nil
end

function M.apply(source, range)
  local name = vim.fn.input("Name: ")

  local nodes = Parser.get_nodes(
    source,
    "rust",
    [[ ; query
      ((function_item body: ((block) @block)) @fun)
      ((match_expression) @match (#has-ancestor? @match function_item))
      ((identifier) @identifier (#has-ancestor? @identifier match_expression))
      ((identifier) @declaration (#has-parent? @declaration let_declaration))
      ((identifier) @declaration (#has-parent? @declaration parameter))
    ]]
  )
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
    Action.insert(
      source,
      Cursor.new(fun.range.end_line, fun.range.end_col),
      string.format(
        [[


fn %s(%s) -> _ {
  %s
}]],
        name,
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
    Action.remove(source, match.range),
    Action.insert(
      source,
      Cursor.new(match.range.start_line, match.range.start_col),
      string.format(
        "%s(%s)",
        name,
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

return M
