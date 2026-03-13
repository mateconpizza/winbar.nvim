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

---@param c winbar.git.diff
---@param diffstat string
---@param is_active boolean
local function format_gitdiff_output(c, diffstat, is_active)
  local hunks = parse_diffstat(diffstat)
  local parts = {}
  local groups = {
    added = is_active and hl_groups.added or highlighter().inactive,
    changed = is_active and hl_groups.changed or highlighter().inactive,
    removed = is_active and hl_groups.removed or highlighter().inactive,
  }

  local hl = highlighter().string

  if hunks.added > 0 then
    local group = groups.added
    table.insert(parts, hl(group, string.format('%s%d', c.added, hunks.added)))
  end

  if hunks.changed > 0 then
    local group = groups.changed
    table.insert(parts, hl(group, string.format('%s%d', c.changed, hunks.changed)))
  end

  if hunks.removed > 0 then
    local group = groups.removed
    table.insert(parts, hl(group, string.format('%s%d', c.removed, hunks.removed)))
  end

  return table.concat(parts, ' ')
end

---@class winbar.git.diff
---@field enabled boolean?
---@field added string? icon for added files in git diff
---@field changed string? icon for changed files in git diff
---@field removed string? icon for removed files in git diff
---@field min_width? integer minimum window width required to display this component.

---@class winbar.components.gitdiff: winbar.component
local M = {}

M.name = 'git_diff'
M.side = 'left'
M.interval_ms = nil
function M.enabled()
  return M.opts.enabled
end

---@type winbar.git.diff
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

  -- retrieve raw diffstat (cached)
  local diffstat = cache().ensure(M.name, bufnr, function()
    local d = vim.b[bufnr].minidiff_summary_string or vim.b[bufnr].gitsigns_status
    return d or ''
  end, M.interval_ms)

  if diffstat == '' then return '' end

  local is_active = utils().is_active_win()

  -- format and highlight (dynamic)
  return format_gitdiff_output(M.opts, diffstat, is_active)
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

---@param opts winbar.git.diff
---@param interval_ms integer
---@return winbar.component
function M.setup(opts, interval_ms)
  M.opts = opts or {}
  M.interval_ms = interval_ms
  return M
end

return M
