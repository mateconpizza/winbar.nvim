local C = require('winbar.components')
local R = require('winbar.registry')
local U = require('winbar.util')

---@class WinBar
local M = {}

---@class WinBar.DiagnosticIcons
---@field error? string icon for errors
---@field hint? string icon for hints
---@field info? string icon for infos
---@field warning? string icon for warnings

---@class WinBar.Diagnostic
---@field enabled? boolean enable diagnostics
---@field style? string diagnostics style (minimalist or standard)
---@field bug_icon? string show bug icon
---@field show_detail? boolean show detail
---@field icons? WinBar.DiagnosticIcons

---@class WinBar.Icons
---@field modified? string icon for modified buffers.
---@field readonly? string icon for readonly buffers.
---@field git_branch? string icon for Git branch indicator.

---@class WinBar.Layout
---@field left? string[] ordered list of left-aligned component names.
---@field right? string[] ordered list of right-aligned component names.

---@class WinBar.Config
---@field enabled? boolean
---@field file_icon? boolean show file icon
---@field diagnostics? WinBar.Diagnostic diagnostics
---@field lsp_status? boolean enable lsp name
---@field icons? WinBar.Icons icons used throughout the WinBar
---@field show_single_buffer? boolean show with single buffer
---@field exclude_filetypes? string[] filetypes to exclude from WinBar display.
---@field exclude_buftypes? string[] buffer types to exclude from WinBar display.
---@field git_branch? boolean show git branch
M.config = {
  enabled = true,

  file_icon = true,
  show_single_buffer = true,

  exclude_filetypes = {
    'aerial',
    'dap-float',
    'fugitive',
    'oil',
    'Trouble',
    'lazy',
    'man',
  },
  exclude_buftypes = {
    'terminal',
    'quickfix',
    'help',
    'nofile',
    'nowrite',
  },

  icons = {
    modified = '●',
    readonly = '',
    git_branch = '',
  },

  diagnostics = {
    enabled = true,
    style = 'standard',
    bug_icon = '󰃤',
    show_detail = true,
    icons = {
      error = '✗:',
      hint = 'h:',
      info = 'i:',
      warn = 'w:',
    },
  },

  lsp_status = true,
  git_branch = true,

  layout = {
    left = { 'git_branch' },
    right = {
      'lsp_status',
      'diagnostics',
      'modified',
      'readonly',
      'file_icon',
      'filename',
    },
  },
}

-- auto-refresh winbar on relevant events
local function setup_autocmds()
  local group = U.augroup('WinBar')

  vim.api.nvim_create_autocmd({
    'BufEnter',
    'BufWritePost',
    'TextChanged',
    'TextChangedI',
    'DiagnosticChanged',
    'LspAttach',
    'LspDetach',
  }, {
    group = group,
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
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
  if not M.config.enabled then
    return
  end

  setup_autocmds()

  R.setup(M.config)
  _G._winbar_render = M.render

  -- set up winbar
  vim.o.winbar = '%{%v:lua._winbar_render()%}'
end

return M
