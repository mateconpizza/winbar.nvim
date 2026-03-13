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

local hl_groups = {
  error = 'WinBarDiagnosticError',
  warn = 'WinBarDiagnosticWarn',
  info = 'WinBarDiagnosticInfo',
  hint = 'WinBarDiagnosticHint',
}

-- formats diagnostic counts in standard mode
---@param counts table
---@param icons winbar.lsp.diagnosticIcons
---@return table<integer, {count: integer, type: string, icon: string}>
local function format_standard_data(counts, icons)
  if vim.o.columns < 60 then return {} end
  icons = icons or {}
  local data_parts = {}

  if counts.errors > 0 then table.insert(data_parts, { count = counts.errors, icon = icons.error, type = 'error' }) end
  if counts.warnings > 0 then
    table.insert(data_parts, { count = counts.warnings, icon = icons.warn, type = 'warn' })
  end
  if counts.info > 0 then table.insert(data_parts, { count = counts.info, icon = icons.info, type = 'info' }) end
  if counts.hints > 0 then table.insert(data_parts, { count = counts.hints, icon = icons.hint, type = 'hint' }) end

  return data_parts
end

-- formats diagnostic counts in minimalist mode (data layer)
---@param counts table
---@return table<integer, {count: integer, type: string, icon: string}>
local function format_mini_data(counts, bug_icon)
  if counts.errors == 0 then return {} end
  bug_icon = bug_icon or ''
  return { { count = counts.errors, icon = bug_icon, type = 'error' } }
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

---@class winbar.lsp.diagnosticIcons
---@field error string? icon for errors.
---@field hint string? icon for hints.
---@field info string? icon for infos.
---@field warn string? icon for warnings.

---@class winbar.lsp.diagnostics
---@field enabled boolean? enable diagnostics.
---@field style 'mini' | 'standard'? diagnostics style (standard or mini).
---@field icons winbar.lsp.diagnosticIcons?
---@field min_width? integer minimum window width required to display this component.

---@class winbar.components.lsp_diagnostics: winbar.component
local M = {}

M.name = 'lsp_diagnostics'
M.side = 'right'
M.interval_ms = nil
function M.enabled()
  return M.opts.enabled
end

-- stylua: ignore
---@class winbar.userHighlights
---@field WinBarDiagnosticError winbar.HighlightAttrs? diagnostic error highlight
---@field WinBarDiagnosticWarn winbar.HighlightAttrs?  diagnostic warning highlight
---@field WinBarDiagnosticInfo winbar.HighlightAttrs?  diagnostic info highlight
---@field WinBarDiagnosticHint winbar.HighlightAttrs?  diagnostic hint highlight
M.highlights = {
  [hl_groups.error]  = { link = 'DiagnosticError' },
  [hl_groups.warn]   = { link = 'DiagnosticWarn'  },
  [hl_groups.info]   = { link = 'DiagnosticInfo'  },
  [hl_groups.hint]   = { link = 'DiagnosticHint'  },
}

---@type winbar.lsp.diagnostics
M.opts = {}

---@return string
function M.render()
  if utils().is_narrow(M.opts.min_width) then return '' end

  local bufnr = vim.api.nvim_get_current_buf()
  if not cache().lsp_attached[bufnr] then return '' end
  if #vim.lsp.get_clients({ bufnr = bufnr }) == 0 then return '' end

  local icons = M.opts.icons or {}

  -- get raw diagnostic counts (cached)
  local counts = cache().ensure(M.name, bufnr, function()
    return get_diagnostic_counts(bufnr)
  end, M.interval_ms)

  -- format into raw data structure (cached)
  local data_parts
  if M.opts.style == 'mini' then
    data_parts = format_mini_data(counts, icons.error)
  else
    data_parts = format_standard_data(counts, icons)
  end

  if vim.tbl_isempty(data_parts) then return '' end

  -- apply highlighting (dynamic / uncached)
  local is_active = utils().is_active_win()
  local hl_suffix = is_active and '' or 'NC'
  local components = {}
  local hl = highlight().string

  for _, part in ipairs(data_parts) do
    local base_group = hl_groups[part.type] -- e.g., 'WinBarLspDiagnosticsError'
    local final_group = base_group .. hl_suffix -- e.g., 'WinBarLspDiagnosticsErrorNC'
    local content = string.format('%s%d', part.icon, part.count)

    table.insert(components, hl(final_group, content))
  end

  return table.concat(components, ' ')
end

function M.autocmd(augroup)
  vim.api.nvim_create_autocmd('DiagnosticChanged', {
    group = augroup,
    callback = function(args)
      local bufnr = args.buf
      if not utils().is_normal_buffer(bufnr) or not utils().is_visible_in_normal_win(bufnr) then return end
      cache().invalidate(M.name, bufnr)
      utils().throttled_redraw(M.interval_ms)
    end,
    desc = 'reset LSP diagnostics on change',
  })

  vim.api.nvim_create_autocmd('LspAttach', {
    group = augroup,
    callback = function(args)
      local bufnr = args.buf
      if not utils().is_normal_buffer(bufnr) or not utils().is_visible_in_normal_win(bufnr) then return end

      cache().invalidate(M.name, bufnr)
      utils().throttled_redraw(M.interval_ms)
    end,
    desc = 'register LSP attach/detach events',
  })

  -- clear diagnostics cache
  vim.api.nvim_create_autocmd('LspDetach', {
    group = augroup,
    callback = function(args)
      local bufnr = args.buf
      cache().invalidate(M.name, bufnr)
    end,
    desc = 'clear LSP diagnostics cache on LSP detach',
  })
end

---@param opts winbar.lsp.diagnostics
---@param interval_ms integer
---@return winbar.component
function M.setup(opts, interval_ms)
  M.opts = opts or {}
  M.interval_ms = interval_ms
  return M
end

return M
