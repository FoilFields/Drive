-- CELL_MIN_X = -16
-- CELL_MAX_X = 16
-- CELL_MIN_Y = -16
-- CELL_MAX_Y = 127

-- Dev
CELL_MIN_X = -4
CELL_MAX_X = 4
CELL_MIN_Y = -4
CELL_MAX_Y = 6

-- This is here to expose stuff to other classes (as SurvivalGame handles respawning player and needs values)
function getElevation(x, y, seed) 
  local elevation = 0.1

  elevation = elevation + (sm.noise.perlinNoise2d( x / 128, y / 128, seed + 14123 ) + 0.25) * 2 -- Super duper scrolling terrain
  elevation = elevation + (sm.noise.perlinNoise2d( x / 64, y / 64, seed + 12032 ) + 0.25) * 1.25
  elevation = elevation + (sm.noise.perlinNoise2d( x / 32, y / 32, seed + 10293 ) + 0.25)
  elevation = elevation + (sm.noise.perlinNoise2d( x / 16, y / 16, seed + 7907 ) + 0.25) * 0.75
  elevation = elevation + (sm.noise.perlinNoise2d( x / 8, y / 8, seed + 5527 ) + 0.25) * 0.5
  elevation = elevation + (sm.noise.perlinNoise2d( x / 4, y / 4, seed + 8733 ) + 0.25) * 0.25
  elevation = elevation + (sm.noise.perlinNoise2d( x / 2, y / 2, seed + 5442 ) + 0.25) * 0.125

  return elevation
end