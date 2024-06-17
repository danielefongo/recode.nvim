local mock = require("luassert.mock")
local helpers = require("tests.helpers")
local Lenses = require("recode.lenses")
local Range = require("recode.range")

---@param text_description string
---@param is_valid boolean | nil
---@return Refactor
local function a_recode(text_description, is_valid)
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

  it("register recodes", function()
    local recode1 = a_recode("action1")
    local recode2 = a_recode("action2")

    local lenses = Lenses.new()

    lenses:register(recode1):register(recode2)

    assert.are.same({ recode1, recode2 }, lenses:all())
  end)

  it("register many recodes", function()
    local recode1 = a_recode("action1")
    local recode2 = a_recode("action2")

    local lenses = Lenses.new()

    lenses:register_many({ recode1, recode2 })

    assert.are.same({ recode1, recode2 }, lenses:all())
  end)

  it("ask for valid recodes", function()
    local recode_mock = mock(a_recode("action1"))
    local recode_mock2 = mock(a_recode("action2"))

    local source = 0
    local range = Range.new(0, 0, 0, 0)

    local lenses = Lenses.new()

    lenses:register(recode_mock):register(recode_mock2)
    lenses:suggestions(source, range)

    assert.spy(recode_mock.is_valid).was.called_with(source, range)
    assert.spy(recode_mock2.is_valid).was.called_with(source, range)
  end)

  it("returns valid recodes", function()
    local lenses = Lenses.new()
    local recode1 = a_recode("action1", false)
    local recode2 = a_recode("action2", true)
    local recode3 = a_recode("action3", false)
    local recode4 = a_recode("action4", true)

    lenses:register(recode1):register(recode2):register(recode3):register(recode4)

    local recodes = lenses:suggestions(0, Range.new(0, 0, 0, 0))

    assert.are.same({ recode2, recode4 }, recodes)
  end)
end)
