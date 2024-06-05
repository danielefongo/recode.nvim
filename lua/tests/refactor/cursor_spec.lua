local helpers = require("tests.helpers")
local cursor = require("refactor.cursor")

describe("cursor", function()
  helpers.setup()

  it("to/from vim", function()
    assert.are.same(cursor.new(0, 0), cursor.from_vim({ 1, 0 }))
    assert.are.same({ 1, 0 }, cursor.new(0, 0):to_vim())
  end)
end)
