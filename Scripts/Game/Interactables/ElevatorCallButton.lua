ElevatorCallButton = class()
ElevatorCallButton.maxParentCount = 0
ElevatorCallButton.maxChildCount = 1
ElevatorCallButton.poseWeightCount = 1
ElevatorCallButton.resetStateOnInteract = false

function ElevatorCallButton.server_onCreate( self )
	self.sv = {}
end

function ElevatorCallButton.sv_push( self )
	self.interactable:setActive(true)
	
	g_portalManager:sv_loadDestination()
end

function ElevatorCallButton.client_onCreate( self )
	self.cl = {}
	self.cl.held = false
	self.cl.pressed = false
	self.cl.loopingIndex = 8
	self.cl.ambianceEffect = sm.effect.createEffect( "ElevatorAmbiance", self.interactable )
	self.cl.ambianceEffect:start()
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
