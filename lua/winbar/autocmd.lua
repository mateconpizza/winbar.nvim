local Cache = require('winbar.cache')
local Util = require('winbar.util')

local autocmd = vim.api.nvim_create_autocmd
local cache_augroup = Util.augroup('cache')

local M = {}

M.cmd = {
  inspect = 'WinBarCacheInspect',
  toggle = 'WinBarToggle',
}

---@param update_interval integer
function M.gitbranch(update_interval)
  autocmd({ 'DirChanged', 'BufEnter' }, {
    group = cache_augroup,
    callback = function(args)
      Cache.invalidate('gitbranch', args.buf)
      Util.throttled_redraw(update_interval)
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
      if not Util.is_normal_buffer(bufnr) or not Util.is_visible_in_normal_win(bufnr) then return end

      Cache.invalidate('lsp_diagnostics', bufnr)
      Util.throttled_redraw(update_interval)
    end,
  })

  -- register LSP attach/detach events
  autocmd('LspAttach', {
    group = cache_augroup,
    callback = function(args)
      local bufnr = args.buf
      if not Util.is_normal_buffer(bufnr) or not Util.is_visible_in_normal_win(bufnr) then return end

      Cache.lsp_attached[bufnr] = true
      Cache.invalidate('lsp_diagnostics', bufnr)
      Util.throttled_redraw(update_interval)
    end,
  })

  -- clear diagnostics cache
  autocmd('LspDetach', {
    group = cache_augroup,
    callback = function(args)
      local bufnr = args.buf
      Cache.lsp_attached[bufnr] = nil
      Cache.invalidate('lsp_diagnostics', bufnr)
      Cache.invalidate('lsp_clients', bufnr)
    end,
  })
end

---@param update_interval integer
function M.gitdiff(update_interval)
  autocmd({ 'BufWritePost', 'BufEnter' }, {
    group = cache_augroup,
    callback = function(args)
      local bufnr = args.buf
      if not Util.is_normal_buffer(bufnr) or not Util.is_visible_in_normal_win(bufnr) then return end
      Cache.invalidate('gitdiff', bufnr)
      Util.throttled_redraw(update_interval)
    end,
  })
end

function M.cleanup()
  autocmd({ 'BufDelete', 'BufWipeout' }, {
    group = cache_augroup,
    callback = function(args)
      local bufnr = args.buf
      if not Util.is_normal_buffer(bufnr) then return end
      Cache.prune(bufnr)
    end,
  })
end

---@param c winbar.config
function M.setup(c)
  -- clear diagnostics on change
  if c.diagnostics.enabled then M.diagnostics(c.update_interval) end

  -- clear branch on dir change or bufenter
  if c.git.branch.enabled then M.gitbranch(c.update_interval) end

  -- clear git diff cache when file changes
  if c.git.diff.enabled then M.gitdiff(c.update_interval) end

  -- cleanup cache on buffer delete
  M.cleanup()
end

-- clear all autocmds in the augroup
function M.disable()
  vim.api.nvim_clear_autocmds({ group = cache_augroup })
  Cache.reset()
end

return M
