-- cmp/gitbranch.lua

local function cache()
  return require('winbar.cache')
end

local function utils()
  return require('winbar.util')
end

local function highlight()
  return require('winbar.highlight')
end

---@class winbar.components.gitbranch: winbar.component
local M = {}

M.name = 'git_branch'
M.side = 'left'
function M.enabled()
  return M.opts.enabled
end

---@type winbar.gitbranch
M.opts = {}

function M.render()
  local bufnr = vim.api.nvim_get_current_buf()
  if utils().is_narrow(M.opts.min_width) then return '' end

  local bufname = vim.api.nvim_buf_get_name(bufnr)
  if bufname == '' then return '' end
  local icon = M.opts.icon
  local hl = highlight().highlights

  return cache().ensure('gitbranch', bufnr, function()
    -- check for external plugin
    local branch = vim.b.minigit_summary_string or vim.b.gitsigns_head
    if branch ~= nil then return highlight().string(hl.git_branch.group, icon .. ' ' .. branch) end

    -- fallback
    branch = utils().git_branch()
    if not branch then return '' end

    return highlight().string(hl.git_branch.group, icon .. ' ' .. branch)
  end)
end

---@param opts winbar.gitbranch
---@return winbar.component
function M.setup(opts)
  M.opts = opts or {}
  return M
end

return M
