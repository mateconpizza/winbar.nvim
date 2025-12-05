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

---@class winbar.components.gitbranch: winbar.component
local M = {}

M.name = 'git_branch'
M.side = 'left'
M.interval_ms = nil
function M.enabled()
  return M.opts.enabled
end

---@type winbar.gitbranch
M.opts = {}

---@class winbar.userHighlights
---@field WinBarGitBranch winbar.HighlightAttrs? git branch highlight
M.highlights = {
  WinBarGitBranch = { link = 'Comment' },
}

function M.render()
  local bufnr = vim.api.nvim_get_current_buf()
  if utils().is_narrow(M.opts.min_width) then return '' end

  local bufname = vim.api.nvim_buf_get_name(bufnr)
  if bufname == '' then return '' end
  local icon = M.opts.icon

  return cache().ensure(M.name, bufnr, function()
    -- check for external plugin
    local branch = vim.b.minigit_summary_string or vim.b.gitsigns_head
    if branch ~= nil then return highlight().string('WinBarGitBranch', icon .. ' ' .. branch) end

    -- fallback
    branch = utils().git_branch()
    if not branch then return '' end

    return highlight().string('WinBarGitBranch', with_icon(icon, branch))
  end)
end

function M.autocmd()
  vim.api.nvim_create_autocmd({ 'DirChanged', 'BufEnter' }, {
    group = cache().augroup,
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

---@param opts winbar.gitbranch
---@param interval_ms integer
---@return winbar.component
function M.setup(opts, interval_ms)
  M.opts = opts or {}
  M.interval_ms = interval_ms
  return M
end

return M
