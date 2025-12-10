-- cmp/lsp_progress.lua
-- LSP progress spinner

local uv = vim.uv or vim.loop

local function cache()
  return require('winbar.cache')
end

local function utils()
  return require('winbar.util')
end

local function highlight()
  return require('winbar.highlight')
end

local done = {
  symbol = '✓',
  timeout = 2000,
}

local progress_state = {
  BEGIN = 'begin',
  REPORT = 'report',
  END = 'end',
  DONE = 'done',
}

local progress_patterns = {
  done = 'LspProgressDone',
  update = 'LspProgressUpdate',
}

local hl = {
  progress = 'WinBarLspProgress',
  spinner = 'WinBarLspProgressSpinner',
  done = 'WinBarLspProgressDone',
}

---@class winbar.components.lsp_progress: winbar.component
local M = {}

M.name = 'lsp_progress'
M.side = 'right'
function M.enabled()
  return M.opts.enabled
end

---@type winbar.lspProgress
M.opts = {}

---@class winbar.userHighlights
---@field WinBarLspProgress winbar.HighlightAttrs? lsp progress highlight
---@field WinBarLspProgressSpinner winbar.HighlightAttrs? lsp progress spinner highlight
---@field WinBarLspProgressDone winbar.HighlightAttrs? progress done highlight
M.highlights = {
  [hl.progress] = { link = 'Comment' },
  [hl.spinner] = { link = 'WarningMsg' },
  [hl.done] = { link = 'Constant' },
}

---@type table<integer, table<integer, vim.lsp.Client.Progress>>
local pending = {} -- pending[bufnr][client_id] = progress

---@type table<integer, string>
local message = {} -- message[bufnr] = formatted string

---@type table<string, integer>
local token_to_buffer = {} -- token_to_buffer[token] = bufnr

local spinner_index = 1

local function format_spinner()
  local frame = M.opts.spinner[spinner_index]
  return highlight().string(hl.spinner, frame)
end

local function format_done(bufnr)
  -- show: done ✓ then auto-clear after timeout
  local out = highlight().string(hl.done, 'done ' .. done.symbol)

  message[bufnr] = nil
  pending[bufnr] = nil

  vim.defer_fn(function()
    cache().invalidate(M.name, bufnr)
    vim.cmd('redrawstatus!')
  end, done.timeout)

  return out
end

-- update message per-buffer from $/progress
---@param bufnr integer
local function update_buffer_message(bufnr, result)
  local v = result.value
  local base = highlight().string(hl.progress, v.title or v.message or '')

  if v.kind == progress_state.BEGIN then
    message[bufnr] = base .. ' '
  elseif v.kind == progress_state.REPORT then
    local m = base
    if v.percentage then m = m .. string.format(' %%#%s#(%d%%%%)%%* ', hl.progress, v.percentage) end
    message[bufnr] = m
  elseif v.kind == progress_state.END then
    message[bufnr] = progress_state.DONE
  end
end

function M.render()
  if utils().is_narrow(M.opts.min_width) then return '' end

  local bufnr = vim.api.nvim_get_current_buf()
  if not cache().lsp_attached[bufnr] then return '' end

  local buf_pending = pending[bufnr]
  local buf_msg = message[bufnr]

  -- no progress for this buffer
  if not buf_pending or next(buf_pending) == nil then
    if buf_msg == progress_state.DONE then return format_done(bufnr) end
    return ''
  end

  -- spinning
  return (buf_msg or '') .. format_spinner()
end

function M.autocmd()
  local group = cache().augroup

  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = progress_patterns.update,
    callback = function()
      utils().throttled_redraw(100)
    end,
  })

  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = progress_patterns.done,
    callback = function()
      vim.cmd('redrawstatus!')
    end,
  })

  vim.api.nvim_create_autocmd({ 'LspAttach', 'LspDetach' }, {
    group = group,
    callback = function(args)
      cache().invalidate(M.name, args.buf)
      message[args.buf] = nil
      pending[args.buf] = nil
    end,
  })

  -- spinner timer
  ---@diagnostic disable-next-line: undefined-field
  local timer = uv.new_timer()
  timer:start(
    0,
    M.opts.spinner_interval,
    vim.schedule_wrap(function()
      -- only advance spinner if any buffer has pending work
      for _, buf_tbl in pairs(pending) do
        if next(buf_tbl) ~= nil then
          spinner_index = (spinner_index % #M.opts.spinner) + 1
          utils().throttled_redraw(50)
          return
        end
      end
    end)
  )

  -- progress handler - only show progress for current buffer
  vim.lsp.handlers['$/progress'] = function(_, result, ctx)
    local client_id = ctx.client_id
    local token = result.token

    -- BEGIN: associate token with current buf
    if result.value.kind == progress_state.BEGIN then
      local current_buf = vim.api.nvim_get_current_buf()

      -- only start tracking if client is attached to current buffer
      local clients = vim.lsp.get_clients({ bufnr = current_buf })
      local is_attached = false
      for _, client in ipairs(clients) do
        if client.id == client_id then
          is_attached = true
          break
        end
      end

      if not is_attached then return end
      token_to_buffer[token] = current_buf
    end

    -- END: use the stored buffer
    local bufnr = token_to_buffer[token]
    if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then return end

    pending[bufnr] = pending[bufnr] or {}
    pending[bufnr][client_id] = result.value
    update_buffer_message(bufnr, result)

    if result.value.kind == progress_state.END then
      -- clean up
      pending[bufnr][client_id] = nil
      token_to_buffer[token] = nil
      vim.api.nvim_exec_autocmds('User', { pattern = progress_patterns.done })
    else
      vim.api.nvim_exec_autocmds('User', { pattern = progress_patterns.update })
    end
  end
end

function M.setup(opts)
  M.opts = opts or {}
  return M
end

return M
