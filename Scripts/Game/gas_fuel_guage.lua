-
FuelGuage = class()

local function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function onTick()
    -- Get all the connected parts to the gas engine
    local connectedParts = sm.engine.getConnectedParts()
    
    -- Iterate over the connected parts
    for _, part in ipairs(connectedParts) do
        -- Check if the connected part is a gas engine
        if part:getType() == "gasengine" then
            -- Get the current fuel level of the gas engine
            local fuelLevel = part:getFuel()
            
            -- Display the fuel level on the screen
            local formattedFuelLevel = round(fuelLevel, 2) -- Round to 2 decimal places
            sm.gui.chatMessage("Fuel level: " .. formattedFuelLevel)
            return -- Exit the loop since we found the gas engine
        end
    end
end

-- Register the onTick function to be called every tick
sm.event.register("onTick", onTick)
