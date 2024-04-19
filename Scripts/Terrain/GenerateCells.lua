dofile("$SURVIVAL_DATA/Scripts/util.lua")
dofile("$CONTENT_DATA/Scripts/Terrain/Processing.lua")
dofile("$CONTENT_DATA/Scripts/Terrain/Util.lua")

-- Some helper FUNctions

-- Writes a tile to the g_cellData and adds the location of a set tile to the provided array (intended for collision prevention)
local function writePoi(tile, x, y, size, rotation, collisionArray)
    for offsetX = 0, size - 1, 1 do
        for offsetY = 0, size - 1, 1 do
            g_cellData.uid[y + offsetY][x + offsetX] = tile
            g_cellData.rotation[y + offsetY][x + offsetX] = rotation
            g_cellData.xOffset[y + offsetY][x + offsetX] = offsetX
            g_cellData.yOffset[y + offsetY][x + offsetX] = offsetY

            if collisionArray then
                collisionArray[#collisionArray + 1] = sm.vec3.new(x + offsetX, y + offsetY, 0)                
            end
        end
    end
end

-- Returns true if a value is in an array
local function inArray(value, array)
    for _, pos in ipairs(array) do
        if pos == value then
            return true
        end
    end

    return false
end

-- Checks if a POI can be placed at the x and y position provided given a collision array
local function validPlacement(x, y, size, collisionArray)
    for offsetX = 0, size, 1 do
        for offsetY = 0, size, 1 do
            if inArray(sm.vec3.new(x + offsetX, y + offsetY, 0), collisionArray) then
                return false
            end
        end
    end

    return true
end

-- Fills g_cellData with world data
function generateOverworldCelldata(xMin, xMax, yMin, yMax, seed, data, padding, progress)
    math.randomseed(seed + progress * 10)

    initializeCellData(xMin, xMax, yMin, yMax, seed)

    local worldSize = yMax - yMin - (2 * padding)
    local offset = worldSize * progress

    -- Set padding to scorched and everything else to desert
    for x = xMin, xMax do
        for y = yMin, yMax do
            local tileId

            if (x < xMin + padding or 
                x > xMax - padding or 
                y < yMin + padding or 
                y > yMax - padding
            ) then
                tileId = getScorchedTileId(sm.noise.intNoise2d( x, y + offset, g_cellData.seed + 1234 ))
            else
                tileId = getDesertTileId(sm.noise.intNoise2d( x, y + offset, g_cellData.seed + 6004 ))
            end
            
            writePoi(tileId, x, y, 1, sm.noise.intNoise2d( x, y + offset, g_cellData.seed ) % 4)
        end
    end

    -- Fences
    local function setFence(x, y, rotation)
        local tileId = getFenceTileId(sm.noise.intNoise2d( x, y + offset, g_cellData.seed + 1234 ))
        writePoi(tileId, x, y, 1, rotation)
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
        writePoi(tileId, x, y, 1, rotation)
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
        writePoi(tileId, 0, y, 1, rotation)
    end
    
    -- Road start tile
    local roadStart = yMin + padding + 1
    if progress == 0 then
        roadStart = -1
    end

    local tileId = getRoadEndTileId(sm.noise.intNoise2d( 0, roadStart + offset, g_cellData.seed + 1452 ))
    writePoi(tileId, 0, roadStart, 1, 1)

    -- Elevation
    forEveryCorner( function( x, y )
        g_cellData.elevation[y][x] = getElevation(x, y + offset, seed, progress == 0) * 83.0
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
        writePoi(getHouseTileID(sm.noise.intNoise2d( 1, 0, g_cellData.seed + 1032 )), 1, 0, 1, 0)

        -- Flattern starter house
        for x = -1, 2, 1 do
            for y = -1, 2, 1 do
                g_cellData.elevation[0 + y][1 + x] = g_cellData.elevation[0][1]
            end
        end
    end

    -- Elevator
    writePoi(getElevatorTileId(sm.noise.intNoise2d( 0, yMax - padding - 1 + offset, g_cellData.seed + 80085 )), 0, yMax - padding - 1, 1, 3)
    
    -- Flattern elevator
    local elevatorHeight = g_cellData.elevation[yMax - padding - 1][0]

    for x = -1, 2, 1 do
        for y = -1, 2, 1 do
            g_cellData.elevation[yMax - padding - 1 + y][0 + x] = elevatorHeight
        end
    end

    -- Road pois
    local roadPoiCount = math.random(2, 6)
    local roadPois = {}
    print("Generating "..roadPoiCount.." road POIs")

    for i = 1, roadPoiCount, 1 do
        local y = math.random(progress == 0 and 2 or (yMin + padding + 2), yMax - padding - 2)
        
        local poi = getRoadPoi(math.random(0, 100))
        local flipped = poi.flippable and math.random() < 0.5
        local poiOffset = poi.offset * (flipped and -1 or 1)

        if validPlacement(poiOffset, y, poi.size, roadPois) then
            print("Generating road POI at "..y)
            if flipped then
                print("Flipped road POI")
            end
            
            writePoi(poi.tile, poiOffset, y, poi.size, (poi.rotation + (flipped and 2 or 0)) % 4, roadPois)
        else 
            print("Not generating road POI at "..y)
        end
    end

    roadPois = nil
    
    -- Desert pois
    local desertPoiCount = math.random(3, 8)
    local desertPois = {}
    print("Generating "..desertPoiCount.." desert POIs")

    for i = 1, desertPoiCount, 1 do
        local poi = getDesertPoi(math.random(0, 100))

        local left = math.random() < 0.5 -- Avoid le road
        local minX = xMin + padding + 1
        local maxX = xMax - padding - (poi.size - 1) - 1

        local x = left and math.random(minX, -5 - (poi.size - 2)) or math.random(5, maxX) 
        local y = math.random(yMin + padding + 5, yMax - padding - 5 - (poi.size - 1))

        if validPlacement(x, y, poi.size, desertPois) then
            print("Generating desert POI at "..x..", "..y)
            writePoi(poi.tile, x, y, poi.size, 0, desertPois)
        else
            print("Not generating desert POI at "..x..", "..y)
        end
    end

    desertPois = nil
end
