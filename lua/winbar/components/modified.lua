-- cmp/readonly.lua

local function highlight()
  return require('winbar.highlight')
end

local hl_groups = {
  modified = 'WinBarModified',
}

---@class winbar.components.modified: winbar.component
local M = {}

M.name = 'modified'
M.side = 'right'
function M.enabled()
  return true
end

---@class winbar.userHighlights[]
---@field WinBarModified winbar.HighlightAttrs? modified highlight
M.highlights = {
  [hl_groups.modified] = { link = 'WarningMsg' },
}

function M.render()
  if not vim.bo.modified then return end
  return highlight().string(hl_groups.modified, M.icon)
end

---@param icon string
---@return winbar.component
function M.setup(icon)
  M.icon = icon or '[+]'
  return M
end

return M
