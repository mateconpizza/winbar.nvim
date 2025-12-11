-- cmp/lsp_clients.lua
-- lsp client names for current buffer as formatted status string.

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
  status = 'WinBarLspStatus',
}

---@class winbar.lsp.clients
---@field enabled boolean? enable LSP client name display.
---@field separator? string? separator between multiple LSP clients.
---@field format? fun(clients: string): string custom formatter for client names.
---@field min_width? integer minimum window width required to display this component.

---@class winbar.components.lsp_clients: winbar.component
local M = {}

M.name = 'lsp_status'
M.side = 'right'
function M.enabled()
  return M.opts.enabled
end

---@type winbar.lsp.clients
M.opts = {}

---@class winbar.userHighlights
---@field WinBarLspStatus winbar.HighlightAttrs? LSP client name highlights.
M.highlights = {
  [hl_groups.status] = { link = 'Comment' },
}

function M.render()
  if utils().is_narrow(M.opts.min_width) then return '' end

  local bufnr = vim.api.nvim_get_current_buf()
  if #vim.lsp.get_clients({ bufnr = bufnr }) == 0 then return '' end

  return cache().ensure(M.name, bufnr, function()
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    local names = {}
    for _, client in pairs(clients) do
      table.insert(names, client.name)
    end
    local result = M.opts.format(table.concat(names, M.opts.separator))

    return highlighter().string(hl_groups.status, result)
  end)
end

function M.autocmd(augroup)
  vim.api.nvim_create_autocmd('LspAttach', {
    group = augroup,
    callback = function(args)
      local bufnr = args.buf
      if not utils().is_normal_buffer(bufnr) or not utils().is_visible_in_normal_win(bufnr) then return end
      cache().lsp_attached[bufnr] = true
      cache().invalidate(M.name, bufnr)
      utils().throttled_redraw(M.interval_ms or 100)
    end,
    desc = 'update LSP clients list when LSP attaches',
  })

  vim.api.nvim_create_autocmd('LspDetach', {
    group = augroup,
    callback = function(args)
      local bufnr = args.buf
      cache().lsp_attached[bufnr] = nil
      cache().invalidate(M.name, bufnr)
    end,
    desc = 'clear cache when LSP client detaches from buffer',
  })
end

---@param opts winbar.lsp.clients
---@return winbar.component
function M.setup(opts)
  M.opts = opts or {}
  return M
end

return M
