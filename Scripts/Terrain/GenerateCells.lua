dofile("$SURVIVAL_DATA/Scripts/util.lua")
dofile("$CONTENT_DATA/Scripts/Terrain/Processing.lua")
dofile("$CONTENT_DATA/Scripts/Terrain/Util.lua")

function generateOverworldCelldata(xMin, xMax, yMin, yMax, seed, data, padding, progress)
    math.randomseed(seed, progress)

    initializeCellData(xMin, xMax, yMin, yMax, seed)

    local worldSize = yMax - yMin - (2 * padding)
    local offset = worldSize * progress

    -- Set padding to scorched and everything else to desert
    for x = xMin, xMax do
        for y = yMin, yMax do
            if (x < xMin + padding or x > xMax - padding or y < yMin + padding or y > yMax - padding) then
                local tileId = getScorchedTileId(sm.noise.intNoise2d( x, y + offset, g_cellData.seed + 1234 ))
                if not tileId:isNil() then
                    g_cellData.uid[y][x] = tileId
                    g_cellData.rotation[y][x] = sm.noise.intNoise2d( x, y + offset, g_cellData.seed ) % 4
                    g_cellData.xOffset[y][x] = 0
                    g_cellData.yOffset[y][x] = 0
                end
            else
                local tileId = getDesertTileId(sm.noise.intNoise2d( x, y + offset, g_cellData.seed + 6004 ))
                if not tileId:isNil() then
                    g_cellData.uid[y][x] = tileId
                    g_cellData.rotation[y][x] = sm.noise.intNoise2d( x, y + offset, g_cellData.seed ) % 4
                    g_cellData.xOffset[y][x] = 0
                    g_cellData.yOffset[y][x] = 0
                end
            end
        end
    end

    -- Fences
    local function setFence(x, y, rotation)
        local tileId = getFenceTileId(sm.noise.intNoise2d( x, y + offset, g_cellData.seed + 1234 ))
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
        local tileId = getFenceCornerTileId(sm.noise.intNoise2d( x, y + offset, g_cellData.seed + 4123 ))
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
        local tileId, rotation = getRoadTileIdAndRotation(sm.noise.intNoise2d( 0, y + offset, g_cellData.seed + 2854 ))
        if not tileId:isNil() then
            g_cellData.uid[y][0] = tileId
            g_cellData.rotation[y][0] = rotation
            g_cellData.xOffset[y][0] = 0
            g_cellData.yOffset[y][0] = 0
        end
    end
    
    -- Road start tile
    local roadStart = yMin + padding + 1
    if progress == 0 then
        roadStart = -1
    end

    local tileId = getRoadEndTileId(sm.noise.intNoise2d( 0, roadStart + offset, g_cellData.seed + 1452 ))
    g_cellData.uid[roadStart][0] = tileId
    g_cellData.rotation[roadStart][0] = 1
    g_cellData.xOffset[roadStart][0] = 0
    g_cellData.yOffset[roadStart][0] = 0

    -- Elevation
    forEveryCorner( function( x, y )
        local elevation = getElevation(x, y + offset, seed)
        
        -- For reliable spawn positions, we must blend elevation with a fixed seed, getting stronger the closer we get to the house
        if progress == 0 then
            local fixedElevation = getElevation(x, y, 852772513)
            local proportion = math.min(math.max(y / (yMax - padding - 1), 0), 1)
            elevation = (elevation * proportion) + (fixedElevation * (1 - proportion))
        end

        g_cellData.elevation[y][x] = elevation * 83.0
	end )

    -- Flattern start of road
    if (progress > 0) then
        for x = -1, 2, 1 do
            for y = -1, 2, 1 do
                g_cellData.elevation[yMin + padding + 2 + y][0 + x] = g_cellData.elevation[yMin + padding + 2][0]
            end
        end
    end

    -- Starter house
    if progress == 0 then
        g_cellData.uid[0][1] = getHouseTileID(sm.noise.intNoise2d( 1, 0, g_cellData.seed + 1032 ))
        g_cellData.rotation[0][1] = 0
        g_cellData.xOffset[0][1] = 0
        g_cellData.yOffset[0][1] = 0

        -- Flattern starter house
        for x = -1, 2, 1 do
            for y = -1, 2, 1 do
                g_cellData.elevation[0 + y][1 + x] = g_cellData.elevation[0][1]
            end
        end
    end

    -- Elevator
    g_cellData.uid[yMax - padding - 1][0] = getElevatorTileId(sm.noise.intNoise2d( 0, yMax - padding - 1 + offset, g_cellData.seed + 80085 ))
    g_cellData.rotation[yMax - padding - 1][0] = 3
    g_cellData.xOffset[yMax - padding - 1][0] = 0
    g_cellData.yOffset[yMax - padding - 1][0] = 0
    
    -- Flattern elevator
    local elevatorHeight = g_cellData.elevation[yMax - padding - 1][0]

    for x = -1, 2, 1 do
        for y = -1, 2, 1 do
            g_cellData.elevation[yMax - padding - 1 + y][0 + x] = elevatorHeight
        end
    end

    -- Road pois
    local roadPoiCount = math.random(2, 5)
    print("Generating "..roadPoiCount.." road POIs")
    
    for i = 1, roadPoiCount, 1 do
        local y = math.random(progress == 0 and (yMin + padding + 2) or 3, yMax - padding - 2)
        
        local poi = getRoadPoi(math.random(0, 100))
        
        local flipped = poi.flippable and math.random() < 0.5

        print("Generating road POI at "..y)
        if flipped then
            print("Flipped road POI")
        end
        
        local poiOffset = poi.offset * (flipped and -1 or 1)
        g_cellData.uid[y][poiOffset] = poi.tile
        g_cellData.rotation[y][poiOffset] = (poi.rotation + (flipped and 2 or 0)) % 4
        g_cellData.xOffset[y][poiOffset] = 0 -- (Ignore, for larger tiles)
        g_cellData.yOffset[y][poiOffset] = 0
    end
    
    -- Desert pois
    local desertPoiCount = math.random(0, 10)
    print("Generating "..desertPoiCount.." desert POIs")

    for i = 1, desertPoiCount, 1 do
        local poi = getDesertPoi(math.random(0, 100))

        local x = math.random() < 0.5 and math.random(xMin + padding, -5 - (poi.size - 1)) or math.random(5, xMax - padding - (poi.size - 1)) -- Avoid le road
        local y = math.random(yMin + padding + 5, yMax - padding - 5 - (poi.size - 1))

        print("Generating desert POI at "..x..", "..y)
        for offsetX = 0, poi.size, 1 do
            for offsetY = 0, poi.size, 1 do
                g_cellData.uid[y + offsetY][x + offsetX] = poi.tile
                g_cellData.rotation[y + offsetY][x + offsetX] = 0
                g_cellData.xOffset[y + offsetY][x + offsetX] = offsetX
                g_cellData.yOffset[y + offsetY][x + offsetX] = offsetY
            end
        end
    end
end
