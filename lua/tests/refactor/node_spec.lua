local helpers = require("tests.helpers")
local Range = require("refactor.range")
local Node = require("refactor.node")

describe("node", function()
  helpers.setup()

  describe("search", function()
    local a = Node.dummy(Range.new(0, 0, 40, 0), "0")
    local b = Node.dummy(Range.new(10, 0, 20, 0), "1")
    local c = Node.dummy(Range.new(20, 0, 30, 0), "1")
    local d = Node.dummy(Range.new(15, 0, 18, 0), "2")
    local e = Node.dummy(Range.new(15, 0, 30, 0), "2")

    local nodes = { a, b, c, d, e }

    it("inside", function()
      assert.are.same({}, a:find_inside(nodes, "0"))
      assert.are.same({ b, c }, a:find_inside(nodes, "1"))
      assert.are.same({ d, e }, a:find_inside(nodes, "2"))
      assert.are.same({}, b:find_inside(nodes, "1"))
      assert.are.same({ d }, b:find_inside(nodes, "2"))
      assert.are.same({}, c:find_inside(nodes, "1"))
      assert.are.same({}, c:find_inside(nodes, "2"))
      assert.are.same({}, d:find_inside(nodes, "1"))
      assert.are.same({}, d:find_inside(nodes, "2"))

      assert.are.same({ b, c, d, e }, a:find_inside(nodes))
      assert.are.same({ d }, b:find_inside(nodes))
      assert.are.same({ c, d }, e:find_inside(nodes))
    end)

    it("outside", function()
      assert.are.same({}, a:find_outside(nodes, "0"))
      assert.are.same({}, a:find_outside(nodes, "1"))
      assert.are.same({}, a:find_outside(nodes, "2"))
      assert.are.same({ a }, b:find_outside(nodes, "0"))
      assert.are.same({}, b:find_outside(nodes, "1"))
      assert.are.same({}, b:find_outside(nodes, "2"))
      assert.are.same({ a }, c:find_outside(nodes, "0"))
      assert.are.same({}, c:find_outside(nodes, "1"))
      assert.are.same({ e }, c:find_outside(nodes, "2"))
      assert.are.same({ a }, d:find_outside(nodes, "0"))
      assert.are.same({ b }, d:find_outside(nodes, "1"))
      assert.are.same({ e }, d:find_outside(nodes, "2"))
      assert.are.same({ a }, e:find_outside(nodes, "0"))
      assert.are.same({}, e:find_outside(nodes, "1"))
      assert.are.same({}, e:find_outside(nodes, "2"))

      assert.are.same({}, a:find_outside(nodes))
      assert.are.same({ a }, b:find_outside(nodes))
      assert.are.same({ a, e }, c:find_outside(nodes))
      assert.are.same({ a, b, e }, d:find_outside(nodes))
      assert.are.same({ a }, e:find_outside(nodes))
    end)

    it("with filter", function()
      assert.are.same(
        { b },
        a:find_inside(nodes, "1", function(n)
          return vim.deep_equal(n, b)
        end)
      )

      assert.are.same(
        {},
        b:find_inside(nodes, "0", function(n)
          return not vim.deep_equal(n, a)
        end)
      )
    end)
  end)
end)
