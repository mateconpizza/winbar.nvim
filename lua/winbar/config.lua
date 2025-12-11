local M = {}

M.commands = {
  -- simple floating window for checking current cache state.
  inspect = 'WinBarCacheInspect',

  -- simple toggle winbar
  toggle = 'WinBarToggle',
}

---@class winbar.lsp
---@field clients winbar.lsp.clients? LSP client name display
---@field diagnostics winbar.lsp.diagnostics? diagnostics display
---@field progress winbar.lsp.progress? LSP progress spinner

---@class winbar.icons
---@field modified string? icon for modified buffers.
---@field readonly string? icon for readonly buffers.

---@class winbar.layout
---@field left string[]? ordered list of left-aligned component names.
---@field center string[]? ordered list of center component names.
---@field right string[]? ordered list of right-aligned component names.

---@class winbar.exclusions
---@field filetypes string[]? filetypes to exclude from WinBar display.
---@field buftypes string[]? buffer types to exclude from WinBar display.

---@class winbar.git
---@field branch winbar.git.branch? git branch configuration
---@field diff winbar.git.diff? git diff configuration

---@class (exact) winbar.config
---@field enabled boolean?
---@field update_interval integer? interval in milliseconds
---@field filename winbar.filename
---@field lsp winbar.lsp? LSP-related components
---@field icons winbar.icons? icons used throughout the WinBar.
---@field show_single_buffer boolean? show with single buffer.
---@field exclusions winbar.exclusions?
---@field git winbar.git?
---@field layout winbar.layout?
---@field highlights winbar.userHighlights? winbar highlights.
---@field dev_mode? boolean @private -- enable debug features
M.config = {
  -- Core behavior
  enabled = true, -- Enable the WinBar plugin
  update_interval = 1000, -- How much to wait in milliseconds before update (git diff, diagnostics)
  filename = {
    enabled = true,
    icon = true, -- Show file icon (e.g., via nvim-web-devicons)
    format = function(filename) -- Custom formatter for the filename.
      return filename
    end,
    min_width = 20,
    max_segments = 3, -- Show the last n folders/segments when two files share the same name.
  },
  show_single_buffer = true, -- Show WinBar even with a single visible buffer
  exclusions = {
    filetypes = {
      -- Filetypes where WinBar will not be shown
      'aerial',
      'checkhealth',
      'dap-float',
      'fugitive',
      'gitcommit',
      'gitrebase',
      'help',
      'lazy',
      'lspinfo',
      'man',
      'oil',
      'qf',
      'trouble',
    },
    -- Buffer types where WinBar will not be shown
    buftypes = {
      'help',
      'netrw',
      'nofile',
      'nowrite',
      'popup',
      'prompt',
      'quickfix',
      'scratch',
      'terminal',
    },
  },
  -- Icons used across components
  icons = {
    modified = '[+]', -- Shown for unsaved buffers (choice: ●)
    readonly = '[RO]', -- Shown for readonly buffers (choice: )
  },
  -- LSP components
  lsp = {
    -- LSP client name display
    clients = {
      enabled = true, -- Enable LSP client display
      separator = ',', -- Separator for multiple clients
      format = function(clients) -- Formatter for LSP client names
        return clients
      end,
      min_width = 50,
    },
    -- Diagnostics configuration
    diagnostics = {
      enabled = true, -- Show diagnostics
      style = 'standard', -- Display style (`standard` or `mini`)
      icons = { -- Diagnostic severity icons
        error = 'e:',
        hint = 'h:',
        info = 'i:',
        warn = 'w:',
      },
      min_width = 55,
    },
    -- LSP loading progress display
    progress = {
      enabled = true,
      spinner = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' },
      spinner_interval = 120,
      min_width = 50,
    },
  },
  -- Git components
  git = {
    branch = {
      enabled = true,
      icon = '', -- Git branch icon (choice: )
      min_width = 45,
    },
    diff = {
      enabled = true,
      added = '+',
      changed = '~',
      removed = '-',
      min_width = 50,
    },
  },
  -- Layout of the WinBar
  layout = {
    left = { 'git_branch', 'git_diff' }, -- Components aligned to the left
    center = {}, -- Components aligned to the center
    right = { -- Components aligned to the right
      'lsp_progress',
      'lsp_status',
      'lsp_diagnostics',
      'modified',
      'readonly',
      'file_icon',
      'filename',
    },
  },
  -- Highlight groups
  highlights = {},
  -- Dev mode
  dev_mode = false,
}

---@return winbar.exclusions
function M.parse_exclusions(exclusions)
  exclusions = exclusions or {}
  local filetypes = vim.tbl_deep_extend('force', M.config.exclusions.filetypes, exclusions.filetypes or {})
  local buftypes = vim.tbl_deep_extend('force', M.config.exclusions.buftypes, exclusions.buftypes or {})

  return { filetypes = filetypes, buftypes = buftypes }
end

return M
