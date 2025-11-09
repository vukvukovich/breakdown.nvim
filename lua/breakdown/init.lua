local config = require("breakdown.config")
local animation = require("breakdown.animation")
local accelerometer = require("breakdown.accelerometer")

local M = {}

function M.setup(user_config)
  config.setup(user_config)

  local cfg = config.get()
  if cfg.enable_accelerometer then
    accelerometer.start(function()
      M.breakdown()
    end)
  end
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

function M.stop_accelerometer()
  accelerometer.stop()
end

return M
