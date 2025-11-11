---@alias WinBar.HighlightAttrs vim.api.keyset.highlight

---@class WinBar.Highlighter
local M = {}

---@class WinBar.Highlight
---@field group string                    -- the actual highlight group name (used in :hi)
---@field default WinBar.HighlightAttrs   -- default highlight attributes for this group

---@class WinBar.Highlights
---@field winbar WinBar.Highlight?        
---@field winbarnc WinBar.Highlight?      
---@field git_branch WinBar.Highlight?    -- highlight for Git branch component
---@field lsp_status WinBar.Highlight?    -- highlight for LSP status indicator
---@field modified WinBar.Highlight?      -- highlight for modified buffer symbol
---@field readonly WinBar.Highlight?      -- highlight for readonly indicator
---@field diagnostics WinBar.Highlight?   -- WIP: highlight for diagnostics section
---@field file_icon WinBar.Highlight?     -- WIP: highlight for file icon component
-- stylua: ignore
M.highlights = {
  winbar      = { group = 'WinBar',           default = {} },
  winbarnc    = { group = 'WinBarNC',         default = {} },
  git_branch  = { group = 'WinBarGitBranch',  default = {} },
  lsp_status  = { group = 'WinBarLspStatus',  default = {} },
  readonly    = { group = 'WinBarReadonly',   default = {} },
  modified    = { group = 'WinBarModified',   default = {} },
}

-- sets a highlight group
---@param name string
---@param val any
function M.set_hl(name, val)
  vim.api.nvim_set_hl(0, name, val)
end

---@param styles WinBar.UserHighlights
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
