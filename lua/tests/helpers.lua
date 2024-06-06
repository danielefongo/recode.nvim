local function setup_test_cov()
  after_each(function()
    if os.getenv("TEST_COV") then
      require("luacov.runner").save_stats()
    end
  end)
end

-- helpers

local helpers = {}

function helpers.setup(opts)
  opts = opts or {}

  setup_test_cov()
end

function helpers.buf_with_text(text)
  local buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buffer, 0, -1, true, vim.split(text, "\n"))
  return buffer
end

return helpers
