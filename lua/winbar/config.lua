---@module 'winbar.config'

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
return {
  -- Core behavior
  enabled = true, -- Enable the WinBar plugin
  file_icon = true, -- Show file icon (e.g., via nvim-web-devicons)
  show_single_buffer = true, -- Show WinBar even with a single visible buffer

  -- Exclusions
  exclude_filetypes = { -- Filetypes where WinBar will not be shown
    'aerial',
    'dap-float',
    'fugitive',
    'oil',
    'Trouble',
    'lazy',
    'man',
  },
  exclude_buftypes = { -- Buffer types where WinBar will not be shown
    'terminal',
    'quickfix',
    'help',
    'nofile',
    'nowrite',
  },

  -- Icons used across components
  icons = {
    modified = '●', -- Shown for unsaved buffers
    readonly = '', -- Shown for readonly buffers
    git_branch = '', -- Git branch icon
  },

  -- Diagnostics configuration
  diagnostics = {
    enabled = true, -- Show diagnostics (LSP/linters)
    style = 'standard', -- Display style ("standard" or "mini")
    bug_icon = '󰃤', -- Icon shown before diagnostic counts
    show_detail = true, -- Show individual counts for each severity
    icons = { -- Diagnostic severity icons
      error = '✗:',
      hint = 'h:',
      info = 'i:',
      warn = 'w:',
    },
  },

  -- LSP client name display
  lsp = {
    enabled = true, -- Enable LSP client display
    separator = ',', -- Separator for multiple clients
    format = function(clients) -- Formatter for LSP client names
      return clients
    end,
  },

  -- Git branch display
  git_branch = true, -- Show the current Git branch

  -- Layout of the WinBar
  layout = {
    left = { 'git_branch' }, -- Components aligned to the left
    right = { -- Components aligned to the right
      'lsp_status',
      'diagnostics',
      'modified',
      'readonly',
      'file_icon',
      'filename',
    },
  },

  -- Highlight groups
  styles = {
    winbar = { link = 'StatusLine' }, -- Active window WinBar highlight
    winbarnc = { link = 'Comment' }, -- Inactive window WinBar highlight
    git_branch = { link = 'Comment' }, -- Git branch highlight
    lsp_status = { link = 'Comment' }, -- LSP client highlight
    readonly = { link = 'ErrorMsg' }, -- Readonly icon highlight
    modified = { link = 'WarningMsg' }, -- Modified indicator highlight
  },
}
