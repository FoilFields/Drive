dofile("$SURVIVAL_DATA/Scripts/util.lua")
dofile("$SURVIVAL_DATA/Scripts/terrain/overworld/processing.lua")

----------------------------------------------------------------------------------------------------

-- g_barrierTileList = g_barrierTileList or  { ["NE"] = {}, ["NW"] = {}, ["SE"] = {}, ["SW"] = {}, ["N"] = {}, ["S"] = {}, ["E"] = {}, ["W"] = {} }

-- g_barrierTileList["NE"][#g_barrierTileList["NE"] + 1] = AddTile( 30000, "$GAME_DATA/Terrain/Tiles/ClassicCreativeTiles/Auto/FenceNE.tile" )
-- g_barrierTileList["NW"][#g_barrierTileList["NW"] + 1] = AddTile( 30001, "$GAME_DATA/Terrain/Tiles/ClassicCreativeTiles/Auto/FenceNW.tile" )
-- g_barrierTileList["SE"][#g_barrierTileList["SE"] + 1] = AddTile( 30002, "$GAME_DATA/Terrain/Tiles/ClassicCreativeTiles/Auto/FenceSE.tile" )
-- g_barrierTileList["SW"][#g_barrierTileList["SW"] + 1] = AddTile( 30003, "$GAME_DATA/Terrain/Tiles/ClassicCreativeTiles/Auto/FenceSW.tile" )
-- g_barrierTileList["N"][#g_barrierTileList["N"] + 1] = AddTile( 31000, "$GAME_DATA/Terrain/Tiles/ClassicCreativeTiles/Auto/FenceN_01.tile" )
-- g_barrierTileList["N"][#g_barrierTileList["N"] + 1] = AddTile( 31001, "$GAME_DATA/Terrain/Tiles/ClassicCreativeTiles/Auto/FenceN_02.tile" )
-- g_barrierTileList["N"][#g_barrierTileList["N"] + 1] = AddTile( 31002, "$GAME_DATA/Terrain/Tiles/ClassicCreativeTiles/Auto/FenceN_03.tile" )
-- g_barrierTileList["S"][#g_barrierTileList["S"] + 1] = AddTile( 32000, "$GAME_DATA/Terrain/Tiles/ClassicCreativeTiles/Auto/FenceS_01.tile" )
-- g_barrierTileList["S"][#g_barrierTileList["S"] + 1] = AddTile( 32001, "$GAME_DATA/Terrain/Tiles/ClassicCreativeTiles/Auto/FenceS_02.tile" )
-- g_barrierTileList["S"][#g_barrierTileList["S"] + 1] = AddTile( 32002, "$GAME_DATA/Terrain/Tiles/ClassicCreativeTiles/Auto/FenceS_03.tile" )
-- g_barrierTileList["E"][#g_barrierTileList["E"] + 1] = AddTile( 33000, "$GAME_DATA/Terrain/Tiles/ClassicCreativeTiles/Auto/FenceE_01.tile" )
-- g_barrierTileList["E"][#g_barrierTileList["E"] + 1] = AddTile( 33001, "$GAME_DATA/Terrain/Tiles/ClassicCreativeTiles/Auto/FenceE_02.tile" )
-- g_barrierTileList["E"][#g_barrierTileList["E"] + 1] = AddTile( 33002, "$GAME_DATA/Terrain/Tiles/ClassicCreativeTiles/Auto/FenceE_03.tile" )
-- g_barrierTileList["W"][#g_barrierTileList["W"] + 1] = AddTile( 34000, "$GAME_DATA/Terrain/Tiles/ClassicCreativeTiles/Auto/FenceW_01.tile" )
-- g_barrierTileList["W"][#g_barrierTileList["W"] + 1] = AddTile( 34001, "$GAME_DATA/Terrain/Tiles/ClassicCreativeTiles/Auto/FenceW_02.tile" )
-- g_barrierTileList["W"][#g_barrierTileList["W"] + 1] = AddTile( 34002, "$GAME_DATA/Terrain/Tiles/ClassicCreativeTiles/Auto/FenceW_03.tile" )

function generateOverworldCelldata(xMin, xMax, yMin, yMax, seed, data, padding)
    math.randomseed(seed)

    initializeCellData(xMin, xMax, yMin, yMax, seed) --Zero everything

    -- Temp corner data during generate
    g_cornerTemp = {
        type = {},
        gradC = {},
        gradN = {},
        forceFlat = {},
        poiDst = {},
        lakeAdjacent = {},
        hillyness = {},
        island = {}
    }
    for y = yMin, yMax + 1 do
        g_cornerTemp.type[y] = {}
        g_cornerTemp.gradC[y] = {}
        g_cornerTemp.gradN[y] = {}
        g_cornerTemp.forceFlat[y] = {}
        g_cornerTemp.poiDst[y] = {}
        g_cornerTemp.lakeAdjacent[y] = {}
        g_cornerTemp.hillyness[y] = {}
        g_cornerTemp.island[y] = {}

        for x = xMin, xMax + 1 do
            g_cornerTemp.type[y][x] = TYPE_DESERT
            g_cornerTemp.gradC[y][x] = 0
            g_cornerTemp.gradN[y][x] = 0
            g_cornerTemp.forceFlat[y][x] = false
            g_cornerTemp.poiDst[y][x] = 0
            g_cornerTemp.lakeAdjacent[y][x] = true
            g_cornerTemp.hillyness[y][x] = 1
            g_cornerTemp.island[y][x] = 1
        end
    end

    -- local function setFence(x, y, direction)
    --     g_cellData.uid[y][x] = g_barrierTileList[direction][1 + sm.noise.intNoise2d( x, y, seed ) % #g_barrierTileList[direction]]
    --     g_cellData.rotation[y][x] = 0
    --     g_cellData.xOffset[y][x] = 0
    --     g_cellData.yOffset[y][x] = 0
    -- end

    for y = yMin + padding, yMax + 1 - padding do
        g_cornerTemp.type[y][xMin + padding] = TYPE_FIELD
        g_cornerTemp.type[y][xMax + 1 - padding] = TYPE_FIELD
        -- setFence(xMin + padding, y, "E")
        -- setFence(xMax + 1 - padding, y, "W")
    end
    
    for x = xMin + padding, xMax + 1 - padding do
        g_cornerTemp.type[yMin + padding][x] = TYPE_FIELD
        g_cornerTemp.type[yMax + 1 - padding][x] = TYPE_FIELD
        -- setFence(x, yMin + padding, "N")
        -- setFence(x, yMax + 1 - padding, "S")
    end
    -- setFence(xMin + padding, yMin + padding, "NE")
    -- setFence(xMin + padding, yMax + 1 - padding, "NW")
    -- setFence(xMax + 1 - padding, yMax + 1 - padding, "SW")
    -- setFence(xMax + 1 - padding, yMin + padding, "SE")

    -- Elevation
    forEveryCorner( function( x, y )
        local elevation = 0.1 + clamp( ( g_cornerTemp.gradC[y][x] * 3 - 1 ) * 0.1, 0, 1 )
        elevation = elevation + sm.noise.perlinNoise2d( x / 64, y / 64, seed + 12032 ) * 4 -- Super duper scrolling terrain
        elevation = elevation + sm.noise.perlinNoise2d( x / 32, y / 32, seed + 10293 ) * 2
        elevation = elevation + sm.noise.perlinNoise2d( x / 16, y / 16, seed + 7907 ) * clamp( ( g_cornerTemp.gradC[y][x] * 3 - 1 ), 0, 1 )
        elevation = elevation + sm.noise.perlinNoise2d( x / 8, y / 8, seed + 5527 ) * 0.5
        elevation = elevation + sm.noise.perlinNoise2d( x / 4, y / 4, seed + 8733 ) * 0.25
        elevation = elevation + sm.noise.perlinNoise2d( x / 2, y / 2, seed + 5442 ) * 0.125
        g_cellData.elevation[y][x] = g_cornerTemp.hillyness[y][x] * elevation * 250 / 3
	end )

    -- Generate all the cell data
	evaluateType( TYPE_DESERT, getDesertTileIdAndRotation )
    evaluateType( TYPE_FIELD, getFieldTileIdAndRotation )
    evaluateType( TYPE_AUTUMNFOREST, getAutumnForestTileIdAndRotation )

    g_cornerTemp = nil
    g_cellTemp = nil
end
