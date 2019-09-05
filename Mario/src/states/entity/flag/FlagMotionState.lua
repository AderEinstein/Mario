--[[
    GD50
    Super Mario Bros. Remake

    -- Flag motion animation Class --

    Franklin Ader
    adereinstein1@gmail.com
]]

FlagMotionState = Class{__includes = BaseState}

function FlagMotionState:init(flag, player)
    self.flag = flag
    self.player = player
    self.animation = Animation {
        frames = {1, 2},
        interval = 0.5
    }
    self.flag.currentAnimation = self.animation
end

function FlagMotionState:update(dt)
    self.flag.currentAnimation:update(dt)
end