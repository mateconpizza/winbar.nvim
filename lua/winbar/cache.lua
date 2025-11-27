---@diagnostic disable: undefined-field
local uv = vim.uv or vim.loop

local function utils()
  return require('winbar.util')
end

local function health()
  return require('winbar.health')
end

local augroup_cache = utils().augroup('cache')

local shown_errors = {}

---@param ttl_ms number|nil time to live in milliseconds. If nil, lives forever.
---@return number
local function calculate_expiry(ttl_ms)
  if not ttl_ms or ttl_ms == math.huge then return math.huge end
  return uv.hrtime() + (ttl_ms * 1e6)
end

local M = {}

-- cache autocommand group
M.augroup = augroup_cache

-- store whether lsp is attached per buffer
---@type table<integer, boolean>
M.lsp_attached = {}

---@class CacheEntry
---@field value any
---@field expires_at number

-- the data store.
-- structure: store[domain][key] = { value = ..., expires_at = ... }
-- uses a metatable to auto-create domains (namespaces) on the fly.
local store = setmetatable({}, {
  __index = function(t, k)
    local v = {}
    rawset(t, k, v)
    return v
  end,
})

-- core memoization function
---@generic T
---@param domain string component (e.g., "filename", "git", "icon")
---@param key string|number unique ID (usually bufnr)
---@param generator fun(): T expensive function to run if cache misses
---@param ttl? number TTL in milliseconds (optional)
---@return T
function M.ensure(domain, key, generator, ttl)
  local k = tostring(key)
  ---@type CacheEntry
  local entry = store[domain][k]
  local now = uv.hrtime()

  -- return if entry exists and hasn't expired
  if entry and now < entry.expires_at then return entry.value end

  -- generate value safely
  local ok, content = pcall(generator)
  if not ok then
    local errmsg = content

    if not shown_errors[domain] then
      shown_errors[domain] = true
      vim.schedule(function()
        local mesg = "component '" .. domain .. "' crashed"
        health().log_error(mesg)
        utils().err(mesg .. '\n' .. errmsg)
      end)
    end

    content = '' -- fallback value
  end

  -- store it
  store[domain][k] = {
    value = content,
    expires_at = calculate_expiry(ttl),
  }

  return content
end

-- manually invalidate a specific entry (useful for bufwritepost)
---@param domain string
---@param key string|number
function M.invalidate(domain, key)
  local k = tostring(key)
  if rawget(store, domain) then store[domain][k] = nil end
end

-- garbage collector: clear all cache domains for a specific key (bufnr)
---@param key string|number
function M.prune(key)
  local k = tostring(key)
  for _, domain_store in pairs(store) do
    domain_store[k] = nil
  end
end

--- completely wipe all cached data
function M.reset()
  for _, domain_store in pairs(store) do
    for k, _ in pairs(domain_store) do
      domain_store[k] = nil
    end
  end
end

-- inspect the current winbar cache state
function M.inspect()
  local lines = utils().prettify_store(store)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = 'markdown'

  local newbufnr, win = utils().create_floating_window({
    title = '~ WinBar Cache Inspector ~',
    buf = buf,
    title_pos = 'center',
  })

  -- easy close with <q> or <esc>
  vim.keymap.set({ 'n', 'i' }, 'q', function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = newbufnr, nowait = true, silent = true })
  vim.keymap.set({ 'n', 'i' }, '<Esc>', function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = newbufnr, nowait = true, silent = true })
end

return M
