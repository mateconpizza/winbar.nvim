local C = require('winbar.components')
local U = require('winbar.util')

local autocmd = vim.api.nvim_create_autocmd
local cache_augroup = U.augroup('cache')

local M = {}

---@type winbar.cache
M.cache = nil

---@param update_interval integer
function M.gitbranch(update_interval)
  autocmd({ 'DirChanged', 'BufEnter' }, {
    group = cache_augroup,
    callback = function(args)
      M.cache['git_branch_' .. args.buf] = nil
      U.throttled_redraw(update_interval)
    end,
  })
end

---@param update_interval integer
function M.diagnostics(update_interval)
  -- diagnostic changes (triggered by LSP updates)
  autocmd('DiagnosticChanged', {
    group = cache_augroup,
    callback = function(args)
      local bufnr = args.buf
      if not U.is_normal_buffer(bufnr) or not U.is_visible_in_normal_win(bufnr) then return end

      C.cache.diagnostics[bufnr] = nil
      U.throttled_redraw(update_interval)
    end,
  })

  -- register LSP attach/detach events
  autocmd('LspAttach', {
    group = cache_augroup,
    callback = function(args)
      local bufnr = args.buf
      if not U.is_normal_buffer(bufnr) or not U.is_visible_in_normal_win(bufnr) then return end

      vim.defer_fn(function()
        M.cache.diagnostics[bufnr] = nil
        M.cache['git_diff_' .. bufnr] = nil
        U.throttled_redraw(update_interval)
      end, 50)
    end,
  })

  -- clear diagnostics cache
  autocmd('LspDetach', {
    group = cache_augroup,
    callback = function(args)
      local bufnr = args.buf
      M.cache.diagnostics[bufnr] = nil
    end,
  })
end

---@param update_interval integer
function M.gitdiff(update_interval)
  autocmd({ 'BufWritePost', 'BufEnter' }, {
    group = cache_augroup,
    callback = function(args)
      local bufnr = args.buf
      if not U.is_normal_buffer(bufnr) or not U.is_visible_in_normal_win(bufnr) then return end

      vim.defer_fn(function()
        M.cache['git_diff_' .. bufnr] = nil
        U.throttled_redraw(update_interval)
      end, 50)
    end,
  })
end

function M.cleanup()
  autocmd('BufDelete', {
    group = cache_augroup,
    callback = function(args)
      local bufnr = args.buf
      C.cache.diagnostics[bufnr] = nil
      C.cache['git_diff_' .. bufnr] = nil
    end,
  })
end

---@param c winbar.config
---@param cache winbar.cache
function M.setup(c, cache)
  M.cache = cache

  -- clear diagnostics on change
  if c.diagnostics.enabled then M.diagnostics(c.update_interval) end

  -- clear branch on dir change or bufenter
  if c.git.branch.enabled then M.gitbranch(c.update_interval) end

  -- clear git diff cache when file changes
  if c.git.diff.enabled then M.gitdiff(c.update_interval) end

  -- cleanup cache on buffer delete
  M.cleanup()
end

return M
