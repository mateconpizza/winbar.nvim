---@module 'winbar'
---@brief [[
---
---             ╻ ╻╻┏┓╻┏┓ ┏━┓┏━┓ ┏┓╻╻ ╻╻┏┳┓
---             ┃╻┃┃┃┗┫┣┻┓┣━┫┣┳┛ ┃┗┫┃┏┛┃┃┃┃
---             ┗┻┛╹╹ ╹┗━┛╹ ╹╹┗╸╹╹ ╹┗┛ ╹╹ ╹
---       -Configurable and minimal Neovim WinBar-
---
---@brief ]]

local C = require('winbar.components')
local H = require('winbar.highlight')
local R = require('winbar.registry')
local U = require('winbar.util')

---@class WinBar
local M = {}

M.config = require('winbar.config')

-- auto-refresh winbar on relevant events
local function setup_autocmds()
  vim.api.nvim_create_autocmd({
    'BufEnter',
    'BufWritePost',
    'TextChanged',
    'TextChangedI',
    'DiagnosticChanged',
    'LspAttach',
    'LspDetach',
  }, {
    group = U.augroup('WinBar'),
    callback = function()
      -- clear cache on relevant events
      C.cache.diagnostics = {}
      C.cache.git_branch = nil

      -- force winbar refresh
      vim.cmd('redrawstatus')
    end,
  })
end

-- render the winbar content based on configuration and current buffer state.
function M.render()
  if U.is_special_buffer(M.config) then
    return ''
  end

  if not M.config.show_single_buffer then
    local visible_buffers = vim.tbl_filter(function(buf)
      -- count visibles buffers only. Ignore floating windows (fzf-lua, Mason, etc)
      return vim.api.nvim_buf_is_loaded(buf)
        and vim.api.nvim_buf_get_name(buf) ~= ''
        and U.is_visible_in_normal_win(buf)
    end, vim.api.nvim_list_bufs())

    if #visible_buffers < 2 then
      return ''
    end
  end

  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname == '' then
    return '[No Name]'
  end

  local filename = vim.fn.fnamemodify(bufname, ':t')
  if filename == '' then
    return ''
  end

  -- build
  local parts = {}

  -- render based on config layout config
  for _, name in ipairs(M.config.layout.left) do
    local component = R.registry[name]
    if component and component.enabled() then
      local content = component.render()
      if content and content ~= '' then
        table.insert(parts, content)
      end
    end
  end

  table.insert(parts, '%=')

  for _, name in ipairs(M.config.layout.right) do
    local component = R.registry[name]
    if component and component.enabled() then
      local content = component.render()
      if content and content ~= '' then
        table.insert(parts, content)
      end
    end
  end

  return table.concat(parts, ' ')
end

---@param opts? WinBar.Config
function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', vim.deepcopy(M.config), opts or {})

  -- styles are replaced entirely
  if opts and opts.styles then
    for key, style in pairs(opts.styles) do
      M.config.styles[key] = style
    end
  end

  if not M.config.enabled then
    return
  end

  setup_autocmds()

  -- define all components
  R.setup(M.config)

  -- apply highlights
  H.setup(M.config.styles)

  _G._winbar_render = M.render
  vim.o.winbar = '%{%v:lua._winbar_render()%}'
end

return M
