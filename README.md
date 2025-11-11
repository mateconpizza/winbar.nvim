# winbar.nvim

<p align="center">
    <img src="./assets/screenshot.png"
    alt="Preview" style="width: 80%; max-width: 600px; height: auto;">
</p>

## Setup

```lua
require('winbar').setup({
  enabled = true,

  file_icon = true, -- show file icon
  show_single_buffer = true, -- show with single buffer

  exclude_filetypes = { -- filetypes to exclude from WinBar display.
    'aerial',
    'dap-float',
    'fugitive',
    'oil',
    'Trouble',
    'lazy',
    'man',
  },
  exclude_buftypes = { -- buffer types to exclude from WinBar display.
    'terminal',
    'quickfix',
    'help',
    'nofile',
    'nowrite',
  },

  icons = {
    modified = '●', -- icon for modified buffers.
    readonly = '', -- icon for readonly buffers.
    git_branch = '', -- icon for Git branch indicator.
  },

  diagnostics = { -- WIP
    enabled = true,
    style = 'standard', -- or 'mini'
    bug_icon = '󰃤',
    show_detail = true,
    icons = {
      error = '✗:',
      hint = 'h:',
      info = 'i:',
      warn = 'w:',
    },
  },

  lsp_status = true, -- show LSP clients
  git_branch = true, -- show git branch

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
    winbarnc = { link = 'StatusLineNC' },
    git_branch = { link = 'Comment' },
    lsp_status = { link = 'Comment' },
    readonly = { link = 'ErrorMsg' },
    modified = { link = 'WarningMsg' },
  },
})
```

## Highlight groups

| Group             | Default      | Description                              |
| ----------------- | ------------ | ---------------------------------------- |
| `WinBar`          | StatusLine   | Active winbar highlight                  |
| `WinBarNC`        | StatusLineNC | Winbar highlight when buffer loses focus |
| `WinBarGitBranch` | Comment      | Git branch highlight                     |
| `WinBarLspStatus` | Comment      | LSP status highlight                     |
| `WinBarReadonly`  | ErrorMsg     | LSP status highlight                     |
| `WinBarModified`  | WarningMsg   | LSP status highlight                     |
