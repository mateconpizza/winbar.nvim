---@class winbar.diagnosticIcons
---@field error string? icon for errors.
---@field hint string? icon for hints.
---@field info string? icon for infos.
---@field warn string? icon for warnings.

---@class winbar.diagnostics
---@field enabled boolean? enable diagnostics.
---@field style 'mini' | 'standard'? diagnostics style (standard or mini).
---@field icons winbar.diagnosticIcons?
---@field min_width? integer minimum window width required to display this component.

---@class winbar.lspClients
---@field enabled boolean? enable LSP client name display.
---@field separator? string? separator between multiple LSP clients.
---@field format? fun(clients: string): string custom formatter for client names.
---@field min_width? integer minimum window width required to display this component.

---@class winbar.icons
---@field modified string? icon for modified buffers.
---@field readonly string? icon for readonly buffers.

---@class winbar.layout
---@field left string[]? ordered list of left-aligned component names.
---@field center string[]? ordered list of center component names.
---@field right string[]? ordered list of right-aligned component names.

---@class winbar.userHighlights
---@field winbar winbar.highlightAttrs? active window WinBar highlight
---@field winbarnc winbar.highlightAttrs? inactive window WinBar highlight
---@field lsp_status winbar.highlightAttrs? LSP client name highlights.
---@field readonly winbar.highlightAttrs? read-only indicator highlight
---@field modified winbar.highlightAttrs? modified buffer indicator highlight
---@field git_branch winbar.highlightAttrs? git branch highlights.
---@field diffadded winbar.highlightAttrs? git diff added lines highlight
---@field diffchanged winbar.highlightAttrs? git diff changed lines highlight
---@field diffremoved winbar.highlightAttrs? git diff removed lines highlight

---@class winbar.exclusions
---@field filetypes string[]? filetypes to exclude from WinBar display.
---@field buftypes string[]? buffer types to exclude from WinBar display.

---@class winbar.gitbranch
---@field enabled boolean?
---@field icon string? icon for Git branch indicator.
---@field min_width? integer minimum window width required to display this component.

---@class winbar.gitdiff
---@field enabled boolean?
---@field added string? icon for added files in git diff
---@field changed string? icon for changed files in git diff
---@field removed string? icon for removed files in git diff
---@field min_width? integer minimum window width required to display this component.

---@class winbar.git
---@field branch winbar.gitbranch? git branch configuration
---@field diff winbar.gitdiff? git diff configuration

---@class winbar.filename
---@field enabled boolean?
---@field icon boolean? -- show file icon (e.g., via nvim-web-devicons)
---@field format? fun(clients: string): string custom formatter for the filename.
---@field min_width? integer minimum window width required to display this component.

---@class (exact) winbar.config
---@field enabled boolean?
---@field update_interval integer? interval in milliseconds
---@field filename winbar.filename
---@field diagnostics winbar.diagnostics? diagnostics.
---@field lsp winbar.lspClients? LSP client name display..
---@field icons winbar.icons? icons used throughout the WinBar.
---@field show_single_buffer boolean? show with single buffer.
---@field exclusions table<string, string[]>?
---@field git winbar.git?
---@field layout winbar.layout?
---@field styles winbar.userHighlights? winbar highlights.
---@field dev_mode? boolean @private -- enable debug features
return {
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
  },
  show_single_buffer = true, -- Show WinBar even with a single visible buffer
  exclusions = {
    filetypes = {
      -- Filetypes where WinBar will not be shown
      'aerial',
      'dap-float',
      'fugitive',
      'oil',
      'Trouble',
      'lazy',
      'man',
    },
    -- Buffer types where WinBar will not be shown
    buftypes = {
      'help',
      'netrw',
      'nofile',
      'nowrite',
      'quickfix',
      'terminal',
    },
  },
  -- Icons used across components
  icons = {
    modified = '[+]', -- Shown for unsaved buffers (choice: ●)
    readonly = '[RO]', -- Shown for readonly buffers (choice: )
  },
  -- Diagnostics configuration
  diagnostics = {
    enabled = true, -- Show diagnostics (LSP/linters)
    style = 'standard', -- Display style ("standard" or "mini")
    icons = { -- Diagnostic severity icons
      error = 'e:',
      hint = 'h:',
      info = 'i:',
      warn = 'w:',
    },
    min_width = 55,
  },
  -- LSP client name display
  lsp = {
    enabled = true, -- Enable LSP client display
    separator = ',', -- Separator for multiple clients
    format = function(clients) -- Formatter for LSP client names
      return clients
    end,
    min_width = 50,
  },
  -- Git display
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
    lsp_status = { link = 'Comment' }, -- LSP client highlight
    readonly = { link = 'ErrorMsg' }, -- Read-only indicator highlight
    modified = { link = 'WarningMsg' }, -- Modified buffer indicator highlight
    git_branch = { link = 'Comment' }, -- Git branch highlight
    diffadded = { link = 'Comment' }, -- Git diff added lines highlight
    diffchanged = { link = 'Comment' }, -- Git diff changed lines highlight
    diffremoved = { link = 'Comment' }, -- Git diff removed lines highlight
    diag_error = { link = 'DiagnosticError' }, -- Lsp Diagnostic error highlight
    diag_warn = { link = 'DiagnosticWarn' }, -- Lsp Diagnostic warning highlight
    diag_info = { link = 'DiagnosticInfo' }, -- Lsp Diagnostic info highlight
    diag_hint = { link = 'DiagnosticHint' }, -- Lsp Diagnostic hint highlight
  },
  -- Dev mode
  dev_mode = false,
}
