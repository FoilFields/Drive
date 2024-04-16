LogBook = class()

function LogBook.server_onCreate( self )
end

function LogBook.client_onUpdate( self, dt )
end

function LogBook.client_canEquip( _ )
	return false
end

function LogBook.client_onEquip( self )
end

function LogBook.client_onUnequip( self )
end
