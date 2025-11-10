---@class WinBar.Registry
local M = {}

---@class WinBar.Component
---@field name string component identifier
---@field enabled fun(): boolean check if component should be rendered
---@field render fun(): string|nil render the component content
---@field side? 'left'|'right' which side of the winbar (optional)
---@field spacing? boolean add space after component (default: true)

-- component registry
---@type table<string, WinBar.Component>
M.registry = {}

-- register a component
---@param c WinBar.Component
function M.register(c)
  if not c.name or not c.render then
    vim.notify('[winbar] Invalid component registration: missing name or render()', vim.log.levels.ERROR)
    return
  end

  M.registry[c.name] = c
end

-- define all components
function M.setup(config)
  local components = require('winbar.components')
  local utils = require('winbar.util')

  -- git branch component
  M.register({
    name = 'git_branch',
    side = 'left',
    enabled = function()
      return config.git_branch
    end,
    render = function()
      return components.git_branch(config.icons.git_branch)
    end,
  })

  -- LSP status component
  M.register({
    name = 'lsp_status',
    side = 'right',
    enabled = function()
      return config.lsp_status
    end,
    render = function()
      return components.lsp_status()
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
      local d = components.diagnostics(config.diagnostics.style or 'standard')
      if d == '' then
        return nil
      end

      local parts = {}

      -- optional bug icon
      if config.diagnostics.bug_icon then
        table.insert(parts, '%#ErrorMsg#' .. config.diagnostics.bug_icon .. '%*')
      end

      -- diagnostic detail
      if config.diagnostics.show_detail then
        table.insert(parts, d)
      end

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
      return '%#WarningMsg#' .. config.icons.modified .. '%*'
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
      return '%#ErrorMsg#' .. config.icons.readonly .. '%*'
    end,
  })

  -- file icon component
  M.register({
    name = 'file_icon',
    side = 'right',
    enabled = function()
      return config.file_icon
    end,
    render = function()
      local bufname = vim.api.nvim_buf_get_name(0)
      local filename = vim.fn.fnamemodify(bufname, ':t')
      return components.file_icon(filename)
    end,
  })

  -- filename component
  M.register({
    name = 'filename',
    side = 'right',
    enabled = function()
      return true
    end,
    render = function()
      local bufname = vim.api.nvim_buf_get_name(0)
      local filename = vim.fn.fnamemodify(bufname, ':t')

      -- check for duplicates
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
        return utils.get_relative_path(bufname)
      else
        return filename
      end
    end,

    spacing = true, -- WIP
  })
end

return M
