PortalManager = class( nil )

-- MODDERS READING THIS
-- I spent a whole 20 minutes crafting my own player teleport system just to find out that I can't move creations between worlds
-- Sorry scrap mechanic devs but this is rediculously over complicated. I can kind of see why its been 600 years since the last update lmao

-- It's hard to describe what this really does so I'll give you a normal use case:
-- Player loads the tile at end of world
-- This loads the interactable there (It's called "ElevatorEnd", it was originally stolen from the elevator im sorry for the name)
-- This interactable creates a portal with a huge openingA (64x64x64) positioned to cover the entire tile
-- It gives the PortalManager the portal it made
-- On pressing the button, it fires sv_loadDestination in SurvivalGame
-- This creates a new world and loads (by exact coordinate, and for every player) the tile with the interactable "ElevatorStart" in it (I KNOW THE NAME STILL HAS ELEVATOR IN IT)
-- Oh yeah we also add a portal world hook so that we can connect the portals
-- The "ElevatorStart" interactable (now having been loaded by like every player in the server) will have loaded and will now pop this hook, set openingB similar to how the first opening is set, then update the PortalManager with the modified portal
-- On a related note, our fixedUpdate method in PortalManager continually checks for whether the portal has two openings, and if it does, we activate the portal, teleporting all people and creations in the area from opening A to B
-- Since this should only happen when someones actually pressed the button and the next world has loaded, this isn't a problem (famous last words)
-- We also have some cleanup code that deletes the old world and also we set the main world at some point

-- Some edge cases i haven't really considered:
-- Someone (somehow) is out of the portal zone but still in the tile
-- Both portals on the SAME WORLD are loaded (would need a player on either side of the world)
-- If a player leaves on an eariler world they cannot rejoin (Devastatingly game-breaking D:)

local loading = false

local nextDestroy = nil
local oldWorld = nil

function PortalManager:sv_remove()
  if self.portal then
    sm.portal.destroy(self.portal)
    self.portal = nil
  end
end

function PortalManager:sv_setPortal(portal)
  self.portal = portal
end

function PortalManager:sv_getPortal(portal)
  return portal
end

function PortalManager:sv_transfer()
  loading = true
  oldWorld = self.portal:getWorldA()
  self.portal:transferAToB()
  -- Cleanup

  -- yeah we have to wait otherwise it'll teleport like half the players and kill itself, crashing everyones games lmao. I cba to write good code so its kind of arbitrarily 30 seconds
  -- TODO: delete old world when we have confirmed that all players AND CREATIONS have been teleported
  print("Staging old world for deletion")
  nextDestroy = os.time() + 30
end

function PortalManager:sv_onFixedUpdate()
  if (nextDestroy and nextDestroy < os.time()) then
    print("Destroying old world!!!!1!!")
    nextDestroy = nil
    if (oldWorld) then
      oldWorld:destroy()
      oldWorld = nil
      g_switchingWorld = false -- We can finally safely do it all again :)
      loading = false
      print("Portal process complete :D")
    end
  end

  if (self.portal and not loading) then
    if self.portal:hasOpeningA() and self.portal:hasOpeningB() then
      print("Two openings detected! Activating portal...")
      self:sv_transfer()
    end
  end
end
