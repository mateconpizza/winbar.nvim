-- comp/readonly.lua

local function highlight()
  return require('winbar.highlight')
end

local hl_groups = {
  readonly = 'WinBarReadonly',
}

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
  [hl_groups.readonly] = { link = 'ErrorMsg' },
}

function M.render()
  return highlight().string(hl_groups.readonly, M.icon)
end

---@param icon string
---@return winbar.component
function M.setup(icon)
  M.icon = icon or '[RO]'
  return M
end

return M
