# WinBar

<p align="center">
    <img src="./assets/screenshot.png"
    alt="Preview" style="width: 80%; max-width: 600px; height: auto;">
</p>

<p align="center">- Configurable and minimal Neovim WinBar -<p>

## Components

- [x] LSP Clients
- [x] LSP Diagnostics
- [x] File Icon
- [x] Git Branch
- [ ] Git Diff

### Status

- [x] Readonly status
- [x] Modified status

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'mateconpizza/winbar.nvim',
  -- optional for file icon support
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  -- or if using mini.icons/mini.nvim (WIP)
  -- dependencies = { "nvim-mini/mini.icons" },
  ---@module 'winbar'
  ---@type winbar.config
  opts = {}
}
```

<details>
<summary>Default configuration</summary>

```lua
require('winbar').setup({
  -- Core behavior
  enabled = true, -- Enable the WinBar plugin
  file_icon = true, -- Show file icon (e.g., via nvim-web-devicons)
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
      'terminal',
      'quickfix',
      'help',
      'nofile',
      'nowrite',
    },
  },
  -- Icons used across components
  icons = {
    modified = '[+]', -- Shown for unsaved buffers (choice: ●)
    readonly = '[RO]', -- Shown for readonly buffers (choice: )
    git_branch = '', -- Git branch icon (choice: )
  },
  -- Diagnostics configuration
  diagnostics = {
    enabled = true, -- Show diagnostics (LSP/linters)
    style = 'standard', -- Display style ("standard" or "mini")
    bug_icon = '!', -- Icon shown before diagnostic counts (choice: 󰃤)
    show_detail = true, -- Show individual counts for each severity
    icons = { -- Diagnostic severity icons
      error = 'e:',
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
})
```

</details>

## Highlight groups

| Group             | Default      | Description                              |
| ----------------- | ------------ | ---------------------------------------- |
| `WinBar`          | StatusLine   | Active winbar highlight                  |
| `WinBarNC`        | StatusLineNC | Winbar highlight when buffer loses focus |
| `WinBarGitBranch` | Comment      | Git branch highlight                     |
| `WinBarLspStatus` | Comment      | LSP status highlight                     |
| `WinBarReadonly`  | ErrorMsg     | LSP status highlight                     |
| `WinBarModified`  | WarningMsg   | LSP status highlight                     |
