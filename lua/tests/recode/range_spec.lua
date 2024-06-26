local helpers = require("tests.helpers")
local Range = require("recode.range")
local Cursor = require("recode.cursor")

describe("range", function()
  helpers.setup()

  describe("contains cursor", function()
    it("is false if it doesn't", function()
      local range = Range.new(0, 10, 3, 5)
      assert.are.same(false, range:contains_cursor(Cursor.new(-1, 0)))
      assert.are.same(false, range:contains_cursor(Cursor.new(0, 0)))
      assert.are.same(false, range:contains_cursor(Cursor.new(0, 9)))
      assert.are.same(false, range:contains_cursor(Cursor.new(3, 5)))
      assert.are.same(false, range:contains_cursor(Cursor.new(3, 10)))
      assert.are.same(false, range:contains_cursor(Cursor.new(4, 0)))
    end)

    it("is true if it does", function()
      local range = Range.new(0, 10, 3, 5)
      assert.are.same(true, range:contains_cursor(Cursor.new(0, 10)))
      assert.are.same(true, range:contains_cursor(Cursor.new(0, 20)))
      assert.are.same(true, range:contains_cursor(Cursor.new(1, 0)))
      assert.are.same(true, range:contains_cursor(Cursor.new(1, 100)))
      assert.are.same(true, range:contains_cursor(Cursor.new(3, 0)))
      assert.are.same(true, range:contains_cursor(Cursor.new(3, 4)))
    end)
  end)

  describe("contains range", function()
    it("is false if it doesn't", function()
      local range = Range.new(0, 10, 3, 5)
      assert.are.same(false, range:contains_range(Range.new(0, 0, 0, 0)))
      assert.are.same(false, range:contains_range(Range.new(0, 0, 0, 20)))
      assert.are.same(false, range:contains_range(Range.new(0, 0, 2, 20)))
      assert.are.same(false, range:contains_range(Range.new(2, 20, 3, 6)))
      assert.are.same(false, range:contains_range(Range.new(3, 6, 10, 10)))
    end)

    it("is true if it does", function()
      local range = Range.new(0, 10, 3, 5)
      assert.are.same(true, range:contains_range(Range.new(0, 10, 2, 0)))
      assert.are.same(true, range:contains_range(Range.new(2, 0, 2, 1)))
      assert.are.same(true, range:contains_range(Range.new(2, 0, 3, 5)))
    end)

    it("is false if equal", function()
      local range = Range.new(0, 10, 3, 5)
      assert.are.same(false, range:contains_range(Range.new(0, 10, 3, 5)))
    end)
  end)

  describe("compare", function()
    it("is true if self is less than range", function()
      local range1 = Range.new(0, 10, 3, 5)
      local range2 = Range.new(1, 0, 3, 5)
      assert.are.same(true, range1:compare(range2))

      local range3 = Range.new(0, 10, 2, 5)
      assert.are.same(true, range3:compare(range2))

      local range4 = Range.new(0, 9, 3, 5)
      assert.are.same(true, range4:compare(range1))
    end)

    it("is false if self is greater than or equal to range", function()
      local range1 = Range.new(0, 10, 3, 5)
      local range2 = Range.new(0, 10, 3, 5)
      assert.are.same(false, range1:compare(range2))

      local range3 = Range.new(0, 11, 3, 5)
      assert.are.same(false, range3:compare(range1))

      local range4 = Range.new(1, 0, 3, 5)
      assert.are.same(false, range4:compare(range1))
    end)
  end)

  it("from cursor(s)", function()
    assert.are.same(Range.from_cursor(Cursor.new(1, 2)), Range.new(1, 2, 1, 2))
    assert.are.same(Range.from_cursors(Cursor.new(1, 2), Cursor.new(5, 6)), Range.new(1, 2, 5, 6))
  end)

  it("to/from vim", function()
    assert.are.same(Range.new(0, 10, 3, 5), Range.from_vim({ 0, 10, 3, 5 }))
    assert.are.same({ 0, 10, 3, 5 }, Range.new(0, 10, 3, 5):to_vim())
  end)

  it("to_string", function()
    assert.are.same(Range.new(0, 10, 3, 5):to_string(), "[0, 10, 3, 5]")
  end)

  it("beginning / ending", function()
    local range = Range.new(0, 10, 3, 5)
    assert.are.same(Cursor.new(0, 10), range:beginning())
    assert.are.same(Cursor.new(3, 5), range:ending())
  end)
end)
