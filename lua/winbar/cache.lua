---@diagnostic disable: undefined-field
local uv = vim.uv or vim.loop

---@param ttl_ms number|nil time to live in milliseconds. If nil, lives forever.
---@return number
local function calculate_expiry(ttl_ms)
  if not ttl_ms or ttl_ms == math.huge then return math.huge end
  return uv.hrtime() + (ttl_ms * 1e6)
end

local M = {}

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

  -- generate value and store it
  local val = generator()
  store[domain][k] = {
    value = val,
    expires_at = calculate_expiry(ttl),
  }

  return val
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

  M.lsp_attached = {}
end

return M
