local config = require("breakdown.config")
local animation = require("breakdown.animation")

local M = {}

function M.setup(user_config)
  config.setup(user_config)
end

function M.breakdown()
  if animation.is_running() then
    vim.notify("Breakdown animation already running", vim.log.levels.WARN)
    return
  end

  animation.start()
end

function M.is_running()
  return animation.is_running()
end

return M
