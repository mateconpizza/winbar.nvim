-- cmp/readonly.lua

local function highlight()
  return require('winbar.highlight')
end

---@class winbar.components.modified: winbar.component
local M = {}

M.name = 'modified'
M.side = 'right'
M.icon = ''
function M.enabled()
  return vim.bo.modified
end

---@class winbar.userHighlights[]
---@field WinBarModified winbar.HighlightAttrs? modified highlight
M.highlights = {
  WinBarModified = { link = 'WarningMsg' },
}

function M.render()
  return highlight().string('WinBarModified', M.icon)
end

---@param icon string
---@return winbar.component
function M.setup(icon)
  M.icon = icon or '[+]'
  return M
end

return M
