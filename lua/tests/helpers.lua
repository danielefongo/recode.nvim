local function setup_test_cov()
  after_each(function()
    if os.getenv("TEST_COV") then
      require("luacov.runner").save_stats()
    end
  end)
end

local function create_dummy_window(buf)
  local win_id = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = 100,
    height = 100,
    row = 0,
    col = 0,
    style = "minimal",
  })

  return win_id
end

-- helpers

local helpers = {}

function helpers.setup(opts)
  opts = opts or {}

  setup_test_cov()
end

function helpers.async(after, lambda, ...)
  local args = { ... }
  local out = nil

  local co = coroutine.running()
  vim.defer_fn(function()
    out = lambda(unpack(args))

    coroutine.resume(co)
  end, after)

  coroutine.yield()
  return out
end

function helpers.buf_with_text(text)
  local buffer = vim.api.nvim_create_buf(false, true)
  local win = create_dummy_window(buffer)
  helpers.buf_write(buffer, text)
  return buffer, win
end

function helpers.buf_with_file(file, ft)
  local buffer = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buffer)
  vim.api.nvim_command("edit " .. file)
  vim.api.nvim_set_option_value("filetype", ft, { buf = buffer })

  return buffer, win
end

function helpers.buf_write(buffer, text)
  vim.api.nvim_buf_set_lines(buffer, 0, -1, true, vim.split(text, "\n"))
end

return helpers
