dofile("$SURVIVAL_DATA/Scripts/util.lua")
dofile("$CONTENT_DATA/Scripts/Terrain/Processing.lua")

function generateOverworldCelldata(xMin, xMax, yMin, yMax, seed, data, padding, progress)
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
    local start = yMin + padding + 1
    if progress == 0 then
        start = 0
    end

    for y = start, yMax - padding - 2 do
        local tileId, rotation = getRoadTileIdAndRotation(sm.noise.intNoise2d( 0, y, g_cellData.seed + 2854 ))
        if not tileId:isNil() then
            g_cellData.uid[y][0] = tileId
            g_cellData.rotation[y][0] = rotation
            g_cellData.xOffset[y][0] = 0
            g_cellData.yOffset[y][0] = 0
        end
    end
    
    -- Road start fade tile
    local roadStart = yMin + padding + 1
    if progress == 0 then
        roadStart = -1
    end

    local tileId = getRoadEndTileId(sm.noise.intNoise2d( 0, 0, g_cellData.seed + 1452 ))
    g_cellData.uid[roadStart][0] = tileId
    g_cellData.rotation[roadStart][0] = 1
    g_cellData.xOffset[roadStart][0] = 0
    g_cellData.yOffset[roadStart][0] = 0

    local function getElevation(x, y, seed) 
        local elevation = 0.1

        elevation = elevation + (sm.noise.perlinNoise2d( x / 128, y / 128, seed + 14123 ) + 0.25) * 2 -- Super duper scrolling terrain
        elevation = elevation + (sm.noise.perlinNoise2d( x / 64, y / 64, seed + 12032 ) + 0.25) * 1.25
        elevation = elevation + (sm.noise.perlinNoise2d( x / 32, y / 32, seed + 10293 ) + 0.25)
        elevation = elevation + (sm.noise.perlinNoise2d( x / 16, y / 16, seed + 7907 ) + 0.25) * 0.75
        elevation = elevation + (sm.noise.perlinNoise2d( x / 8, y / 8, seed + 5527 ) + 0.25) * 0.5
        elevation = elevation + (sm.noise.perlinNoise2d( x / 4, y / 4, seed + 8733 ) + 0.25) * 0.25
        elevation = elevation + (sm.noise.perlinNoise2d( x / 2, y / 2, seed + 5442 ) + 0.25) * 0.125

        return elevation
    end

    -- Elevation
    forEveryCorner( function( x, y )
        local elevation = getElevation(x, y, seed)
        
        -- For reliable spawn positions, we must blend elevation with a fixed seed, getting stronger the closer we get to the house
        if progress == 0 then
            local fixedElevation = getElevation(x, y, 852772513)
            local proportion = math.min(math.max(y / (yMax - padding - 1), 0), 1)
            elevation = (elevation * proportion) + (fixedElevation * (1 - proportion))
        end

        g_cellData.elevation[y][x] = elevation * 250 / 3
	end )

    -- Starter house
    if progress == 0 then
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
    end

    -- Elevator
    g_cellData.uid[yMax - padding - 1][0] = getElevatorTileId(sm.noise.intNoise2d( 1, 0, g_cellData.seed + 80085 ))
    g_cellData.rotation[yMax - padding - 1][0] = 3
    g_cellData.xOffset[yMax - padding - 1][0] = 0
    g_cellData.yOffset[yMax - padding - 1][0] = 0

    -- Flattern elevator
    for x = -1, 1, 1 do
        for y = -1, 1, 1 do
            g_cellData.elevation[yMax - padding - 1 + y][0 + x] = g_cellData.elevation[yMax - padding - 1][0]
        end
    end

    -- on-road pois

    -- road-side pois

    -- far-off pois
end
