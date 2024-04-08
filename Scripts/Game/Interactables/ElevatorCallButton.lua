ElevatorCallButton = class()
ElevatorCallButton.maxParentCount = 0
ElevatorCallButton.maxChildCount = 1
ElevatorCallButton.poseWeightCount = 1
ElevatorCallButton.resetStateOnInteract = false

function ElevatorCallButton.server_onCreate( self )
	self.sv = {}
end

function ElevatorCallButton.sv_push( self )
	self.interactable:setActive( true )

	sm.event.sendToGame("sv_try_progress")

	-- local progress = sm.storage.load("progress") + 1
	-- sm.storage.save("progress", progress)

	-- world:destroy()
	-- world = sm.world.createWorld("$CONTENT_DATA/Scripts/Game/Worlds/Overworld.lua", "Overworld", { dev = g_survivalDev }, self.sv.saved.data.seed)
	
	-- self.storage:save(self.sv.saved)

	-- local params = { pos = character:getWorldPosition(), dir = character:getDirection() }
	-- self.sv.saved.overworld:loadCell(math.floor(params.pos.x / 64), math.floor(params.pos.y / 64), player,
	-- 	"sv_recreatePlayerCharacter", params)

	-- self.network:sendToClients("client_showMessage", "Recreating world")
end

function ElevatorCallButton.client_onCreate( self )
	self.cl = {}
	self.cl.held = false
	self.cl.pressed = false
	self.cl.loopingIndex = 8
end

function ElevatorCallButton.client_onInteract( self, character, state )
	self.network:sendToServer("sv_push")
	self.cl.held = state
end

function ElevatorCallButton.server_onProjectile( self, hitPos, hitTime, hitVelocity, _, attacker, damage, userData, hitNormal, projectileUuid )
	self:sv_push()
end

function ElevatorCallButton.client_onFixedUpdate( self )
	if self.cl.held or self.cl.pressed then
		self.interactable:setPoseWeight( 0, 1.0 ) -- Down
	else
		self.interactable:setPoseWeight( 0, 0.0 ) -- Up
	end
	self.cl.pressed = false
end

function ElevatorCallButton.client_onUpdate( self, dt )
	self.cl.loopingIndex = self.cl.loopingIndex + dt * -30.0

	if self.cl.loopingIndex < 4 then
		self.cl.loopingIndex = 8
	end

	self.interactable:setUvFrameIndex( math.floor( self.cl.loopingIndex ) )
end

function ElevatorCallButton.client_onClientDataUpdate( self, clientData )
	self.cl.loopingIndex = 8
end
