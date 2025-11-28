---@alias winbar.highlightAttrs vim.api.keyset.highlight

---@module 'winbar.highlight'
---@class winbar.highlighter
local M = {}

---@class winbar.highlight
---@field group? string                    -- the actual highlight group name (used in :hi)
---@field default? winbar.highlightAttrs   -- default highlight attributes for this group

---@class winbar.highlights
M.highlights = {}

-- sets a highlight group
---@param name string
---@param val any
function M.set_highlight(name, val)
  vim.api.nvim_set_hl(0, name, val)
end

---@param highlights winbar.highlight[]
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

---@param highlights winbar.userHighlights
function M.setup(highlights)
  for key, def in pairs(M.highlights) do
    if vim.fn.hlexists(def.group) == 0 then
      local style = highlights[key]
      local attrs = style or def.default

      M.set_highlight(def.group, attrs)
    end
  end
end

return M
