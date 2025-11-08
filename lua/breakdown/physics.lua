local config = require("breakdown.config")
local M = {}

function M.create_particle(char, row, col)
  local cfg = config.get()

  return {
    char = char,
    x = col,
    y = row,
    vx = (math.random() - 0.5) * 2 * cfg.drift_max,
    vy = math.random() * cfg.initial_velocity_max,
    mass = cfg.mass_min + math.random() * (cfg.mass_max - cfg.mass_min),
    resting = false,
    hl_group = "Normal",
  }
end

function M.check_particle_collision(particle, all_particles)
  local cfg = config.get()

  for _, other in ipairs(all_particles) do
    if other ~= particle and other.resting then
      local dx = math.abs(particle.x - other.x)
      local dy = particle.y - other.y

      if dx < cfg.collision_distance and dy < 0.5 and dy > -0.3 then
        particle.y = other.y - cfg.collision_padding
        particle.vy = 0
        particle.vx = particle.vx * 0.5
        particle.resting = true
        return true
      end
    end
  end

  return false
end

function M.update_particle(particle, dt, ground_level, all_particles)
  if particle.resting then
    return
  end

  local cfg = config.get()

  particle.vy = particle.vy + (cfg.gravity * particle.mass) * dt
  particle.y = particle.y + particle.vy * dt
  particle.x = particle.x + particle.vx * dt
  particle.vx = particle.vx * cfg.air_resistance

  if M.check_particle_collision(particle, all_particles) then
    return
  end

  if particle.y >= ground_level then
    particle.y = ground_level
    particle.vy = 0
    particle.vx = 0
    particle.resting = true
  end
end

function M.all_particles_resting(particles)
  for _, p in ipairs(particles) do
    if not p.resting then
      return false
    end
  end
  return true
end

return M
