local config = require("breakdown.config")
local M = {}

local state = {
  running = false,
  timer = nil,
  last_reading = nil,
  on_impact = nil,
}

local function read_accelerometer()
  local handle = io.popen("ioreg -c SMCMotionSensor 2>/dev/null | grep -A 2 '\"Coordinates\"' | tail -1")
  if not handle then
    return nil
  end

  local result = handle:read("*a")
  handle:close()

  local x, y, z = result:match("%((-?%d+),(-?%d+),(-?%d+)%)")
  if x and y and z then
    return {
      x = tonumber(x),
      y = tonumber(y),
      z = tonumber(z),
    }
  end

  return nil
end

local function calculate_magnitude(reading)
  return math.sqrt(reading.x * reading.x + reading.y * reading.y + reading.z * reading.z)
end

local function check_impact()
  local current = read_accelerometer()
  if not current then
    return false
  end

  if not state.last_reading then
    state.last_reading = current
    return false
  end

  local cfg = config.get()
  local delta = {
    x = current.x - state.last_reading.x,
    y = current.y - state.last_reading.y,
    z = current.z - state.last_reading.z,
  }

  local magnitude = calculate_magnitude(delta)
  state.last_reading = current

  return magnitude > cfg.impact_threshold
end

function M.start(callback)
  if state.running then
    return
  end

  if vim.fn.has("mac") == 0 then
    vim.notify("Accelerometer only works on macOS", vim.log.levels.WARN)
    return
  end

  local initial_test = read_accelerometer()
  if not initial_test then
    vim.notify(
      "Accelerometer not accessible (Intel Macs only). Use :Breakdown command instead.",
      vim.log.levels.WARN
    )
    return
  end

  state.running = true
  state.on_impact = callback
  state.last_reading = initial_test

  local cfg = config.get()

  state.timer = vim.loop.new_timer()
  state.timer:start(0, cfg.poll_interval, vim.schedule_wrap(function()
    if not state.running then
      if state.timer then
        state.timer:stop()
        state.timer:close()
        state.timer = nil
      end
      return
    end

    if check_impact() and state.on_impact then
      state.on_impact()
    end
  end))
end

function M.stop()
  if state.timer then
    state.timer:stop()
    state.timer:close()
    state.timer = nil
  end

  state.running = false
  state.last_reading = nil
  state.on_impact = nil
end

function M.is_running()
  return state.running
end

return M
