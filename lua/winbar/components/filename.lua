-- comp/filename.lua

local function cache()
  return require('winbar.cache')
end

local function utils()
  return require('winbar.util')
end

local function cmp_icon()
  return require('winbar.components.fileicon')
end

---@class winbar.components.filename: winbar.component
local M = {}

M.name = 'filename'
M.side = 'right'
M.enabled = function()
  return M.opts.enabled
end

---@type winbar.filename
M.opts = {}

---@return string
function M.render()
  if utils().is_narrow(M.opts.min_width) then return '' end

  local bufnr = vim.api.nvim_get_current_buf()

  return cache().ensure(M.name, bufnr, function()
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    local filename = vim.fn.fnamemodify(bufname, ':t')

    -- check if duplicate name
    local all_buffers = vim.api.nvim_list_bufs()
    local duplicates = 0
    for _, buf in ipairs(all_buffers) do
      if vim.api.nvim_buf_is_loaded(buf) then
        local name = vim.api.nvim_buf_get_name(buf)
        if vim.fn.fnamemodify(name, ':t') == filename then duplicates = duplicates + 1 end
      end
    end

    -- add relative path if duplicate
    if duplicates > 1 then filename = require('winbar.util').get_relative_path(bufname) end

    -- add icon
    if M.opts.icon then filename = cmp_icon().render() .. ' ' .. filename end

    return M.opts.format(filename)
  end)
end

---@param opts winbar.filename
---@return winbar.component
function M.setup(opts)
  M.opts = opts
  return M
end

return M
