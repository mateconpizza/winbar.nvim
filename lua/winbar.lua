---@module 'winbar'
---@brief [[
---
---             ╻ ╻╻┏┓╻┏┓ ┏━┓┏━┓ ┏┓╻╻ ╻╻┏┳┓
---             ┃╻┃┃┃┗┫┣┻┓┣━┫┣┳┛ ┃┗┫┃┏┛┃┃┃┃
---             ┗┻┛╹╹ ╹┗━┛╹ ╹╹┗╸╹╹ ╹┗┛ ╹╹ ╹
---       -Configurable and minimal Neovim WinBar-
---
---@brief ]]

local function autocmd()
  return require('winbar.autocmd')
end

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

local shown_errors = {}

---@param comp winbar.component
local function safe_render(comp)
  local ok, content = pcall(comp.render)

  if not ok then
    if not shown_errors[comp.name] then
      shown_errors[comp.name] = true
      utils().err("component '" .. comp.name .. "' crashed!\n" .. content)
    end

    local hl = highlight().highlights
    return highlight().string(hl.diag_error.group, comp.name)
    -- return ''
  end

  return content or ''
end

---@class winbar
local M = {}

M.config = require('winbar.config')

-- render the winbar content based on configuration and current buffer state.
function M.render()
  if utils().is_special_buffer(M.config.exclusions.buftypes, M.config.exclusions.filetypes) then return '' end

  if not M.config.show_single_buffer then
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
  for _, name in ipairs(M.config.layout.left) do
    local component = cmp().registry[name]
    if component and component.enabled() then
      local content = safe_render(component)
      if content ~= '' then table.insert(parts, content) end
    end
  end

  -- center section --
  table.insert(parts, '%=')
  for _, name in ipairs(M.config.layout.center) do
    local component = cmp().registry[name]
    if component and component.enabled() then
      local content = safe_render(component)
      if content ~= '' then table.insert(parts, content) end
    end
  end

  -- right section --
  table.insert(parts, '%=')
  for _, name in ipairs(M.config.layout.right) do
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
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})

  -- styles are replaced entirely
  if opts and opts.styles then
    for key, style in pairs(opts.styles) do
      M.config.styles[key] = style
    end
  end

  health().validate(M.config)

  -- setup autocmd
  autocmd().setup(M.config)

  -- define all components
  cmp().setup(M.config)

  -- apply highlights
  require('winbar.highlight').setup(M.config.styles)

  -- global function
  _G._winbar_render = M.render

  -- user commands
  vim.api.nvim_create_user_command(autocmd().cmd.toggle, function()
    M.config.enabled = not M.config.enabled
    if not M.config.enabled then
      vim.o.winbar = ''
      autocmd().disable()

      return
    end

    vim.o.winbar = '%{%v:lua._winbar_render()%}'
    autocmd().setup(M.config)
  end, {})

  if M.config.dev_mode then
    vim.api.nvim_create_user_command(autocmd().cmd.inspect, function()
      require('winbar.cache').inspect()
    end, {})
  end

  if not M.config.enabled then return end
  vim.o.winbar = '%{%v:lua._winbar_render()%}'
end

return M
