# winbar.nvim

## Setup

```lua
require('winbar').setup({
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
    style = 'standard', -- or 'mini' (wip)
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
})
```

## Highlight groups

- `WinBar` : Active winbar highlight
- `WinBarNC` : Winbar highlight when buffer loses focus
