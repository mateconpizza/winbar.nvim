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
  timeout = 2000, -- ms to show done message
}

local user_events = {
  done = 'LspProgressDone',
  update = 'LspProgressUpdate',
}

local hl_groups = {
  progress = 'WinBarLspProgress',
  spinner = 'WinBarLspProgressSpinner',
  done = 'WinBarLspProgressDone',
}

-- progress state for a single buffer
---@class BufferProgress
---@field pending table<integer, table> active LSP clients and their progress values
---@field message string? current formatted progress message
---@field done_title string? title to display when progress completes

-- token metadata linking progress events to buffers
---@class LspTokenInfo
---@field bufnr integer buffer associated with this progress token
---@field title string? cached title from BEGIN/REPORT events

-- LSP progress event types
---@class LspLoadingState
---@field BEGIN string progress started
---@field REPORT string progress update
---@field END string progress completed
---@field DONE string internal state for showing completion message

-- global LSP progress tracking state
---@class LspProgressState
---@field buffer_data table<integer, BufferProgress> progress state per buffer
---@field token_map table<string, LspTokenInfo> maps progress tokens to buffers
---@field loading LspLoadingState progress event kind constants
local state = {
  buffer_data = {},
  token_map = {},
  loading = {
    BEGIN = 'begin',
    REPORT = 'report',
    END = 'end',
    DONE = 'done',
  },
}

---@class winbar.lsp.progress
---@field enabled boolean? enable LSP progress display.
---@field spinner string[]? Array of frames.
---@field spinner_interval number? ms between frames.
---@field min_width? integer minimum window width required to display this component.

---@class winbar.components.lsp_progress: winbar.component
local M = {}

M.name = 'lsp_progress'
M.side = 'right'

function M.enabled()
  return M.opts and M.opts.enabled
end

---@type winbar.lsp.progress
M.opts = {}

---@class winbar.userHighlights
---@field WinBarLspProgress winbar.HighlightAttrs?
---@field WinBarLspProgressSpinner winbar.HighlightAttrs?
---@field WinBarLspProgressDone winbar.HighlightAttrs?
M.highlights = {
  [hl_groups.progress] = { link = 'Comment' },
  [hl_groups.spinner] = { link = 'WarningMsg' },
  [hl_groups.done] = { link = 'Constant' },
}

local spinner_index = 1
local timer = nil

local function token_key(t)
  return tostring(t)
end

local function format_spinner()
  local frame = M.opts.spinner[spinner_index] or M.opts.spinner[1]
  return highlight().string(hl_groups.spinner, frame)
end

local function format_done(bufnr)
  local buf_data = state.buffer_data[bufnr]
  local title = buf_data and buf_data.done_title or ''
  local out
  if title ~= '' then
    -- e.g. "Loading workspace ✓ done"
    local left = highlight().string(hl_groups.progress, title)
    local right = highlight().string(hl_groups.done, done.symbol .. ' done')
    out = left .. ' ' .. right
  else
    out = highlight().string(hl_groups.done, done.symbol .. ' done')
  end

  -- schedule clearing after timeout
  vim.defer_fn(function()
    -- remove buffer data and invalidate cache so render refreshes
    state.buffer_data[bufnr] = nil
    cache().invalidate(M.name, bufnr)
    vim.cmd('redrawstatus!')
  end, done.timeout)

  return out
end

-- Build a combined title/message string following preference:
-- 1. explicit v.title
-- 2. cached title for token
-- 3. v.message
-- If both title and message present, render "title: message"
local function build_combined_text(token, v)
  local token_info = state.token_map[token]
  local t = v.title
  if (not t or t == '') and token_info and token_info.title then t = token_info.title end

  local m = v.message
  -- prefer message if present; if both present, join
  if t and t ~= '' and m and m ~= '' then
    return t .. ': ' .. m
  elseif t and t ~= '' then
    return t
  elseif m and m ~= '' then
    return m
  end
  return ''
end

-- update message per-buffer from $/progress
---@param bufnr integer
---@param result table
local function update_buffer_message(bufnr, result)
  local v = result.value or {}
  local token = token_key(result.token)

  -- Ensure buffer data exists
  state.buffer_data[bufnr] = state.buffer_data[bufnr] or { pending = {} }
  local buf_data = state.buffer_data[bufnr]

  -- Manage token-scoped title cache
  if v.kind == state.loading.BEGIN then
    if v.title and v.title ~= '' then
      state.token_map[token] = state.token_map[token] or {}
      state.token_map[token].title = v.title
    end
  elseif v.kind == state.loading.REPORT then
    if v.title and v.title ~= '' then
      state.token_map[token] = state.token_map[token] or {}
      state.token_map[token].title = v.title
    end
    -- if no title in report, keep existing token title
  elseif v.kind == state.loading.END then
    -- capture title to show in DONE message for the buffer
    local token_info = state.token_map[token]
    local t = v.title or (token_info and token_info.title) or v.message or ''
    if t and t ~= '' then buf_data.done_title = t end
    -- cleanup token title
    if state.token_map[token] then state.token_map[token].title = nil end
  end

  local combined = build_combined_text(token, v)
  local base = highlight().string(hl_groups.progress, combined)

  if v.kind == state.loading.BEGIN then
    buf_data.message = base .. ' '
  elseif v.kind == state.loading.REPORT then
    local m = base
    if v.percentage then
      -- percentage styled with progress hl group
      m = m .. string.format(' %%#%s#(%d%%%%)%%* ', hl_groups.progress, v.percentage)
    end
    buf_data.message = m
  elseif v.kind == state.loading.END then
    buf_data.message = state.loading.DONE
  end
end

function M.render()
  if utils().is_narrow(M.opts.min_width) then return '' end

  local bufnr = vim.api.nvim_get_current_buf()
  if not cache().lsp_attached[bufnr] then return '' end

  local buf_data = state.buffer_data[bufnr]
  if not buf_data then return '' end

  local buf_pending = buf_data.pending
  local buf_msg = buf_data.message

  -- no progress for this buffer
  if not buf_pending or next(buf_pending) == nil then
    if buf_msg == state.loading.DONE then return format_done(bufnr) end
    return ''
  end

  -- spinning
  return (buf_msg or '') .. format_spinner()
end

function M.autocmd(augroup)
  vim.api.nvim_create_autocmd('User', {
    group = augroup,
    pattern = user_events.update,
    callback = function()
      utils().throttled_redraw(100)
    end,
  })

  vim.api.nvim_create_autocmd('User', {
    group = augroup,
    pattern = user_events.done,
    callback = function()
      -- force a full redraw slightly after done timeout to ensure clearing
      vim.defer_fn(function()
        vim.cmd('redrawstatus!')
      end, done.timeout)
    end,
    desc = 'redraw slightly after done timeout to ensure clearing',
  })

  vim.api.nvim_create_autocmd({ 'LspAttach', 'LspDetach' }, {
    group = augroup,
    callback = function(args)
      local bufnr = args.buf
      -- clear buffer data
      state.buffer_data[bufnr] = nil

      -- remove token_map entries that point to this buffer
      for tok, info in pairs(state.token_map) do
        if info.bufnr == bufnr then state.token_map[tok] = nil end
      end

      cache().invalidate(M.name, bufnr)
    end,
    desc = 'clear buffer state',
  })

  -- spinner timer (advance only if any buffer has pending work)
  timer = uv.new_timer()
  ---@diagnostic disable-next-line: need-check-nil
  timer:start(
    0,
    M.opts.spinner_interval,
    vim.schedule_wrap(function()
      for _, buf_data in pairs(state.buffer_data) do
        if buf_data.pending and next(buf_data.pending) ~= nil then
          spinner_index = (spinner_index % #M.opts.spinner) + 1
          utils().throttled_redraw(50)
          return
        end
      end
    end)
  )

  -- progress handler - token-scoped and buffer-aware
  vim.lsp.handlers['$/progress'] = function(_, result, ctx)
    local client_id = ctx.client_id
    local token = result.token
    local token_k = token_key(token)

    -- BEGIN: associate token with current buf
    if result.value and result.value.kind == state.loading.BEGIN then
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

      state.token_map[token_k] = { bufnr = current_buf }
    end

    -- map token -> buffer
    local token_info = state.token_map[token_k]
    if not token_info then return end

    local bufnr = token_info.bufnr
    if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then return end

    -- ensure buffer data exists
    state.buffer_data[bufnr] = state.buffer_data[bufnr] or { pending = {} }
    state.buffer_data[bufnr].pending[client_id] = result.value

    -- update per-buffer message using the token-scoped state
    update_buffer_message(bufnr, result)

    if result.value and result.value.kind == state.loading.END then
      -- clean up per-client for this buffer
      state.buffer_data[bufnr].pending[client_id] = nil
      state.token_map[token_k] = nil
      -- emit done pattern so autocmd does the final redraw after timeout
      vim.api.nvim_exec_autocmds('User', { pattern = user_events.done })
    else
      vim.api.nvim_exec_autocmds('User', { pattern = user_events.update })
    end
  end
end

local function clear_state()
  state.buffer_data = {}
  state.token_map = {}
end

-- teardown helper
local function stop_timer()
  if not timer then return end

  if timer.stop then pcall(timer.stop, timer) end

  pcall(timer.close, timer)
  timer = nil
end

function M.cleanup()
  clear_state()
  stop_timer()
end

function M.setup(opts)
  M.opts = opts or {}
  return M
end

return M
