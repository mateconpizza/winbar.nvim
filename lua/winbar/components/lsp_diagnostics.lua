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
---@param icons winbar.diagnosticIcons
---@return string
local function format_standard(counts, icons)
  if vim.o.columns < 60 then return '' end
  icons = icons or {}
  local components = {}
  local hl = highlight().string

  if counts.errors > 0 then table.insert(components, hl(hl_groups.error, icons.error .. counts.errors)) end
  if counts.warnings > 0 then table.insert(components, hl(hl_groups.warn, icons.warn .. counts.warnings)) end
  if counts.info > 0 then table.insert(components, hl(hl_groups.info, icons.info .. counts.info)) end
  if counts.hints > 0 then table.insert(components, hl(hl_groups.hint, icons.hint .. counts.hints)) end

  return table.concat(components, ' ')
end

-- formats diagnostic counts in minimalist mode
---@param counts table
---@return string
local function format_mini(counts, bug_icon)
  if counts.errors == 0 then return '' end
  bug_icon = bug_icon or ''
  return highlight().string(hl_groups.error, bug_icon .. counts.errors)
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

-- stylua: ignore
---@class winbar.userHighlights
---@field WinBarDiagnosticError winbar.HighlightAttrs? diagnostic error highlight
---@field WinBarDiagnosticWarn winbar.HighlightAttrs?  diagnostic warning highlight
---@field WinBarDiagnosticInfo winbar.HighlightAttrs?  diagnostic info highlight
---@field WinBarDiagnosticHint winbar.HighlightAttrs?  diagnostic hint highlight
M.highlights = {
  WinBarDiagnosticError  = { link = 'DiagnosticError' },
  WinBarDiagnosticWarn   = { link = 'DiagnosticWarn'  },
  WinBarDiagnosticInfo   = { link = 'DiagnosticInfo'  },
  WinBarDiagnosticHint   = { link = 'DiagnosticHint'  },
}

---@type winbar.diagnostics
M.opts = {}

function M.render()
  if utils().is_narrow(M.opts.min_width) then return '' end

  local bufnr = vim.api.nvim_get_current_buf()
  if #vim.lsp.get_clients({ bufnr = bufnr }) == 0 then return '' end

  local icons = M.opts.icons or {}

  return cache().ensure(M.name, bufnr, function()
    local counts = get_diagnostic_counts(bufnr)
    if M.opts.style == 'mini' then return format_mini(counts, icons.error) end
    return format_standard(counts, icons)
  end, M.interval_ms)
end

function M.autocmd()
  vim.api.nvim_create_autocmd('DiagnosticChanged', {
    group = cache().augroup,
    callback = function(args)
      local bufnr = args.buf
      if not utils().is_normal_buffer(bufnr) or not utils().is_visible_in_normal_win(bufnr) then return end
      cache().invalidate(M.name, bufnr)
      utils().throttled_redraw(M.interval_ms)
    end,
    desc = 'reset LSP diagnostics on change',
  })

  vim.api.nvim_create_autocmd('LspAttach', {
    group = cache().augroup,
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
    group = cache().augroup,
    callback = function(args)
      local bufnr = args.buf
      cache().invalidate(M.name, bufnr)
    end,
    desc = 'clear LSP diagnostics cache on LSP detach',
  })
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
