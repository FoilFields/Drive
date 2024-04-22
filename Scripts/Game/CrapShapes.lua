dofile("$SURVIVAL_DATA/Scripts/game/survival_items.lua")

g_crap_pools = {}

g_crap_pools["crap"] = {
  weight = 0,
  draws = {
    {uid = obj_scrap_gasengine, weight = 10}, 
    {uid = obj_scrap_driverseat, weight = 8}, 
    {uid = obj_scrap_seat, weight = 10}, 
    {uid = obj_scrap_smallwheel, weight = 10}, 
    {uid = obj_interactive_timer, weight = 10}, 
    {uid = obj_interactive_logicgate, weight = 10}, 
    {uid = obj_interactive_horn, weight = 10}, 
    {uid = obj_interactive_radio, weight = 2}, 
    {uid = obj_interactive_button, weight = 10}, 
    {uid = obj_interactive_switch, weight = 10}, 
    {uid = obj_interactive_seat_01, weight = 10}, 
    {uid = obj_interactive_driversaddle_01, weight = 8},
    {uid = obj_interactive_saddle_01, weight = 10},
    {uid = obj_interactive_gasengine_01, weight = 5},
    {uid = obj_interactive_thruster_01, weight = 1},
    {uid = obj_interactive_controller_01, weight = 3},
    {uid = obj_interactive_sensor_01, weight = 10},
    {uid = obj_interactive_mountablespudgun, weight = 10},
    {uid = obj_vehicle_smallwheel, weight = 10},
    {uid = obj_vehicle_bigwheel, weight = 8},
    {uid = obj_container_gas, weight = 5},
    {uid = obj_powertools_drill, weight = 4},
    {uid = obj_vehicle_license_plate, weight = 10}
  }
}

-- The ship currently spawns 9 items
g_crap_pools["ship"] = {
  weight = 0,
  draws = {
    {uid = obj_interactive_timer, weight = 15}, 
    {uid = obj_interactive_logicgate, weight = 15}, 
    {uid = obj_interactive_button, weight = 15}, 
    {uid = obj_interactive_switch, weight = 15}, 
    {uid = obj_interactive_gasengine_01, weight = 9},
    {uid = obj_interactive_gasengine_04, weight = 3},
    {uid = obj_interactive_gasengine_05, weight = 1},
    {uid = obj_interactive_thruster_01, weight = 1},
    {uid = obj_interactive_thruster_02, weight = 1},
    {uid = obj_interactive_controller_02, weight = 1},
    {uid = obj_interactive_controller_05, weight = 1},
    {uid = obj_interactive_mountablespudgun, weight = 1},
    {uid = obj_consumable_gas, weight = 60},
    {uid = obj_consumable_component, weight = 40},
  }
}

g_crap_pools["robot_bits"] = {
  weight = 0,
  draws = {
    {uid = obj_interactive_robotbasshead, weight = 10},
    {uid = obj_interactive_robotdrumhead, weight = 10},
    {uid = obj_interactive_robotsynthhead, weight = 10},
    {uid = obj_interactive_robotbliphead01, weight = 10},
    {uid = obj_decor_screw01, weight = 5},
    {uid = obj_decor_screw02, weight = 5}
  }
}

g_crap_pools["garage"] = {
  weight = 0,
  draws = {
    {uid = obj_interactive_robotbasshead, weight = 10},
    {uid = obj_interactive_robotdrumhead, weight = 10},
    {uid = obj_interactive_robotsynthhead, weight = 10},
    {uid = obj_interactive_robotbliphead01, weight = 10},
    {uid = obj_decor_screw01, weight = 5},
    {uid = obj_decor_screw02, weight = 5}
  }
}

g_crap_pools["garage_back"] = {
  weight = 0,
  draws = {
    {uid = obj_interactive_robotbasshead, weight = 10},
    {uid = obj_interactive_robotdrumhead, weight = 10},
    {uid = obj_interactive_robotsynthhead, weight = 10},
    {uid = obj_interactive_robotbliphead01, weight = 10},
    {uid = obj_decor_screw01, weight = 5},
    {uid = obj_decor_screw02, weight = 5}
  }
}

g_crap_pools["bus_roof"] = {
  weight = 0,
  draws = {
    {uid = obj_interactive_bathtub, weight = 10},
    {uid = obj_interactive_toilet, weight = 10},
    {uid = obj_consumable_component, weight = 6},
    {uid = obj_decor_screw01, weight = 2},
    {uid = obj_decor_screw02, weight = 2}
  }
}

g_crap_pools["radio_station_secret"] = {
  weight = 0,
  draws = {
    {uid = obj_consumable_gas, weight = 10},
    {uid = obj_consumable_component, weight = 10},
  }
}

g_crap_pools["radio_station_roof"] = {
  weight = 0,
  draws = {
    {uid = obj_consumable_gas, weight = 10},
    {uid = obj_consumable_component, weight = 10},
  }
}

g_crap_pools["radio_station_walkway"] = {
  weight = 0,
  draws = {
    {uid = obj_consumable_gas, weight = 10},
    {uid = obj_consumable_component, weight = 10},
  }
}

g_crap_pools["pothole"] = {
  weight = 0,
  draws = {
    {uid = obj_decor_cone, weight = 10},
    {uid = obj_decor_babyduck, weight = 10},
    {uid = obj_decor_mannequinhand, weight = 10},
    {uid = obj_decor_boot, weight = 10},
    {uid = obj_consumable_component, weight = 10}
  }
}

g_crap_pools["observation_top"] = {
  weight = 0,
  draws = {
    {uid = obj_consumable_water, weight = 10},
    {uid = obj_consumable_longsandwich, weight = 10},
  }
}

g_crap_pools["petrol_station"] = {
  weight = 0,
  draws = {
    {uid = obj_consumable_sunshake, weight = 10},
    {uid = obj_consumable_gas, weight = 10},
  }
}

-- Spawns 5 of these
g_crap_pools["radio_tower"] = {
  weight = 0,
  draws = {
    {uid = obj_consumable_component, weight = 5},
    {uid = obj_tool_frier, weight = 1},
    {uid = obj_tool_spudling, weight = 1},
    {uid = obj_tool_paint, weight = 1},
    {uid = obj_tool_connect, weight = 1},
    {uid = obj_tool_weld, weight = 1},
    {uid = obj_tool_spudgun, weight = 1},
  }
}

-- Spawns 3 of these
g_crap_pools["parking_lot"] = {
  weight = 0,
  draws = {
    {uid = obj_consumable_component, weight = 5},
  }
}

-- Spawns 2 of these
g_crap_pools["shop_roof"] = {
  weight = 0,
  draws = {
    {uid = obj_consumable_component, weight = 5},
  }
}

g_crap_pools["petrol_station_roof"] = {
  weight = 0,
  draws = {
    {uid = obj_containers_cowcrate, weight = 3},
    {uid = obj_decor_cone, weight = 10},
    {uid = obj_container_chest, weight = 3},
    {uid = obj_container_smallchest, weight = 6},
    {uid = obj_consumable_component, weight = 10},
  }
}

-- spawns 1 on the bus-stop bench
g_crap_pools["bus_seat"] = {
  weight = 0,
  draws = {
    {uid = obj_decor_babyduck, weight = 10},
    {uid = obj_decor_pillow, weight = 7}
  }
}

-- g_crap_pools["tools"] = {
--   weight = 0,
--   draws = {
--     {uid = tool_sledgehammer, weight = 10}, 
--     {uid = tool_connect, weight = 10}, 
--     {uid = tool_paint, weight = 10}, 
--     {uid = tool_weld, weight = 10}, 
--     {uid = tool_spudgun, weight = 10}, 
--     {uid = tool_shotgun, weight = 10}, 
--     {uid = tool_gatling, weight = 10}, 
--   }
-- }

-- g_crap_pools["lights"] = {
--   weight = 0,
--   draws = {
--     {uid = obj_light_headlight, weight = 10}, 
--     {uid = obj_light_beamframelight, weight = 10}, 
--     {uid = obj_light_factorylamp, weight = 10}, 
--     {uid = obj_light_packingtablelamp, weight = 10}, 
--     {uid = obj_light_fluorescentlamp, weight = 10}, 
--     {uid = obj_light_arealight, weight = 10}, 
--     {uid = obj_light_posterspotlight, weight = 10}, 
--     {uid = obj_light_posterspotlight2, weight = 10}, 
--   }
-- }

function calculatePoolWeight(pool)
  local totalWeight = 0
  for _, item in ipairs(pool.draws) do
    totalWeight = totalWeight + item.weight
  end
  return totalWeight
end

for poolName, poolData in pairs(g_crap_pools) do
  poolData.weight = calculatePoolWeight(poolData)
end
