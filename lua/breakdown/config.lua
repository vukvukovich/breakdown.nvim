local M = {}

M.defaults = {
  fps = 60,
  gravity = 50.0,
  mass_min = 0.7,
  mass_max = 1.7,
  drift_max = 1.5,
  initial_velocity_max = 2.0,
  air_resistance = 0.98,
  collision_padding = 0.3,
  collision_distance = 1.5,
}

M.options = vim.deepcopy(M.defaults)

function M.setup(user_config)
  M.options = vim.tbl_deep_extend("force", M.defaults, user_config or {})
end

function M.get()
  return M.options
end

function M.reset()
  M.options = vim.deepcopy(M.defaults)
end

return M
