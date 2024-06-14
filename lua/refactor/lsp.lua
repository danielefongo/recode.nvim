local Range = require("refactor.range")
local M = {}

---@return table
---@param win integer
---@param buf integer
local function request(action, win, buf)
  local params = vim.lsp.util.make_position_params(win, "utf-8")
  params.context = { includeDeclaration = true }

  local results = vim.lsp.buf_request_sync(buf, action, params, 5000)

  -- TODO: hardcoded 1
  return results and results[1] and results[1].result
end

---@class LspElement
---@field range Range
---@field uri string

---@return LspElement | nil
---@param win integer
---@param buf integer
function M.definition(win, buf)
  local definitions = request("textDocument/definition", win, buf)
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

---@return LspElement[] | nil
---@param win integer
---@param buf integer
function M.references(win, buf)
  local references = request("textDocument/references", win, buf)
  -- print(vim.inspect(references))

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
  -- print(vim.inspect(final_references))

  return final_references
end

return M
