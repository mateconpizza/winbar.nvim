---@module 'winbar'
---@brief [[
---
---             ╻ ╻╻┏┓╻┏┓ ┏━┓┏━┓ ┏┓╻╻ ╻╻┏┳┓
---             ┃╻┃┃┃┗┫┣┻┓┣━┫┣┳┛ ┃┗┫┃┏┛┃┃┃┃
---             ┗┻┛╹╹ ╹┗━┛╹ ╹╹┗╸╹╹ ╹┗┛ ╹╹ ╹
---       -Configurable and minimal Neovim WinBar-
---
---@brief ]]

local function cmp()
  return require('winbar.components')
end

local function utils()
  return require('winbar.util')
end

local function highlight()
  return require('winbar.highlight')
end

local function health()
  return require('winbar.health')
end

local function cache()
  return require('winbar.cache')
end

local function defaults()
  return require('winbar.config')
end

local shown_errors = {}

---@param comp winbar.component
local function safe_render(comp)
  local ok, content = pcall(comp.render)

  if not ok then
    if not shown_errors[comp.name] then
      shown_errors[comp.name] = true
      utils().err("component '" .. comp.name .. "' crashed!\n" .. content)
    end

    return highlight().string('ErrorMsg', comp.name)
    -- return ''
  end

  return content or ''
end

local config = defaults().config

---@class winbar
local M = {}

-- clear all autocmds in the augroup
function M.disable()
  vim.api.nvim_clear_autocmds({ group = cache().augroup })
  cache().reset()
end

-- render the winbar content based on configuration and current buffer state.
function M.render()
  if utils().is_special_buffer(config.exclusions.buftypes, config.exclusions.filetypes) then return '' end

  if not config.show_single_buffer then
    local visible_buffers = vim.tbl_filter(function(buf)
      -- count visibles buffers only. Ignore floating windows (fzf-lua, Mason, etc)
      return vim.api.nvim_buf_is_loaded(buf)
        and vim.api.nvim_buf_get_name(buf) ~= ''
        and utils().is_visible_in_normal_win(buf)
    end, vim.api.nvim_list_bufs())

    if #visible_buffers < 2 then return '' end
  end

  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname == '' then return '[No Name]' end

  local filename = vim.fn.fnamemodify(bufname, ':t')
  if filename == '' then return '' end

  -- build
  local parts = {}

  -- left section
  for _, name in ipairs(config.layout.left) do
    local component = cmp().registry[name]
    if component and component.enabled() then
      local content = safe_render(component)
      if content ~= '' then table.insert(parts, content) end
    end
  end

  -- center section --
  table.insert(parts, '%=')
  for _, name in ipairs(config.layout.center) do
    local component = cmp().registry[name]
    if component and component.enabled() then
      local content = safe_render(component)
      if content ~= '' then table.insert(parts, content) end
    end
  end

  -- right section --
  table.insert(parts, '%=')
  for _, name in ipairs(config.layout.right) do
    local component = cmp().registry[name]
    if component and component.enabled() then
      local content = safe_render(component)
      if content ~= '' then table.insert(parts, content) end
    end
  end

  return table.concat(parts, ' ')
end

---@param opts? winbar.config
function M.setup(opts)
  config = vim.tbl_deep_extend('force', config, opts or {})

  health().validate(config)

  -- setup all components
  cmp().setup(config)

  -- highlights are replaced entirely
  if opts and opts.highlights then
    for key, style in pairs(opts.highlights) do
      config.highlights[key] = style
    end
  end

  -- apply highlights
  highlight().setup(config.highlights)

  -- global function
  _G._winbar_render = M.render

  -- user commands
  vim.api.nvim_create_user_command(defaults().commands.toggle, function()
    config.enabled = not config.enabled
    if not config.enabled then
      vim.o.winbar = ''
      M.disable()

      return
    end

    vim.o.winbar = '%{%v:lua._winbar_render()%}'
    cmp().setup(config)
  end, {})

  if config.dev_mode then
    vim.api.nvim_create_user_command(defaults().commands.inspect, function()
      cache().inspect()
    end, {})
  end

  if not config.enabled then return end
  vim.o.winbar = '%{%v:lua._winbar_render()%}'
end

return M
