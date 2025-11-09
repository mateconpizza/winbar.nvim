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
    enabled = false,
    bug_icon = '󰃤',
    show_detail = true,
  },

  lsp_status = true,
  git_branch = true,
})
```
