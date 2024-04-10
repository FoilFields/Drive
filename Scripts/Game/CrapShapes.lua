dofile("$SURVIVAL_DATA/Scripts/game/survival_items.lua")

g_crap_pools = {}

g_crap_pools["crap"] = {
  count = 4,
  draws = {
    -- {uid = jnt_bearing, count = 1, weight = 10}, 
    {uid = obj_scrap_gasengine, count = 1, weight = 10}, 
    {uid = obj_scrap_driverseat, count = 1, weight = 10}, 
    {uid = obj_scrap_seat, count = 1, weight = 10}, 
    {uid = obj_scrap_smallwheel, count = 1, weight = 10}, 
    {uid = obj_interactive_timer, count = 1, weight = 10}, 
    {uid = obj_interactive_logicgate, count = 1, weight = 10}, 
    {uid = obj_interactive_horn, count = 1, weight = 10}, 
    {uid = obj_interactive_radio, count = 1, weight = 10}, 
    {uid = obj_interactive_button, count = 1, weight = 10}, 
    {uid = obj_interactive_switch, count = 1, weight = 10}, 
    -- {uid = jnt_suspensionsport_01, count = 1, weight = 10}, 
    -- {uid = jnt_suspensionoffroad_01, count = 1, weight = 10}, 
    {uid = obj_interactive_bathtub, count = 1, weight = 10}, 
    {uid = obj_interactive_toilet, count = 1, weight = 10}, 
    {uid = obj_interactive_seat_01, count = 1, weight = 10}, 
    {uid = obj_interactive_driversaddle_01, count = 1, weight = 10},
    {uid = obj_interactive_saddle_01, count = 1, weight = 10},
    {uid = obj_interactive_gasengine_01, count = 1, weight = 10},
    {uid = obj_interactive_thruster_01, count = 1, weight = 10},
    {uid = obj_interactive_controller_01, count = 1, weight = 10},
    {uid = obj_interactive_sensor_01, count = 1, weight = 10},
    -- {uid = jnt_interactive_piston_01, count = 1, weight = 10},
    {uid = obj_interactive_comfybed, count = 1, weight = 10},
    {uid = obj_interactive_mountablespudgun, count = 1, weight = 10},
    {uid = obj_vehicle_smallwheel, count = 1, weight = 10},
    {uid = obj_vehicle_bigwheel, count = 1, weight = 10},
    {uid = obj_powertools_drill, count = 1, weight = 10}
  }
}

g_crap_pools["head"] = {
  {uid = obj_interactive_robotbasshead, count = 1, weight = 10}, 
  {uid = obj_interactive_robotdrumhead, count = 1, weight = 10}, 
  {uid = obj_interactive_robotsynthhead, count = 1, weight = 10}, 
  {uid = obj_interactive_robotbliphead01, count = 1, weight = 10}
}

g_crap_pools["tools"] = {
  {uid = tool_sledgehammer, count = 1, weight = 10}, 
  {uid = tool_connect, count = 1, weight = 10}, 
  {uid = tool_paint, count = 1, weight = 10}, 
  {uid = tool_weld, count = 1, weight = 10}, 
  {uid = tool_spudgun, count = 1, weight = 10}, 
  {uid = tool_shotgun, count = 1, weight = 10}, 
  {uid = tool_gatling, count = 1, weight = 10}, 
}

g_crap_pools["lights"] = {
  {uid = obj_light_headlight, count = 1, weight = 10}, 
  {uid = obj_light_beamframelight, count = 1, weight = 10}, 
  {uid = obj_light_factorylamp, count = 1, weight = 10}, 
  {uid = obj_light_packingtablelamp, count = 1, weight = 10}, 
  {uid = obj_light_fluorescentlamp, count = 1, weight = 10}, 
  {uid = obj_light_arealight, count = 1, weight = 10}, 
  {uid = obj_light_posterspotlight, count = 1, weight = 10}, 
  {uid = obj_light_posterspotlight2, count = 1, weight = 10}, 
}
