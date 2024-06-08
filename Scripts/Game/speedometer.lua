-- Declare lastPosition and lastTime outside the function to retain values between calls
local lastPosition = nil
local lastTime = nil

-- Function to calculate speed in km/h
local function calculateSpeed()
    -- Get the current position of the creation's root part
    local currentPosition = sm.localPlayer.getCharacter():getWorldPosition()
    
    -- Get the previous position if it exists
    if not lastPosition then
        lastPosition = currentPosition
        lastTime = sm.game.getCurrentTick()
        return 0
    end
    
    -- Calculate the distance traveled
    local distanceTraveled = (currentPosition - lastPosition):length()
    
    -- Calculate the time difference in seconds (assuming 40 ticks per second)
    local currentTime = sm.game.getCurrentTick()
    local timeDifferenceInSeconds = (currentTime - lastTime) / 40
    
    -- Calculate speed in meters per second
    local speedInMetersPerSecond = distanceTraveled / timeDifferenceInSeconds
    
    -- Convert speed to km/h (1 m/s = 3.6 km/h)
    local speedInKmPerHour = speedInMetersPerSecond * 3.6
    
    -- Update last position and time for next calculation
    lastPosition = currentPosition
    lastTime = currentTime
    
    return speedInKmPerHour
end

-- Function to display speed in chat
local function displaySpeed()
    local speed = calculateSpeed()
    sm.gui.chatMessage("Current Speed: " .. string.format("%.2f", speed) .. " km/h")
end

-- Function to be called every tick
function onTick()
    displaySpeed()
end

-- Register the onTick function to be called every tick
sm.event.register("onTick", onTick)
