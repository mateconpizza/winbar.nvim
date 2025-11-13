---@alias winbar.highlightAttrs vim.api.keyset.highlight

---@module 'winbar.highlight'
---@class winbar.highlighter
local M = {}

---@class winbar.highlight
---@field group string                    -- the actual highlight group name (used in :hi)
---@field default winbar.highlightAttrs   -- default highlight attributes for this group

---@class winbar.highlights
---@field git_branch winbar.highlight?    -- highlight for Git branch component
---@field lsp_status winbar.highlight?    -- highlight for LSP status indicator
---@field modified winbar.highlight?      -- highlight for modified buffer symbol
---@field readonly winbar.highlight?      -- highlight for readonly indicator
---@field diagnostics winbar.highlight?   -- WIP: highlight for diagnostics section
---@field file_icon winbar.highlight?     -- WIP: highlight for file icon component
-- stylua: ignore
M.highlights = {
  git_branch  = { group = 'WinBarGitBranch',      default = {} },
  lsp_status  = { group = 'WinBarLspStatus',      default = {} },
  readonly    = { group = 'WinBarReadonly',       default = {} },
  modified    = { group = 'WinBarModified',       default = {} },
  diffadded   = { group = 'WinBarGitDiffAdded',   default = {} },
  diffchanged = { group = 'WinBarGitDiffChanged', default = {} },
  diffremoved = { group = 'WinBarGitDiffRemoved', default = {} },
}

-- sets a highlight group
---@param name string
---@param val any
function M.set_hl(name, val)
  vim.api.nvim_set_hl(0, name, val)
end

---@param styles winbar.userHighlights
function M.setup(styles)
  for key, def in pairs(M.highlights) do
    if vim.fn.hlexists(def.group) == 0 then
      local style = styles[key]
      local attrs = style or def.default
      M.set_hl(def.group, attrs)
    end
  end
end

return M
