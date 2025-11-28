-- comp/readonly.lua

---@class winbar.components.readonly: winbar.component
local M = {}

M.name = 'readonly'
M.side = 'right'
M.icon = '[RO]'
function M.enabled()
  return vim.bo.readonly
end

---@class winbar.userHighlights
---@field modified winbar.highlight? LSP client name highlights.
M.highlights = {
  readonly = { group = 'WinBarReadonly', default = { link = 'ErrorMsg' } },
}

function M.render()
  return '%#' .. M.highlights.readonly.group .. '#' .. M.icon .. '%*'
end

---@param icon string
---@return winbar.component
function M.setup(icon)
  M.icon = icon
  return M
end

return M
