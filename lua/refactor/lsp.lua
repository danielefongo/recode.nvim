local Range = require("refactor.range")
local M = {}

---@return table
---@param action string
---@param buf integer
---@param cursor Cursor
local function request(action, buf, cursor, custom_params)
  local params = custom_params
    or {
      textDocument = { uri = vim.uri_from_bufnr(buf) },
      position = { line = cursor.line, character = cursor.col },
      context = { includeDeclaration = true },
    }

  local results = vim.lsp.buf_request_sync(buf, action, params, 5000)

  -- TODO: hardcoded 1
  return results and results[1] and results[1].result or {}
end

---@class LspElement
---@field range Range
---@field file string

---@return LspElement | nil
---@param buf integer
---@param cursor Cursor
function M.definition(buf, cursor)
  local definitions = request("textDocument/definition", buf, cursor)
  local lsp_range = definitions and definitions[1] and definitions[1].targetRange

  if lsp_range then
    return {
      range = Range.new(
        lsp_range.start.line,
        lsp_range.start.character,
        lsp_range["end"].line,
        lsp_range["end"].character
      ),
      file = string.gsub(definitions[1].targetUri, "file://", ""),
    }
  end
end

---@return LspElement[]
---@param buf integer
---@param cursor Cursor
function M.references(buf, cursor)
  local references = request("textDocument/references", buf, cursor)

  local final_references = vim.tbl_map(function(reference)
    return {
      range = Range.new(
        reference.range.start.line,
        reference.range.start.character,
        reference.range["end"].line,
        reference.range["end"].character
      ),
      file = string.gsub(reference.uri, "file://", ""),
    }
  end, references)

  return final_references
end

---@return LspElement[]
---@param buf integer
---@param cursor Cursor
function M.incoming_calls(buf, cursor)
  local call_item = request("textDocument/prepareCallHierarchy", buf, cursor)[1]
  local lsp_references = request("callHierarchy/incomingCalls", buf, cursor, { item = call_item })

  local references = {}

  for _, reference in pairs(lsp_references) do
    local file = string.gsub(reference.from.uri, "file://", "")
    for _, range in pairs(reference.fromRanges) do
      references[#references + 1] = {
        range = Range.new(range.start.line, range.start.character, range["end"].line, range["end"].character),
        file = file,
      }
    end
  end

  return references
end

return M
