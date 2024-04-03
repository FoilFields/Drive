local function directionToUuid( direction )
	return sm.uuid.generateNamed( sm.uuid.new( "82b89df0-55ce-4aad-bb18-5c1395689332" ), direction )
end

g_fenceTileList = {}

function initMeadowTiles()
  g_fenceTileList[tostring( directionToUuid( "NE" ) )] = "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/Flatterrain_FenceNE.tile"
  g_fenceTileList[tostring( directionToUuid( "NW" ) )] = "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/Flatterrain_FenceNW.tile"
  g_fenceTileList[tostring( directionToUuid( "SE" ) )] = "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/Flatterrain_FenceSE.tile"
  g_fenceTileList[tostring( directionToUuid( "SW" ) )] = "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/Flatterrain_FenceSW.tile"
  g_fenceTileList[tostring( directionToUuid( "N" ) )] = "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/Flatterrain_FenceN_01.tile"
  g_fenceTileList[tostring( directionToUuid( "S" ) )] = "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/Flatterrain_FenceS_01.tile"
  g_fenceTileList[tostring( directionToUuid( "E" ) )] = "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/Flatterrain_FenceE_01.tile"
  g_fenceTileList[tostring( directionToUuid( "W" ) )] = "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/Flatterrain_FenceW_01.tile"
end