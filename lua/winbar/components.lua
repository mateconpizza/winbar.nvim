---@diagnostic disable: undefined-field
---@class WinBar.Components
local M = {}

-- cache for performance
M.cache = {
  diagnostics = {},
  git_branch = nil,
  last_update = 0,
}

M.hl = require('winbar.highlight').highlights

-- formats diagnostic counts in standard mode
---@param counts table
---@param icons WinBar.DiagnosticIcons
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
---@param lsp WinBar.LspStatus
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
---@param icons WinBar.DiagnosticIcons
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

return M
