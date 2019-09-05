--[[
    GD50
    Super Mario Bros. Remake

    -- PlayState Class --

    Franklin Ader
    adereinstein1@gmail.com
]]

PlayState = Class{__includes = BaseState}

function PlayState:init()
    self.camX = 0
    self.camY = 0
    self.FlagColor = math.random(4)
    self.levelLabelY = -70
    self.level = LevelMaker.generate(100, 10, self.FlagColor)
    self.tileMap = self.level.tileMap
    self.background = math.random(3)
    self.backgroundX = 0

    self.gravityOn = true
    self.gravityAmount = 6

    self.player = Player({
        x = 0, y = 0,
        width = 16, height = 20,
        texture = 'green-alien',
        stateMachine = StateMachine {
            ['idle'] = function() return PlayerIdleState(self.player) end,
            ['walking'] = function() return PlayerWalkingState(self.player) end,
            ['jump'] = function() return PlayerJumpState(self.player, self.gravityAmount, self.FlagColor) end,
            ['falling'] = function() return PlayerFallingState(self.player, self.gravityAmount) end
        },
        map = self.tileMap,
        level = self.level,
        levelNum = 1
    })

    self.player:changeState('falling')

    self:spawnEnemies()

     -- Unless we find a tile in the a column of the tile map, we shift the player's x until the column where we find the first tile to prevent him from falling into casm at the start of the game
    for x = 1, 100 do
        local breakOuter = false
        for y = 1, 10 do
            if self.tileMap.tiles[y][x].id == TILE_ID_GROUND then
                self.player.x = (x - 1) * TILE_SIZE
                breakOuter = true
            else
                self.player.x = TILE_SIZE * x
            end
        end
        if breakOuter then
            break
        end
    end
end

function PlayState:enter(params)
    self.transitionAlpha = 255

    -- Persist the score if comming from another Play State
    if params then
        self.player.score = self.player.score + params.score
        self.player.levelNum = params.levelNum
    end
      
    Timer.tween(3, {
        [self] = {transitionAlpha = 0}
    })

    Timer.tween(1, {
        [self] = {levelLabelY = VIRTUAL_HEIGHT / 2 - 8}
    })
    -- after that, pause for one second
    :finish(function()
        Timer.after(2, function()
        -- then, animate the label going down past the bottom edge
            Timer.tween(0.5, {
                [self] = {levelLabelY = VIRTUAL_HEIGHT + 30}
            })
        end)
    end)
    
end

function PlayState:update(dt)
    Timer.update(dt)

    -- remove any nils from pickups, etc.
    self.level:clear()

    -- update player and level
    self.player:update(dt)
    self.level:update(dt)

    -- constrain player X no matter which state
    if self.player.x <= 0 then
        self.player.x = 0
    elseif self.player.x > TILE_SIZE * self.tileMap.width - self.player.width then
        self.player.x = TILE_SIZE * self.tileMap.width - self.player.width
    end

    self:updateCamera()
  
end

function PlayState:render()
    love.graphics.push()
    love.graphics.draw(gTextures['backgrounds'], gFrames['backgrounds'][self.background], math.floor(-self.backgroundX), 0)

    love.graphics.draw(gTextures['backgrounds'], gFrames['backgrounds'][self.background], math.floor(-self.backgroundX),

        gTextures['backgrounds']:getHeight() / 3 * 2, 0, 
        1,
        -1)
    love.graphics.draw(gTextures['backgrounds'], gFrames['backgrounds'][self.background], math.floor(-self.backgroundX + 256), 0)
    love.graphics.draw(gTextures['backgrounds'], gFrames['backgrounds'][self.background], math.floor(-self.backgroundX + 256),
        gTextures['backgrounds']:getHeight() / 3 * 2, 0, 1, -1)
    
    -- translate the entire view of the scene to emulate a camera
    love.graphics.translate(-math.floor(self.camX), -math.floor(self.camY))
    
    self.level:render()
    
    self.player:render()
    love.graphics.pop()
    
    -- render score
    love.graphics.setFont(gFonts['medium'])
    love.graphics.setColor(0, 0, 0, 255)
    love.graphics.print(tostring(self.player.score), 5, 5)
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.print(tostring(self.player.score), 4, 4)

    -- Display the key at the top right edge of the screen if we've collected it
    if self.player.hasKey then
        love.graphics.draw(gTextures['keys_and_locks'], gFrames['keys_and_locks'][math.random(4)], 5, 18)
    end

    -- render Level # label and background rect
    --[[
    love.graphics.setColor(95, 205, 228, 200)
    love.graphics.rectangle('fill', 0, self.levelLabelY - 8, VIRTUAL_WIDTH, 48)
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.setFont(gFonts['large'])
    love.graphics.printf('Level ' .. self.player.levelNum,
        0, self.levelLabelY, VIRTUAL_WIDTH, 'center')
]]
    -- Render Transition Box
    love.graphics.setColor(255, 255, 255, self.transitionAlpha)
    love.graphics.rectangle('fill', 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
end

function PlayState:updateCamera()
    -- clamp movement of the camera's X between 0 and the map bounds - virtual width,
    -- setting it half the screen to the left of the player so they are in the center
    self.camX = math.max(0,
        math.min(TILE_SIZE * self.tileMap.width - VIRTUAL_WIDTH,
        self.player.x - (VIRTUAL_WIDTH / 2 - 8)))

    -- adjust background X to move a third the rate of the camera for parallax
    self.backgroundX = (self.camX / 3) % 256
end

--[[
    Adds a series of enemies to the level randomly.
]]
function PlayState:spawnEnemies()
    -- spawn snails in the level
    for x = 1, self.tileMap.width do

        -- flag for whether there's ground on this column of the level
        local groundFound = false

        for y = 1, self.tileMap.height do
            if not groundFound then
                if self.tileMap.tiles[y][x].id == TILE_ID_GROUND then
                    groundFound = true

                    -- random chance, 1 in 20
                    if math.random(20) == 1 then
                        
                        -- instantiate snail, declaring in advance so we can pass it into state machine
                        local snail
                        snail = Snail {
                            texture = 'creatures',
                            x = (x - 1) * TILE_SIZE,
                            y = (y - 2) * TILE_SIZE + 2,
                            width = 16,
                            height = 16,
                            lethal = true,
                            stateMachine = StateMachine {
                                ['idle'] = function() return SnailIdleState(self.tileMap, self.player, snail) end,
                                ['moving'] = function() return SnailMovingState(self.tileMap, self.player, snail) end,
                                ['chasing'] = function() return SnailChasingState(self.tileMap, self.player, snail) end
                            }
                        }
                        snail:changeState('idle', {
                            wait = math.random(5)
                        })

                        table.insert(self.level.entities, snail)
                    end
                end
            end
        end
    end
end