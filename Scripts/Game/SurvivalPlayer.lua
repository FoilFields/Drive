dofile("$GAME_DATA/Scripts/game/BasePlayer.lua")
dofile("$SURVIVAL_DATA/Scripts/game/survival_camera.lua")
dofile("$SURVIVAL_DATA/Scripts/game/survival_constants.lua")
dofile("$SURVIVAL_DATA/Scripts/game/survival_items.lua")
dofile("$SURVIVAL_DATA/Scripts/game/survival_projectiles.lua")
dofile("$SURVIVAL_DATA/Scripts/game/util/Timer.lua")
dofile("$SURVIVAL_DATA/Scripts/util.lua")

SurvivalPlayer = class(BasePlayer)

local StatsTickRate = 40

local PerMinute = StatsTickRate / (40 * 60)

local HpRecovery = 50 * PerMinute

local SprintStaminaCost = 0.7 / 40 -- Per tick while sprinting
local CarryStaminaCost = 1.4 / 40  -- Per tick while carrying

local BreathLostPerTick = (100 / 60) / 40

local DrownDamage = 5
local DrownDamageCooldown = 40

local RespawnTimeout = 60 * 40

local RespawnFadeDuration = 0.45
local RespawnEndFadeDuration = 0.45

local RespawnFadeTimeout = 5.0
local RespawnDelay = RespawnFadeDuration * 40
local RespawnEndDelay = 1.0 * 40

local BaguetteSteps = 9

function SurvivalPlayer.server_onCreate(self)
	print("SurvivalPlayer.server_onCreate")
	self.sv = {}
	self.sv.saved = self.storage:load()
	print(self.sv.saved)
	self.sv.saved = self.sv.saved or {}
	self.sv.saved.stats = self.sv.saved.stats or {
		hp = 100,
		maxhp = 100,
		breath = 100,
		maxbreath = 100
	}
	if self.sv.saved.isConscious == nil then self.sv.saved.isConscious = true end
	if self.sv.saved.hasRevivalItem == nil then self.sv.saved.hasRevivalItem = false end
	self.sv.saved.isNewPlayer = true -- I know this sucks but we can't set a joining players world otherwise
	-- if self.sv.saved.isNewPlayer == nil then self.sv.saved.isNewPlayer = true end
	if self.sv.saved.inChemical == nil then self.sv.saved.inChemical = false end
	if self.sv.saved.inOil == nil then self.sv.saved.inOil = false end
	if self.sv.saved.tutorialsWatched == nil then self.sv.saved.tutorialsWatched = {} end
	self.storage:save(self.sv.saved)
	print("Saved 'self.sv.saved' (player) (creation): ")
	print(self.sv.saved)

	self:sv_init()
	self.network:setClientData(self.sv.saved)
end

function SurvivalPlayer.server_onRefresh(self)
	self:sv_init()
	self.network:setClientData(self.sv.saved)
end

function SurvivalPlayer.sv_init(self)
	print("SurvivalPlayer.sv_init")
	BasePlayer.sv_init(self)
	-- self.player:getInventory():setAllowCollect(false) -- Disable manually moving stuff into the inventory
	self.sv.staminaSpend = 0

	self.sv.statsTimer = Timer()
	self.sv.statsTimer:start(StatsTickRate)

	self.sv.drownTimer = Timer()
	self.sv.drownTimer:stop()

	self.sv.spawnparams = {}
end

function SurvivalPlayer.client_onCreate(self)
	BasePlayer.client_onCreate(self)
	self.cl = self.cl or {}
	if self.player == sm.localPlayer.getPlayer() then
		if g_survivalHud then
			-- GUI stuff can be found in GAME_DATA/Gui/Layouts/Hud
			g_survivalHud:setVisible("FoodBar", false)
			g_survivalHud:setVisible("WaterBar", false)

			g_survivalHud:setVisible("LogbookBinding", false)
			g_survivalHud:setVisible("LogbookIconBackground", false)
			g_survivalHud:setVisible("LogbookNotification", false)


			g_survivalHud:setVisible("InventoryIconBackground", false)
			g_survivalHud:setVisible("InventoryBinding", false)
			
			-- TODO: Figure out how to access the inventory gui and then do something like this
			-- inventoryHud:setVisible("InventoryPanel", false)
			-- or overwrite the layout directly by file
			-- or even hide the hud when opening the inventory
			-- could create a new ui with the same hotkey (idk is this possible?) and hope that the inventory closes automatically (bit of a long shot)

			g_survivalHud:setVisible("HandbookIconBackground", false)
			g_survivalHud:setVisible("HandbookBinding", false)
			g_survivalHud:open()
		end

		self.cl.underwaterEffect = sm.effect.createEffect("Mechanic - StatusUnderwater")
		self.cl.followCutscene = 0
		self.cl.tutorialsWatched = {}
	end

	self:cl_init()
end

function SurvivalPlayer.client_onRefresh(self)
	self:cl_init()

	sm.gui.hideGui(false)
	sm.camera.setCameraState(sm.camera.state.default)
	sm.localPlayer.setLockedControls(false)
end

function SurvivalPlayer.cl_init(self)
	self.useCutsceneCamera = false
	self.progress = 0
	self.nodeIndex = 1
	self.cl.revivalChewCount = 0
end

function SurvivalPlayer.client_onClientDataUpdate(self, data)
	BasePlayer.client_onClientDataUpdate(self, data)
	if sm.localPlayer.getPlayer() == self.player then
		if self.cl.stats == nil then self.cl.stats = data.stats end -- First time copy to avoid nil errors

		if g_survivalHud then
			g_survivalHud:setSliderData("Health", data.stats.maxhp * 10 + 1, data.stats.hp * 10)
			g_survivalHud:setSliderData("Breath", data.stats.maxbreath * 10 + 1, data.stats.breath * 10)
		end

		if self.cl.hasRevivalItem ~= data.hasRevivalItem then
			self.cl.revivalChewCount = 0
		end

		if self.player.character then
			local charParam = self.player:isMale() and 1 or 2
			self.cl.underwaterEffect:setParameter("char", charParam)

			if data.stats.breath <= 15 and not self.cl.underwaterEffect:isPlaying() and data.isConscious then
				self.cl.underwaterEffect:start()
			elseif (data.stats.breath > 15 or not data.isConscious) and self.cl.underwaterEffect:isPlaying() then
				self.cl.underwaterEffect:stop()
			end
		end

		if data.stats.hp < self.cl.stats.hp and data.stats.breath == 0 then
			sm.gui.displayAlertText("#{DAMAGE_BREATH}", 1)
		end

		self.cl.stats = data.stats
		self.cl.isConscious = data.isConscious
		self.cl.hasRevivalItem = data.hasRevivalItem

		-- sm.localPlayer.setBlockSprinting( false )

		for tutorialKey, _ in pairs(data.tutorialsWatched) do
			-- Merge saved tutorials and avoid resetting client tutorials
			self.cl.tutorialsWatched[tutorialKey] = true
		end
	end
end

function SurvivalPlayer.cl_e_tryPickupItemTutorial(self)
	if not g_disableTutorialHints then
		if not self.cl.tutorialsWatched["pickupitem"] then
			if not self.cl.tutorialGui then
				self.cl.tutorialGui = sm.gui.createGuiFromLayout("$GAME_DATA/Gui/Layouts/Tutorial/PopUp_Tutorial.layout",
					true, { isHud = true, isInteractive = false, needsCursor = false })
				self.cl.tutorialGui:setText("TextTitle", "#{TUTORIAL_PICKUP_ITEM_TITLE}")
				self.cl.tutorialGui:setText("TextMessage", "#{TUTORIAL_PICKUP_ITEM_MESSAGE}")
				local dismissText = string.format(sm.gui.translateLocalizationTags("#{TUTORIAL_DISMISS}"),
					sm.gui.getKeyBinding("Use"))
				self.cl.tutorialGui:setText("TextDismiss", dismissText)
				self.cl.tutorialGui:setImage("ImageTutorial", "gui_tutorial_image_pickup_items.png")
				self.cl.tutorialGui:setOnCloseCallback("cl_onCloseTutorialPickupItemGui")
				self.cl.tutorialGui:open()
			end
		end
	end
end

function SurvivalPlayer.cl_onCloseTutorialPickupItemGui(self)
	self.cl.tutorialsWatched["pickupitem"] = true
	self.network:sendToServer("sv_e_watchedTutorial", { tutorialKey = "pickupitem" })
	self.cl.tutorialGui = nil
end

function SurvivalPlayer.sv_e_watchedTutorial(self, params, player)
	self.sv.saved.tutorialsWatched[params.tutorialKey] = true
	self.storage:save(self.sv.saved)
	self.network:setClientData(self.sv.saved)

	print("Saved 'self.sv.saved' (player) (watched tutorial): ")
	print(self.sv.saved)
end

function SurvivalPlayer.cl_localPlayerUpdate(self, dt)
	BasePlayer.cl_localPlayerUpdate(self, dt)
	self:cl_updateCamera(dt)

	local character = self.player:getCharacter()
	if character and not self.cl.isConscious then
		local keyBindingText = sm.gui.getKeyBinding("Use", true)
		if self.cl.hasRevivalItem then
			if self.cl.revivalChewCount < BaguetteSteps then
				sm.gui.setInteractionText("", keyBindingText, "#{INTERACTION_EAT} (" .. self.cl.revivalChewCount ..
					"/10)")
			else
				sm.gui.setInteractionText("", keyBindingText, "#{INTERACTION_REVIVE}")
			end
		else
			sm.gui.setInteractionText("", keyBindingText, "#{INTERACTION_RESPAWN}")
		end
	end

	if character then
		self.cl.underwaterEffect:setPosition(character.worldPosition)
	end
end

function SurvivalPlayer.client_onInteract(self, character, state)
	if state == true then
		if self.cl.tutorialGui and self.cl.tutorialGui:isActive() then
			self.cl.tutorialGui:close()
		end

		if not self.cl.isConscious then
			if self.cl.hasRevivalItem then
				if self.cl.revivalChewCount >= BaguetteSteps then
					self.network:sendToServer("sv_n_revive")
				end
				self.cl.revivalChewCount = self.cl.revivalChewCount + 1
				self.network:sendToServer("sv_onEvent", { type = "character", data = "chew" })
			else
				self.network:sendToServer("sv_n_tryRespawn")
			end
		end
	end
end

function SurvivalPlayer.server_onFixedUpdate(self, dt)
	BasePlayer.server_onFixedUpdate(self, dt)

	if g_survivalDev and not self.sv.saved.isConscious and not self.sv.saved.hasRevivalItem then
		if sm.container.canSpend(self.player:getInventory(), obj_consumable_longsandwich, 1) then
			if sm.container.beginTransaction() then
				sm.container.spend(self.player:getInventory(), obj_consumable_longsandwich, 1, true)
				if sm.container.endTransaction() then
					self.sv.saved.hasRevivalItem = true
					self.player:sendCharacterEvent("baguette")
					self.network:setClientData(self.sv.saved)
				end
			end
		end
	end

	-- Delays the respawn so clients have time to fade to black
	if self.sv.respawnDelayTimer then
		self.sv.respawnDelayTimer:tick()
		if self.sv.respawnDelayTimer:done() then
			self:sv_e_respawn()
			self.sv.respawnDelayTimer = nil
		end
	end

	-- End of respawn sequence
	if self.sv.respawnEndTimer then
		self.sv.respawnEndTimer:tick()
		if self.sv.respawnEndTimer:done() then
			self.network:sendToClient(self.player, "cl_n_endFadeToBlack", { duration = RespawnEndFadeDuration })
			self.sv.respawnEndTimer = nil;
		end
	end

	-- If respawn failed, restore the character
	if self.sv.respawnTimeoutTimer then
		self.sv.respawnTimeoutTimer:tick()
		if self.sv.respawnTimeoutTimer:done() then
			self:sv_e_onSpawnCharacter()
		end
	end

	local character = self.player:getCharacter()
	-- Update breathing
	if character then
		if character:isDiving() then
			self.sv.saved.stats.breath = math.max(self.sv.saved.stats.breath - BreathLostPerTick, 0)
			if self.sv.saved.stats.breath == 0 then
				self.sv.drownTimer:tick()
				if self.sv.drownTimer:done() then
					if self.sv.saved.isConscious then
						print("'SurvivalPlayer' is drowning!")
						self:sv_takeDamage(DrownDamage, "drown")
					end
					self.sv.drownTimer:start(DrownDamageCooldown)
				end
			end
		else
			self.sv.saved.stats.breath = self.sv.saved.stats.maxbreath
			self.sv.drownTimer:start(DrownDamageCooldown)
		end

		-- Spend stamina on sprinting
		if character:isSprinting() then
			self.sv.staminaSpend = self.sv.staminaSpend + SprintStaminaCost
		end

		-- Spend stamina on carrying
		if not self.player:getCarry():isEmpty() then
			self.sv.staminaSpend = self.sv.staminaSpend + CarryStaminaCost
		end
	end

	-- Update healing
	if character and self.sv.saved.isConscious and not g_godMode then
		self.sv.statsTimer:tick()
		if self.sv.statsTimer:done() then
			self.sv.statsTimer:start(StatsTickRate)

			self.sv.saved.stats.hp = math.min(self.sv.saved.stats.hp + HpRecovery, self.sv.saved.stats.maxhp)

			self.storage:save(self.sv.saved)
			self.network:setClientData(self.sv.saved)

			print("Saved 'self.sv.saved' (player) (healing): ")
			print(self.sv.saved)
		end
	end

	-- Crap items
	self:sv_crapItems(self.player:getInventory())
end

function SurvivalPlayer.server_onInventoryChanges(self, container, changes)
	self:sv_crapItems(container)
	self.network:sendToClient(self.player, "cl_n_onInventoryChanges", { container = container, changes = changes })
end

function SurvivalPlayer:sv_crapItems(container)
	if not sm.game.getLimitedInventory() then
		return
	end

	for i = 10, container:getSize() - 1, 1 do
		local item = container:getItem(i)
			
		if item.quantity > 0 then
			sm.container.beginTransaction()

			if item.uuid == tool_lift or item.uuid == tool_sledgehammer then
				print("WE HATE CRAP MECHANIC, moving essential item back to hotbar")
				-- move to the first empty slot. if there isnt then i dont like the player so ill fukcing drop it how about htat haha get fucked nerd
				for j = 0, 9, 1 do
					local hotbarSlot = container:getItem(j)

					if hotbarSlot.quantity == 0 then
						container:setItem(i, sm.uuid.getNil(), 0, -1)
						container:setItem(j, item.uuid, item.quantity, item.instance)
						
						goto balls -- I hate this stupid idiot coding language it is a rediculous fake language for primitive minds
					end
				end
				::balls::
			else
				print("Crapping items...")
	
				local params = { lootUid = item.uuid, lootQuantity = item.quantity or 1, epic = false }
				local character = self.player:getCharacter()
				local worldPosition = character.worldPosition
				local vel = sm.vec3.new(0, 0, 1) + character.direction * 3
				sm.projectile.customProjectileAttack( params, projectile_loot, 0, worldPosition, vel, self.player, worldPosition, worldPosition, 0 )
				container:setItem(i, sm.uuid.getNil(), 0, -1)
				
			end

			sm.container.endTransaction()
		end
	end
end

function SurvivalPlayer.sv_e_staminaSpend(self, stamina)
	if not g_godMode then
		if stamina > 0 then
			self.sv.staminaSpend = self.sv.staminaSpend + stamina
		end
	end
end

function SurvivalPlayer.sv_takeDamage(self, damage, source)
	if damage > 0 then
		damage = damage * GetDifficultySettings().playerTakeDamageMultiplier
		local character = self.player:getCharacter()
		local lockingInteractable = character:getLockingInteractable()
		if lockingInteractable and lockingInteractable:hasSeat() then
			lockingInteractable:setSeatCharacter(character)
		end

		if not g_godMode and self.sv.damageCooldown:done() then
			if self.sv.saved.isConscious then
				self.sv.saved.stats.hp = math.max(self.sv.saved.stats.hp - damage, 0)

				print("'SurvivalPlayer' took:", damage, "damage.", self.sv.saved.stats.hp, "/", self.sv.saved.stats
					.maxhp, "HP")

				if source then
					self.network:sendToClients("cl_n_onEvent",
						{ event = source, pos = character:getWorldPosition(), damage = damage * 0.01 })
				else
					self.player:sendCharacterEvent("hit")
				end

				if self.sv.saved.stats.hp <= 0 then
					print("'SurvivalPlayer' knocked out!")
					self.sv.respawnInteractionAttempted = false
					self.sv.saved.isConscious = false
					character:setTumbling(true)
					character:setDowned(true)
				end

				self.storage:save(self.sv.saved)
				self.network:setClientData(self.sv.saved)

				print("Saved 'self.sv.saved' (player) (take damage): ")
				print(self.sv.saved)
			end
		else
			print("'SurvivalPlayer' resisted", damage, "damage")
		end
	end
end

function SurvivalPlayer.sv_n_revive(self)
	local character = self.player:getCharacter()
	if not self.sv.saved.isConscious and self.sv.saved.hasRevivalItem and not self.sv.spawnparams.respawn then
		print("SurvivalPlayer", self.player.id, "revived")
		self.sv.saved.stats.hp = self.sv.saved.stats.maxhp
		self.sv.saved.isConscious = true
		self.sv.saved.hasRevivalItem = false
		self.storage:save(self.sv.saved)
		self.network:setClientData(self.sv.saved)
		self.network:sendToClient(self.player, "cl_n_onEffect",
			{ name = "Eat - EatFinish", host = self.player.character })
		if character then
			character:setTumbling(false)
			character:setDowned(false)
		end
		self.sv.damageCooldown:start(40)
		self.player:sendCharacterEvent("revive")

		print("Saved 'self.sv.saved' (player) (revive): ")
		print(self.sv.saved)
	end
end

function SurvivalPlayer.sv_e_respawn(self)
	print("SurvivalPlayer.sv_e_respawn")
	if self.sv.spawnparams.respawn then
		if not self.sv.respawnTimeoutTimer then
			self.sv.respawnTimeoutTimer = Timer()
			self.sv.respawnTimeoutTimer:start(RespawnTimeout)
		end
		return
	end
	if not self.sv.saved.isConscious then
		g_respawnManager:sv_performItemLoss(self.player)
		self.sv.spawnparams.respawn = true

		sm.event.sendToGame("sv_e_respawn", { player = self.player })
	else
		print("SurvivalPlayer must be unconscious to respawn")
	end
end

function SurvivalPlayer.sv_n_tryRespawn(self)
	if not self.sv.saved.isConscious and not self.sv.respawnDelayTimer and not self.sv.respawnInteractionAttempted then
		self.sv.respawnInteractionAttempted = true
		self.sv.respawnEndTimer = nil;
		self.network:sendToClient(self.player, "cl_n_startFadeToBlack",
			{ duration = RespawnFadeDuration, timeout = RespawnFadeTimeout })

		self.sv.respawnDelayTimer = Timer()
		self.sv.respawnDelayTimer:start(RespawnDelay)
	end
end

function SurvivalPlayer.sv_e_onSpawnCharacter(self)
	print("SurvivalPlayer.sv_e_onSpawnCharacter")
	if not self.sv.saved.isNewPlayer and self.sv.spawnparams.respawn then
		local playerBed = g_respawnManager:sv_getPlayerBed(self.player)
		if playerBed and playerBed.shape and sm.exists(playerBed.shape) and playerBed.shape.body:getWorld() == self.player.character:getWorld() then
			-- Attempt to seat the respawned character in a bed
			self.network:sendToClient(self.player, "cl_seatCharacter", { shape = playerBed.shape })
		end

		self.sv.respawnEndTimer = Timer()
		self.sv.respawnEndTimer:start(RespawnEndDelay)
	end

	if self.sv.saved.isNewPlayer or self.sv.spawnparams.respawn then
		print("SurvivalPlayer", self.player.id, "spawned")
		if self.sv.saved.isNewPlayer then
			self.sv.saved.stats.hp = self.sv.saved.stats.maxhp
		else
			self.sv.saved.stats.hp = 30
		end
		self.sv.saved.isConscious = true
		self.sv.saved.hasRevivalItem = false
		self.sv.saved.isNewPlayer = false
		self.storage:save(self.sv.saved)
		self.network:setClientData(self.sv.saved)

		print("Saved 'self.sv.saved' (player) (respawn): ")
		print(self.sv.saved)

		self.player.character:setTumbling(false)
		self.player.character:setDowned(false)
		self.sv.damageCooldown:start(40)

	else
		-- SurvivalPlayer rejoined the game
		if self.sv.saved.stats.hp <= 0 or not self.sv.saved.isConscious then
			self.player.character:setTumbling(true)
			self.player.character:setDowned(true)
		end
	end

	self.sv.respawnInteractionAttempted = false
	self.sv.respawnDelayTimer = nil
	self.sv.respawnTimeoutTimer = nil
	self.sv.spawnparams = {}

	sm.event.sendToGame("sv_e_onSpawnPlayerCharacter", self.player)
end

function SurvivalPlayer.cl_n_onInventoryChanges(self, params)
	if params.container == sm.localPlayer.getInventory() then
		
		for i, item in ipairs(params.changes) do
			if item.difference > 0 then
				g_survivalHud:addToPickupDisplay(item.uuid, item.difference)
			end
		end
	end
end

function SurvivalPlayer.cl_seatCharacter(self, params)
	sm.projectile.playerFire(sm.uuid.new("45209992-1a59-479e-a446-57140b605836"), sm.vec3.new(0, 0, 0),
		sm.vec3.new(0, 1, 0))
	if sm.exists(params.shape) then
		params.shape.interactable:setSeatCharacter(self.player.character)
	end
end

function SurvivalPlayer.sv_e_debug(self, params)
	if params.hp then
		self.sv.saved.stats.hp = params.hp
	end
	self.storage:save(self.sv.saved)
	self.network:setClientData(self.sv.saved)

	print("Saved 'self.sv.saved' (player) (debug): ")
	print(self.sv.saved)
end

function SurvivalPlayer.sv_e_eat(self, edibleParams)
	if edibleParams.hpGain then
		self:sv_restoreHealth(edibleParams.hpGain)
		self.network:sendToClient(self.player, "cl_n_onEffect",
			{ name = "Eat - EatFinish", host = self.player.character })
		self.network:sendToClient(self.player, "cl_n_onEffect",
			{ name = "Eat - DrinkFinish", host = self.player.character })
	end
	self.storage:save(self.sv.saved)
	self.network:setClientData(self.sv.saved)

	print("Saved 'self.sv.saved' (player) (eated food): ")
	print(self.sv.saved)
end

function SurvivalPlayer.sv_e_feed(self, params)
	if not self.sv.saved.isConscious and not self.sv.saved.hasRevivalItem then
		if sm.container.beginTransaction() then
			sm.container.spend(params.playerInventory, params.foodUuid, 1, true)
			if sm.container.endTransaction() then
				self.sv.saved.hasRevivalItem = true
				self.player:sendCharacterEvent("baguette")
				self.network:setClientData(self.sv.saved)
			end
		end
	end
end

function SurvivalPlayer.sv_restoreHealth(self, health)
	if self.sv.saved.isConscious then
		self.sv.saved.stats.hp = self.sv.saved.stats.hp + health
		self.sv.saved.stats.hp = math.min(self.sv.saved.stats.hp, self.sv.saved.stats.maxhp)
		print("'SurvivalPlayer' restored:", health, "health.", self.sv.saved.stats.hp, "/", self.sv.saved.stats.maxhp,
			"HP")
	end
end

function SurvivalPlayer.sv_restoreFood(self, food)
	print("Something tried to update this players food. what a BOZO")
end

function SurvivalPlayer.sv_restoreWater(self, water)
	print("Something tried to update this players water. what a BOZO")
end

function SurvivalPlayer.server_onShapeRemoved(self, removedShapes)
	local numParts = 0
	local numBlocks = 0
	local numJoints = 0

	for _, removedShapeType in ipairs(removedShapes) do
		if removedShapeType.type == "block" then
			numBlocks = numBlocks + removedShapeType.amount
		elseif removedShapeType.type == "part" then
			numParts = numParts + removedShapeType.amount
		elseif removedShapeType.type == "joint" then
			numJoints = numJoints + removedShapeType.amount
		end
	end
end

-- Camera
function SurvivalPlayer.cl_updateCamera(self, dt)
	if self.cl.cutsceneEffect then
		local cutscenePos = self.cl.cutsceneEffect:getCameraPosition()
		local cutsceneRotation = self.cl.cutsceneEffect:getCameraRotation()
		local cutsceneFOV = self.cl.cutsceneEffect:getCameraFov()
		if cutscenePos == nil then cutscenePos = sm.camera.getPosition() end
		if cutsceneRotation == nil then cutsceneRotation = sm.camera.getRotation() end
		if cutsceneFOV == nil then cutsceneFOV = sm.camera.getFov() end

		if self.cl.cutsceneEffect:isPlaying() then
			self.cl.followCutscene = math.min(self.cl.followCutscene + dt / CUTSCENE_FADE_IN_TIME, 1.0)
		else
			self.cl.followCutscene = math.max(self.cl.followCutscene - dt / CUTSCENE_FADE_OUT_TIME, 0.0)
		end

		local lerpedCameraPosition = sm.vec3.lerp(sm.camera.getDefaultPosition(), cutscenePos, self.cl.followCutscene)
		local lerpedCameraRotation = sm.quat.slerp(sm.camera.getDefaultRotation(), cutsceneRotation,
			self.cl.followCutscene)
		local lerpedCameraFOV = lerp(sm.camera.getDefaultFov(), cutsceneFOV, self.cl.followCutscene)
		print(self.cl.followCutscene)
		sm.camera.setPosition(lerpedCameraPosition)
		sm.camera.setRotation(lerpedCameraRotation)
		sm.camera.setFov(lerpedCameraFOV)

		if self.cl.followCutscene <= 0.0 and not self.cl.cutsceneEffect:isPlaying() then
			sm.gui.hideGui(false)
			sm.camera.setCameraState(sm.camera.state.default)
			self.cl.cutsceneEffect:destroy()
			self.cl.cutsceneEffect = nil
		end
	else
		self.cl.followCutscene = 0.0
	end
end

function SurvivalPlayer.cl_startCutscene(self, params)
	self.cl.cutsceneEffect = sm.effect.createEffect(params.effectName)
	if params.worldPosition then
		self.cl.cutsceneEffect:setPosition(params.worldPosition)
	end
	if params.worldRotation then
		self.cl.cutsceneEffect:setRotation(params.worldRotation)
	end
	self.cl.cutsceneEffect:start()
	sm.gui.hideGui(true)
	sm.camera.setCameraState(sm.camera.state.cutsceneTP)
end

function SurvivalPlayer.sv_e_startCutscene(self, params)
	self.network:sendToClient(self.player, "cl_startCutscene", params)
end

function SurvivalPlayer.client_onCancel(self)
	BasePlayer.client_onCancel(self)
	g_effectManager:cl_cancelAllCinematics()
end
