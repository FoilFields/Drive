-- This script doubles the game's tick rate when inside a bathtub

-- Define the tick rate multiplier when inside a bathtub
local TICK_RATE_MULTIPLIER = 2

-- Function to check if a player is inside a bathtub
local function isInBathtub(player)
    -- Get the player's position
    local position = player.character.worldPosition
    
    -- Check if the player is inside a bathtub
    local trigger = sm.areaTrigger.createBox(position - sm.vec3.new(0.5, 0.5, 0.5), position + sm.vec3.new(0.5, 0.5, 0.5), sm.areaTrigger.filter.dynamicBody)
    local bodies = trigger:getBodyList()
    for _, body in ipairs(bodies) do
        if body:getShape():getType() == sm.shape.type.container then
            return true
        end
    end
    return false
end

-- Function to modify the tick rate
local function modifyTickRate()
    if isInBathtub(sm.localPlayer) then
        sm.game.setTickRate(4)
    else
        sm.game.resetTickRate()
    end
end

-- Function to be called every tick
function onTick()
    modifyTickRate()
end

-- Register the onTick function to be called every tick
sm.event.register("onTick", onTick)
