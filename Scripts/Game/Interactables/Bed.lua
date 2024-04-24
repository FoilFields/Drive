-- you get NO BEDS ┻━┻ ︵ ＼( °□° )／ ︵ ┻━┻

Bed = class( nil )

function Bed.client_onInteract( self, character, state )
  if state == true then
    self:cl_seat()
	end
end

function Bed.cl_seat( self )
	if sm.localPlayer.getPlayer() and sm.localPlayer.getPlayer():getCharacter() then
		self.interactable:setSeatCharacter( sm.localPlayer.getPlayer():getCharacter() )
	end
end

function Bed.client_onAction( self, controllerAction, state )
	local consumeAction = true
	if state == true then
		if controllerAction == sm.interactable.actions.use or controllerAction == sm.interactable.actions.jump then
			self:cl_seat()
		else
			consumeAction = false
		end
	else
		consumeAction = false
	end
	return consumeAction
end
