PortalManager = class( nil )

function PortalManager:sv_remove()
  if self.portal then
    sm.portal.destroy(self.portal)
    self.portal = nil
  end
end

function PortalManager:sv_setPortal(portal)
  self.portal = portal

  if portal:hasOpeningA() and portal:hasOpeningB() then
    self:sv_transfer()
  end
end

function PortalManager:sv_transfer()
  local newWorld = self.portal:getWorldB()
  self.portal:transferAToB()
  sm.event.sendToGame("sv_progressWorld", newWorld)
end

function PortalManager:sv_loadDestination()
  sm.event.sendToGame("sv_loadDestination", self.portal)
end
