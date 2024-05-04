function Game:client_onCreate()
    SurvivalGame.client_onCreate(self)
    self.cl.tfpCrosshair = sm.gui.createWorldIconGui(30, 30, "$GAME_DATA/Gui/Layouts/Hud/Hud_BeaconIcon.layout", false)
	self.cl.tfpCrosshair:setImage("Icon", "$CONTENT_DATA/Gui/hud_tfp_crosshair.png")
    self.antiZoom = 5
    self.camEnabled = true
end

function Game:server_onPlayerJoined( player, newPlayer )
	SurvivalGame.server_onPlayerJoined( self, player, newPlayer )
    self.network:sendToClient(player, "cl_crosshair")
end

function Game:cl_crosshair()
    sm.gui.displayAlertText(AlertMessage, 15)
    sm.gui.chatMessage(AlertMessage)
end

function Game:client_onUpdate( dt )
    SurvivalGame.client_onUpdate( self, dt )
    --sets camera to head level in third person mode
    --local plrPos = sm.localPlayer.getPlayer():getCharacter():getWorldPosition()
    if sm.exists(sm.localPlayer.getPlayer():getCharacter()) and self.camEnabled then
        local compensateSpeed = sm.localPlayer.getPlayer().character:getVelocity()
        local camOffset = sm.localPlayer.getPlayer():getCharacter():getDirection() / self.antiZoom + compensateSpeed / 50
        camOffset.z = camOffset.z / 1.5
        local eyeRPos = sm.localPlayer.getPlayer():getCharacter():getTpBonePos("jnt_right_eye") --jnt_right_eye
        sm.camera.setCameraState(3)
        sm.camera.setPosition(eyeRPos + camOffset)
        sm.camera.setDirection(sm.localPlayer.getPlayer():getCharacter():getDirection())
        sm.camera.setFov(sm.camera.getDefaultFov()+5)

        if self.cl.tfpCrosshair and not self.cl.tfpCrosshair:isActive() then
            self.cl.tfpCrosshair:open()
        end
        local hit, res = sm.localPlayer.getRaycast(7.5)
        if hit then
            self.cl.tfpCrosshair:setWorldPosition( res.pointWorld, sm.localPlayer.getPlayer().character:getWorld() )
        else
            self.cl.tfpCrosshair:close()
        end
    elseif self.cl.tfpCrosshair:isActive() then
        self.cl.tfpCrosshair:close()
    end
end

--bind commands
function Game:bindChatCommands()
    SurvivalGame.bindChatCommands( self )

	if true then
		sm.game.bindChatCommand( "/recam", {}, "cl_onChatCommand", "Manually sets the fake camera once" )
        sm.game.bindChatCommand( "/camtoggle", {}, "cl_onChatCommand", "Toggles the normal camera" )
        sm.game.bindChatCommand( "/alert", {}, "cl_onChatCommand", "Manually displays the initial alert" )
        sm.game.bindChatCommand( "/zoom", { { "number" } }, "cl_onChatCommand", "Manually sets the camera's zoom(higher number = less zoom)" )
    end
end

function Game:cl_onChatCommand( params )
    SurvivalGame.cl_onChatCommand( self, params )
    if params[1] == "/recam" then
        local camOffset = sm.localPlayer.getPlayer():getCharacter():getDirection() / self.antiZoom
        camOffset.z = camOffset.z / 1.5
        local eyeRPos = sm.localPlayer.getPlayer():getCharacter():getTpBonePos("jnt_right_eye") --jnt_right_eye
        sm.camera.setCameraState(3)
        sm.camera.setPosition(eyeRPos + camOffset)
        sm.camera.setDirection(sm.localPlayer.getPlayer():getCharacter():getDirection())
        sm.camera.setFov(70)
    elseif params[1] == "/camtoggle" then
        self.camEnabled = not self.camEnabled
        sm.camera.setCameraState(sm.camera.state.default)
    elseif params[1] == "/alert" then
        sm.gui.displayAlertText(AlertMessage, 15)
        sm.gui.chatMessage(AlertMessage)
    elseif params[1] == "/zoom" then
        self.antiZoom = math.max(1, params[2])
        sm.gui.chatMessage("Set zoom to "..self.antiZoom)
    end
end
