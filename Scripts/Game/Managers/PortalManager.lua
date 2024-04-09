PortalManager = class( nil )

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
  local newWorld = self.portal:getWorldB()
  self.portal:transferAToB()
  sm.event.sendToGame("sv_progressWorld", newWorld)
end

function PortalManager:sv_loadDestination()
  sm.event.sendToGame("sv_loadDestination", self.portal)
end

function PortalManager:sv_onFixedUpdate()
  if (self.portal) then
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
