--[[
    GD50
    Super Mario Bros. Remake

    -- Flag falling animation Class --

    Franklin Ader
    adereinstein1@gmail.com
]]

FlagFallingState = Class{__includes = BaseState}

function FlagFallingState:init(flag, player)
    self.flag = flag
    self.player = player
    self.animation = Animation {
        frames = {3},
        interval = 0.5
    }
    self.flag.currentAnimation = self.animation
end

function FlagFallingState:update(dt)
    self.flag.currentAnimation:update(dt)
    Timer.tween(2, {
        [self.flag] = {y = (7 - BLOCK_HEIGHT - 2) * TILE_SIZE}
    })
    Timer.update(dt)
end