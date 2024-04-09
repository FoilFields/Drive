dofile( "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_constants.lua" )

ElevatorEnd = class()

function ElevatorEnd.client_onCreate( self )
	self.cl = {}
end

function ElevatorEnd.server_onCreate( self )
	local portal = sm.portal.createPortal(sm.vec3.new(64, 64, 64))
	portal:setOpeningA(self.shape.worldPosition, self.shape.worldRotation)

	g_portalManager:sv_remove()
	g_portalManager:sv_setPortal(portal)
	print("Portal recreated")
end

function ElevatorEnd.server_onDestroy( self )
	
end

function ElevatorEnd.server_onRefresh( self )
	print( "Refresh Portal")
end
