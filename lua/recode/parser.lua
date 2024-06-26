local Node = require("recode.node")
local Range = require("recode.range")

local M = {}

local ts = vim.treesitter
local parse = ts.query.parse or ts.parse_query
local language = ts.language

---@return nil
---@param nodes table
---@param new_node Node
local function insert_sorted(nodes, new_node)
  local inserted = false
  for i = 1, #nodes do
    if new_node.range:compare(nodes[i].range) then
      table.insert(nodes, i, new_node)
      inserted = true
      break
    end
  end
  if not inserted then
    table.insert(nodes, new_node)
  end
end

---@return Node[]
---@param source string | number
---@param ft string
---@param raw_query string
function M.get_nodes(source, ft, raw_query)
  local lang = language.get_lang(ft) or ft

  local root
  if type(source) == "number" then
    root = ts.get_parser(source, lang):parse()[1]:root()
  else
    local file_path = source
    local buf = vim.fn.bufnr(file_path)

    if buf == -1 then
      local file = io.open(source, "r")
      if file then
        source = file:read("*a")
      end
      root = ts.get_string_parser(source, lang):parse()[1]:root()
    else
      source = buf
      root = ts.get_parser(buf, lang):parse()[1]:root()
    end
  end
  local query = parse(lang, raw_query)

  local nodes = {}
  local node_ranges = {}
  for _, match in query:iter_matches(root, source) do
    for idx, type in ipairs(query.captures) do
      ---@type TSNode
      local capture = match[idx]

      if capture then
        local node_range = Range.new(capture:range())
        local node_range_string = node_range:to_string() .. type

        local text = vim.treesitter.get_node_text(capture, source)
        if not node_ranges[node_range_string] then
          insert_sorted(nodes, Node.new(type, node_range, capture, text))
        end
        node_ranges[node_range_string] = 1
      end
    end
  end

  return nodes
end

return M
