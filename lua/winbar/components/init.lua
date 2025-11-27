local function utils()
  return require('winbar.util')
end

---@class winbar.components
---@field filename winbar.components.filename
---@field fileicon winbar.components.fileicon
---@field readonly winbar.components.readonly
---@field modified winbar.components.modified
---@field gitbranch winbar.components.gitbranch
---@field gitdiff winbar.components.gitdiff
---@field lsp_clients winbar.components.lsp_clients
---@field lsp_diagnostics winbar.components.lsp_diagnostics
---@field pomodoro winbar.components.pomodoro
local M = {}

setmetatable(M, {
  __index = function(tbl, key)
    tbl[key] = require('winbar.components.' .. key)
    return tbl[key]
  end,
})

---@class winbar.component
---@field name string component identifier
---@field enabled fun(): boolean check if component should be rendered
---@field render fun(): string|nil render the component content
---@field opts? table|boolean|string
---@field side? 'left'|'center'|'right' which side of the winbar (optional)
---@field interval_ms? integer

-- component registry
---@type table<string, winbar.component>
M.registry = {}

-- register a component
---@param c winbar.component
function M.register(c)
  if not c.name or not c.render then
    utils().err('invalid component registration: missing name or render()')
    return
  end

  M.registry[c.name] = c
end

---@param c winbar.config
function M.setup(c)
  -- stylua: ignore
  local components = {
    { 'modified',        c.icons.modified },
    { 'readonly',        c.icons.readonly },
    -- { 'fileicon',        c.filename.icon },
    { 'filename',        c.filename },
    { 'gitbranch',       c.git.branch },
    { 'gitdiff',         c.git.diff, c.update_interval },
    { 'lsp_clients',     c.lsp },
    { 'lsp_diagnostics', c.diagnostics, c.update_interval },
  }

  for _, item in ipairs(components) do
    local name, cfg, _interval = unpack(item)
    local module = M[name]
    if module and module.setup then M.register(module.setup(cfg, _interval)) end
  end
end

return M
