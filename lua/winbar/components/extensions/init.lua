local function utils()
  return require('winbar.util')
end

---@class winbar.components.extensions
local M = {}

setmetatable(M, {
  __index = function(tbl, key)
    local ok, mod = pcall(require, 'winbar.components.extensions.' .. key)
    if not ok then
      if mod:match('module.*not found') then
        utils().warn("extension '" .. key .. "' does not exist")
      else
        utils().err("extension '" .. key .. "' failed to load:\n" .. mod)
      end
      return nil
    end

    rawset(tbl, key, mod)
    return mod
  end,
})

return M
