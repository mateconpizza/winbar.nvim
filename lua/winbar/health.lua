local function defaults()
  return require('winbar.config')
end

local errors = {}
local warnings = {}

local M = {}

local function hl_exists(name)
  return vim.fn.hlexists(name) == 1
end

function M.log_error(key)
  errors[key] = true
end

function M.log_warning(key)
  warnings[key] = true
end

function M.show_highlights()
  local hl = require('winbar.highlight').highlights
  local missing = {}

  for _, def in pairs(hl) do
    if type(def) == 'table' and def.group then
      if not hl_exists(def.group) then table.insert(missing, def.group) end
    end
  end

  if #missing == 0 then
    vim.health.ok('All highlight groups exist')
  else
    vim.health.warn('Missing highlight groups:')
    for _, name in ipairs(missing) do
      vim.health.info('  - ' .. name)
    end
  end
end

function M.show_warnings()
  for w, _ in pairs(warnings) do
    vim.health.warn(w)
  end
end

function M.show_errors()
  for e, _ in pairs(errors) do
    vim.health.error(e)
  end
end

---@param c winbar.config
function M.validate(c)
  local function validate_field(name, value, type_check, optional)
    local ok = pcall(function()
      if vim.fn.has('nvim-0.11') == 1 then
        vim.validate(name, value, type_check, optional)
      else
        vim.validate({ [name] = { value, type_check, optional } })
      end
    end)

    return ok
  end

  -- validate update_interval
  if not validate_field('update_interval', c.update_interval, 'number') then
    M.log_warning(
      "invalid 'update_interval':\n"
        .. "  fallback to default value '"
        .. tostring(defaults().config.update_interval)
        .. "'"
    )
    c.update_interval = defaults().config.update_interval
  end

  -- validate enabled
  if not validate_field('enabled', c.enabled, 'boolean') then
    M.log_warning("invalid 'enabled', fallback to default true")
    c.enabled = defaults().config.enabled
  end

  -- validate show_single_buffer
  if not validate_field('show_single_buffer', c.show_single_buffer, 'boolean') then
    M.log_warning("invalid 'show_single_buffer', fallback to default false")
    c.show_single_buffer = defaults().config.show_single_buffer
  end

  -- validate exclusions structure
  if c.exclusions then
    -- check it's not a list
    if vim.islist(c.exclusions) then
      M.log_error(
        'invalid config:\n'
          .. "  ✗ exclusions = {'somestring'}\n"
          .. '  ✓ exclusions = { filetypes = {...}, buftypes = {...} }'
      )
      -- reset to defaults
      c.exclusions = {
        filetypes = defaults().config.exclusions.filetypes,
        buftypes = defaults().config.exclusions.buftypes,
      }
      return
    end

    -- Validate exclusions is a table
    if not validate_field('exclusions', c.exclusions, 'table', true) then
      M.log_warning("invalid 'exclusions', fallback to empty tables")
      c.exclusions = {
        filetypes = defaults().config.exclusions.filetypes,
        buftypes = defaults().config.exclusions.buftypes,
      }
    else
      -- validate filetypes
      if c.exclusions.filetypes ~= nil then
        if type(c.exclusions.filetypes) ~= 'table' or not vim.islist(c.exclusions.filetypes) then
          M.log_warning("invalid 'exclusions.filetypes', must be a string array. Fallback to empty")
          c.exclusions.filetypes = defaults().config.exclusions.filetypes
        end
      end

      -- validate buftypes
      if c.exclusions.buftypes ~= nil then
        if type(c.exclusions.buftypes) ~= 'table' or not vim.islist(c.exclusions.buftypes) then
          M.log_warning("invalid 'exclusions.buftypes', must be a string array. Fallback to empty")
          c.exclusions.buftypes = defaults().config.exclusions.buftypes
        end
      end
    end
  end

  -- validate layout structure
  if c.layout then
    if not validate_field('layout', c.layout, 'table', true) then
      M.log_warning("invalid 'layout', fallback to default layout")
      c.layout = { left = {}, center = {}, right = {} }
    else
      -- validate each section
      for _, section in ipairs({ 'left', 'center', 'right' }) do
        if c.layout[section] ~= nil then
          if type(c.layout[section]) ~= 'table' or not vim.islist(c.layout[section]) then
            M.log_warning(string.format("invalid 'layout.%s', must be a string array. Fallback to empty", section))
            c.layout[section] = {}
          end
        end
      end
    end
  end

  -- Validate highlights
  if c.highlights then
    if not validate_field('highlights', c.highlights, 'table', true) then
      M.log_warning("invalid 'highlights', fallback to defaults")
      c.highlights = {}
    end
  end

  -- Validate icons
  if c.icons then
    if not validate_field('icons', c.icons, 'table', true) then
      M.log_warning("invalid 'icons', fallback to defaults")
      c.icons = {}
    end
  end

  vim.health.ok('Valid configuration')
end

function M.check()
  if vim.fn.has('nvim-0.10') == 0 then vim.health.error('Neovim 0.10 or later is required') end

  vim.health.start('winbar.nvim report')
  M.show_highlights()
  M.show_errors()
  M.show_warnings()
end

return M
