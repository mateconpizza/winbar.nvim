-- cmp/gitdiff.lua

local function cache()
  return require('winbar.cache')
end

local function utils()
  return require('winbar.util')
end

local function highlighter()
  return require('winbar.highlight')
end

local hl_groups = {
  added = 'WinBarGitDiffAdded',
  changed = 'WinBarGitDiffChanged',
  removed = 'WinBarGitDiffRemoved',
}

-- parse a git diff stat string
---@param diffstat string
---@return table<string, integer>
local function parse_diffstat(diffstat)
  local stats = { added = 0, changed = 0, removed = 0 }

  -- Match patterns like +22, ~30, -1 in any order
  for sign, num in diffstat:gmatch('([+~%-])(%d+)') do
    num = tonumber(num)
    if sign == '+' then
      stats.added = num
    elseif sign == '~' then
      stats.changed = num
    elseif sign == '-' then
      stats.removed = num
    end
  end

  return stats
end

---@param c winbar.gitdiff
---@param diffstat string
local function format_gitdiff_output(c, diffstat)
  local hunks = parse_diffstat(diffstat)
  local h = highlighter().string
  local parts = {}

  if hunks.added > 0 then table.insert(parts, h(hl_groups.added, string.format('%s%d', c.added, hunks.added))) end
  if hunks.changed > 0 then
    table.insert(parts, h(hl_groups.changed, string.format('%s%d', c.changed, hunks.changed)))
  end
  if hunks.removed > 0 then
    table.insert(parts, h(hl_groups.removed, string.format('%s%d', c.removed, hunks.removed)))
  end

  return table.concat(parts, ' ')
end

---@class winbar.components.gitdiff: winbar.component
local M = {}

M.name = 'git_diff'
M.side = 'left'
M.interval_ms = nil
function M.enabled()
  return M.opts.enabled
end

---@type winbar.gitdiff
M.opts = {}

-- stylua: ignore
---@class winbar.userHighlights
---@field WinBarGitDiffAdded winbar.HighlightAttrs?   git diff added lines highlight
---@field WinBarGitDiffChanged winbar.HighlightAttrs? git diff changed lines highlight
---@field WinBarGitDiffRemoved winbar.HighlightAttrs? git diff removed lines highlight
M.highlights = {
  [hl_groups.added]   = { link = 'Comment' },
  [hl_groups.changed] = { link = 'Comment' },
  [hl_groups.removed] = { link = 'Comment' },
}

function M.render()
  if utils().is_narrow(M.opts.min_width) then return '' end
  local bufnr = vim.api.nvim_get_current_buf()

  return cache().ensure(M.name, bufnr, function()
    local diffstat = vim.b.minidiff_summary_string or vim.b.gitsigns_status
    if diffstat == nil then return '' end

    return format_gitdiff_output(M.opts, diffstat)
  end, M.interval_ms)
end

function M.autocmd(augroup)
  vim.api.nvim_create_autocmd({ 'BufWritePost', 'BufEnter' }, {
    group = augroup,
    callback = function(args)
      local bufnr = args.buf

      if not utils().is_normal_buffer(bufnr) then return end
      if not utils().is_visible_in_normal_win(bufnr) then return end

      cache().invalidate(M.name, bufnr)
      utils().throttled_redraw(M.interval_ms)
    end,
    desc = 'refresh git diff status after file writes or buffer switches',
  })
end

---@param opts winbar.gitdiff
---@param interval_ms integer
---@return winbar.component
function M.setup(opts, interval_ms)
  M.opts = opts or {}
  M.interval_ms = interval_ms
  return M
end

return M
