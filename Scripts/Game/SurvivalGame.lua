dofile("$SURVIVAL_DATA/Scripts/game/managers/BeaconManager.lua")
dofile("$SURVIVAL_DATA/Scripts/game/managers/EffectManager.lua")
dofile("$SURVIVAL_DATA/Scripts/game/managers/ElevatorManager.lua")
dofile("$SURVIVAL_DATA/Scripts/game/managers/RespawnManager.lua")
dofile("$SURVIVAL_DATA/Scripts/game/managers/UnitManager.lua")
dofile("$SURVIVAL_DATA/Scripts/game/survival_constants.lua")
dofile("$SURVIVAL_DATA/Scripts/game/survival_harvestable.lua")
dofile("$SURVIVAL_DATA/Scripts/game/survival_shapes.lua")
dofile("$CONTENT_DATA/Scripts/Game/CustomObjects.lua")
dofile("$SURVIVAL_DATA/Scripts/game/survival_units.lua")
dofile("$SURVIVAL_DATA/Scripts/game/survival_projectiles.lua")
dofile("$SURVIVAL_DATA/Scripts/game/survival_meleeattacks.lua")
dofile("$SURVIVAL_DATA/Scripts/game/util/recipes.lua")
dofile("$SURVIVAL_DATA/Scripts/game/util/Timer.lua")
dofile("$GAME_DATA/Scripts/game/managers/EventManager.lua")
dofile("$CONTENT_DATA/Scripts/Game/Managers/PortalManager.lua")
dofile("$CONTENT_DATA/Scripts/Terrain/Util.lua")

---@class SurvivalGame : GameClass
---@field sv table
---@field cl table
---@field warehouses table
SurvivalGame = class(nil)
SurvivalGame.enableLimitedInventory = true
SurvivalGame.enableRestrictions = true
SurvivalGame.enableFuelConsumption = true
SurvivalGame.enableAmmoConsumption = true
SurvivalGame.enableUpgrade = true

local SyncInterval = 400 -- 400 ticks | 10 seconds
local IntroFadeDuration = 1.1
local IntroEndFadeDuration = 1.1
local IntroFadeTimeout = 5.0

START_AREA_SPAWN_POINT = sm.vec3.new(79.3593, 27.5039, 136.696)

function SurvivalGame.server_onCreate(self)
	
	self.sv = {}
	
	-- We have to have this before world is created as progress effects world creation
	self.sv.progress = sm.storage.load("progress")
	if (self.sv.progress) then
		print("Loaded progress:")
		print(self.sv.progress)
	else
		self.sv.progress = 0
		sm.storage.save("progress", self.sv.progress)
		print("Saved progress: ")
		print(self.sv.progress)
	end

	print("SurvivalGame.server_onCreate")
	self.sv.saved = self.storage:load()
	print("Saved:", self.sv.saved)
	if self.sv.saved == nil then
		self.sv.saved = {}
		self.sv.saved.data = self.data
		print("Seed: %.0f", self.sv.saved.data.seed)
		self.sv.saved.overworld = sm.world.createWorld("$CONTENT_DATA/Scripts/Game/Worlds/Overworld.lua", "Overworld", { dev = self.sv.saved.data.dev, progress = self.sv.progress }, self.sv.saved.data.seed)
		self.storage:save(self.sv.saved)
	end
	self.data = nil

	print(self.sv.saved.data)
	if self.sv.saved.data and self.sv.saved.data.dev then
		g_godMode = true
		g_survivalDev = true
		sm.log.info("Starting SurvivalGame in DEV mode")
	end

	self:loadCraftingRecipes()
	g_enableCollisionTumble = true

	g_eventManager = EventManager()
	g_eventManager:sv_onCreate()

	g_portalManager = PortalManager()

	g_respawnManager = RespawnManager()
	g_respawnManager:sv_onCreate(self.sv.saved.overworld)

	g_beaconManager = BeaconManager()
	g_beaconManager:sv_onCreate()

	g_unitManager = UnitManager()
	g_unitManager:sv_onCreate(self.sv.saved.overworld)

	g_switchingWorld = false

	-- Game script managed global warehouse table
	self.sv.warehouses = sm.storage.load(STORAGE_CHANNEL_WAREHOUSES)
	if self.sv.warehouses then
		print("Loaded warehouses:")
		print(self.sv.warehouses)
	else
		self.sv.warehouses = {}
		sm.storage.save(STORAGE_CHANNEL_WAREHOUSES, self.sv.warehouses)
	end

	self.sv.time = sm.storage.load(STORAGE_CHANNEL_TIME)
	if self.sv.time then
		print("Loaded timeData:")
		print(self.sv.time)
	else
		self.sv.time = {}
		self.sv.time.timeOfDay = 6 / 24 -- 06:00
		self.sv.time.timeProgress = true
		sm.storage.save(STORAGE_CHANNEL_TIME, self.sv.time)
	end
	self.network:setClientData({ dev = g_survivalDev }, 1)
	self:sv_updateClientData()

	self.sv.syncTimer = Timer()
	self.sv.syncTimer:start(0)
end

-- IDK what data this stores but we save it anyway in case its data effected by the createWorld process. Also better to save this data asap, rather than when we destroy the old world
function SurvivalGame:sv_save()
	self.storage:save(self.sv.saved)
end

function SurvivalGame:sv_loadDestination()
	if g_switchingWorld then
		print("Cannot load new destination as we're already switching worlds")
		return
	end

	print("Loading portal destination")
	
	local players = sm.player.getAllPlayers();
	
	-- Ensure everyone is in the exit
	for _, player in ipairs(players) do
		local character = player:getCharacter();
		local cellX = math.floor(character.worldPosition.x / 64)
		local cellY = math.floor(character.worldPosition.y / 64)
		
		print("Player at ("..cellX.." | "..cellY..")")

		if (cellX ~= 0 or cellY ~= CELL_MAX_Y - 1) then
			print("Can't progress, player outside exit area!")
			return false
		end
	end
	
	print("All players inside exit area...")

	g_switchingWorld = true

	-- Creations on a lift won't teleport so we gotta do this
	for _, player in ipairs(players) do
		player:removeLift()
	end
	print("Removed all lifts")

	print("Incrementing progress")
	self.sv.progress = self.sv.progress + 1
	sm.storage.save("progress", self.sv.progress)

	print("Creating new world")
	self.sv.saved.overworld = sm.world.createWorld("$CONTENT_DATA/Scripts/Game/Worlds/Overworld.lua", "Overworld", { dev = g_survivalDev, progress = self.sv.progress }, self.sv.saved.data.seed)
	sm.storage:save(self.sv.saved)
	print("Created and saved world " .. self.sv.saved.overworld.id)
	
	sm.portal.addWorldPortalHook(self.sv.saved.overworld, "PORTAL", g_portalManager:sv_getPortal())

	for _, player in ipairs(players) do
		print("Loading entrance cell for "..player.name)
		self.sv.saved.overworld:loadCell(0, CELL_MIN_Y + 1, player, "sv_cellLoaded", nil, self)
	end
	
	print("Created new world with portal hook and loaded entrance portal for all players")
end

function SurvivalGame.sv_cellLoaded(self, world, x, y, player)
	print("Confirmed loading portal cell for a player at "..x..", "..y)
end

function SurvivalGame.server_onRefresh(self)
	g_craftingRecipes = nil
	g_refineryRecipes = nil
	self:loadCraftingRecipes()
end

function SurvivalGame.client_onCreate(self)
	print("SurvivalGame.client_onCreate")
	self.cl = {}
	self.cl.time = {}
	self.cl.time.timeOfDay = 0.0
	self.cl.time.timeProgress = true

	if not sm.isHost then
		self:loadCraftingRecipes()
		g_enableCollisionTumble = true
	end

	if g_respawnManager == nil then
		assert(not sm.isHost)
		g_respawnManager = RespawnManager()
	end
	g_respawnManager:cl_onCreate()

	if g_beaconManager == nil then
		assert(not sm.isHost)
		g_beaconManager = BeaconManager()
	end
	g_beaconManager:cl_onCreate()

	if g_unitManager == nil then
		assert(not sm.isHost)
		g_unitManager = UnitManager()
	end
	g_unitManager:cl_onCreate()

	g_effectManager = EffectManager()
	g_effectManager:cl_onCreate()

	-- Music effect
	g_survivalMusic = sm.effect.createEffect("SurvivalMusic")
	assert(g_survivalMusic)

	-- Survival HUD
	g_survivalHud = sm.gui.createSurvivalHudGui()
	assert(g_survivalHud)
end

function SurvivalGame.bindChatCommands(self)
	local addCheats = g_survivalDev

	if addCheats then
		sm.game.bindChatCommand("/ammo", { { "int", "quantity", true } }, "cl_onChatCommand", "Give ammo (default 50)")
		sm.game.bindChatCommand("/spudgun", {}, "cl_onChatCommand", "Give the spudgun")
		sm.game.bindChatCommand("/gatling", {}, "cl_onChatCommand", "Give the potato gatling gun")
		sm.game.bindChatCommand("/shotgun", {}, "cl_onChatCommand", "Give the fries shotgun")
		sm.game.bindChatCommand("/sunshake", {}, "cl_onChatCommand", "Give 1 sunshake")
		sm.game.bindChatCommand("/baguette", {}, "cl_onChatCommand", "Give 1 revival baguette")
		sm.game.bindChatCommand("/keycard", {}, "cl_onChatCommand", "Give 1 keycard")
		sm.game.bindChatCommand("/powercore", {}, "cl_onChatCommand", "Give 1 powercore")
		sm.game.bindChatCommand("/components", { { "int", "quantity", true } }, "cl_onChatCommand",
			"Give <quantity> components (default 10)")
		sm.game.bindChatCommand("/glowsticks", { { "int", "quantity", true } }, "cl_onChatCommand",
			"Give <quantity> components (default 10)")
		sm.game.bindChatCommand("/tumble", { { "bool", "enable", true } }, "cl_onChatCommand", "Set tumble state")
		sm.game.bindChatCommand("/god", {}, "cl_onChatCommand", "Mechanic characters will take no damage")
		sm.game.bindChatCommand("/respawn", {}, "cl_onChatCommand", "Respawn at last bed (or at the crash site)")
		sm.game.bindChatCommand("/encrypt", {}, "cl_onChatCommand", "Restrict interactions in all warehouses")
		sm.game.bindChatCommand("/decrypt", {}, "cl_onChatCommand", "Unrestrict interactions in all warehouses")
		sm.game.bindChatCommand("/limited", {}, "cl_onChatCommand", "Use the limited inventory")
		sm.game.bindChatCommand("/unlimited", {}, "cl_onChatCommand", "Use the unlimited inventory")
		sm.game.bindChatCommand("/ambush", { { "number", "magnitude", true }, { "int", "wave", true } },
			"cl_onChatCommand", "Starts a 'random' encounter")
		sm.game.bindChatCommand("/recreate", {}, "cl_onChatCommand", "Recreate world")
		sm.game.bindChatCommand("/timeofday", { { "number", "timeOfDay", true } }, "cl_onChatCommand",
			"Sets the time of the day as a fraction (0.5=mid day)")
		sm.game.bindChatCommand("/timeprogress", { { "bool", "enabled", true } }, "cl_onChatCommand",
			"Enables or disables time progress")
		sm.game.bindChatCommand("/day", {}, "cl_onChatCommand", "Disable time progression and set time to daytime")
		sm.game.bindChatCommand("/spawn", { { "string", "unitName", true }, { "int", "amount", true } },
			"cl_onChatCommand", "Spawn a unit: 'woc', 'tapebot', 'totebot', 'haybot'")
		sm.game.bindChatCommand("/harvestable", { { "string", "harvestableName", true } }, "cl_onChatCommand",
			"Create a harvestable: 'tree', 'stone'")
		sm.game.bindChatCommand("/cleardebug", {}, "cl_onChatCommand", "Clear debug draw objects")
		sm.game.bindChatCommand("/import", { { "string", "name", false } }, "cl_onChatCommand",
			"Imports blueprint $SURVIVAL_DATA/LocalBlueprints/<name>.blueprint")
		sm.game.bindChatCommand("/starterkit", {}, "cl_onChatCommand", "Spawn a starter kit")
		sm.game.bindChatCommand("/mechanicstartkit", {}, "cl_onChatCommand",
			"Spawn a starter kit for starting at mechanic station")
		sm.game.bindChatCommand("/pipekit", {}, "cl_onChatCommand", "Spawn a pipe kit")
		sm.game.bindChatCommand("/foodkit", {}, "cl_onChatCommand", "Spawn a food kit")
		sm.game.bindChatCommand("/seedkit", {}, "cl_onChatCommand", "Spawn a seed kit")
		sm.game.bindChatCommand("/die", {}, "cl_onChatCommand", "Kill the player")
		sm.game.bindChatCommand("/sethp", { { "number", "hp", false } }, "cl_onChatCommand", "Set player hp value")
		sm.game.bindChatCommand("/setwater", { { "number", "water", false } }, "cl_onChatCommand",
			"Set player water value")
		sm.game.bindChatCommand("/setfood", { { "number", "food", false } }, "cl_onChatCommand", "Set player food value")
		sm.game.bindChatCommand("/tp", { { "number", "x", true }, { "number", "y", true } }, "cl_onChatCommand", "Set player position")
		sm.game.bindChatCommand("/end", {}, "cl_onChatCommand", "Go to the end")
		sm.game.bindChatCommand("/aggroall", {}, "cl_onChatCommand",
			"All hostile units will be made aware of the player's position")
		sm.game.bindChatCommand("/goto", { { "string", "name", false } }, "cl_onChatCommand",
			"Teleport to predefined position")
		sm.game.bindChatCommand("/raid",
			{ { "int", "level", false }, { "int", "wave", true }, { "number", "hours", true } }, "cl_onChatCommand",
			"Start a level <level> raid at player position at wave <wave> in <delay> hours.")
		sm.game.bindChatCommand("/stopraid", {}, "cl_onChatCommand", "Cancel all incoming raids")
		sm.game.bindChatCommand("/disableraids", { { "bool", "enabled", false } }, "cl_onChatCommand",
			"Disable raids if true")
		sm.game.bindChatCommand("/camera", {}, "cl_onChatCommand", "Spawn a SplineCamera tool")
		sm.game.bindChatCommand("/noaggro", { { "bool", "enable", true } }, "cl_onChatCommand",
			"Toggles the player as a target")
		sm.game.bindChatCommand("/killall", {}, "cl_onChatCommand", "Kills all spawned units")
		sm.game.bindChatCommand("/printglobals", {}, "cl_onChatCommand", "Print all global lua variables")
		sm.game.bindChatCommand("/clearpathnodes", {}, "cl_onChatCommand", "Clear all path nodes in overworld")
		sm.game.bindChatCommand("/enablepathpotatoes", { { "bool", "enable", true } }, "cl_onChatCommand",
			"Creates path nodes at potato hits in overworld and links to previous node")
		sm.game.bindChatCommand("/settilebool", { { "string", "name", false }, { "bool", "value", false } },
			"cl_onChatCommand", "Set named tile value at player position as a bool")
		sm.game.bindChatCommand("/settilefloat", { { "string", "name", false }, { "number", "value", false } },
			"cl_onChatCommand", "Set named tile value at player position as a floating point number")
		sm.game.bindChatCommand("/settilestring", { { "string", "name", false }, { "string", "value", false } },
			"cl_onChatCommand", "Set named tile value at player position as a bool")
		sm.game.bindChatCommand("/printtilevalues", {}, "cl_onChatCommand", "Print all tile values at player position")
		sm.game.bindChatCommand("/reloadcell", { { "int", "x", true }, { "int", "y", true } }, "cl_onChatCommand",
			"Reload cells at self or {x,y}")
		sm.game.bindChatCommand("/tutorialstartkit", {}, "cl_onChatCommand",
			"Spawn a starter kit for building a scrap car")
	end
end

function SurvivalGame.client_onClientDataUpdate(self, clientData, channel)
	if channel == 2 then
		self.cl.time = clientData.time
	elseif channel == 1 then
		g_survivalDev = clientData.dev
		self:bindChatCommands()
	end
end

function SurvivalGame.loadCraftingRecipes(self)
	LoadCraftingRecipes({
		workbench = "$SURVIVAL_DATA/CraftingRecipes/workbench.json",
		dispenser = "$SURVIVAL_DATA/CraftingRecipes/dispenser.json",
		cookbot = "$SURVIVAL_DATA/CraftingRecipes/cookbot.json",
		craftbot = "$SURVIVAL_DATA/CraftingRecipes/craftbot.json",
		dressbot = "$SURVIVAL_DATA/CraftingRecipes/dressbot.json"
	})
end

function SurvivalGame.server_onFixedUpdate(self, timeStep)
	-- Update time

	local prevTime = self.sv.time.timeOfDay
	if self.sv.time.timeProgress then
		self.sv.time.timeOfDay = self.sv.time.timeOfDay + timeStep / DAYCYCLE_TIME
	end
	local newDay = self.sv.time.timeOfDay >= 1.0
	if newDay then
		self.sv.time.timeOfDay = math.fmod(self.sv.time.timeOfDay, 1)
	end

	if self.sv.time.timeOfDay >= DAYCYCLE_DAWN and prevTime < DAYCYCLE_DAWN then
		g_unitManager:sv_initNewDay()
	end

	-- Ambush
	--if not g_survivalDev then
	--	for _,ambush in ipairs( AMBUSHES ) do
	--		if self.sv.time.timeOfDay >= ambush.time and ( prevTime < ambush.time or newDay ) then
	--			self:sv_ambush( { magnitude = ambush.magnitude, wave = ambush.wave } )
	--		end
	--	end
	--end

	-- Client and save sync
	self.sv.syncTimer:tick()
	if self.sv.syncTimer:done() then
		self.sv.syncTimer:start(SyncInterval)
		sm.storage.save(STORAGE_CHANNEL_TIME, self.sv.time)
		self:sv_updateClientData()
	end

	g_unitManager:sv_onFixedUpdate()
	if g_eventManager then
		g_eventManager:sv_onFixedUpdate()
	end

	g_portalManager:sv_onFixedUpdate()
end

function SurvivalGame.sv_updateClientData(self)
	self.network:setClientData({ time = self.sv.time }, 2)
end

function SurvivalGame.client_onUpdate(self, dt)
	-- Update time
	if self.cl.time.timeProgress then
		self.cl.time.timeOfDay = math.fmod(self.cl.time.timeOfDay + dt / DAYCYCLE_TIME, 1.0)
	end
	sm.game.setTimeOfDay(self.cl.time.timeOfDay)

	-- Update lighting values
	local index = 1
	while index < #DAYCYCLE_LIGHTING_TIMES and self.cl.time.timeOfDay >= DAYCYCLE_LIGHTING_TIMES[index + 1] do
		index = index + 1
	end
	assert(index <= #DAYCYCLE_LIGHTING_TIMES)

	local light = 0.0
	if index < #DAYCYCLE_LIGHTING_TIMES then
		local p = (self.cl.time.timeOfDay - DAYCYCLE_LIGHTING_TIMES[index]) /
		(DAYCYCLE_LIGHTING_TIMES[index + 1] - DAYCYCLE_LIGHTING_TIMES[index])
		light = sm.util.lerp(DAYCYCLE_LIGHTING_VALUES[index], DAYCYCLE_LIGHTING_VALUES[index + 1], p)
	else
		light = DAYCYCLE_LIGHTING_VALUES[index]
	end
	sm.render.setOutdoorLighting(light)
end

function SurvivalGame.client_showMessage(self, msg)
	sm.gui.chatMessage(msg)
end

function SurvivalGame.cl_onChatCommand(self, params)
	local unitSpawnNames =
	{
		woc = unit_woc,
		tapebot = unit_tapebot,
		tb = unit_tapebot,
		redtapebot = unit_tapebot_red,
		rtb = unit_tapebot_red,
		totebot = unit_totebot_green,
		green = unit_totebot_green,
		t = unit_totebot_green,
		totered = unit_totebot_red,
		red = unit_totebot_red,
		tr = unit_totebot_red,
		haybot = unit_haybot,
		h = unit_haybot,
		worm = unit_worm,
		farmbot = unit_farmbot,
		f = unit_farmbot,











	}

	if params[1] == "/ammo" then
		self.network:sendToServer("sv_giveItem",
			{ player = sm.localPlayer.getPlayer(), item = obj_plantables_potato, quantity = (params[2] or 50) })
	elseif params[1] == "/spudgun" then
		self.network:sendToServer("sv_giveItem",
			{ player = sm.localPlayer.getPlayer(), item = tool_spudgun, quantity = 1 })
	elseif params[1] == "/gatling" then
		self.network:sendToServer("sv_giveItem",
			{ player = sm.localPlayer.getPlayer(), item = tool_gatling, quantity = 1 })
	elseif params[1] == "/shotgun" then
		self.network:sendToServer("sv_giveItem",
			{ player = sm.localPlayer.getPlayer(), item = tool_shotgun, quantity = 1 })
	elseif params[1] == "/sunshake" then
		self.network:sendToServer("sv_giveItem",
			{ player = sm.localPlayer.getPlayer(), item = obj_consumable_sunshake, quantity = 1 })
	elseif params[1] == "/baguette" then
		self.network:sendToServer("sv_giveItem",
			{ player = sm.localPlayer.getPlayer(), item = obj_consumable_longsandwich, quantity = 1 })
	elseif params[1] == "/keycard" then
		self.network:sendToServer("sv_giveItem",
			{ player = sm.localPlayer.getPlayer(), item = obj_survivalobject_keycard, quantity = 1 })
	elseif params[1] == "/camera" then
		self.network:sendToServer("sv_giveItem",
			{ player = sm.localPlayer.getPlayer(), item = sm.uuid.new("5bbe87d3-d60a-48b5-9ca9-0086c80ebf7f"), quantity = 1 })
	elseif params[1] == "/powercore" then
		self.network:sendToServer("sv_giveItem",
			{ player = sm.localPlayer.getPlayer(), item = obj_survivalobject_powercore, quantity = 1 })
	elseif params[1] == "/components" then
		self.network:sendToServer("sv_giveItem",
			{ player = sm.localPlayer.getPlayer(), item = obj_consumable_component, quantity = (params[2] or 10) })
	elseif params[1] == "/glowsticks" then
		self.network:sendToServer("sv_giveItem",
			{ player = sm.localPlayer.getPlayer(), item = obj_consumable_glowstick, quantity = (params[2] or 10) })
	elseif params[1] == "/god" then
		self.network:sendToServer("sv_switchGodMode")
	elseif params[1] == "/encrypt" then
		self.network:sendToServer("sv_enableRestrictions", true)
	elseif params[1] == "/decrypt" then
		self.network:sendToServer("sv_enableRestrictions", false)
	elseif params[1] == "/unlimited" then
		self.network:sendToServer("sv_setLimitedInventory", false)
	elseif params[1] == "/limited" then
		self.network:sendToServer("sv_setLimitedInventory", true)
	elseif params[1] == "/ambush" then
		self.network:sendToServer("sv_ambush", { magnitude = params[2] or 1, wave = params[3] })
	elseif params[1] == "/tp" then
		self.network:sendToServer("sv_teleportplayer", {player = sm.localPlayer.getPlayer(), x = params[2], y = params[3]})
	elseif params[1] == "/end" then
		self.network:sendToServer("sv_end", sm.localPlayer.getPlayer())
	elseif params[1] == "/recreate" then
		self.network:sendToServer("sv_recreateWorld", sm.localPlayer.getPlayer())
	elseif params[1] == "/timeofday" then
		self.network:sendToServer("sv_setTimeOfDay", params[2])
	elseif params[1] == "/timeprogress" then
		self.network:sendToServer("sv_setTimeProgress", params[2])
	elseif params[1] == "/day" then
		self.network:sendToServer("sv_setTimeOfDay", 0.5)
		self.network:sendToServer("sv_setTimeProgress", false)
	elseif params[1] == "/die" then
		self.network:sendToServer("sv_killPlayer", { player = sm.localPlayer.getPlayer() })
	elseif params[1] == "/spawn" then
		local rayCastValid, rayCastResult = sm.localPlayer.getRaycast(100)
		if rayCastValid then
			local spawnParams = {
				uuid = sm.uuid.getNil(),
				world = sm.localPlayer.getPlayer().character:getWorld(),
				position = rayCastResult.pointWorld,
				yaw = 0.0,
				amount = 1
			}
			if unitSpawnNames[params[2]] then
				spawnParams.uuid = unitSpawnNames[params[2]]
			else
				spawnParams.uuid = sm.uuid.new(params[2])
			end
			if params[3] then
				spawnParams.amount = params[3]
			end
			self.network:sendToServer("sv_spawnUnit", spawnParams)
		end
	elseif params[1] == "/harvestable" then
		local character = sm.localPlayer.getPlayer().character
		if character then
			local harvestableUuid = sm.uuid.getNil()
			if params[2] == "tree" then
				harvestableUuid = sm.uuid.new("c4ea19d3-2469-4059-9f13-3ddb4f7e0b79")
			elseif params[2] == "stone" then
				harvestableUuid = sm.uuid.new("0d3362ae-4cb3-42ae-8a08-d3f9ed79e274")
			elseif params[2] == "soil" then
				harvestableUuid = hvs_soil
			elseif params[2] == "fencelong" then
				harvestableUuid = sm.uuid.new("c0f19413-6d8e-4b20-819a-949553242259")
			elseif params[2] == "fenceshort" then
				harvestableUuid = sm.uuid.new("144b5e79-483e-4da6-86ab-c575d0fdcd11")
			elseif params[2] == "fencecorner" then
				harvestableUuid = sm.uuid.new("ead875db-59d0-45f5-861e-b3075e1f8434")
			elseif params[2] == "beehive" then
				harvestableUuid = hvs_farmables_beehive
			elseif params[2] == "cotton" then
				harvestableUuid = hvs_farmables_cottonplant
			elseif params[2] then
				harvestableUuid = sm.uuid.new(params[2])
			end
			local spawnParams = { world = character:getWorld(), uuid = harvestableUuid, position = character
			.worldPosition, quat = sm.vec3.getRotation(sm.vec3.new(0, 1, 0), sm.vec3.new(0, 0, 1)) }
			self.network:sendToServer("sv_spawnHarvestable", spawnParams)
		end
	elseif params[1] == "/cleardebug" then
		sm.debugDraw.clear()
	elseif params[1] == "/import" then
		local rayCastValid, rayCastResult = sm.localPlayer.getRaycast(100)
		if rayCastValid then
			local importParams = {
				world = sm.localPlayer.getPlayer().character:getWorld(),
				name = params[2],
				position = rayCastResult.pointWorld
			}
			self.network:sendToServer("sv_importCreation", importParams)
		end
	elseif params[1] == "/noaggro" then
		if type(params[2]) == "boolean" then
			self.network:sendToServer("sv_n_switchAggroMode", { aggroMode = not params[2] })
		else
			self.network:sendToServer("sv_n_switchAggroMode", { aggroMode = not sm.game.getEnableAggro() })
		end
	elseif params[1] == "/reloadcell" then
		local world = sm.localPlayer.getPlayer():getCharacter():getWorld()
		local player = sm.localPlayer.getPlayer()
		local pos = player.character:getWorldPosition();
		local x = params[2] or math.floor(pos.x / 64)
		local y = params[3] or math.floor(pos.y / 64)
		self.network:sendToServer("sv_reloadCell", { x = x, y = y, world = world, player = player })
	else
		self.network:sendToServer("sv_onChatCommand", params)
	end
end

function SurvivalGame.sv_reloadCell(self, params, player)
	print("sv_reloadCell Reloading cell at {" .. params.x .. " : " .. params.y .. "}")

	self.sv.saved.overworld:loadCell(params.x, params.y, player)
	self.network:sendToClients("cl_reloadCell", params)
end

function SurvivalGame.cl_reloadCell(self, params)
	print("cl_reloadCell reloading " .. params.x .. " : " .. params.y)
	for x = -2, 2 do
		for y = -2, 2 do
			params.world:reloadCell(params.x + x, params.y + y, "cl_reloadCellTestCallback")
		end
	end
end

function SurvivalGame.cl_reloadCellTestCallback(self, world, x, y, result)
	print("cl_reloadCellTestCallback")
	print("result = " .. result)
end

function SurvivalGame.sv_giveItem(self, params)
	sm.container.beginTransaction()
	sm.container.collect(params.player:getInventory(), params.item, params.quantity, false)
	sm.container.endTransaction()
end

function SurvivalGame.cl_n_onJoined(self, params)
	print("SurvivalGame.cl_n_onJoined(self, params)")
	print(params)
	--self.cl.playIntroCinematic = params.newPlayer
end

function SurvivalGame.client_onLoadingScreenLifted(self)
	g_effectManager:cl_onLoadingScreenLifted()
	self.network:sendToServer("sv_n_loadingScreenLifted")
	if self.cl.playIntroCinematic then
		local callbacks = {}
		callbacks[#callbacks + 1] = { fn = "cl_onCinematicEvent", params = { cinematicName = "cinematic.survivalstart01" }, ref =
		self }
		g_effectManager:cl_playNamedCinematic("cinematic.survivalstart01", callbacks)
	end
end

function SurvivalGame.sv_n_loadingScreenLifted(self, _, player)
	-- Ignore (used to activate tutorial quest)
end

function SurvivalGame.cl_onCinematicEvent(self, eventName, params)
	local myPlayer = sm.localPlayer.getPlayer()
	local myCharacter = myPlayer and myPlayer.character or nil
	if eventName == "survivalstart01.dramatics_standup" then
		if sm.exists(myCharacter) then
			sm.event.sendToCharacter(myCharacter, "cl_e_onEvent", "dramatics_standup")
		end
	elseif eventName == "survivalstart01.fadeout" then
		sm.event.sendToPlayer(myPlayer, "cl_e_startFadeToBlack",
			{ duration = IntroFadeDuration, timeout = IntroFadeTimeout })
	elseif eventName == "survivalstart01.fadein" then
		sm.event.sendToPlayer(myPlayer, "cl_n_endFadeToBlack", { duration = IntroEndFadeDuration })
	end
end

function SurvivalGame.sv_switchGodMode(self)
	g_godMode = not g_godMode
	self.network:sendToClients("client_showMessage", "GODMODE: " .. (g_godMode and "On" or "Off"))
end

function SurvivalGame.sv_n_switchAggroMode(self, params)
	sm.game.setEnableAggro(params.aggroMode)
	self.network:sendToClients("client_showMessage", "AGGRO: " .. (params.aggroMode and "On" or "Off"))
end

function SurvivalGame.sv_enableRestrictions(self, state)
	sm.game.setEnableRestrictions(state)
	self.network:sendToClients("client_showMessage", (state and "Restricted" or "Unrestricted"))
end

function SurvivalGame.sv_setLimitedInventory(self, state)
	sm.game.setLimitedInventory(state)
	self.network:sendToClients("client_showMessage", (state and "Limited inventory" or "Unlimited inventory"))
end

function SurvivalGame.sv_ambush(self, params)
	if sm.exists(self.sv.saved.overworld) then
		sm.event.sendToWorld(self.sv.saved.overworld, "sv_ambush", params)
	end
end

function SurvivalGame.sv_teleportplayer(self, data)
	local progressionOffset = (CELL_MAX_Y - CELL_MIN_Y) * self.sv.progress

	local elevation = getElevation(data.x, data.y + progressionOffset, self.sv.saved.data.seed, self.sv.progress == 0) * 83.0 + 1

	local params = { pos = sm.vec3.new(data.x * 64, data.y * 64, elevation), dir = data.player:getCharacter():getDirection() }
	self.sv.saved.overworld:loadCell(data.x, data.y, data.player, "sv_recreatePlayerCharacter", params)
end

function SurvivalGame.sv_end(self, player)
	local progressionOffset = (CELL_MAX_Y - CELL_MIN_Y) * self.sv.progress

	local params = { pos = sm.vec3.new(32, (CELL_MAX_Y - 1) * 64 + 32, getElevation(0, CELL_MAX_Y - 1 + progressionOffset, self.sv.saved.data.seed, self.sv.progress == 0) * 83.0 + 1), dir = player:getCharacter():getDirection() }
	self.sv.saved.overworld:loadCell(math.floor(params.pos.x / 64), math.floor(params.pos.y / 64), player,
		"sv_recreatePlayerCharacter", params)
end

function SurvivalGame.sv_recreateWorld(self, player)
	local character = player:getCharacter()
	if character:getWorld() == self.sv.saved.overworld then
		self.sv.saved.overworld:destroy()
		self.sv.saved.overworld = sm.world.createWorld("$CONTENT_DATA/Scripts/Game/Worlds/Overworld.lua", "Overworld",
			{ dev = g_survivalDev, progress = self.sv.progress }, self.sv.saved.data.seed)
		self.storage:save(self.sv.saved)

		local params = { pos = character:getWorldPosition(), dir = character:getDirection() }
		self.sv.saved.overworld:loadCell(math.floor(params.pos.x / 64), math.floor(params.pos.y / 64), player,
			"sv_recreatePlayerCharacter", params)

		self.network:sendToClients("client_showMessage", "Recreating world")
	else
		self.network:sendToClients("client_showMessage", "Recreate world only allowed for overworld")
	end
end

function SurvivalGame.sv_setTimeOfDay(self, timeOfDay)
	if timeOfDay then
		self.sv.time.timeOfDay = timeOfDay
		self.sv.syncTimer.count = self.sv.syncTimer.ticks -- Force sync
	end
	self.network:sendToClients("client_showMessage", ("Time of day set to " .. self.sv.time.timeOfDay))
end

function SurvivalGame.sv_setTimeProgress(self, timeProgress)
	if timeProgress ~= nil then
		self.sv.time.timeProgress = timeProgress
		self.sv.syncTimer.count = self.sv.syncTimer.ticks -- Force sync
	end
	self.network:sendToClients("client_showMessage",
		("Time scale set to " .. (self.sv.time.timeProgress and "on" or "off ")))
end

function SurvivalGame.sv_killPlayer(self, params)
	params.damage = 9999
	sm.event.sendToPlayer(params.player, "sv_e_receiveDamage", params)
end

function SurvivalGame.sv_spawnUnit(self, params)
	sm.event.sendToWorld(params.world, "sv_e_spawnUnit", params)
end

function SurvivalGame.sv_spawnHarvestable(self, params)
	sm.event.sendToWorld(params.world, "sv_spawnHarvestable", params)
end

function SurvivalGame.sv_importCreation(self, params)
	sm.creation.importFromFile(params.world, "$SURVIVAL_DATA/LocalBlueprints/" .. params.name .. ".blueprint",
		params.position)
end

function SurvivalGame.sv_onChatCommand(self, params, player)
	if params[1] == "/tumble" then
		if params[2] ~= nil then
			player.character:setTumbling(params[2])
		else
			player.character:setTumbling(not player.character:isTumbling())
		end
		if player.character:isTumbling() then
			self.network:sendToClients("client_showMessage", "Player is tumbling")
		else
			self.network:sendToClients("client_showMessage", "Player is not tumbling")
		end
	elseif params[1] == "/sethp" then
		sm.event.sendToPlayer(player, "sv_e_debug", { hp = params[2] })
	elseif params[1] == "/setwater" then
		sm.event.sendToPlayer(player, "sv_e_debug", { water = params[2] })
	elseif params[1] == "/setfood" then
		sm.event.sendToPlayer(player, "sv_e_debug", { food = params[2] })
	elseif params[1] == "/goto" then
		local pos
		if params[2] == "here" then
			pos = player.character:getWorldPosition()
		elseif params[2] == "start" then
			pos = START_AREA_SPAWN_POINT
		else
			self.network:sendToClient(player, "client_showMessage", "Unknown place")
		end
		if pos then
			local cellX, cellY = math.floor(pos.x / 64), math.floor(pos.y / 64)
			if not sm.exists(self.sv.saved.overworld) then
				sm.world.loadWorld(self.sv.saved.overworld)
			end
			self.sv.saved.overworld:loadCell(cellX, cellY, player, "sv_recreatePlayerCharacter",
				{ pos = pos, dir = player.character:getDirection() })
		end
	elseif params[1] == "/respawn" then
		sm.event.sendToPlayer(player, "sv_e_respawn")
	else
		params.player = player
		if sm.exists(player.character) then
			sm.event.sendToWorld(player.character:getWorld(), "sv_e_onChatCommand", params)
		end
	end
end

function SurvivalGame.server_onPlayerJoined(self, player, newPlayer)
	print(player.name, "joined the game")

	if newPlayer then --Player is first time joiners
		local inventory = player:getInventory()

		sm.container.beginTransaction()

		sm.container.setItem(inventory, 0, tool_lift, 1)
		sm.container.setItem(inventory, 1, tool_sledgehammer, 1)
		sm.container.setItem(inventory, 2, tool_connect, 1)

		sm.container.endTransaction()

		local spawnPoint = START_AREA_SPAWN_POINT
		if not sm.exists(self.sv.saved.overworld) then
			sm.world.loadWorld(self.sv.saved.overworld)
		end
		self.sv.saved.overworld:loadCell(math.floor(spawnPoint.x / 64), math.floor(spawnPoint.y / 64), player,
			"sv_createNewPlayer")
		self.network:sendToClient(player, "cl_n_onJoined", { newPlayer = newPlayer })
	else
		local inventory = player:getInventory()

		local sledgehammerCount = sm.container.totalQuantity(inventory, tool_sledgehammer)
		if sledgehammerCount == 0 then
			sm.container.beginTransaction()
			sm.container.collect(inventory, tool_sledgehammer, 1)
			sm.container.endTransaction()
		elseif sledgehammerCount > 1 then
			sm.container.beginTransaction()
			sm.container.spend(inventory, tool_sledgehammer, sledgehammerCount - 1)
			sm.container.endTransaction()
		end

		local tool_lift_creative = sm.uuid.new("5cc12f03-275e-4c8e-b013-79fc0f913e1b")
		local creativeLiftCount = sm.container.totalQuantity(inventory, tool_lift_creative)
		if creativeLiftCount > 0 then
			sm.container.beginTransaction()
			sm.container.spend(inventory, tool_lift_creative, creativeLiftCount)
			sm.container.endTransaction()
		end

		local liftCount = sm.container.totalQuantity(inventory, tool_lift)
		if liftCount == 0 then
			sm.container.beginTransaction()
			sm.container.collect(inventory, tool_lift, 1)
			sm.container.endTransaction()
		elseif liftCount > 1 then
			sm.container.beginTransaction()
			sm.container.spend(inventory, tool_lift, liftCount - 1)
			sm.container.endTransaction()
		end
	end
	g_unitManager:sv_onPlayerJoined(player)
end

function SurvivalGame.server_onPlayerLeft(self, player)
	print(player.name, "left the game")
end

function SurvivalGame.sv_e_requestWarehouseRestrictions(self, params)
	-- Send the warehouse restrictions to the world that asked
	print("SurvivalGame.sv_e_requestWarehouseRestrictions")

	-- Warehouse get
	local warehouse = nil
	if params.warehouseIndex then
		warehouse = self.sv.warehouses[params.warehouseIndex]
	end
	if warehouse then
		sm.event.sendToWorld(params.world, "server_updateRestrictions", warehouse.restrictions)
	end
end

function SurvivalGame.sv_e_setWarehouseRestrictions(self, params)
	-- Set the restrictions for this warehouse and propagate the restrictions to all floors

	-- Warehouse get
	local warehouse = nil
	if params.warehouseIndex then
		warehouse = self.sv.warehouses[params.warehouseIndex]
	end

	if warehouse then
		for _, newRestrictionSetting in pairs(params.restrictions) do
			if warehouse.restrictions[newRestrictionSetting.name] then
				warehouse.restrictions[newRestrictionSetting.name].state = newRestrictionSetting.state
			else
				warehouse.restrictions[newRestrictionSetting.name] = newRestrictionSetting
			end
		end
		self.sv.warehouses[params.warehouseIndex] = warehouse
		sm.storage.save(STORAGE_CHANNEL_WAREHOUSES, self.sv.warehouses)

		for i, world in ipairs(warehouse.worlds) do
			if sm.exists(world) then
				sm.event.sendToWorld(world, "server_updateRestrictions", warehouse.restrictions)
			end
		end
	end
end

function SurvivalGame.sv_createNewPlayer(self, world, x, y, player)
	print("SurvivalGame.sv_createNewPlayer")
	local params = { player = player, x = x, y = y }
	sm.event.sendToWorld(self.sv.saved.overworld, "sv_spawnNewCharacter", params)
end

function SurvivalGame.sv_recreatePlayerCharacter(self, world, x, y, player, params)
	local yaw = math.atan2(params.dir.y, params.dir.x) - math.pi / 2
	local pitch = math.asin(params.dir.z)
	local newCharacter = sm.character.createCharacter(player, self.sv.saved.overworld, params.pos, yaw, pitch)
	player:setCharacter(newCharacter)
	print("Recreate character in new world")
	print(params)
end

function SurvivalGame.sv_e_respawn(self, params)
	print("SurvivalGame.sv_e_respawn")
	if params.player.character and sm.exists(params.player.character) then
		g_respawnManager:sv_requestRespawnCharacter(params.player)
	else
		local spawnPoint = g_survivalDev and SURVIVAL_DEV_SPAWN_POINT or START_AREA_SPAWN_POINT
		if not sm.exists(self.sv.saved.overworld) then
			sm.world.loadWorld(self.sv.saved.overworld)
		end
		self.sv.saved.overworld:loadCell(math.floor(spawnPoint.x / 64), math.floor(spawnPoint.y / 64), params.player,
			"sv_createNewPlayer")
	end
end

function SurvivalGame.sv_loadedRespawnCell(self, world, x, y, player)
	print("SurvivalGame.sv_loadedRespawnCell")
	g_respawnManager:sv_respawnCharacter(player, world)
end

function SurvivalGame.sv_e_onSpawnPlayerCharacter(self, player)
	print("SurvivalGame.sv_e_onSpawnPlayerCharacter")
	if player.character and sm.exists(player.character) then
		g_respawnManager:sv_onSpawnCharacter(player)
		g_beaconManager:sv_onSpawnCharacter(player)
	else
		sm.log.warning("SurvivalGame.sv_e_onSpawnPlayerCharacter for a character that doesn't exist")
	end
end

function SurvivalGame.sv_e_markBag(self, params)
	if sm.exists(params.world) then
		sm.event.sendToWorld(params.world, "sv_e_markBag", params)
	else
		sm.log.warning("SurvivalGame.sv_e_markBag in a world that doesn't exist")
	end
end

function SurvivalGame.sv_e_unmarkBag(self, params)
	if sm.exists(params.world) then
		sm.event.sendToWorld(params.world, "sv_e_unmarkBag", params)
	else
		sm.log.warning("SurvivalGame.sv_e_unmarkBag in a world that doesn't exist")
	end
end

-- Beacons
function SurvivalGame.sv_e_createBeacon(self, params)
	if sm.exists(params.beacon.world) then
		sm.event.sendToWorld(params.beacon.world, "sv_e_createBeacon", params)
	else
		sm.log.warning("SurvivalGame.sv_e_createBeacon in a world that doesn't exist")
	end
end

function SurvivalGame.sv_e_destroyBeacon(self, params)
	if sm.exists(params.beacon.world) then
		sm.event.sendToWorld(params.beacon.world, "sv_e_destroyBeacon", params)
	else
		sm.log.warning("SurvivalGame.sv_e_destroyBeacon in a world that doesn't exist")
	end
end

function SurvivalGame.sv_e_unloadBeacon(self, params)
	if sm.exists(params.beacon.world) then
		sm.event.sendToWorld(params.beacon.world, "sv_e_unloadBeacon", params)
	else
		sm.log.warning("SurvivalGame.sv_e_unloadBeacon in a world that doesn't exist")
	end
end
