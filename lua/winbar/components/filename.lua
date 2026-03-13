-- comp/filename.lua

local function cache()
  return require('winbar.cache')
end

local function utils()
  return require('winbar.util')
end

local function highlight()
  return require('winbar.highlight')
end

local function cmp_icon()
  return require('winbar.components.fileicon')
end

local hl_groups = {
  filename = 'WinbarFilename',
}

---@class winbar.filename
---@field enabled boolean?
---@field icon boolean? -- show file icon (e.g., via nvim-web-devicons)
---@field format? fun(clients: string): string custom formatter for the filename.
---@field min_width? integer minimum window width required to display this component.
---@field max_segments? integer show the last n folders when two files share the same name.

---@class winbar.components.filename: winbar.component
local M = {}

M.name = 'filename'
M.side = 'right'
M.enabled = function()
  return M.opts.enabled
end

---@type winbar.filename
M.opts = {}

---@class winbar.userHighlights
---@field WinbarFilename winbar.HighlightAttrs? filename highlight
M.highlights = {
  [hl_groups.filename] = { link = 'Normal' },
}

---@return string
function M.render()
  if utils().is_narrow(M.opts.min_width) then return '' end

  local bufnr = vim.api.nvim_get_current_buf()

  -- this handles the active/inactive color based on the current window.
  local icon_string = M.opts.icon and cmp_icon().render() .. ' ' or ''

  -- cache the filename logic only
  local filename_string = cache().ensure(M.name, bufnr, function()
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    local filename = vim.fn.fnamemodify(bufname, ':t')

    -- check if duplicate name (heavy logic)
    local all_buffers = vim.api.nvim_list_bufs()
    local duplicates = 0
    for _, buf in ipairs(all_buffers) do
      if vim.api.nvim_buf_is_loaded(buf) then
        local name = vim.api.nvim_buf_get_name(buf)
        if vim.fn.fnamemodify(name, ':t') == filename then duplicates = duplicates + 1 end
      end
    end

    -- add relative path if duplicate
    if duplicates > 1 then filename = utils().get_relative_path(bufname, M.opts.max_segments) end

    return M.opts.format(filename)
  end)

  local hl_group = hl_groups.filename
  if not utils().is_active_win() then hl_group = highlight().inactive end

  return icon_string .. highlight().string(hl_group, filename_string)
end

---@param opts winbar.filename
---@return winbar.component
function M.setup(opts)
  M.opts = opts
  return M
end

return M
