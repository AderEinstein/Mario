--[[
    GD50
    -- Super Mario Bros. Remake --

    Franklin Ader
    adereinstein1@langara.ca
]]

GameObject = Class{}

function GameObject:init(def)
    self.x = def.x
    self.y = def.y
    self.texture = def.texture
    self.width = def.width
    self.height = def.height
    self.frame = def.frame
    self.solid = def.solid
    self.collidable = def.collidable
    self.consumable = def.consumable
    self.onCollide = def.onCollide
    self.onConsume = def.onConsume
    self.hit = def.hit
    self.breakable = def.breakable 
    self.pSystem = def.pSystem
end

function GameObject:collides(target)
    return not (target.x > self.x + self.width or self.x > target.x + target.width or
            target.y > self.y + self.height or self.y > target.y + target.height)
end

function GameObject:update(dt)

end

function GameObject:render()
    if self.pSystem then
        love.graphics.draw(PSYSTEM, self.x + 8, self.y + 8)
    else
        love.graphics.draw(gTextures[self.texture], gFrames[self.texture][self.frame], self.x, self.y)
    end
end