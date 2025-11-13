---@diagnostic disable: undefined-field

local U = require('winbar.util')

local function has_plugin(name)
  local ok, _ = pcall(require, name)
  return ok
end

---@module 'winbar.components'
---@class winbar.components
local M = {}

-- cache for performance
M.cache = {
  diagnostics = {},
  git_branch = nil,
  git_diff = nil,
  last_update = 0,
}

M.hl = require('winbar.highlight').highlights

-- formats diagnostic counts in standard mode
---@param counts table
---@param icons winbar.diagnosticIcons
---@return string
local function format_standard(counts, icons)
  icons = icons or {}
  local components = {}

  if counts.errors > 0 then
    table.insert(components, '%#DiagnosticError#' .. icons.error .. counts.errors .. '%*')
  end
  if counts.warnings > 0 then
    table.insert(components, '%#DiagnosticWarn#' .. icons.warn .. counts.warnings .. '%*')
  end
  if counts.info > 0 then
    table.insert(components, '%#DiagnosticInfo#' .. icons.info .. counts.info .. '%*')
  end
  if counts.hints > 0 then
    table.insert(components, '%#DiagnosticHint#' .. icons.hint .. counts.hints .. '%*')
  end

  return table.concat(components, ' ')
end

-- formats diagnostic counts in minimalist mode
---@param counts table
---@return string
local function format_mini(counts)
  local icon = '󰃤'
  local components = {}

  if counts.errors > 0 then
    table.insert(components, '%#DiagnosticError#' .. icon .. ' ' .. counts.errors .. '%*')
  end
  if counts.warnings > 0 then
    table.insert(components, '%#DiagnosticWarn#' .. icon .. ' ' .. counts.warnings .. '%*')
  end
  if counts.info > 0 then
    table.insert(components, '%#DiagnosticInfo#' .. icon .. ' ' .. counts.info .. '%*')
  end
  if counts.hints > 0 then
    table.insert(components, '%#DiagnosticHint#' .. icon .. ' ' .. counts.hints .. '%*')
  end

  return table.concat(components, ' ')
end

function M.file_icon(filename)
  -- FIX: add for `mini.icons` https://github.com/echasnovski/mini.nvim
  local has_devicons, devicons = pcall(require, 'nvim-web-devicons')
  if has_devicons then
    local icon, hl = devicons.get_icon(filename, vim.fn.fnamemodify(filename, ':e'), { default = true })
    if icon and hl then
      return '%#' .. hl .. '#' .. icon .. '%*'
    end
  end
  return ''
end

-- lsp client names for current buffer as formatted status string.
---@param lsp winbar.lspStatus
function M.lsp_status(lsp)
  if vim.o.columns < 60 then
    return ''
  end

  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    return ''
  end

  local names = {}
  for _, client in pairs(clients) do
    table.insert(names, client.name)
  end

  local result = lsp.format(table.concat(names, lsp.separator))

  return '%#' .. M.hl.lsp_status.group .. '#' .. result .. '%*'
end

-- current git branch name as formatted string with icon, cached for performance.
---@param icon string
function M.git_branch(icon)
  if M.cache.git_branch then
    return M.cache.git_branch
  end

  -- check if git is available
  if vim.fn.executable('git') ~= 1 then
    M.cache.git_branch = ''
    return ''
  end

  -- check if inside a git repository
  local is_git_repo = vim.fn.system({ 'git', 'rev-parse', '--is-inside-work-tree' })
  if vim.v.shell_error ~= 0 or not is_git_repo:match('true') then
    M.cache.git_branch = ''
    return ''
  end

  -- get current branch name
  local branch = vim.fn.system({ 'git', 'rev-parse', '--abbrev-ref', 'HEAD' }):gsub('\n', '')
  if vim.v.shell_error ~= 0 or branch == '' then
    M.cache.git_branch = ''
    return ''
  end

  M.cache.git_branch = string.format('%%#%s#%s %s%%*', M.hl.git_branch.group, icon, branch)
  return M.cache.git_branch
end

-- diagnostic counts for the current buffer
---@param bufnr number
---@return table table with counts {errors, warnings, info, hints}
local function get_diagnostic_counts(bufnr)
  local diag = vim.diagnostic
  return {
    errors = #diag.get(bufnr, { severity = diag.severity.ERROR }),
    warnings = #diag.get(bufnr, { severity = diag.severity.WARN }),
    hints = #diag.get(bufnr, { severity = diag.severity.HINT }),
    info = #diag.get(bufnr, { severity = diag.severity.INFO }),
  }
end

-- formatted string of diagnostic counts for the current buffer.
-- cached for 100ms.
---@param style? "standard"|"mini"
---@param icons winbar.diagnosticIcons
---@return string
function M.diagnostics(style, icons)
  local bufnr = vim.api.nvim_get_current_buf()
  local current_time = vim.loop.hrtime()
  local style_key = style or 'standard'

  -- use a unique cache key per buffer/style combination
  local cache_key = bufnr .. '_' .. style_key
  local cache = M.cache.diagnostics

  -- cache diagnostics for 100ms
  if cache[cache_key] and (current_time - M.cache.last_update) < 100000000 then
    return cache[cache_key]
  end

  local counts = get_diagnostic_counts(bufnr)
  local result = (style_key == 'mini') and format_mini(counts) or format_standard(counts, icons)

  cache[cache_key] = result
  M.cache.last_update = current_time

  return result
end

-- formatted string of diagnostic counts in minimalist mode for the current buffer.
-- cached for 100ms.
---@return string a string with the counts using icons instead of prefixes
function M.diagnostics_mini()
  local bufnr = vim.api.nvim_get_current_buf()
  local current_time = vim.loop.hrtime()

  -- Use separate cache key for mini mode
  local cache_key = bufnr .. '_mini'
  if M.cache.diagnostics[cache_key] and (current_time - M.cache.last_update) < 100000000 then
    return M.cache.diagnostics[cache_key]
  end

  local counts = get_diagnostic_counts(bufnr)
  local result = format_mini(counts)

  M.cache.diagnostics[cache_key] = result
  M.cache.last_update = current_time
  return result
end

---@param bufname string
---@param filename string
---@return string
function M.filename(bufname, filename)
  local all_buffers = vim.api.nvim_list_bufs()
  local duplicates = 0
  for _, buf in ipairs(all_buffers) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      if vim.fn.fnamemodify(name, ':t') == filename then
        duplicates = duplicates + 1
      end
    end
  end

  if duplicates > 1 then
    filename = require('winbar.util').get_relative_path(bufname)
  end

  return filename
end

---@param icon string
function M.readonly(icon)
  return '%#' .. M.hl.readonly.group .. '#' .. icon .. '%*'
end

---@param icon string
function M.modified(icon)
  return '%#' .. M.hl.modified.group .. '#' .. icon .. '%*'
end

---@param bufnr integer
---@param update_interval integer
---@param c winbar.gitdiff
function M.git_diff_signs(bufnr, update_interval, c)
  local cache_key = 'git_diff_' .. bufnr
  local cache = M.cache
  local ttl = update_interval * 1e6 -- to nanoseconds

  local cached = U.get_cached(cache, cache_key, ttl)
  if cached then
    return cached
  end

  local ok, gitsigns = pcall(require, 'gitsigns')
  if not ok then
    return ''
  end

  local hunks = gitsigns.get_hunks(bufnr)
  if not hunks or #hunks == 0 then
    return ''
  end

  local added, changed, removed = 0, 0, 0
  for _, hunk in ipairs(hunks) do
    if hunk.type == 'add' then
      added = added + hunk.added.count
    elseif hunk.type == 'change' then
      changed = changed + hunk.added.count + hunk.removed.count
    elseif hunk.type == 'delete' then
      removed = removed + hunk.removed.count
    end
  end

  local result = M.format_gitdiff_output(c, { added = added, changed = changed, removed = removed })
  U.set_cached(cache, cache_key, result)

  return result
end

---@param bufnr integer
---@param update_interval integer
---@param c winbar.gitdiff
function M.git_diff_stats_mini(bufnr, update_interval, c)
  local cache_key = 'git_diff_' .. bufnr
  local cache = M.cache
  local ttl = update_interval * 1e6 -- to nanoseconds

  local cached = U.get_cached(cache, cache_key, ttl)
  if cached then
    return cached
  end

  local ok, MiniDiff = pcall(require, 'mini.diff')
  if not ok then
    return ''
  end

  local data = MiniDiff.get_buf_data(bufnr)
  if not data then
    return ''
  end

  local hunks = data.summary
  if not hunks then
    return ''
  end

  local added = hunks.add or 0
  local changed = hunks.change or 0
  local removed = hunks.delete or 0

  local result = M.format_gitdiff_output(c, { added = added, changed = changed, removed = removed })
  U.set_cached(cache, cache_key, result)

  return result
end

---@return fun(bufnr: integer, update_interval: integer, c: winbar.gitdiff)
function M.get_gitdiff_strategy()
  if M.cache.git_diff then
    return M.cache.git_diff
  end

  local strategies = {
    { 'gitsigns', M.git_diff_signs },
    { 'mini.diff', M.git_diff_stats_mini },
  }

  vim.api.nvim_create_autocmd('BufDelete', {
    callback = function(args)
      M.cache['git_diff_' .. args.buf] = nil
    end,
  })

  for _, s in ipairs(strategies) do
    if has_plugin(s[1]) then
      M.cache.git_diff = s[2]
      return M.cache.git_diff
    end
  end

  -- default
  M.cache.git_diff = function()
    return ''
  end

  return M.cache.git_diff
end

---@param c winbar.gitdiff
---@param hunks table<string, integer>
function M.format_gitdiff_output(c, hunks)
  local h = M.hl
  local parts = {}
  if hunks.added > 0 then
    table.insert(parts, '%#' .. h.diffadded.group .. '#' .. string.format('%s%d', c.added, hunks.added) .. '%*')
  end
  if hunks.changed > 0 then
    table.insert(parts, '%#' .. h.diffchanged.group .. '#' .. string.format('%s%d', c.changed, hunks.changed) .. '%*')
  end
  if hunks.removed > 0 then
    table.insert(parts, '%#' .. h.diffremoved.group .. '#' .. string.format('%s%d', c.removed, hunks.removed) .. '%*')
  end

  return table.concat(parts, ' ')
end

return M
