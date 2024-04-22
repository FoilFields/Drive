dofile("$CONTENT_DATA/Scripts/Game/CrapCrateLoot.lua")

CrapCrate = class()

function CrapCrate:server_onMelee() 
  self:sv_open()
end

function CrapCrate:server_onExplosion() 
  self:sv_open()
end

function CrapCrate:server_onProjectile()
  self:sv_open()
end

function CrapCrate:sv_open() 
  local position = self.shape.getWorldPosition(self.shape)

  sm.effect.playEffect("Lootbox - Break", position)

  sm.shape.destroyShape(self.shape, 0)

  for i = 1, math.random(2, 4) do
    local angle = math.random() * math.pi * 2

    local vel = sm.vec3.new( 1, 4.0, 0.0 )
    vel = vel:rotateY(angle)

    local crap = GetRandomCrap()

    local params = { lootUid = crap.uid, lootQuantity = crap.stackSize }

    sm.projectile.shapeCustomProjectileAttack(params, sm.uuid.new("45209992-1a59-479e-a446-57140b605836"), 0, sm.vec3.new( 0, 0, 0 ), vel, self.shape, 0)
  end
end
