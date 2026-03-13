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

local function with_icon(icon, text)
  if icon == nil or icon == '' then return text end
  return icon .. ' ' .. text
end

local hl_groups = {
  branch = 'WinBarGitBranch',
}

---@class winbar.git.branch
---@field enabled boolean?
---@field icon string? icon for Git branch indicator.
---@field min_width? integer minimum window width required to display this component.

---@class winbar.components.gitbranch: winbar.component
local M = {}

M.name = 'git_branch'
M.side = 'left'
M.interval_ms = nil
function M.enabled()
  return M.opts.enabled
end

---@type winbar.git.branch
M.opts = {}

---@class winbar.userHighlights
---@field WinBarGitBranch winbar.HighlightAttrs? git branch highlight
M.highlights = {
  [hl_groups.branch] = { link = 'Comment' },
}

function M.render()
  if utils().is_narrow(M.opts.min_width) then return '' end

  local bufnr = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  if bufname == '' then return '' end

  local branch_name = cache().ensure(M.name, bufnr, function()
    -- check for external plugin variables first
    local b = vim.b[bufnr].minigit_summary_string or vim.b[bufnr].gitsigns_head
    if b then return b end

    -- fallback to shell command
    return utils().git_branch()
  end)

  if not branch_name or branch_name == '' then return '' end

  local hl_group = hl_groups.branch
  if not utils().is_active_win() then hl_group = highlight().inactive end

  return highlight().string(hl_group, with_icon(M.opts.icon, branch_name))
end

function M.autocmd(augroup)
  vim.api.nvim_create_autocmd({ 'DirChanged', 'BufEnter' }, {
    group = augroup,
    callback = function(args)
      local bufnr = args.buf

      if not utils().is_normal_buffer(bufnr) then return end
      if not utils().is_visible_in_normal_win(bufnr) then return end

      cache().invalidate(M.name, bufnr)
      utils().throttled_redraw(M.interval_ms)
    end,
    desc = 'update git branch display when directory or buffer changes',
  })
end

---@param opts winbar.git.branch
---@param interval_ms integer
---@return winbar.component
function M.setup(opts, interval_ms)
  M.opts = opts or {}
  M.interval_ms = interval_ms
  return M
end

return M
