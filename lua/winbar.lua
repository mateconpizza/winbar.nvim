---@module 'winbar'
---@brief [[
---
---             ╻ ╻╻┏┓╻┏┓ ┏━┓┏━┓ ┏┓╻╻ ╻╻┏┳┓
---             ┃╻┃┃┃┗┫┣┻┓┣━┫┣┳┛ ┃┗┫┃┏┛┃┃┃┃
---             ┗┻┛╹╹ ╹┗━┛╹ ╹╹┗╸╹╹ ╹┗┛ ╹╹ ╹
---       -Configurable and minimal Neovim WinBar-
---
---@brief ]]

local function cache()
  return require('winbar.components').cache
end

local function reg()
  return require('winbar.registry')
end

local function utils()
  return require('winbar.util')
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
    local component = reg().registry[name]
    if component and component.enabled() then
      local content = component.render()
      if content and content ~= '' then table.insert(parts, content) end
    end
  end

  -- center section --
  table.insert(parts, '%=')
  for _, name in ipairs(M.config.layout.center) do
    local component = reg().registry[name]
    if component and component.enabled() then
      local content = component.render()
      if content and content ~= '' then table.insert(parts, content) end
    end
  end

  -- right section --
  table.insert(parts, '%=')
  for _, name in ipairs(M.config.layout.right) do
    local component = reg().registry[name]
    if component and component.enabled() then
      local content = component.render()
      if content and content ~= '' then table.insert(parts, content) end
    end
  end

  return table.concat(parts, ' ')
end

---@param opts? winbar.config
function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
  if not M.config.enabled then return end

  -- styles are replaced entirely
  if opts and opts.styles then
    for key, style in pairs(opts.styles) do
      M.config.styles[key] = style
    end
  end

  -- setup autocmd
  require('winbar.autocmd').setup(M.config, cache())
  -- define all components
  reg().setup(M.config)
  -- apply highlights
  require('winbar.highlight').setup(M.config.styles)

  _G._winbar_render = M.render
  vim.o.winbar = '%{%v:lua._winbar_render()%}'
end

return M
