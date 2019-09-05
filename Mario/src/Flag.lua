--[[
    GD50
    Super Mario Bros. Remake

    -- Flag Class --

    Franklin Ader
    adereinstein1@gmail.com
]]

Flag = Class{__includes = Entity}

function Flag:init(def)
    self.FlagColor = def.FlagColor
    Entity.init(self, def)
    self.onDrag = def.onDrag
end

function Flag:render()
    --self.stateMachine:render()
    love.graphics.draw(gTextures[self.texture], gFrames[self.texture][self.currentAnimation:getCurrentFrame() + 3 * ((3 * (self.FlagColor - 1)) + 1 - 1)], 
    self.x, self.y)
end