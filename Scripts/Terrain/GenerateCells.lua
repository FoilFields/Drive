dofile("$SURVIVAL_DATA/Scripts/util.lua")
dofile("$CONTENT_DATA/Scripts/Terrain/Processing.lua")

----------------------------------------------------------------------------------------------------

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

    for y = yMin + padding, yMax + 1 - padding do
        g_cornerTemp.type[y][xMin + padding] = TYPE_FIELD
        g_cornerTemp.type[y][xMax + 1 - padding] = TYPE_FIELD

        local tileId, rotation = getRoadTileIdAndRotation(sm.noise.intNoise2d( 0, y, g_cellData.seed + 2854 ))
        if not tileId:isNil() and g_cellData.uid[y][0]:isNil() then
            g_cellData.uid[y][0] = tileId
            g_cellData.rotation[y][0] = rotation
            g_cellData.xOffset[y][0] = 0
            g_cellData.yOffset[y][0] = 0
        end
        
    end
    
    for x = xMin + padding, xMax + 1 - padding do
        g_cornerTemp.type[yMin + padding][x] = TYPE_FIELD
        g_cornerTemp.type[yMax + 1 - padding][x] = TYPE_FIELD
    end

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

	evaluateType( TYPE_DESERT, getDesertTileIdAndRotation )
    evaluateType( TYPE_FIELD, getFieldTileIdAndRotation )
    -- evaluateType( TYPE_AUTUMNFOREST, getAutumnForestTileIdAndRotation )
    

    g_cornerTemp = nil
end
