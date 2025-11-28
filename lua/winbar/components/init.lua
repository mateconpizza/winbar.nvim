local function utils()
  return require('winbar.util')
end

local function cache()
  return require('winbar.cache')
end

local function highlight()
  return require('winbar.highlight')
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
local M = {}

setmetatable(M, {
  __index = function(tbl, key)
    tbl[key] = require('winbar.components.' .. key)
    return tbl[key]
  end,
})

---@class winbar.component
---@field name string                               -- unique identifier
---@field side 'left'|'center'|'right'             -- position in winbar
---@field enabled fun(): boolean                    -- check if it should render
---@field render fun(): string|nil                  -- return content or nil to hide
---@field opts? table|boolean|string                -- component options
---@field interval_ms? integer                      -- redraw throttle interval
---@field autocmd? fun()                            -- define autocmds
---@field highlights? winbar.highlight[]            -- component highlights groups
---@field setup? fun(opts?: table|boolean|string, interval_ms?: integer|string): winbar.component

-- component registry
---@type table<string, winbar.component>
M.registry = {}

function M.cleanup()
  vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
    group = cache().augroup,
    callback = function(args)
      local bufnr = args.buf
      if not utils().is_normal_buffer(bufnr) then return end
      cache().prune(bufnr)
    end,
    desc = 'remove cache entries when buffers are deleted or wiped out',
  })
end

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
    { 'modified',         c.icons.modified },
    { 'readonly',         c.icons.readonly },
    { 'filename',         c.filename },
    { 'git_branch',       c.git.branch, c.update_interval },
    { 'git_diff',         c.git.diff, c.update_interval },
    { 'lsp_clients',      c.lsp },
    { 'lsp_diagnostics',  c.diagnostics, c.update_interval },
  }

  for _, item in ipairs(components) do
    local name, cfg, _interval = unpack(item)

    ---@type winbar.component
    local module = M[name]
    if module and module.setup then M.register(module.setup(cfg, _interval)) end
    if module and module.autocmd then module.autocmd() end
    if module and module.highlights then highlight().merge(module.highlights) end
  end

  -- setup cleanup autocmd
  M.cleanup()
end

return M
