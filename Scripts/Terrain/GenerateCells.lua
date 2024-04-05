dofile("$SURVIVAL_DATA/Scripts/util.lua")
dofile("$CONTENT_DATA/Scripts/Terrain/Processing.lua")

----------------------------------------------------------------------------------------------------

function generateOverworldCelldata(xMin, xMax, yMin, yMax, seed, data, padding)
    math.randomseed(seed)

    initializeCellData(xMin, xMax, yMin, yMax, seed)

    -- Set padding to scorched and everything else to desert
    for x = xMin, xMax do
        for y = yMin, yMax do
            if (x < xMin + padding or x > xMax - padding or y < yMin + padding or y > yMax - padding) then
                local tileId = getScorchedTileId(sm.noise.intNoise2d( x, y, g_cellData.seed + 1234 ))
                if not tileId:isNil() then
                    g_cellData.uid[y][x] = tileId
                    g_cellData.rotation[y][x] = sm.noise.intNoise2d( x, y, g_cellData.seed ) % 4
                    g_cellData.xOffset[y][x] = 0
                    g_cellData.yOffset[y][x] = 0
                end
            else
                local tileId = getDesertTileId(sm.noise.intNoise2d( x, y, g_cellData.seed + 6004 ))
                if not tileId:isNil() then
                    g_cellData.uid[y][x] = tileId
                    g_cellData.rotation[y][x] = sm.noise.intNoise2d( x, y, g_cellData.seed ) % 4
                    g_cellData.xOffset[y][x] = 0
                    g_cellData.yOffset[y][x] = 0
                end
            end
        end
    end

    -- Fences
    local function setFence(x, y, rotation)
        local tileId = getFenceTileId(sm.noise.intNoise2d( x, y, g_cellData.seed + 1234 ))
        if not tileId:isNil() then
            g_cellData.uid[y][x] = tileId
            g_cellData.rotation[y][x] = rotation
            g_cellData.xOffset[y][x] = 0
            g_cellData.yOffset[y][x] = 0
        end
    end

    for y = yMin + padding, yMax - padding do
        setFence(xMin + padding, y, 1)
        setFence(xMax - padding, y, 3)
    end
    
    for x = xMin + padding, xMax - padding do
        setFence(x, yMin + padding, 2)
        setFence(x, yMax - padding, 0)
    end

    -- Fence corners
    local function setFenceCorner(x, y, rotation)
        local tileId = getFenceCornerTileId(sm.noise.intNoise2d( x, y, g_cellData.seed + 4123 ))
        if not tileId:isNil() then
            g_cellData.uid[y][x] = tileId
            g_cellData.rotation[y][x] = rotation
            g_cellData.xOffset[y][x] = 0
            g_cellData.yOffset[y][x] = 0
        end
    end

    setFenceCorner(xMin + padding, yMax - padding, 0)
    setFenceCorner(xMin + padding, yMin + padding, 1)
    setFenceCorner(xMax - padding, yMin + padding, 2)
    setFenceCorner(xMax - padding, yMax - padding, 3)

    -- Roads
    for y = yMin + padding + 1, yMax - padding - 1 do
        local tileId, rotation = getRoadTileIdAndRotation(sm.noise.intNoise2d( 0, y, g_cellData.seed + 2854 ))
        if not tileId:isNil() then
            g_cellData.uid[y][0] = tileId
            g_cellData.rotation[y][0] = rotation
            g_cellData.xOffset[y][0] = 0
            g_cellData.yOffset[y][0] = 0
        end
    end

    -- Elevation
    forEveryCorner( function( x, y )
        local elevation = 0.1
        elevation = elevation + (sm.noise.perlinNoise2d( x / 128, y / 128, seed + 14123 ) + 0.5) * 1.5 -- Super duper scrolling terrain
        elevation = elevation + (sm.noise.perlinNoise2d( x / 64, y / 64, seed + 12032 ) + 0.5) * 1.25
        elevation = elevation + (sm.noise.perlinNoise2d( x / 32, y / 32, seed + 10293 ) + 0.5)
        elevation = elevation + (sm.noise.perlinNoise2d( x / 16, y / 16, seed + 7907 ) + 0.5) * 0.75
        elevation = elevation + (sm.noise.perlinNoise2d( x / 8, y / 8, seed + 5527 ) + 0.5) * 0.5
        elevation = elevation + (sm.noise.perlinNoise2d( x / 4, y / 4, seed + 8733 ) + 0.5) * 0.25
        elevation = elevation + (sm.noise.perlinNoise2d( x / 2, y / 2, seed + 5442 ) + 0.5) * 0.125
        g_cellData.elevation[y][x] = elevation * 250 / 3
	end )

    -- Starter house
    g_cellData.uid[0][1] = getPoi(sm.noise.intNoise2d( 1, 0, g_cellData.seed + 1032 ), "StarterHouse")
    g_cellData.rotation[0][1] = 0
    g_cellData.xOffset[0][1] = 0
    g_cellData.yOffset[0][1] = 0

    -- Flattern starter house
    for x = -1, 1, 1 do
        for y = -1, 1, 1 do
            g_cellData.elevation[0 + y][1 + x] = g_cellData.elevation[0][1]
        end
    end

    -- Elevator

    -- on-road pois

    -- road-side pois

    -- far-off pois
end
