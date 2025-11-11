local C = require('winbar.components')
local H = require('winbar.highlight')
local R = require('winbar.registry')
local U = require('winbar.util')

---@class WinBar
local M = {}

---@class WinBar.DiagnosticIcons
---@field error? string icon for errors.
---@field hint? string icon for hints.
---@field info? string icon for infos.
---@field warning? string icon for warnings.

---@class WinBar.Diagnostic
---@field enabled? boolean enable diagnostics.
---@field style? string diagnostics style (minimalist or standard).
---@field bug_icon? string show bug icon.
---@field show_detail? boolean show detail.
---@field icons? WinBar.DiagnosticIcons

---@class WinBar.LspStatus
---@field enabled? boolean enable LSP client name display.
---@field separator? string separator between multiple LSP clients.
---@field format? fun(clients: string): string custom formatter for client names.

---@class WinBar.Icons
---@field modified? string icon for modified buffers.
---@field readonly? string icon for readonly buffers.
---@field git_branch? string icon for Git branch indicator.

---@class WinBar.Layout
---@field left? string[] ordered list of left-aligned component names.
---@field right? string[] ordered list of right-aligned component names.

---@class WinBar.UserHighlights
---@field git_branch? WinBar.HighlightAttrs git branch highlights.
---@field lsp_status? WinBar.HighlightAttrs LSP client name highlights.

---@class WinBar.Config
---@field enabled? boolean
---@field file_icon? boolean show file icon.
---@field diagnostics? WinBar.Diagnostic diagnostics.
---@field lsp? WinBar.LspStatus LSP client name display..
---@field icons? WinBar.Icons icons used throughout the WinBar.
---@field show_single_buffer? boolean show with single buffer.
---@field exclude_filetypes? string[] filetypes to exclude from WinBar display..
---@field exclude_buftypes? string[] buffer types to exclude from WinBar display..
---@field git_branch? boolean show git branch.
---@field styles? table<string, WinBar.HighlightAttrs> winbar highlights.
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

  lsp = {
    enabled = true,
    separator = ',',
    format = function(clients)
      return clients
    end,
  },

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

  styles = {
    winbar = { link = 'StatusLine' },
    winbarnc = { link = 'Comment' },
    git_branch = { link = 'Comment' },
    lsp_status = { link = 'Comment' },
    readonly = { link = 'ErrorMsg' },
    modified = { link = 'WarningMsg' },
  },
}

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
