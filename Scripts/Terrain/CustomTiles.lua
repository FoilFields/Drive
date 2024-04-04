--This file is generated! Don't edit here.

----------------------------------------------------------------------------------------------------
-- Data
----------------------------------------------------------------------------------------------------

local g_desert = {} --Flags lookup table

-------------------------------
-- Bits                      --
-- dir | SE | SW | NW | NE | --
-- bit |  3 |  2 |  1 |  0 | --
-------------------------------

local function toDesertIndex( se, sw, nw, ne )
	return bit.bor( bit.lshift( se, 3 ), bit.lshift( sw, 2 ), bit.lshift( nw, 1 ), bit.tobit( ne ) )
end

function initCustomTiles()

  -- Desert tiles

	for i=0, 15 do
		g_desert[i] = { tiles = {}, rotation = 0 }
	end
	g_desert[toDesertIndex( 0, 0, 0, 1 )] = { tiles = { AddTile( 3000101, "$SURVIVAL_DATA/Terrain/Tiles/desert/Desert(0001)_01.tile", 3 ) }, rotation = 0 }
	g_desert[toDesertIndex( 0, 0, 1, 0 )] = { tiles = { AddTile( 3000101, "$SURVIVAL_DATA/Terrain/Tiles/desert/Desert(0001)_01.tile", 3 ) }, rotation = 1 }
	g_desert[toDesertIndex( 0, 0, 1, 1 )] = { tiles = { AddTile( 3000301, "$SURVIVAL_DATA/Terrain/Tiles/desert/Desert(0011)_01.tile", 3 ), AddTile( 3000302, "$SURVIVAL_DATA/Terrain/Tiles/desert/Desert(0011)_02.tile", 3 ) }, rotation = 0 }
	g_desert[toDesertIndex( 0, 1, 0, 0 )] = { tiles = { AddTile( 3000101, "$SURVIVAL_DATA/Terrain/Tiles/desert/Desert(0001)_01.tile", 3 ) }, rotation = 2 }
	g_desert[toDesertIndex( 0, 1, 0, 1 )] = { tiles = { AddTile( 3000501, "$SURVIVAL_DATA/Terrain/Tiles/desert/Desert(0101)_01.tile", 3 ) }, rotation = 0 }
	g_desert[toDesertIndex( 0, 1, 1, 0 )] = { tiles = { AddTile( 3000301, "$SURVIVAL_DATA/Terrain/Tiles/desert/Desert(0011)_01.tile", 3 ), AddTile( 3000302, "$SURVIVAL_DATA/Terrain/Tiles/desert/Desert(0011)_02.tile", 3 ) }, rotation = 1 }
	g_desert[toDesertIndex( 0, 1, 1, 1 )] = { tiles = { AddTile( 3000701, "$SURVIVAL_DATA/Terrain/Tiles/desert/Desert(0111)_01.tile", 3 ) }, rotation = 0 }
	g_desert[toDesertIndex( 1, 0, 0, 0 )] = { tiles = { AddTile( 3000101, "$SURVIVAL_DATA/Terrain/Tiles/desert/Desert(0001)_01.tile", 3 ) }, rotation = 3 }
	g_desert[toDesertIndex( 1, 0, 0, 1 )] = { tiles = { AddTile( 3000301, "$SURVIVAL_DATA/Terrain/Tiles/desert/Desert(0011)_01.tile", 3 ), AddTile( 3000302, "$SURVIVAL_DATA/Terrain/Tiles/desert/Desert(0011)_02.tile", 3 ) }, rotation = 3 }
	g_desert[toDesertIndex( 1, 0, 1, 0 )] = { tiles = { AddTile( 3000501, "$SURVIVAL_DATA/Terrain/Tiles/desert/Desert(0101)_01.tile", 3 ) }, rotation = 3 }
	g_desert[toDesertIndex( 1, 0, 1, 1 )] = { tiles = { AddTile( 3000701, "$SURVIVAL_DATA/Terrain/Tiles/desert/Desert(0111)_01.tile", 3 ) }, rotation = 3 }
	g_desert[toDesertIndex( 1, 1, 0, 0 )] = { tiles = { AddTile( 3000301, "$SURVIVAL_DATA/Terrain/Tiles/desert/Desert(0011)_01.tile", 3 ), AddTile( 3000302, "$SURVIVAL_DATA/Terrain/Tiles/desert/Desert(0011)_02.tile", 3 ) }, rotation = 2 }
	g_desert[toDesertIndex( 1, 1, 0, 1 )] = { tiles = { AddTile( 3000701, "$SURVIVAL_DATA/Terrain/Tiles/desert/Desert(0111)_01.tile", 3 ) }, rotation = 2 }
	g_desert[toDesertIndex( 1, 1, 1, 0 )] = { tiles = { AddTile( 3000701, "$SURVIVAL_DATA/Terrain/Tiles/desert/Desert(0111)_01.tile", 3 ) }, rotation = 1 }
	g_desert[toDesertIndex( 1, 1, 1, 1 )] = { tiles = { AddTile( 3001501, "$SURVIVAL_DATA/Terrain/Tiles/desert/Desert(1111)_01.tile", 3 ), AddTile( 3001502, "$SURVIVAL_DATA/Terrain/Tiles/desert/Desert(1111)_02.tile", 3 ), AddTile( 3001503, "$SURVIVAL_DATA/Terrain/Tiles/desert/Desert(1111)_03.tile", 3 ), AddTile( 3001504, "$SURVIVAL_DATA/Terrain/Tiles/desert/Desert(1111)_04.tile", 3 ), AddTile( 3001505, "$SURVIVAL_DATA/Terrain/Tiles/desert/Desert(1111)_05.tile", 3 ), AddTile( 3001506, "$SURVIVAL_DATA/Terrain/Tiles/desert/Desert(1111)_06.tile", 3 ) }, rotation = 0 }

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

  g_fences = {
		AddTile( 5002500, "$CONTENT_DATA/Terrain/Tiles/Fence/fence_01.tile", 5 ),
	}

  g_fence_corners = {
		AddTile( 5002600, "$CONTENT_DATA/Terrain/Tiles/Fence/fence_corner_01.tile", 5 ),
	}

  g_scorched = {
		AddTile( 1232500, "$CONTENT_DATA/Terrain/Tiles/Scorched/scorched_01.tile", 5 ),
		AddTile( 1232501, "$CONTENT_DATA/Terrain/Tiles/Scorched/scorched_02.tile", 5 ),
	}
end

----------------------------------------------------------------------------------------------------
-- Getters
----------------------------------------------------------------------------------------------------

function getDesertTileIdAndRotation( cornerFlags, variationNoise, rotationNoise )
	if cornerFlags > 0 then
		local item = g_desert[cornerFlags]
		local tileCount = #item.tiles

		if tileCount == 0 then
			return ERROR_TILE_UUID, 0
		end

		local rotation = cornerFlags == 15 and ( rotationNoise % 4 ) or item.rotation

		return item.tiles[variationNoise % tileCount + 1], rotation
	end

	return sm.uuid.getNil(), 0
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
