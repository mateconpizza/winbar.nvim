-- comp/readonly.lua

local function highlight()
  return require('winbar.highlight')
end

---@class winbar.components.readonly: winbar.component
local M = {}

M.name = 'readonly'
M.side = 'right'
M.icon = ''
function M.enabled()
  return vim.bo.readonly
end

---@class winbar.userHighlights
---@field WinBarReadonly winbar.HighlightAttrs? readonly highlight
M.highlights = {
  WinBarReadonly = { link = 'ErrorMsg' },
}

function M.render()
  return highlight().string('WinBarReadonly', M.icon)
end

---@param icon string
---@return winbar.component
function M.setup(icon)
  M.icon = icon or '[RO]'
  return M
end

return M
