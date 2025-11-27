-- cmp/lsp_clients.lua
-- lsp client names for current buffer as formatted status string.

local function cache()
  return require('winbar.cache')
end

local function utils()
  return require('winbar.util')
end

local function highlight()
  return require('winbar.highlight').highlights
end

---@class winbar.components.lsp_clients: winbar.component
local M = {}

M.name = 'lsp_status'
M.side = 'right'
function M.enabled()
  return true
end

---@type winbar.lspClients
M.opts = {}

function M.render()
  if utils().is_narrow(M.opts.min_width) then return '' end

  local bufnr = vim.api.nvim_get_current_buf()
  if not cache().lsp_attached[bufnr] then return '' end

  return cache().ensure('lsp_clients', bufnr, function()
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    local names = {}
    for _, client in pairs(clients) do
      table.insert(names, client.name)
    end
    local result = M.opts.format(table.concat(names, M.opts.separator))

    return '%#' .. highlight().lsp_status.group .. '#' .. result .. '%*'
  end)
end

---@param opts winbar.lspClients
---@return winbar.component
function M.setup(opts)
  M.opts = opts or {}
  return M
end

return M
