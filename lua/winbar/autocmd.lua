-- autocmd.lua

local function cache()
  return require('winbar.cache')
end

local function utils()
  return require('winbar.util')
end

local autocmd = vim.api.nvim_create_autocmd
local cache_augroup = utils().augroup('cache')

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
      cache().invalidate('gitbranch', args.buf)
      utils().throttled_redraw(update_interval)
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
      if not utils().is_normal_buffer(bufnr) or not utils().is_visible_in_normal_win(bufnr) then return end

      cache().invalidate('lsp_diagnostics', bufnr)
      utils().throttled_redraw(update_interval)
    end,
  })

  -- register LSP attach/detach events
  autocmd('LspAttach', {
    group = cache_augroup,
    callback = function(args)
      local bufnr = args.buf
      if not utils().is_normal_buffer(bufnr) or not utils().is_visible_in_normal_win(bufnr) then return end

      cache().lsp_attached[bufnr] = true
      cache().invalidate('lsp_diagnostics', bufnr)
      utils().throttled_redraw(update_interval)
    end,
  })

  -- clear diagnostics cache
  autocmd('LspDetach', {
    group = cache_augroup,
    callback = function(args)
      local bufnr = args.buf
      cache().lsp_attached[bufnr] = nil
      cache().invalidate('lsp_diagnostics', bufnr)
      cache().invalidate('lsp_clients', bufnr)
    end,
  })
end

---@param update_interval integer
function M.gitdiff(update_interval)
  autocmd({ 'BufWritePost', 'BufEnter' }, {
    group = cache_augroup,
    callback = function(args)
      local bufnr = args.buf
      if not utils().is_normal_buffer(bufnr) or not utils().is_visible_in_normal_win(bufnr) then return end
      cache().invalidate('gitdiff', bufnr)
      utils().throttled_redraw(update_interval)
    end,
  })
end

function M.cleanup()
  autocmd({ 'BufDelete', 'BufWipeout' }, {
    group = cache_augroup,
    callback = function(args)
      local bufnr = args.buf
      if not utils().is_normal_buffer(bufnr) then return end
      cache().prune(bufnr)
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
  cache().reset()
end

return M
