PortalManager = class( nil )

-- MODDERS READING THIS
-- I spent a whole 20 minutes crafting my own player teleport system just to find out that I can't move creations between worlds

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

function PortalManager:sv_transfer()
  loading = true
  oldWorld = self.portal:getWorldA()
  self.portal:transferAToB()
  loading = not sm.event.sendToGame("sv_progressWorld", self.portal:getWorldB())

  -- Cleanup

  nextDestroy = os.time() + 30
end

function PortalManager:sv_loadDestination()
  sm.event.sendToGame("sv_loadDestination", self.portal)
end

function PortalManager:sv_onFixedUpdate()
  if (nextDestroy and nextDestroy < os.time()) then
    nextDestroy = nil
    if (oldWorld) then
      oldWorld:destroy()
      oldWorld = nil
    end
  end

  if (self.portal and not loading) then
    if self.portal:hasOpeningA() and self.portal:hasOpeningB() then
      for _, player in ipairs(sm.player.getAllPlayers()) do
        if player:getCharacter():getWorld() == self.portal:getWorldB() then
          return
        end
      end

      self:sv_transfer()
    end
  end
end
