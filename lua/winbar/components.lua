local Cache = require('winbar.cache')
local Util = require('winbar.util')

-- get icon from external plugin
local function get_icon(bufnr)
  local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':t')
  local filetype = vim.bo[bufnr].filetype
  local icon, hl

  -- try mini.icons
  local ok_mini, mini = pcall(require, 'mini.icons')
  if ok_mini then
    icon, hl = mini.get('filetype', filetype)
  end

  -- fallback to devicons
  if not icon then
    local ok_dev, devicons = pcall(require, 'nvim-web-devicons')
    if ok_dev then
      local ext = vim.fn.fnamemodify(filename, ':e')
      icon, hl = devicons.get_icon(filename, ext or filetype, { default = true })
    end
  end

  return (icon and hl) and ('%#' .. hl .. '#' .. icon .. '%*') or ''
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

---@module 'winbar.components'
---@class winbar.components
local M = {}

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
function M.fileicon(bufnr)
  return Cache.ensure('fileicon', bufnr, function()
    return get_icon(bufnr)
  end)
end

-- lsp client names for current buffer as formatted status string.
---@param opts winbar.lspClients
function M.lsp_clients(opts)
  if Util.is_narrow(opts.min_width) then return '' end

  local bufnr = vim.api.nvim_get_current_buf()
  if not Cache.lsp_attached[bufnr] then return '' end

  return Cache.ensure('lsp_clients', bufnr, function()
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    local names = {}
    for _, client in pairs(clients) do
      table.insert(names, client.name)
    end
    local result = opts.format(table.concat(names, opts.separator))

    return '%#' .. M.hl.lsp_status.group .. '#' .. result .. '%*'
  end)
end

-- formatted string of diagnostic counts for the current buffer.
---@param style? "standard"|"mini"
---@param opts winbar.diagnostic
---@param interval_ms integer
---@return string
function M.lsp_diagnostics(style, opts, interval_ms)
  if Util.is_narrow(opts.min_width) then return '' end

  local bufnr = vim.api.nvim_get_current_buf()
  if not Cache.lsp_attached[bufnr] then return '' end

  local icons = opts.icons or {}

  return Cache.ensure('lsp_diagnostics', bufnr, function()
    local counts = get_diagnostic_counts(bufnr)
    if style == 'mini' then return format_mini(counts, icons.error) end
    return format_standard(counts, icons)
  end, interval_ms)
end

---@param bufnr integer
---@param opts winbar.filename
---@return string
function M.filename(bufnr, opts)
  if Util.is_narrow(opts.min_width) then return '' end

  return Cache.ensure('filename', bufnr, function()
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
    if duplicates > 1 then filename = require('winbar.util').get_relative_path(bufname) end

    -- add icon
    if opts.icon then filename = M.fileicon(bufnr) .. ' ' .. filename end

    return opts.format(filename)
  end)
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
---@param opts winbar.gitbranch
function M.git_branch(bufnr, opts)
  if Util.is_narrow(opts.min_width) then return '' end

  local bufname = vim.api.nvim_buf_get_name(bufnr)
  if bufname == '' then return '' end
  local icon = opts.icon

  return Cache.ensure('gitbranch', bufnr, function()
    -- check for external plugin
    local branch = vim.b.minigit_summary_string or vim.b.gitsigns_head
    if branch ~= nil then
      local result = string.format('%%#%s#%s %s%%*', M.hl.git_branch.group, icon, branch)
      return result
    end

    branch = Util.git_branch()
    if not branch then return '' end

    local result = string.format('%%#%s#%s %s%%*', M.hl.git_branch.group, icon, branch)
    return result
  end)
end

---@param bufnr integer
---@param interval_ms integer
---@param opts winbar.gitdiff
function M.git_diff(bufnr, interval_ms, opts)
  if Util.is_narrow(opts.min_width) then return '' end

  return Cache.ensure('gitdiff', bufnr, function()
    local diffstat = vim.b.minidiff_summary_string or vim.b.gitsigns_status
    if diffstat == nil then return '' end
    return M.format_gitdiff_output(opts, diffstat)
  end, interval_ms)
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
