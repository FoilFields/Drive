dofile("$SURVIVAL_DATA/Scripts/game/survival_constants.lua")
dofile("$SURVIVAL_DATA/Scripts/game/survival_units.lua")
dofile("$SURVIVAL_DATA/Scripts/util.lua")

FireManager = class( nil )

--Server to client
NETWORK_MSG_ADD_FIRE = 10000
NETWORK_MSG_REMOVE_FIRE = 10001
NETWORK_MSG_REMOVE_FIRE_CELL = 10002
NETWORK_MSG_UPDATE_FIRE_HEALTH = 10003
NETWORK_MSG_UPDATE_FIRE_EFFECT = 10004
--Client to server
NETWORK_MSG_REQUEST_FIRE = 10005

FIRE_SIZE = {
	sm.vec3.new( 0.4, 0.4, 0.4 ),
	sm.vec3.new( 0.7, 0.7, 1.7 ),
	sm.vec3.new( 1.75, 1.75, 3.5 )
}

burningShapes = {} --key = shape id, value = {cellkey, fireId, isLoaded, lifeTime}
isFlamable = {}
Durability = {}
Density = {}

invicibleShapes = {}

-- Server side
function FireManager.sv_onCreate( self, sender )
	self.sv = {}
	self.sv.sender = sender
	self.sv.fireCells = {}
	self.sv.triggerCells = {}
	self.sv.conIdCells = {}
	self.sv.world = sender.world

	local shapeSetPaths = sm.json.open("$SURVIVAL_DATA/Objects/Database/shapesets.json")["shapeSetList"]

	for i = 1, #shapeSetPaths, 1 do
		local shapeSet = sm.json.open(shapeSetPaths[i])
		for _, shapes in pairs(shapeSet) do
			for j = 1, #shapes, 1 do
				isFlamable[shapes[j]["uuid"]] = shapes[j]["flammable"]
				if shapes[j]["ratings"] then
					Durability[shapes[j]["uuid"]] = shapes[j]["ratings"]["durability"]
					Density[shapes[j]["uuid"]] = shapes[j]["ratings"]["density"]
				end
			end
		end
	end

	self.sv.fireCells[1] = {}
	self.sv.triggerCells[1] = {}

	local fireCell = sm.storage.load( { STORAGE_CHANNEL_FIRE, self.sv.world.id, 1} )
	if fireCell ~= nil then
		for fireId, fireObj in pairs(fireCell) do
			burningShapes[fireObj.shape:getId()] = {1, fireId, false, 100000000000000000000000000}
			local shape = fireObj.shape

			local fireObj = {
				hitCooldowns = {},
				hp = 1,
				startHp = 1,
				position = fireObj.position,
				rotation = sm.quat.identity,
				scale = sm.vec3.new(0, 0, 0),
				effect = "",
				connections = nil,
				shape = fireObj.shape,
				isDynamic = true
			}

			self.sv.fireCells[1][fireId] = fireObj
		end
	end
end

function FireManager.sv_handleMsg( self, msg )
	if msg.type == NETWORK_MSG_REQUEST_FIRE then
		self:sv_loadCellForClient( msg.cellKey )
		return true
	end
	return false
end

function FireManager.sv_onFixedUpdate( self )
	invicibleShapes = {}

	--load dynamic fires
	for shapeId, value in pairs(burningShapes) do
		if value[3] == false then
			local fireCell = self.sv.fireCells[1]
			local fireObj = fireCell[value[2]]
			local shape = fireObj.shape

			if shape ~= nil and sm.exists(shape) then
				self:sv_loadDynamicFire( value[2] )
			end
		end
	end

	--move dynamic fires
	for k, v in pairs(burningShapes) do
		v[4] = v[4] - 1
		if v[3] then
			local cellKey = v[1]
			local fireId = v[2]
			local fireObj = self.sv.fireCells[cellKey][fireId]
			local trigger = self.sv.triggerCells[cellKey][fireId]
			local shape = fireObj.shape
			
			if shape == nil or (not sm.exists(shape)) then
				self:sv_removeFire( cellKey, fireId, {} )
			elseif shapePos ~= fireObj.position then
				local shapePos = shape:getWorldPosition()
				--move the fire
				fireObj.position = shapePos
				trigger:setWorldPosition(shapePos)
				
				sm.storage.save( { STORAGE_CHANNEL_FIRE, self.sv.world.id, cellKey }, self.sv.fireCells[cellKey] )
				self.sv.sender.network:sendToClients( "cl_n_fireMsg", { type = NETWORK_MSG_UPDATE_FIRE_EFFECT, cellKey = cellKey, fireId = fireId, position = shapePos } )
			end

			if v[4] < 0 then
				shape:destroyShape()
				self:sv_removeFire( 1, v[2], {} )
				burningShapes[k] = nil
			end
		end
	end

	for _, fireObjs in pairs( self.sv.fireCells ) do
		for _, fireObj in pairs( fireObjs ) do
			local updatedHitCooldowns = {}
			for _, hitCooldown in pairs( fireObj.hitCooldowns ) do
				hitCooldown.ticks = hitCooldown.ticks - 1
				if hitCooldown.ticks > 0 then
					updatedHitCooldowns[#updatedHitCooldowns+1] = hitCooldown
				end
			end
			fireObj.hitCooldowns = updatedHitCooldowns
		end
	end
end

function FireManager.sv_onCellLoaded( self, x, y )
	local cellKey = CellKey(x, y)
	local nodes = sm.cell.getNodesByTags( x, y, { "FIRE", "EFFECT" } )
	if #nodes > 0 then

		self.sv.fireCells[cellKey] = {}
		self.sv.triggerCells[cellKey] = {}
		self.sv.conIdCells[cellKey] = {}

		for idx, node in ipairs( nodes ) do
			local health = 1
			local scale = node.scale
			if node.params.effect and node.params.effect.params then
				for k,v in kvpairs( node.params.effect.params ) do
					if k == "health" then
						health = v
						scale = FIRE_SIZE[health]
					end
				end
			end
			self:sv_addFire( cellKey, idx, node.position, node.rotation, scale, node.params.effect.name, node.params.connections, health )
		end
	end
end

function FireManager.sv_onCellUnloaded( self, x, y )
	local cellKey = CellKey(x, y)

	for k, v in pairs(burningShapes) do
		if v[3] then
			local fireObj = self.sv.fireCells[v[1]][v[2]]
			if fireObj ~= nil then
				local pos = fireObj.position
				local X, Y = getCell(pos.x, pos.y)
	
				if X == x and Y == y then
					burningShapes[k][3] = false

					self.sv.sender.network:sendToClients( "cl_n_fireMsg", { type = NETWORK_MSG_REMOVE_FIRE, cellKey = 1, fireId = v[2] } )
				end
			end
		end
	end

	if self.sv.fireCells[cellKey] ~= nil then

		for fireId, areaTrigger in ipairs( self.sv.triggerCells[cellKey] ) do
			if areaTrigger and sm.exists( areaTrigger ) then
				sm.areaTrigger.destroy( areaTrigger )
			end
		end

		self.sv.fireCells[cellKey] = {}
		self.sv.triggerCells[cellKey] = {}
		self.sv.conIdCells[cellKey] = {}

		self.sv.sender.network:sendToClients( "cl_n_fireMsg", { type = NETWORK_MSG_REMOVE_FIRE_CELL, cellKey = cellKey } )
	end
end

function FireManager.sv_onCellReloaded( self, x, y )
	--print("--- reloading fire objs on cell " .. x .. ":" .. y .. " ---")
	local cellKey = CellKey(x, y)

	local fireCell = sm.storage.load( { STORAGE_CHANNEL_FIRE, self.sv.world.id, cellKey } )
	if fireCell ~= nil then
		self.sv.fireCells[cellKey] = {}
		self.sv.triggerCells[cellKey] = {}
		self.sv.conIdCells[cellKey] = {}
		for fireId, fireObj in pairs( fireCell ) do
			self:sv_addFire( cellKey, fireId, fireObj.position, fireObj.rotation, fireObj.scale, fireObj.effect, fireObj.connections, fireObj.hp )
		end
	end
end

function FireManager.sv_loadCellForClient( self, cellKey )
	self.sv.sender.network:sendToClients( "cl_n_fireMsg", { type = NETWORK_MSG_REMOVE_FIRE_CELL, cellKey = cellKey } )
	local fireCell = sm.storage.load( { STORAGE_CHANNEL_FIRE, self.sv.world.id, cellKey } )
	if fireCell ~= nil then
		for fireId, fireObj in pairs( fireCell ) do
			self.sv.sender.network:sendToClients( "cl_n_fireMsg", { type = NETWORK_MSG_ADD_FIRE, cellKey = cellKey, fireId = fireId, position = fireObj.position, rotation = fireObj.rotation, effect = fireObj.effect, health = fireObj.hp } )
		end
	end
end

function FireManager.sv_loadDynamicFire( self, fireId )

	local fireCell = self.sv.fireCells[1]
	local fireObj = fireCell[fireId]
	local shape = fireObj.shape
	burningShapes[shape:getId()][3] = true

	if (burningShapes[shape:getId()][4] > 40000) then
		local lifeTime = Density[tostring(shape:getShapeUuid())] * Durability[tostring(shape:getShapeUuid())] * 420
		burningShapes[shape:getId()][4] = lifeTime
	end
	
	--get correct sized effect
	local effect = ""
	local box = shape:getBoundingBox()
	local effectSize = sm.vec3.new(1, 1, 1)

	if box:length() > 3 then
		effect = "Fire - large01"
		effectSize = sm.vec3.new(6, 6, 6)
	elseif box:length() > 0.65 then
		effect = "Fire -medium01"
		effectSize = sm.vec3.new(1.5, 1.5, 1.5)
	else
		effect = "Fire - small01"
		effectSize = sm.vec3.new(0.6, 0.6, 2)
	end

	local areaTrigger = sm.areaTrigger.createBox( effectSize * 0.5, shape:getWorldPosition(), sm.quat.identity(), sm.areaTrigger.filter.all, { cellKey = cellKey, fireId = fireId } )
	areaTrigger:bindOnEnter( "trigger_onEnterFire", self )
	areaTrigger:bindOnStay( "trigger_onStayFire", self )
	areaTrigger:bindOnProjectile( "trigger_onProjectile", self )
	self.sv.triggerCells[1][fireId] = areaTrigger


	--prepare lists
	if self.sv.fireCells[1] == nil then
		self.sv.fireCells[1] = {}
	end

	if self.sv.triggerCells[1] == nil then
		self.sv.triggerCells[1] = {}
	end

	self.sv.sender.network:sendToClients( "cl_n_fireMsg", { type = NETWORK_MSG_ADD_FIRE, cellKey = 1, fireId = fireId, position = shape:getWorldPosition(), rotation = sm.quat.identity(), effect = effect, health = 1 } )
end

function FireManager.sv_addDynamicFire( self, shape )
	
	--check if shape is valid
	if shape == nil then
		return
	end

	if not sm.exists(shape) then
		return
	end

	--prepare lists
	if self.sv.fireCells[1] == nil then
		self.sv.fireCells[1] = {}
	end

	if self.sv.triggerCells[1] == nil then
		self.sv.triggerCells[1] = {}
	end
	
	--get correct sized effect
	local effect = ""
	local box = shape:getBoundingBox()
	local effectSize = sm.vec3.new(1, 1, 1)

	if box:length() > 3 then
		effect = "Fire - large01"
		effectSize = sm.vec3.new(6, 6, 6)
	elseif box:length() > 0.65 then
		effect = "Fire -medium01"
		effectSize = sm.vec3.new(1.5, 1.5, 1.5)
	else
		effect = "Fire - small01"
		effectSize = sm.vec3.new(0.6, 0.6, 2)
	end

	local fireId = 0

	for k, _ in pairs(self.sv.fireCells[1]) do
		if k > fireId then
			fireId = k
		end
	end

	--link shape to fire
	burningShapes[shape:getId()] = {1, fireId + 1, true, Density[tostring(shape:getShapeUuid())] * Durability[tostring(shape:getShapeUuid())] * 420}

	--add fire
	FireManager.sv_addFire( self, 1, fireId + 1, shape:getWorldPosition(), sm.quat.identity(), effectSize, effect, nil, 1, shape, true)
end

function FireManager.sv_addFire( self, cellKey, fireId, position, rotation, scale, effect, connections, health, shape, isDynamic )

	local fireObj = {
		hitCooldowns = {},
		hp = health,
		startHp = health,
		position = position,
		rotation = rotation,
		scale = scale,
		effect = effect,
		connections = connections,
		shape = shape or nil,
		isDynamic = isDynamic or false
	}
	self.sv.fireCells[cellKey][fireId] = fireObj

	-- Optional: map connection ids to fire ids
	if connections ~= nil then
		self.sv.conIdCells[cellKey][connections.id] = fireId
	end

	local areaTrigger = sm.areaTrigger.createBox( scale * 0.5, position, rotation, sm.areaTrigger.filter.all, { cellKey = cellKey, fireId = fireId } )
	areaTrigger:bindOnEnter( "trigger_onEnterFire", self )
	areaTrigger:bindOnStay( "trigger_onStayFire", self )
	areaTrigger:bindOnProjectile( "trigger_onProjectile", self )
	self.sv.triggerCells[cellKey][fireId] = areaTrigger

	self.sv.sender.network:sendToClients( "cl_n_fireMsg", { type = NETWORK_MSG_ADD_FIRE, cellKey = cellKey, fireId = fireId, position = position, rotation = rotation, effect = effect, health = health } )
	if cellkey ~= 1 then
		sm.storage.save( { STORAGE_CHANNEL_FIRE, self.sv.world.id, cellKey }, self.sv.fireCells[cellKey] )
	end
end

function FireManager.sv_removeFire( self, cellKey, fireId, removedFires )
	local fireObj = self.sv.fireCells[cellKey][fireId]
	if fireObj ~= nil then
		removedFires[fireId] = true

		if fireObj.isDynamic then
			burningShapes[fireObj.shape:getId()] = nil
		end

		if fireObj.connections ~= nil then
			for _,conId in ipairs( fireObj.connections.otherIds ) do
				local otherFireId = self.sv.conIdCells[cellKey][conId]
				if not removedFires[otherFireId] then
					self:sv_removeFire( cellKey, otherFireId, removedFires )
				end
			end
		end

		self.sv.fireCells[cellKey][fireId] = nil

		sm.areaTrigger.destroy(self.sv.triggerCells[cellKey][fireId])
		self.sv.triggerCells[cellKey][fireId] = nil

		self.sv.sender.network:sendToClients( "cl_n_fireMsg", { type = NETWORK_MSG_REMOVE_FIRE, cellKey = cellKey, fireId = fireId } )
		sm.storage.save( { STORAGE_CHANNEL_FIRE, self.sv.world.id, cellKey }, self.sv.fireCells[cellKey] )
	end
end

function FireManager.trigger_onEnterFire( self, trigger, results )
	for _,result in ipairs( results ) do
		if sm.exists( result ) then
			if type( result ) == "Character" then
				local characterType = result:getCharacterType()
				if characterType == unit_mechanic or characterType == unit_woc or characterType == unit_worm  then
					local diff = (result:getWorldPosition() - trigger:getWorldPosition()):normalize()
					diff.z = 0
					sm.physics.applyImpulse( result, diff * 500, true )
					if result:isPlayer() then
						sm.event.sendToPlayer( result:getPlayer(), "sv_e_onEnterFire" )
					end
				end
			end
		end
	end
end

function FireManager.trigger_onStayFire( self, trigger, results )
	for _,result in ipairs( results ) do
		if sm.exists( result ) then
			if type( result ) == "Character" then
				if result:isPlayer() then
					sm.event.sendToPlayer( result:getPlayer(), "sv_e_onStayFire" )
				end
			elseif type( result ) == "Body" and math.random( 20 ) < 2 and sm.game.getCurrentTick() % 10 == 1 then
				local shapes = result:getShapes()
				local trigerPos = trigger:getWorldPosition()
				local trigerMin = trigger:getWorldMin()
				local trigerMax = trigger:getWorldMax()

				for i = 1, #shapes, 1 do --search for flamable shapes that are inside of the fire
					if invicibleShapes[shapes[i]:getId()] == nil then
						local shape = shapes[i]
						invicibleShapes[shape:getId()] = true
						local shapePos = shape:getWorldPosition()
						if isFlamable[tostring(shape:getShapeUuid())] and burningShapes[shape:getId()] == nil then --check if shape is flammable, also check if it isnt already on fire
							if (shapePos - trigerPos):length() < trigger:getSize():length() then --check if shape is close to fire (for perfomance reasons)
								local shapeBox = shape:getBoundingBox()
								local shapeMin = shapePos - (shapeBox / 2)
								local shapeMax = shapePos + (shapeBox / 2)
								if shapeMin < trigerMax and shapeMax > trigerMin then --check if shape is in triger bounding box
									--flamable shapes that shhould catch fire will get here
									FireManager.sv_addDynamicFire( self, shape )
								end
							end
						end
					end
				end
			end
		end
	end
end

function FireManager.trigger_onProjectile( self, trigger, hitPos, hitTime, hitVelocity, projectileName, shooter )
	if ( projectileName == "water" or g_survivalDev ) and sm.exists(trigger) then
		local ud = trigger:getUserData()
		local fireObj = self.sv.fireCells[ud.cellKey][ud.fireId]
		if fireObj ~= nil then

			for _, hitCooldown in ipairs( fireObj.hitCooldowns ) do
				if hitCooldown.shooter == shooter then
					-- Ignore projectile hit during hit cooldown
					return
				end
			end
			if shooter and sm.exists( shooter ) then
				fireObj.hitCooldowns[#fireObj.hitCooldowns+1] = { shooter = shooter, ticks = 20 }
			end

			self:sv_updateHealth( ud.cellKey, ud.fireId, fireObj.hp - 1 )
			sm.effect.playEffect( "Steam - quench", hitPos )
			return true
		end
	end
	return false
end

function FireManager.sv_updateHealth( self, cellKey, fireId, health )
	local fireObj = self.sv.fireCells[cellKey][fireId]
	if fireObj ~= nil then
		fireObj.hp = health
		if fireObj.hp <= 0 then
			self:sv_removeFire( cellKey, fireId, {} )
		else
			self.sv.sender.network:sendToClients( "cl_n_fireMsg", {
				type = NETWORK_MSG_UPDATE_FIRE_HEALTH,
				cellKey = cellKey,
				fireId = fireId,
				health = fireObj.hp,
				healthFraction = fireObj.hp / fireObj.startHp
			} )
			fireObj.scale = FIRE_SIZE[health]
			self.sv.triggerCells[cellKey][fireId]:setSize( fireObj.scale )
			sm.storage.save( { STORAGE_CHANNEL_FIRE, self.sv.world.id, cellKey }, self.sv.fireCells[cellKey] )
		end
	end
end

-- Client side
function FireManager.cl_onCreate( self, sender )
	self.cl = {}
	self.cl.sender = sender
	self.cl.fireCells = {}
end

function FireManager.cl_onCellLoaded( self, x, y )
	self.cl.sender.network:sendToServer( "sv_n_fireMsg", { type = NETWORK_MSG_REQUEST_FIRE, cellKey = CellKey( x, y ) } )
end

function FireManager.cl_handleMsg( self, msg )
	if msg.type == NETWORK_MSG_ADD_FIRE then
		self:cl_addFire( msg.cellKey, msg.fireId, msg.position, msg.rotation, msg.effect, msg.health )
		return true
	elseif msg.type == NETWORK_MSG_REMOVE_FIRE then
		self:cl_removeFire( msg.cellKey, msg.fireId )
		return true
	elseif msg.type == NETWORK_MSG_UPDATE_FIRE_EFFECT then
		self:cl_updateFireEffect( msg.cellKey, msg.fireId, msg.position )
		return true
	elseif msg.type == NETWORK_MSG_REMOVE_FIRE_CELL then
		self:cl_removeFireCell( msg.cellKey )
		return true
	elseif msg.type == NETWORK_MSG_UPDATE_FIRE_HEALTH then
		self:cl_updateHealth(  msg.cellKey, msg.fireId, msg.health, msg.healthFraction )
		return true
	end
	return false
end

function FireManager.cl_updateFireEffect( self, cellKey, fireId, position )
	self.cl.fireCells[cellKey][fireId].effect:setPosition(position)
end

function FireManager.cl_addFire( self, cellKey, fireId, position, rotation, effect, health )
	if self.cl.fireCells[cellKey] == nil then
		self.cl.fireCells[cellKey] = {}
	end

	local fireObj = {
		effect = sm.effect.createEffect( effect )
	}
	fireObj.effect:setPosition( position )
	fireObj.effect:setRotation( rotation )
	fireObj.effect:setParameter( "health", health )
	fireObj.effect:start()

	if effect == "Fire -medium01" or effect == "ShipFire - medium01" then
		fireObj.putout = {
			effectName = "Fire -medium01_putout"
		}
	elseif effect == "Fire - large01" or effect == "ShipFire - large01" then
		fireObj.putout = {
			effectName = "Fire - large01_putout"
		}
	end
	if fireObj.putout then
		fireObj.putout.position = position
		fireObj.putout.rotation = rotation
	end

	self.cl.fireCells[cellKey][fireId] = fireObj
end

function FireManager.cl_removeFire( self, cellKey, fireId )
	local fireObj = self.cl.fireCells[cellKey][fireId]
	fireObj.effect:stop()
	if fireObj.putout then
		sm.effect.playEffect( fireObj.putout.effectName, fireObj.putout.position, sm.vec3.zero(), fireObj.putout.rotation )
	end
	self.cl.fireCells[cellKey][fireId] = nil
end

function FireManager.cl_removeFireCell( self, cellKey )
	if self.cl.fireCells[cellKey] ~= nil then
		for fireId, fireObj in ipairs( self.cl.fireCells[cellKey] ) do
			if fireObj.effect and sm.exists( fireObj.effect ) then
				fireObj.effect:stop()
				fireObj.effect:destroy()
			end
		end
	end
	self.cl.fireCells[cellKey] = nil
end

function FireManager.cl_updateHealth( self, cellKey, fireId, health, healthFraction )
	self.cl.fireCells[cellKey][fireId].effect:setParameter( "health", health )
	self.cl.fireCells[cellKey][fireId].effect:setParameter( "fire_intensity", healthFraction )
end
