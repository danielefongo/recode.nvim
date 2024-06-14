local helpers = require("tests.helpers")
local Parser = require("refactor.parser")

describe("parser", function()
  helpers.setup()

  ---@return table
  ---@param source string
  ---@param ft string
  ---@param raw_query string
  local function parse(source, ft, raw_query)
    return vim.tbl_map(function(node)
      return {
        type = node.type,
        range = node.range:to_vim(),
      }
    end, Parser.get_nodes(source, ft, raw_query))
  end

  describe("for strings", function()
    it("for simple query without nesting", function()
      local code = [[
fn my_function(param1: i32, param2: i32) -> i32 {
  param1 + param2
}
    ]]
      local ft = "rust"
      local query = [[ ; query
      (function_item
          name: ((identifier) @fun_name)
          parameters: (parameters ((parameter) @param))
          return_type: ((_) @return)
          body: (_) @body)
    ]]

      local nodes = parse(code, ft, query)
      assert.are.same({
        { type = "fun_name", range = { 0, 3, 0, 14 } },
        { type = "param", range = { 0, 15, 0, 26 } },
        { type = "param", range = { 0, 28, 0, 39 } },
        { type = "return", range = { 0, 44, 0, 47 } },
        { type = "body", range = { 0, 48, 2, 1 } },
      }, nodes)
    end)

    it("for splitted query without nesting", function()
      local code = [[
fn my_function(param1: i32, param2: i32) -> i32 {
  param1 + param2
}
    ]]
      local ft = "rust"
      local query = [[ ; query
      (function_item
          return_type: ((_) @return)
          body: (_) @body)

      (function_item
          name: ((identifier) @fun_name)
          parameters: (parameters ((parameter) @param)))
    ]]

      local nodes = parse(code, ft, query)
      assert.are.same({
        { type = "fun_name", range = { 0, 3, 0, 14 } },
        { type = "param", range = { 0, 15, 0, 26 } },
        { type = "param", range = { 0, 28, 0, 39 } },
        { type = "return", range = { 0, 44, 0, 47 } },
        { type = "body", range = { 0, 48, 2, 1 } },
      }, nodes)
    end)

    it("for splitted query with nesting", function()
      local code = [[
fn my_function(param1: i32, param2: i32) -> i32 {
  match param1 {
    1 => 1,
    _ => param2,
  }
}
    ]]
      local ft = "rust"
      local query = [[ ; query
      (function_item
          name: ((identifier) @fun_name)
          parameters: (parameters ((parameter) @param))
          return_type: ((_) @return)
          body: (_) @body)

      ((match_expression) @match)
      ((identifier) @identifier (#has-ancestor? @identifier match_expression))
    ]]

      local nodes = parse(code, ft, query)
      assert.are.same({
        { type = "fun_name", range = { 0, 3, 0, 14 } },
        { type = "param", range = { 0, 15, 0, 26 } },
        { type = "param", range = { 0, 28, 0, 39 } },
        { type = "return", range = { 0, 44, 0, 47 } },
        { type = "body", range = { 0, 48, 5, 1 } },
        { type = "match", range = { 1, 2, 4, 3 } },
        { type = "identifier", range = { 1, 8, 1, 14 } },
        { type = "identifier", range = { 3, 9, 3, 15 } },
      }, nodes)
    end)
  end)

  it("for buffer", function()
    local buffer = helpers.buf_with_text([[
fn my_function(param1: i32, param2: i32) -> i32 {
  param1 + param2
}
    ]])

    local ft = "rust"
    local query = [[ ; query
      (function_item
          name: ((identifier) @fun_name)
          parameters: (parameters ((parameter) @param))
          return_type: ((_) @return)
          body: (_) @body)
    ]]

    local nodes = parse(buffer, ft, query)
    assert.are.same({
      { type = "fun_name", range = { 0, 3, 0, 14 } },
      { type = "param", range = { 0, 15, 0, 26 } },
      { type = "param", range = { 0, 28, 0, 39 } },
      { type = "return", range = { 0, 44, 0, 47 } },
      { type = "body", range = { 0, 48, 2, 1 } },
    }, nodes)
  end)

  it("for files", function()
    local ft = "rust"
    local query = [[ ; query
      (function_item
          name: ((identifier) @fun_name)
          parameters: (parameters ((parameter) @param))
          return_type: ((_) @return)
          body: (_) @body)
    ]]

    local nodes = parse("./lua/tests/example/src/parser.rs", ft, query)
    assert.are.same({
      { type = "fun_name", range = { 0, 3, 0, 14 } },
      { type = "param", range = { 0, 15, 0, 26 } },
      { type = "param", range = { 0, 28, 0, 39 } },
      { type = "return", range = { 0, 44, 0, 47 } },
      { type = "body", range = { 0, 48, 2, 1 } },
    }, nodes)
  end)
end)
