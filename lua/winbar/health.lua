local errors = {}
local warnings = {}

local M = {}

local function hl_exists(name)
  return vim.fn.hlexists(name) == 1
end

function M.log_error(key)
  errors[key] = true
end

function M.log_warning(key)
  warnings[key] = true
end

function M.show_warnings()
  for w, _ in pairs(warnings) do
    vim.health.warn(w)
  end
end

function M.show_errors()
  for e, _ in pairs(errors) do
    vim.health.error(e)
  end
end

---@param c winbar.config
function M.validate(c)
  local ok_ttl_ms = pcall(function()
    if vim.fn.has('nvim-0.11') == 1 then
      vim.validate('update_interval', c.update_interval, 'number')
    else
      vim.validate({ update_interval = { c.update_interval, 'number' } })
    end
  end)

  -- fallback
  if not ok_ttl_ms then
    M.log_warning("invalid 'update_interval', fallback to default 1000")
    c.update_interval = 1000
    return
  end

  vim.health.ok('Valid configuration')
end

function M.check()
  if vim.fn.has('nvim-0.10') == 0 then vim.health.error('Neovim 0.10 or later is required') end

  vim.health.start('winbar.nvim report')

  M.show_errors()
  M.show_warnings()
end

return M
