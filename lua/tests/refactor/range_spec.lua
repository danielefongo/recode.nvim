local helpers = require("tests.helpers")
local range = require("refactor.range")
local cursor = require("refactor.cursor")

describe("range", function()
  helpers.setup()

  describe("contains cursor", function()
    it("is false if it doesn't", function()
      local my_range = range.new(0, 10, 3, 5)
      assert.are.same(false, my_range:contains_cursor(cursor.new(-1, 0)))
      assert.are.same(false, my_range:contains_cursor(cursor.new(0, 0)))
      assert.are.same(false, my_range:contains_cursor(cursor.new(0, 9)))
      assert.are.same(false, my_range:contains_cursor(cursor.new(3, 5)))
      assert.are.same(false, my_range:contains_cursor(cursor.new(3, 10)))
      assert.are.same(false, my_range:contains_cursor(cursor.new(4, 0)))
    end)

    it("is true if it does", function()
      local my_range = range.new(0, 10, 3, 5)
      assert.are.same(true, my_range:contains_cursor(cursor.new(0, 10)))
      assert.are.same(true, my_range:contains_cursor(cursor.new(0, 20)))
      assert.are.same(true, my_range:contains_cursor(cursor.new(1, 0)))
      assert.are.same(true, my_range:contains_cursor(cursor.new(1, 100)))
      assert.are.same(true, my_range:contains_cursor(cursor.new(3, 0)))
      assert.are.same(true, my_range:contains_cursor(cursor.new(3, 4)))
    end)
  end)

  describe("contains range", function()
    it("is false if it doesn't", function()
      local my_range = range.new(0, 10, 3, 5)
      assert.are.same(false, my_range:contains_range(range.new(0, 0, 0, 0)))
      assert.are.same(false, my_range:contains_range(range.new(0, 0, 0, 20)))
      assert.are.same(false, my_range:contains_range(range.new(0, 0, 2, 20)))
      assert.are.same(false, my_range:contains_range(range.new(2, 20, 3, 6)))
      assert.are.same(false, my_range:contains_range(range.new(3, 6, 10, 10)))
    end)

    it("is true if it does", function()
      local my_range = range.new(0, 10, 3, 5)
      assert.are.same(true, my_range:contains_range(range.new(0, 10, 3, 5)))
      assert.are.same(true, my_range:contains_range(range.new(0, 10, 2, 0)))
      assert.are.same(true, my_range:contains_range(range.new(2, 0, 2, 1)))
      assert.are.same(true, my_range:contains_range(range.new(2, 0, 3, 5)))
    end)
  end)

  describe("compare", function()
    it("is true if self is less than range", function()
      local range1 = range.new(0, 10, 3, 5)
      local range2 = range.new(1, 0, 3, 5)
      assert.are.same(true, range1:compare(range2))

      local range3 = range.new(0, 10, 2, 5)
      assert.are.same(true, range3:compare(range2))

      local range4 = range.new(0, 9, 3, 5)
      assert.are.same(true, range4:compare(range1))
    end)

    it("is false if self is greater than or equal to range", function()
      local range1 = range.new(0, 10, 3, 5)
      local range2 = range.new(0, 10, 3, 5)
      assert.are.same(false, range1:compare(range2))

      local range3 = range.new(0, 11, 3, 5)
      assert.are.same(false, range3:compare(range1))

      local range4 = range.new(1, 0, 3, 5)
      assert.are.same(false, range4:compare(range1))
    end)
  end)

  it("from cursor", function()
    assert.are.same(range.from_cursor(cursor.new(1, 2)), range.new(1, 2, 1, 2))
  end)

  it("to/from vim", function()
    assert.are.same(range.new(0, 10, 3, 5), range.from_vim({ 0, 10, 3, 5 }))
    assert.are.same({ 0, 10, 3, 5 }, range.new(0, 10, 3, 5):to_vim())
  end)

  it("to_string", function()
    assert.are.same(range.new(0, 10, 3, 5):to_string(), "[0, 10, 3, 5]")
  end)
end)
