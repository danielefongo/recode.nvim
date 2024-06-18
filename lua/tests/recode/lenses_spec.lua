local mock = require("luassert.mock")
local helpers = require("tests.helpers")
local Lenses = require("recode.lenses")
local Range = require("recode.range")

---@param text_description string
---@param is_valid boolean | nil
---@return Refactor
local function a_refactor(text_description, is_valid)
  return {
    description = function()
      return text_description
    end,
    is_valid = function(_, _)
      return is_valid ~= false
    end,
    apply = function(_, _)
      return {}
    end,
  }
end

describe("lenses", function()
  helpers.setup()

  it("register refactors", function()
    local refactor1 = a_refactor("action1")
    local refactor2 = a_refactor("action2")

    local lenses = Lenses.new()

    lenses:register(refactor1):register(refactor2)

    assert.are.same({ refactor1, refactor2 }, lenses:all())
  end)

  it("register many refactors", function()
    local refactor1 = a_refactor("action1")
    local refactor2 = a_refactor("action2")

    local lenses = Lenses.new()

    lenses:register_many({ refactor1, refactor2 })

    assert.are.same({ refactor1, refactor2 }, lenses:all())
  end)

  it("ask for valid refactors", function()
    local refactor_mock = mock(a_refactor("action1"))
    local refactor_mock2 = mock(a_refactor("action2"))

    local source = 0
    local range = Range.new(0, 0, 0, 0)

    local lenses = Lenses.new()

    lenses:register(refactor_mock):register(refactor_mock2)
    lenses:suggestions(source, range)

    assert.spy(refactor_mock.is_valid).was.called_with(source, range)
    assert.spy(refactor_mock2.is_valid).was.called_with(source, range)
  end)

  it("returns valid refactors", function()
    local lenses = Lenses.new()
    local refactor1 = a_refactor("action1", false)
    local refactor2 = a_refactor("action2", true)
    local refactor3 = a_refactor("action3", false)
    local refactor4 = a_refactor("action4", true)

    lenses:register(refactor1):register(refactor2):register(refactor3):register(refactor4)

    local refactors = lenses:suggestions(0, Range.new(0, 0, 0, 0))

    assert.are.same({ refactor2, refactor4 }, refactors)
  end)
end)
