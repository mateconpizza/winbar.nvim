-- cmp/readonly.lua

---@class winbar.components.modified: winbar.component
local M = {}

M.name = 'modified'
M.side = 'right'
M.icon = '[+]'
function M.enabled()
  return vim.bo.modified
end

---@class winbar.userHighlights
---@field readonly winbar.highlight? LSP client name highlights.
M.highlights = {
  modified = { group = 'WinBarModified', default = { link = 'WarningMsg' } },
}

function M.render()
  return '%#' .. M.highlights.modified.group .. '#' .. M.icon .. '%*'
end

---@param icon string
---@return winbar.component
function M.setup(icon)
  M.icon = icon
  return M
end

return M
