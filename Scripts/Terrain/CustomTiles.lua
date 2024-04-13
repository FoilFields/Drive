local g_desert = {} --Flags lookup table

local function toDesertIndex( se, sw, nw, ne )
	return bit.bor( bit.lshift( se, 3 ), bit.lshift( sw, 2 ), bit.lshift( nw, 1 ), bit.tobit( ne ) )
end

function initCustomTiles()

  -- Desert tiles
	g_desert = {
		AddTile( 3001501, "$SURVIVAL_DATA/Terrain/Tiles/desert/Desert(1111)_01.tile", 3 ), 
		AddTile( 3001502, "$SURVIVAL_DATA/Terrain/Tiles/desert/Desert(1111)_02.tile", 3 ), 
		AddTile( 3001503, "$SURVIVAL_DATA/Terrain/Tiles/desert/Desert(1111)_03.tile", 3 ), 
		AddTile( 3001504, "$SURVIVAL_DATA/Terrain/Tiles/desert/Desert(1111)_04.tile", 3 ), 
		AddTile( 3001505, "$SURVIVAL_DATA/Terrain/Tiles/desert/Desert(1111)_05.tile", 3 ), 
		AddTile( 3001506, "$SURVIVAL_DATA/Terrain/Tiles/desert/Desert(1111)_06.tile", 3 ),
		AddTile( 3001507, "$CONTENT_DATA/Terrain/Tiles/Desert/desert_01.tile", 3 ),
		AddTile( 3001508, "$CONTENT_DATA/Terrain/Tiles/Desert/desert_02.tile", 3 ),
		AddTile( 3001509, "$CONTENT_DATA/Terrain/Tiles/Desert/desert_03.tile", 3 ),
		AddTile( 3001510, "$CONTENT_DATA/Terrain/Tiles/Desert/desert_04.tile", 3 ),
		AddTile( 3001511, "$CONTENT_DATA/Terrain/Tiles/Desert/desert_05.tile", 3 ),
	}

  -- Just north/south straight road tiles with no cliff data
  g_roads = { 
		tiles = { 
			AddTile( 1128001, "$CONTENT_DATA/Terrain/Tiles/Road/01.tile" ), 
			AddTile( 1128002, "$CONTENT_DATA/Terrain/Tiles/Road/02.tile" ), 
			AddTile( 1128003, "$CONTENT_DATA/Terrain/Tiles/Road/03.tile" ), 
			AddTile( 1128004, "$CONTENT_DATA/Terrain/Tiles/Road/04.tile" ), 
			AddTile( 1128005, "$CONTENT_DATA/Terrain/Tiles/Road/05.tile" ), 
			AddTile( 1128006, "$CONTENT_DATA/Terrain/Tiles/Road/06.tile" ), 
			AddTile( 1128007, "$CONTENT_DATA/Terrain/Tiles/Road/07.tile" ), 
			AddTile( 1128008, "$CONTENT_DATA/Terrain/Tiles/Road/08.tile" ), 
			AddTile( 1128009, "$CONTENT_DATA/Terrain/Tiles/Road/09.tile" ), 
			AddTile( 1128010, "$CONTENT_DATA/Terrain/Tiles/Road/10.tile" ), 
			AddTile( 1128011, "$CONTENT_DATA/Terrain/Tiles/Road/11.tile" ), 
			AddTile( 1128012, "$CONTENT_DATA/Terrain/Tiles/Road/12.tile" ), 
			AddTile( 1128013, "$CONTENT_DATA/Terrain/Tiles/Road/13.tile" ), 
			AddTile( 1128014, "$CONTENT_DATA/Terrain/Tiles/Road/14.tile" ), 
			AddTile( 1128015, "$CONTENT_DATA/Terrain/Tiles/Road/15.tile" ), 
			AddTile( 1128016, "$CONTENT_DATA/Terrain/Tiles/Road/16.tile" ),
		},
		rotation = 3 
	}

  g_road_ends = { 
		AddTile( 1293000, "$CONTENT_DATA/Terrain/Tiles/Road/road_end.tile" ), 
	}

  g_elevators = { 
		AddTile( 9423000, "$CONTENT_DATA/Terrain/Tiles/Elevator/elevator.tile" ), 
	}

  g_fences = {
		AddTile( 5002500, "$CONTENT_DATA/Terrain/Tiles/Fence/fence_01.tile", 5 ),
		AddTile( 5002501, "$CONTENT_DATA/Terrain/Tiles/Fence/fence_02.tile", 5 ),
	}

  g_fence_corners = {
		AddTile( 5002600, "$CONTENT_DATA/Terrain/Tiles/Fence/fence_corner_01.tile", 5 ),
	}

  g_scorched = {
		AddTile( 1232500, "$CONTENT_DATA/Terrain/Tiles/Scorched/scorched_01.tile", 5 ),
		AddTile( 1232501, "$CONTENT_DATA/Terrain/Tiles/Scorched/scorched_02.tile", 5 ),
		AddTile( 1232502, "$CONTENT_DATA/Terrain/Tiles/Scorched/scorched_03.tile", 5 ),
		AddTile( 1232503, "$CONTENT_DATA/Terrain/Tiles/Scorched/scorched_04.tile", 5 ),
	}

	g_starter_houses = {
		AddTile( 1222500, "$CONTENT_DATA/Terrain/Tiles/Starter House.tile" )
	}
	
	g_desert_pois = {
		{tile = AddTile( 3210300, "$CONTENT_DATA/Terrain/Tiles/DesertPois/poi_01.tile", 5 ), size = 4},
		{tile = AddTile( 3210301, "$CONTENT_DATA/Terrain/Tiles/DesertPois/poi_02.tile", 5 ), size = 2},
		{tile = AddTile( 3210302, "$CONTENT_DATA/Terrain/Tiles/DesertPois/ship_01.tile", 5 ), size = 1}
	}

	g_road_pois = { -- Flippable lets the tile be on the other side of the road, rotates by 180 as well
		{tile = AddTile( 4201000, "$CONTENT_DATA/Terrain/Tiles/RoadPois/bunker_01.tile", 5 ), size = 1, offset = 1, rotation = 3, flippable = true},
		{tile = AddTile( 4201001, "$CONTENT_DATA/Terrain/Tiles/RoadPois/kiosk_64_01.tile", 5 ), size = 1, offset = 0, rotation = 3, flippable = true},
		{tile = AddTile( 4201002, "$CONTENT_DATA/Terrain/Tiles/RoadPois/kiosk_64_02.tile", 5 ), size = 1, offset = 0, rotation = 3, flippable = true},
		{tile = AddTile( 4201003, "$CONTENT_DATA/Terrain/Tiles/RoadPois/kiosk_64_03.tile", 5 ), size = 1, offset = 0, rotation = 3, flippable = true},
	}
end

----------------------------------------------------------------------------------------------------
-- Getters
----------------------------------------------------------------------------------------------------

function getDesertTileId( variationNoise )
	local tileCount = #g_desert

	if tileCount == 0 then
		return ERROR_TILE_UUID, 0
	end

	return g_desert[variationNoise % tileCount + 1]
end

function getRoadTileIdAndRotation( variationNoise )
	local tiles = g_roads.tiles

	local tileCount = #tiles

	if tileCount == 0 then
		return ERROR_TILE_UUID, 0
	end

	local rotation = g_roads.rotation

	return tiles[variationNoise % tileCount + 1], rotation
end

function getFenceTileId( variationNoise )
	local tileCount = #g_fences

	if tileCount == 0 then
		return ERROR_TILE_UUID, 0
	end

	return g_fences[variationNoise % tileCount + 1]
end

function getDesertPoi( variationNoise )
	local tileCount = #g_desert_pois

	if tileCount == 0 then
		return ERROR_TILE_UUID, 0
	end

	return g_desert_pois[variationNoise % tileCount + 1]
end

function getRoadPoi( variationNoise )
	local tileCount = #g_road_pois

	if tileCount == 0 then
		return ERROR_TILE_UUID, 0
	end

	return g_road_pois[variationNoise % tileCount + 1]
end

function getFenceCornerTileId( variationNoise )
	local tileCount = #g_fence_corners

	if tileCount == 0 then
		return ERROR_TILE_UUID, 0
	end

	return g_fence_corners[variationNoise % tileCount + 1]
end

function getScorchedTileId( variationNoise )
	local tileCount = #g_scorched

	if tileCount == 0 then
		return ERROR_TILE_UUID, 0
	end

	return g_scorched[variationNoise % tileCount + 1]
end

function getRoadEndTileId( variationNoise )
	local tileCount = #g_road_ends

	if tileCount == 0 then
		return ERROR_TILE_UUID, 0
	end

	return g_road_ends[variationNoise % tileCount + 1]
end

function getElevatorTileId( variationNoise )
	local tileCount = #g_elevators

	if tileCount == 0 then
		return ERROR_TILE_UUID, 0
	end

	return g_elevators[variationNoise % tileCount + 1]
end

function getHouseTileID( variationNoise )
	local tileCount = #g_starter_houses

	if tileCount == 0 then
		return ERROR_TILE_UUID, 0
	end

	return g_starter_houses[variationNoise % tileCount + 1]
end
