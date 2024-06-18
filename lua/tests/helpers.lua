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

local first_lsp_call = true
local helpers = {}

function helpers.setup(opts)
  opts = opts or {}

  setup_test_cov()
end

function helpers.with_lsp(lambda, ...)
  local args = { ... }
  local out = nil

  local co = coroutine.running()
  vim.defer_fn(function()
    out = lambda(unpack(args))

    first_lsp_call = false

    coroutine.resume(co)
  end, (first_lsp_call and 1000) or 0)

  coroutine.yield()
  return out
end

function helpers.buf_with_text(text)
  local buffer = vim.api.nvim_create_buf(false, true)
  local win = create_dummy_window(buffer)
  helpers.buf_write(buffer, text)
  return buffer, win
end

function helpers.buf_with_fake_file(filename, ft, text)
  local buffer, win = helpers.buf_with_text(text)
  vim.api.nvim_buf_set_name(buffer, filename)
  vim.api.nvim_set_option_value("filetype", ft, { buf = buffer })
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

function helpers.temp_file(content)
  local filename = os.tmpname()
  local f = io.open(filename, "w")
  if f then
    f:write(content)
    f:close()
  end
  return filename
end

return helpers
