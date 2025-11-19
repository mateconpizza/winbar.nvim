---@diagnostic disable: undefined-field

local U = require('winbar.util')

---@module 'winbar.components'
---@class winbar.components
local M = {}

-- cache for performance
---@class winbar.cache
---@field fileicon table<string, string> cached file icon
---@field filename table<string, string> cached filename
---@field diagnostics table<string, string>  cached diagnostics per buffer
---@field git_diff fun(bufnr: integer, update_interval: integer, c: winbar.gitdiff)|nil  active git diff strategy function
---@field last_update integer                last update timestamp (nanoseconds or ms depending on usage)
M.cache = {
  fileicon = {},
  filename = {},
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
  if vim.o.columns < 60 then return '' end
  icons = icons or {}
  local components = {}

  if counts.errors > 0 then table.insert(components, '%#DiagnosticError#' .. icons.error .. counts.errors .. '%*') end
  if counts.warnings > 0 then table.insert(components, '%#DiagnosticWarn#' .. icons.warn .. counts.warnings .. '%*') end
  if counts.info > 0 then table.insert(components, '%#DiagnosticInfo#' .. icons.info .. counts.info .. '%*') end
  if counts.hints > 0 then table.insert(components, '%#DiagnosticHint#' .. icons.hint .. counts.hints .. '%*') end

  return table.concat(components, ' ')
end

-- formats diagnostic counts in minimalist mode
---@param counts table
---@return string
local function format_mini(counts, bug_icon)
  bug_icon = bug_icon or ''
  local components = {}
  if counts.errors == 0 then return '' end
  table.insert(components, '%#DiagnosticError#' .. bug_icon .. ' ' .. counts.errors .. '%*')
  return table.concat(components, ' ')
end

---@param bufnr integer
---@return string
function M.file_icon(bufnr)
  local cache, cache_key = M.cache.fileicon, tostring(bufnr)
  local cached = U.get_cached(cache, cache_key, math.huge)
  if cached then return cached end

  local icon, hl
  local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':t')
  local filetype = vim.bo[bufnr].filetype

  -- try `echasnovski/mini.nvim` first
  local ok, mini = pcall(require, 'mini.icons')
  if ok then
    icon, hl = mini.get('filetype', filetype)
  end

  -- fallback to `nvim-tree/nvim-web-devicons` if needed
  if not icon or not hl then
    local ok2, devicons = pcall(require, 'nvim-web-devicons')
    if ok2 then
      icon, hl = devicons.get_icon(filename, vim.fn.fnamemodify(filename, ':e'), { default = true })
    end
  end

  local result = (icon and hl) and ('%#' .. hl .. '#' .. icon .. '%*') or ''
  U.set_cached(cache, cache_key, result)

  return result
end

-- lsp client names for current buffer as formatted status string.
---@param lsp winbar.lspClients
function M.lsp_status(lsp)
  if vim.o.columns < 60 then return '' end

  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then return '' end

  local names = {}
  for _, client in pairs(clients) do
    table.insert(names, client.name)
  end

  local result = lsp.format(table.concat(names, lsp.separator))

  return '%#' .. M.hl.lsp_status.group .. '#' .. result .. '%*'
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
---@param style? "standard"|"mini"
---@param icons winbar.diagnosticIcons
---@param update_interval integer
---@return string
function M.diagnostics(style, icons, update_interval)
  local bufnr = vim.api.nvim_get_current_buf()
  local cache_key = tostring(bufnr)
  local cache = M.cache.diagnostics
  local ttl = update_interval * 1e6 -- to nanoseconds

  local cached = U.get_cached(cache, cache_key, ttl)
  if cached then return cached end

  local counts = get_diagnostic_counts(bufnr)
  local result = (style == 'mini') and format_mini(counts, icons.error) or format_standard(counts, icons)

  U.set_cached(cache, cache_key, result)
  return result
end

---@param bufnr integer
---@param fn winbar.filename
---@return string
function M.filename(bufnr, fn)
  local cache, cache_key = M.cache.filename, tostring(bufnr)
  local cached = U.get_cached(cache, cache_key, math.huge)
  if cached then return cached end

  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local filename = vim.fn.fnamemodify(bufname, ':t')

  local all_buffers = vim.api.nvim_list_bufs()
  local duplicates = 0
  for _, buf in ipairs(all_buffers) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      if vim.fn.fnamemodify(name, ':t') == filename then duplicates = duplicates + 1 end
    end
  end

  -- check if duplicate name
  if duplicates > 1 then filename = require('winbar.util').get_relative_path(bufname) end

  -- add icon
  if fn.icon then
    local icon = M.file_icon(bufnr)
    filename = icon .. ' ' .. filename
  end

  filename = fn.format(filename)
  U.set_cached(cache, cache_key, filename)

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

-- current git branch name as formatted string with icon, cached for performance.
---@param bufnr integer
---@param icon string
function M.git_branch(bufnr, icon)
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  if bufname == '' then return '' end

  -- derive directory key (repository context)
  local dir = vim.fn.fnamemodify(bufname, ':h')
  local cache_key = 'git_branch_' .. dir
  local cache = M.cache
  local cached = U.get_cached(cache, cache_key, math.huge)
  if cached then return cached end

  -- check for external plugin
  local branch = vim.b.minigit_summary_string or vim.b.gitsigns_head
  if branch ~= nil then
    local result = string.format('%%#%s#%s %s%%*', M.hl.git_branch.group, icon, branch)
    U.set_cached(cache, cache_key, result)
    return result
  end

  branch = U.git_branch()
  if not branch then return '' end

  local result = string.format('%%#%s#%s %s%%*', M.hl.git_branch.group, icon, branch)
  U.set_cached(cache, cache_key, result)
  return result
end

---@param bufnr integer
---@param update_interval integer
---@param c winbar.gitdiff
function M.git_diff(bufnr, update_interval, c)
  local cache_key = 'git_diff_' .. bufnr
  local cache = M.cache
  local ttl = update_interval * 1e6 -- to nanoseconds

  local cached = U.get_cached(cache, cache_key, ttl)
  if cached then return cached end

  local diffstat = vim.b.minidiff_summary_string or vim.b.gitsigns_status
  if diffstat == nil then return '' end

  return M.format_gitdiff_output(c, diffstat)
end

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
function M.format_gitdiff_output(c, diffstat)
  local hunks = parse_diffstat(diffstat)
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
