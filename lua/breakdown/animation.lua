local config = require("breakdown.config")
local physics = require("breakdown.physics")
local M = {}

local state = {
  running = false,
  timer = nil,
  bufnr = nil,
  namespace = nil,
  particles = {},
  original_lines = {},
  original_buf_line_count = nil,
  top_line = 1,
  ground_level = 0,
}

local function get_highlight_at_pos(bufnr, row, col)
  local ok, data = pcall(vim.inspect_pos, bufnr, row, col)

  if not ok or not data then
    return "Normal"
  end

  if data.treesitter and data.treesitter[1] and data.treesitter[1].hl_group then
    return data.treesitter[1].hl_group
  elseif data.semantic_tokens and data.semantic_tokens[1] and data.semantic_tokens[1].opts then
    return data.semantic_tokens[1].opts.hl_group or "Normal"
  elseif data.extmarks and data.extmarks[1] and data.extmarks[1].opts then
    return data.extmarks[1].opts.hl_group or "Normal"
  elseif data.syntax and data.syntax[1] and data.syntax[1].hl_group then
    return data.syntax[1].hl_group
  end

  return "Normal"
end

local function capture_particles(bufnr, winnr, win_height)
  local particles = {}
  local top_line = vim.fn.line('w0', winnr)
  local bot_line = vim.fn.line('w$', winnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, top_line - 1, bot_line, false)

  for row_offset, line in ipairs(lines) do
    local buffer_row = top_line + row_offset - 2

    for col = 1, #line do
      local char = line:sub(col, col)
      if char ~= " " and char ~= "" then
        local window_row = row_offset - 1
        local particle = physics.create_particle(char, window_row, col - 1)
        particle.hl_group = get_highlight_at_pos(bufnr, buffer_row, col - 1)
        table.insert(particles, particle)
      end
    end
  end

  return particles
end

local function render_particles()
  vim.api.nvim_buf_clear_namespace(state.bufnr, state.namespace, 0, -1)

  for _, particle in ipairs(state.particles) do
    local window_row = math.floor(particle.y + 0.5)
    local col = math.floor(particle.x + 0.5)
    local buffer_row = window_row + state.top_line - 1

    if buffer_row >= 0 and col >= 0 and vim.api.nvim_buf_is_valid(state.bufnr) then
      local line_count = vim.api.nvim_buf_line_count(state.bufnr)
      if buffer_row < line_count then
        pcall(vim.api.nvim_buf_set_extmark, state.bufnr, state.namespace, buffer_row, 0, {
          virt_text = {{particle.char, particle.hl_group}},
          virt_text_pos = "overlay",
          virt_text_win_col = col,
          priority = 200,
        })
      end
    end
  end
end

local function update_frame(last_time)
  if not state.running then
    return
  end

  local current_time = vim.loop.hrtime()
  local dt = math.min((current_time - last_time) / 1e9, 0.033)

  for _, particle in ipairs(state.particles) do
    physics.update_particle(particle, dt, state.ground_level, state.particles)
  end

  render_particles()

  if physics.all_particles_resting(state.particles) then
    M.stop()
  end

  return current_time
end

local function restore_buffer()
  vim.on_key(nil, vim.api.nvim_create_namespace("breakdown_keyhandler"))

  if not state.bufnr or not vim.api.nvim_buf_is_valid(state.bufnr) then
    return
  end

  vim.api.nvim_buf_clear_namespace(state.bufnr, state.namespace, 0, -1)

  if #state.original_lines > 0 then
    local start_line = state.top_line - 1
    local end_line = start_line + #state.original_lines
    vim.api.nvim_buf_set_lines(state.bufnr, start_line, end_line, false, state.original_lines)
  end

  if state.original_buf_line_count then
    local current_count = vim.api.nvim_buf_line_count(state.bufnr)
    if current_count > state.original_buf_line_count then
      vim.api.nvim_buf_set_lines(state.bufnr, state.original_buf_line_count, -1, false, {})
    end
  end

  state.particles = {}
  state.original_lines = {}
  state.top_line = 1
  state.original_buf_line_count = nil
end

function M.start()
  if state.running then
    return
  end

  state.running = true
  state.bufnr = vim.api.nvim_get_current_buf()
  state.namespace = vim.api.nvim_create_namespace("breakdown")

  local winnr = vim.api.nvim_get_current_win()
  local win_height = vim.api.nvim_win_get_height(0)

  local top_line = vim.fn.line('w0')
  local bot_line = vim.fn.line('w$')
  state.original_lines = vim.api.nvim_buf_get_lines(state.bufnr, top_line - 1, bot_line, false)
  state.top_line = top_line
  state.original_buf_line_count = vim.api.nvim_buf_line_count(state.bufnr)
  state.ground_level = win_height - 1

  state.particles = capture_particles(state.bufnr, winnr, win_height)

  if #state.particles == 0 then
    state.running = false
    return
  end

  local required_lines = top_line - 1 + win_height
  if state.original_buf_line_count < required_lines then
    local lines_to_add = {}
    for i = 1, required_lines - state.original_buf_line_count do
      table.insert(lines_to_add, "")
    end
    vim.api.nvim_buf_set_lines(state.bufnr, -1, -1, false, lines_to_add)
  end

  local empty_lines = {}
  for i = 1, #state.original_lines do
    table.insert(empty_lines, "")
  end
  vim.api.nvim_buf_set_lines(state.bufnr, top_line - 1, bot_line, false, empty_lines)

  local cfg = config.get()
  local frame_time = math.floor(1000 / cfg.fps)
  local last_time = vim.loop.hrtime()

  state.timer = vim.loop.new_timer()
  state.timer:start(0, frame_time, vim.schedule_wrap(function()
    if not state.running then
      if state.timer then
        state.timer:stop()
        state.timer:close()
        state.timer = nil
      end
      return
    end

    last_time = update_frame(last_time)
  end))
end

function M.stop()
  if state.timer then
    state.timer:stop()
    state.timer:close()
    state.timer = nil
  end

  state.running = false

  local keyhandler_ns = vim.api.nvim_create_namespace("breakdown_keyhandler")
  vim.on_key(nil, keyhandler_ns)

  if state.bufnr and vim.api.nvim_buf_is_valid(state.bufnr) then
    vim.on_key(function(key)
      vim.schedule(function()
        restore_buffer()
      end)
    end, keyhandler_ns)
  end
end

function M.is_running()
  return state.running
end

return M
