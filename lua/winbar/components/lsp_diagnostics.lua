-- cmp/lsp_diagnostics.lua

local function cache()
  return require('winbar.cache')
end

local function utils()
  return require('winbar.util')
end

local function highlight()
  return require('winbar.highlight')
end

-- formats diagnostic counts in standard mode
---@param counts table
---@param icons winbar.diagnosticIcons
---@return string
local function format_standard(counts, icons)
  if vim.o.columns < 60 then return '' end
  icons = icons or {}
  local components = {}
  local hl = highlight().highlights

  if counts.errors > 0 then
    table.insert(components, highlight().string(hl.diag_error.group, icons.error .. counts.errors))
  end
  if counts.warnings > 0 then
    table.insert(components, highlight().string(hl.diag_warn.group, icons.warn .. counts.warnings))
  end
  if counts.info > 0 then
    table.insert(components, highlight().string(hl.diag_info.group, icons.info .. counts.info))
  end
  if counts.hints > 0 then
    table.insert(components, highlight().string(hl.diag_hint.group, icons.hint .. counts.hints))
  end

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

---@class winbar.components.lsp_diagnostics: winbar.component
local M = {}

M.name = 'lsp_diagnostics'
M.side = 'right'
M.interval_ms = nil
function M.enabled()
  return M.opts.enabled
end

---@type winbar.diagnostics
M.opts = {}

function M.render()
  if utils().is_narrow(M.opts.min_width) then return '' end

  local bufnr = vim.api.nvim_get_current_buf()
  if not cache().lsp_attached[bufnr] then return '' end

  local icons = M.opts.icons or {}

  return cache().ensure(M.name, bufnr, function()
    local counts = get_diagnostic_counts(bufnr)
    if M.opts.style == 'mini' then return format_mini(counts, icons.error) end
    return format_standard(counts, icons)
  end, M.interval_ms)
end

---@param opts winbar.diagnostics
---@param interval_ms integer
---@return winbar.component
function M.setup(opts, interval_ms)
  M.opts = opts or {}
  M.interval_ms = interval_ms
  return M
end

return M
