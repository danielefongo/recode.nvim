local helpers = require("tests.helpers")
local refactor = require("refactor")

describe("events", function()
  helpers.setup()

  it("it works", function()
    assert.are.same(42, refactor(42))
  end)
end)
