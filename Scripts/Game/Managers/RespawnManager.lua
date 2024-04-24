dofile("$SURVIVAL_DATA/Scripts/game/survival_constants.lua")
dofile "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua"

-- Server side
RespawnManager = class( nil )

function RespawnManager.sv_onCreate( self, overworld )
	self.sv = {}

	self.sv.latestSpawnIndex = 1
	self.sv.overworld = overworld
end

function RespawnManager.cl_onCreate( self )
	self.cl = {}
end

-- Game environment
function RespawnManager.sv_onSpawnCharacter( self, player )
end

function RespawnManager.sv_requestRespawnCharacter( self, player )
	local spawnPosition = START_AREA_SPAWN_POINT
	local respawnWorld = self.sv.overworld

	respawnWorld:loadCell( math.floor( spawnPosition.x / 64 ), math.floor( spawnPosition.y / 64 ), player, "sv_loadedRespawnCell" ) -- Callback received by the Game script
end

-- Game environment helper function
function RespawnManager.sv_respawnCharacter( self, player, world )
	print("RespawnManager.sv_respawnCharacter")
	local spawnPosition = START_AREA_SPAWN_POINT
	local spawnRotation = sm.quat.identity()

	spawnPosition = spawnPosition + sm.vec3.new( 0, 0, player.character:getHeight() * 0.5 )
	local yaw = 0
	local pitch = 0
	local spawnDirection = spawnRotation * sm.vec3.new( 0, 0, 1 )
	yaw = math.atan2( spawnDirection.y, spawnDirection.x ) - math.pi/2
	local newCharacter = sm.character.createCharacter( player, world, spawnPosition, yaw, pitch )
	player:setCharacter( newCharacter )
	print("Created character at "..spawnPosition.x..", "..spawnPosition.y..", "..spawnPosition.z)
end
