# WinBar

<p align="center">
    <img src="./assets/screenshot.png"
    alt="Preview" style="width: 80%; max-width: 600px; height: auto;">
</p>

<p align="center">- Configurable and minimal Neovim WinBar -<p>

## Components

- [x] Filename (icon support)
- [x] LSP Clients
- [x] LSP Diagnostics
- [x] LSP Loading progress (wip)
- [x] File Icon
- [x] Git Branch
- [x] Git Diff

### Status

- [x] Readonly status
- [x] Modified status

### Optional / Extensions

Optional components are **not enabled by default.**

To enable one, add its configuration under the **extensions** table and include its name in your **layout** table.

<details>
<summary><strong>Vim mode</strong></summary>

```lua
extensions = {
  modes = {
    enabled = true,
    format = function(mode)
      return mode
    end,
  },
}
```

</details>

## Installation

Install with your preferred `plug-in manager`.

<details>
<summary>With <a href="https://github.com/nvim-mini/mini.deps">nvim-mini/mini.deps</a></summary>

```lua
require('mini.deps').later(function()
  require('mini.deps').add({
    source = 'mateconpizza/winbar.nvim',
    depends = {
      -- optional: add file icons to the winbar
      'nvim-mini/mini.icons',       -- or 'nvim-tree/nvim-web-devicons'

      -- optional: show git diff stats in the winbar
      'nvim-mini/mini.diff',        -- or 'lewis6991/gitsigns.nvim'
    },
  })

  require('winbar').setup()
end)
```

</details>

<details>
<summary>With <a href="https://github.com/folke/lazy.nvim">folke/lazy.nvim</a></summary>

```lua
{
  'mateconpizza/winbar.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = {
    -- optional: add file icons to the winbar
    'nvim-tree/nvim-web-devicons',  -- or use 'nvim-mini/mini.icons'

    -- optional: show git diff stats in the winbar
    'lewis6991/gitsigns.nvim',      -- or use 'nvim-mini/mini.diff'
  },
  ---@module 'winbar'
  ---@type winbar.config
  opts = {},
}
```

</details>

> [!NOTE]
> **Note**: You must call `require('winbar').setup()` to activate the plugin.

This plug-in adds a user command `WinBarToggle` for toggling the WinBar.

<details>
<summary><strong>Default configuration</strong></summary>

```lua
-- There's no need to include this in setup(). It will be used automatically.
require('winbar').setup({
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
  -- Optional components
  extensions = {},
  -- Layout of the WinBar
  layout = {
    left = { 'git_branch', 'git_diff' }, -- Components aligned to the left
    center = {}, -- Components at the center
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
  highlights = {
    WinBarModified              = { link = 'WarningMsg' },
    WinBarReadonly              = { link = 'ErrorMsg' },
    WinBarGitBranch             = { link = 'Comment' },
    WinBarGitDiffAdded          = { link = 'Comment' },
    WinBarGitDiffChanged        = { link = 'Comment' },
    WinBarGitDiffRemoved        = { link = 'Comment' },
    WinBarLspStatus             = { link = 'Comment' },
    WinBarDiagnosticError       = { link = 'DiagnosticError' },
    WinBarDiagnosticWarn        = { link = 'DiagnosticWarn' },
    WinBarDiagnosticInfo        = { link = 'DiagnosticInfo' },
    WinBarDiagnosticHint        = { link = 'DiagnosticHint' },
    WinBarLspProgress           = { link = 'Comment' },
    WinBarLspProgressSpinner    = { link = 'WarningMsg' },
    WinBarLspProgressDone       = { link = 'Constant' },
  },
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
})
```

</details>

<details>
<summary><strong>Highlight groups</strong></summary>

## Highlight groups

### Built-in components

| Group                      | Default         | Description                              |
| -------------------------- | --------------- | ---------------------------------------- |
| `WinBarReadonly`           | ErrorMsg        | File read-only indicator highlight       |
| `WinBarModified`           | WarningMsg      | File modified buffer indicator highlight |
| `WinBarGitBranch`          | Comment         | Git branch highlight                     |
| `WinBarGitDiffAdded`       | Comment         | Git diff added lines highlight           |
| `WinBarGitDiffChanged`     | Comment         | Git diff changed lines highlight         |
| `WinBarGitDiffRemoved`     | Comment         | Git diff removed lines highlight         |
| `WinBarLspStatus`          | Comment         | LSP client highlight                     |
| `WinBarDiagnosticError`    | DiagnosticError | LSP Diagnostic error highlight           |
| `WinBarDiagnosticWarn`     | DiagnosticWarn  | LSP Diagnostic warning highlight         |
| `WinBarDiagnosticInfo`     | DiagnosticInfo  | LSP Diagnostic info highlight            |
| `WinBarDiagnosticHint`     | DiagnosticHint  | LSP Diagnostic hint highlight            |
| `WinBarLspProgress`        | Comment         | LSP Progress loading                     |
| `WinBarLspProgressSpinner` | WarningMsg      | LSP Progress loading spinner             |
| `WinBarLspProgressDone`    | Constant        | LSP Progress loading done message        |

</details>

<details>
<summary><strong>Visible elements</strong></summary>

- Terminal: [st-terminal](https://st.suckless.org/)
- Font: [maple-font](https://github.com/subframe7536/maple-font)
- Colorscheme: built-in `Retrobox`

</details>

<details>
<summary><strong>Todo</strong></summary>

- [ ] Add `mini` opt to `lsp progress` component
  - Or maybe add `format` fn `func(progress, message, percentage, spinner)`
  - show only percentage and spinner

</details>
