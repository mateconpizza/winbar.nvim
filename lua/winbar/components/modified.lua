-- cmp/readonly.lua

local function utils()
  return require('winbar.util')
end

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
  local hl_group = hl_groups.modified
  if not utils().is_active_win() then hl_group = highlight().inactive end

  return highlight().string(hl_group, M.icon)
end

---@param icon string
---@return winbar.component
function M.setup(icon)
  M.icon = icon or '[+]'
  return M
end

return M
