dofile( "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_constants.lua" )

ElevatorStart = class()

function ElevatorStart.client_onCreate( self )
	self.cl = {}
end

function ElevatorStart.server_onCreate( self )
	self:sv_findPortal()
end

function ElevatorStart.server_onFixedUpdate( self )
	self:sv_findPortal()
end

-- Tries to connect with the portal from the previous world
function ElevatorStart:sv_findPortal()
	local portal = g_portalManager.sv_getPortal()
	if not portal or sm.world.getCurrentWorld() == portal:getWorldA() then -- Ensure this is the destination portal before connecting
		return
	end

	local portal = sm.portal.popWorldPortalHook("PORTAL")
	if portal then
		print( "Found Portal "..portal.id.."!" )
		local position = self.shape.worldPosition
		portal:setOpeningB( position, self.shape.worldRotation )
		g_portalManager:sv_setPortal(portal)
	end
end
