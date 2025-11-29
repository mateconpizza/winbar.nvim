---@alias winbar.highlightAttrs vim.api.keyset.highlight

---@module 'winbar.highlight'
---@class winbar.highlighter
local M = {}

---@alias winbar.HighlightAttrs vim.api.keyset.highlight

---@class winbar.highlights[]
M.highlights = {}

-- sets a highlight group
---@param name string
---@param val any
function M.set_highlight(name, val)
  vim.api.nvim_set_hl(0, name, val)
end

---@param highlights winbar.HighlightAttrs[]
function M.merge(highlights)
  M.highlights = vim.tbl_deep_extend('force', M.highlights or {}, highlights or {})
end

-- create a string with highlight group applied
--- @param highlight_group string The highlight group name
--- @param text string The text to highlight
--- @return string The formatted highlight string
function M.string(highlight_group, text)
  return '%#' .. highlight_group .. '#' .. text .. '%*'
end

---@param user_hl winbar.HighlightAttrs
function M.setup(user_hl)
  user_hl = user_hl or {}

  -- merge defaults with user overrides
  M.highlights = vim.tbl_deep_extend('force', M.highlights, user_hl)

  -- apply all highlight groups
  for group, attrs in pairs(M.highlights) do
    M.set_highlight(group, attrs)
  end
end

return M
