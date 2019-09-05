--[[
    GD50
    Super Mario Bros. Remake

    Franklin Ader
    adereinstein1@gmail.com
]]

PlayerJumpState = Class{__includes = BaseState}

function PlayerJumpState:init(player, gravity, FlagColor)
    self.player = player
    self.gravity = gravity
    self.animation = Animation {
        frames = {3},
        interval = 1
    }
    self.player.currentAnimation = self.animation
    self.FlagColor = FlagColor
end

function PlayerJumpState:enter(params)
    gSounds['jump']:play()
    self.player.dy = PLAYER_JUMP_VELOCITY
end


function PlayerJumpState:update(dt)
    self.player.currentAnimation:update(dt)
    self.player.dy = self.player.dy + self.gravity
    self.player.y = self.player.y + (self.player.dy * dt)

    -- go into the falling state when y velocity is positive
    if self.player.dy >= 0 then
        self.player:changeState('falling')
    end

    self.player.y = self.player.y + (self.player.dy * dt)

    -- look at two tiles above our head and check for collisions; 3 pixels of leeway for getting through gaps
    local tileLeft = self.player.map:pointToTile(self.player.x + 3, self.player.y)
    local tileRight = self.player.map:pointToTile(self.player.x + self.player.width - 3, self.player.y)

    -- if we get a collision up top, go into the falling state immediately
    if (tileLeft and tileRight) and (tileLeft:collidable() or tileRight:collidable()) then
        self.player.dy = 0
        self.player:changeState('falling')

    -- else test our sides for blocks
    elseif love.keyboard.isDown('left') then
        self.player.direction = 'left'
        self.player.x = self.player.x - PLAYER_WALK_SPEED * dt
        self.player:checkLeftCollisions(dt)
    elseif love.keyboard.isDown('right') then
        self.player.direction = 'right'
        self.player.x = self.player.x + PLAYER_WALK_SPEED * dt
        self.player:checkRightCollisions(dt)
    end

    -- check if we've collided with any collidable game objects
    for k, object in pairs(self.player.level.objects) do
        if object:collides(self.player) then
            if object.solid then
                object.onCollide(object, self.player)
                self.player.y = object.y + object.height
                self.player.dy = 0
                self.player:changeState('falling')
            end
            if object.consumable then
                object.onConsume(self.player, self.player.level.objects)
                if object.breakable then
                    table.insert(self.player.level.objects,
                        --PSYSTEM
                        GameObject{
                            x = object.x,
                            y = object.y,
                            width = object.width,
                            height = object.height,
                            pSystem = true
                        }
                    )
                        --FLAG 
                    self.flag = Flag{
                        texture = 'flags',
                        x = (POLE_X - 1) * TILE_SIZE + 8,
                        y = ((7 - 3) * TILE_SIZE) - POLE_LENGTH,
                        width = 16, height = 16,
                        stateMachine = StateMachine {
                            ['motion'] = function() return FlagMotionState(self.flag, self.player) end,
                            ['falling'] = function() return FlagFallingState(self.flag, self.player) end
                        },
                        --level = self.level,
                        FlagColor = self.FlagColor,
                        flag = true,
                        onDrag = function()
                            gSounds['flag-drag']:play()
                            self.flag:changeState('falling')
                            self.player.levelNum = self.player.levelNum + 1
                            Timer.after(0.5, 
                                function()
                                    gStateMachine:change('play', 
                                        {score = self.player.score,
                                         levelNum = self.player.levelNum
                                        })
                                end
                            )
                        end
                    }
                    self.flag:changeState('motion')
                    table.insert(self.player.level.entities, self.flag)

                end
                table.remove(self.player.level.objects, k)
            end
        end
    end

    -- check if we've collided with any entities and die if so
    for k, entity in pairs(self.player.level.entities) do
        if entity:collides(self.player) then
            if entity.lethal then
                gSounds['death']:play()
                gStateMachine:change('start')
            elseif entity.flag then
                entity.onDrag()
            end
        end
    end
end