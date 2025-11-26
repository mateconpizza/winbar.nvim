---@module 'winbar.registry'
---@class winbar.registry
local M = {}

---@class winbar.component
---@field name string component identifier
---@field enabled fun(): boolean check if component should be rendered
---@field render fun(): string|nil render the component content
---@field side? 'left'|'center'|'right' which side of the winbar (optional)
---@field spacing? boolean add space after component (default: true)

-- component registry
---@type table<string, winbar.component>
M.registry = {}

-- register a component
---@param c winbar.component
function M.register(c)
  if not c.name or not c.render then
    vim.notify('[winbar] Invalid component registration: missing name or render()', vim.log.levels.ERROR)
    return
  end

  M.registry[c.name] = c
end

-- define all components
---@param config winbar.config
function M.setup(config)
  local components = require('winbar.components')

  -- git branch component
  M.register({
    name = 'git_branch',
    side = 'left',
    enabled = function()
      return config.git.branch.enabled
    end,
    render = function()
      local bufnr = vim.api.nvim_get_current_buf()
      return components.git_branch(bufnr, config.git.branch)
    end,
  })

  -- LSP status component
  M.register({
    name = 'lsp_status',
    side = 'right',
    enabled = function()
      return config.lsp.enabled
    end,
    render = function()
      return components.lsp_clients(config.lsp)
    end,
  })

  -- diagnostics component
  M.register({
    name = 'diagnostics',
    side = 'right',
    enabled = function()
      return config.diagnostics.enabled
    end,
    render = function()
      local style = config.diagnostics.style or 'standard'
      local d = components.lsp_diagnostics(style, config.diagnostics, config.update_interval)
      if d == '' then return nil end

      local parts = {}
      table.insert(parts, d)
      return table.concat(parts, ' ')
    end,
  })

  -- modified indicator component
  M.register({
    name = 'modified',
    side = 'right',
    enabled = function()
      return vim.bo.modified
    end,
    render = function()
      return components.modified(config.icons.modified)
    end,
  })

  -- readonly indicator component
  M.register({
    name = 'readonly',
    side = 'right',
    enabled = function()
      return vim.bo.readonly
    end,
    render = function()
      return components.readonly(config.icons.readonly)
    end,
  })

  -- filename component
  M.register({
    name = 'filename',
    side = 'right',
    enabled = function()
      return config.filename.enabled
    end,
    render = function()
      local bufnr = vim.api.nvim_get_current_buf()
      return components.filename(bufnr, config.filename)
    end,

    spacing = true, -- WIP
  })

  -- git diff
  M.register({
    name = 'git_diff',
    side = 'left',
    enabled = function()
      return config.git.diff.enabled
    end,
    render = function()
      local bufnr = vim.api.nvim_get_current_buf()
      return components.git_diff(bufnr, config.update_interval, config.git.diff)
    end,
  })
end

return M
