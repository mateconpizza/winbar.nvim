local function cache()
  return require('winbar.cache')
end

local function highlight()
  return require('winbar.highlight')
end

local function extensions()
  return require('winbar.components.extensions')
end

-- stylua: ignore
local hl_groups = {
  NORMAL        = 'WinBarModeNormal',
  INSERT        = 'WinBarModeInsert',
  VISUAL        = 'WinBarModeVisual',
  REPLACE       = 'WinBarModeReplace',
  COMMAND       = 'WinBarModeCommand',
  TERMINAL      = 'WinBarModeTerminal',
  SELECT        = 'WinBarModeSelect',
  ['V-LINE']    = 'WinBarModeVisual',
  ['V-BLOCK']   = 'WinBarModeVisual',
  ['V-REPLACE'] = 'WinBarModeReplace',
  MORE          = 'WinBarModeMore',
  CONFIRM       = 'WinBarModeConfirm',
  SHELL         = 'WinBarModeShell',
}

-- stylua: ignore
local mode_standard = {
  ['n']       = 'NORMAL',
  ['niI']     = 'NORMAL',
  ['niR']     = 'NORMAL',
  ['niV']     = 'NORMAL',
  ['nt']      = 'NORMAL',
  ['ntT']     = 'NORMAL',
  ['v']       = 'VISUAL',
  ['vs']      = 'VISUAL',
  ['V']       = 'V-LINE',
  ['Vs']      = 'V-LINE',
  ['\22']     = 'V-BLOCK',
  ['\22s']    = 'V-BLOCK',
  ['s']       = 'SELECT',
  ['S']       = 'S-LINE',
  ['\19']     = 'S-BLOCK',
  ['i']       = 'INSERT',
  ['ic']      = 'INSERT',
  ['ix']      = 'INSERT',
  ['R']       = 'REPLACE',
  ['Rc']      = 'REPLACE',
  ['Rx']      = 'REPLACE',
  ['Rv']      = 'V-REPLACE',
  ['Rvc']     = 'V-REPLACE',
  ['Rvx']     = 'V-REPLACE',
  ['c']       = 'COMMAND',
  ['r']       = 'REPLACE',
  ['rm']      = 'MORE',
  ['r?']      = 'CONFIRM',
  ['!']       = 'SHELL',
  ['t']       = 'TERMINAL',
}

---@class winbar.currentMode
---@field enabled boolean?
---@field format? fun(mode: string): string custom formatter

---@class winbar.components.extensions
---@field modes winbar.components.modes?

---@class winbar.components.modes: winbar.component
local M = {}

M.name = 'modes'
M.side = 'left'
M.enabled = function()
  return M.opts.enabled
end

-- stylua: ignore
---@class winbar.userHighlights
---@field WinBarModeNormal winbar.HighlightAttrs?    highlight for NORMAL mode
---@field WinBarModeInsert winbar.HighlightAttrs?    highlight for INSERT mode
---@field WinBarModeVisual winbar.HighlightAttrs?    highlight for VISUAL mode
---@field WinBarModeReplace winbar.HighlightAttrs?   highlight for REPLACE mode
---@field WinBarModeCommand winbar.HighlightAttrs?   highlight for COMMAND mode
---@field WinBarModeTerminal winbar.HighlightAttrs?  highlight for TERMINAL mode
---@field WinBarModeSelect winbar.HighlightAttrs?    highlight for SELECT mode
---@field WinBarModeVLine winbar.HighlightAttrs?     highlight for V-LINE mode
---@field WinBarModeVBlock winbar.HighlightAttrs?    highlight for V-BLOCK mode
---@field WinBarModeVReplace winbar.HighlightAttrs?  highlight for V-REPLACE mode
---@field WinBarModeMore winbar.HighlightAttrs?      highlight for MORE mode
---@field WinBarModeConfirm winbar.HighlightAttrs?   highlight for CONFIRM mode
---@field WinBarModeShell winbar.HighlightAttrs?     highlight for SHELL mode
M.highlights = {
  [hl_groups.NORMAL]        = {  link = 'Conceal'    },
  [hl_groups.INSERT]        = {  link = 'String'     },
  [hl_groups.VISUAL]        = {  link = 'Title'      },
  [hl_groups.REPLACE]       = {  link = 'Error'      },
  [hl_groups.COMMAND]       = {  link = 'Identifier' },
  [hl_groups.TERMINAL]      = {  link = 'Special'    },
  [hl_groups.SELECT]        = {  link = 'Statement'  },
  [hl_groups['V-LINE']]     = {  link = 'Statement'  },
  [hl_groups['V-BLOCK']]    = {  link = 'Statement'  },
  [hl_groups['V-REPLACE']]  = {  link = 'Statement'  },
  [hl_groups.MORE]          = {  link = 'WarningMsg' },
  [hl_groups.CONFIRM]       = {  link = 'WarningMsg' },
  [hl_groups.SHELL]         = {  link = 'Special'    },
}

---@type winbar.currentMode
M.opts = {
  enabled = false,
  format = function(mode)
    return mode
  end,
}

function M.render()
  return cache().ensure(M.name, vim.api.nvim_get_current_buf(), function()
    local mode = vim.api.nvim_get_mode().mode
    local mode_name = mode_standard[mode] or 'NORMAL'
    local hl = hl_groups[mode_name] or 'WinBarModeNormal'
    mode = M.opts.format(mode_name) or ''

    return highlight().string(hl, mode)
  end)
end

function M.autocmd(augroup)
  vim.api.nvim_create_autocmd('ModeChanged', {
    group = augroup,
    callback = function(args)
      cache().invalidate(M.name, args.buf)
    end,
    desc = 'invalidate cache when editor mode changes',
  })
end

---@param opts winbar.currentMode
---@return winbar.component
function M.setup(opts)
  M.opts = vim.tbl_deep_extend('force', M.opts, opts or {})
  return M
end

return M
