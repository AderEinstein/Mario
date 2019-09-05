--[[
    GD50
    Super Mario Bros. Remake

    -- LevelMaker Class --

    Franklin Ader
    adereinstein1@langara.ca
]]

LevelMaker = Class{}

function LevelMaker.generate(width, height, FlagColor)
    local tiles = {}
    local entities = {}
    local objects = {}

    local tileID = TILE_ID_GROUND
    
    -- whether we should draw our tiles with toppers
    local topper = true
    local tileset = math.random(20)
    local topperset = math.random(20)

    -- insert blank tables into tiles for later access
    for x = 1, height do
        table.insert(tiles, {})
    end

    -- References to previous block created as we iterate over our world below
    local previousBlockX = nil
    local previousBlockY = 4
    local keyInserted = false
    local lockedBlockInserted = false

    -- column by column generation instead of row; sometimes better for platformers
    for x = 1, width do
        local tileID = TILE_ID_EMPTY

        -- lay out the empty space
        for y = 1, 6 do
            table.insert(tiles[y],
                Tile(x, y, tileID, nil, tileset, topperset))
        end

        -- chance to just be emptiness
        if math.random(7) == 1 then
            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, nil, tileset, topperset))
            end
            -- Ground Here for flag
            if (x == width - 1) then
                tileID = TILE_ID_GROUND
                for y = 7, height do
                    table.insert(tiles[y],
                        Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
                end
            end 
        else
            tileID = TILE_ID_GROUND

            local blockHeight = 4

            -- generate ground where it's not completely empty
            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end

            --Pillar here
            if x == width - 1 then
                LevelMaker.generatePillar (x, tileID, topper, tileset, topperset, objects, tiles, true)
                goto continue
            end
                
            -- chance to generate a pillar
            if math.random(8) == 1 then
            -- If we've generated a pillar on this column, we wanna elevate the height of any block created aswell 
            blockHeight = 2
            LevelMaker.generatePillar (x, tileID, topper, tileset, topperset, objects, tiles, true)
        
            -- chance to generate bushes
            elseif math.random(8) == 1 then
                table.insert(objects,
                    GameObject {
                        texture = 'bushes',
                        x = (x - 1) * TILE_SIZE,
                        y = (6 - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                        collidable = false
                    }
                )
            end

            -- Insert locked bloc before tile 80
            if x == (width - 20) and not lockedBlockInserted then
                LevelMaker.insertLockedBlock(objects, x, blockHeight, FlagColor) 
                lockedBlockInserted = true
            end
            -- chance to spawn a block
            if math.random(10) == 1 then

                previousBlockX = x
                previousBlockY = blockHeight
                
                -- 1/3 chance of inserting a locked block instead of a regular block
                if not lockedBlockInserted and math.random(3) == 1 then
                    LevelMaker.insertLockedBlock(objects, x, blockHeight, FlagColor)
                    lockedBlockInserted = true
                else -- Insert a regular Block
                    table.insert(objects,

                        -- jump block
                        GameObject {
                            texture = 'jump-blocks',
                            x = (x - 1) * TILE_SIZE,
                            y = (blockHeight - 1) * TILE_SIZE,
                            width = 16,
                            height = 16,

                            -- make it a random variant
                            frame = math.random(#JUMP_BLOCKS),
                            collidable = true,
                            hit = false,
                            solid = true,

                            -- collision function takes itself
                            onCollide = function(obj)
                                -- spawn a gem if we haven't already hit the block
                                if not obj.hit then

                                    -- chance to spawn gem, not guaranteed
                                    if math.random(5) == 1 then

                                        -- maintain reference so we can set it to nil
                                        local gem = GameObject {
                                            texture = 'gems',
                                            x = (x - 1) * TILE_SIZE,
                                            y = (blockHeight - 1) * TILE_SIZE - 4,
                                            width = 16,
                                            height = 16,
                                            frame = math.random(#GEMS),
                                            collidable = true,
                                            consumable = true,
                                            solid = false,

                                            -- gem has its own function to add to the player's score
                                            onConsume = function(player, object)
                                                gSounds['pickup']:play()
                                                player.score = player.score + 100
                                            end
                                        }
                                        
                                        -- make the gem move up from the block and play a sound
                                        Timer.tween(0.1, {
                                            [gem] = {y = (blockHeight - 2) * TILE_SIZE}
                                        })
                                        gSounds['powerup-reveal']:play()

                                        table.insert(objects, gem)
                                    end

                                    obj.hit = true
                                end

                                gSounds['empty-block']:play()
                            end
                        }
                    )
                end
                
            
            -- Spawn a key at an upset from a random block generated in our map to uplarge the 
            -- player to make the player work more in searching for it and having to jump to catch it
            elseif previousBlockX and not keyInserted then
                
                local distanceFromLastBlock = x - previousBlockX 
                if distanceFromLastBlock and distanceFromLastBlock <= 4 and distanceFromLastBlock >= 2  then
                    if math.random(5) == 1 then
                        keyInserted = true
                        local keyY = previousBlockY == 4 and 2 or 1
                        table.insert(objects,
                        
                        -- KEY
                        GameObject{
                            texture = 'keys_and_locks',
                            x = (x - 1) * TILE_SIZE,
                            y = (keyY - 1) * TILE_SIZE,
                            width = 16,
                            height = 16,
                            -- Selecting a random color 
                            frame = math.random(4),
                            collidable = true,
                            consumable = true,
                            solid = false,

                            onConsume = function(player, object)
                                gSounds['pickup']:play()
                                player.hasKey = true
                            end
                        }
                    )
                    end
                end 
            end

            if x == width - 10 and not keyInserted then
                keyInserted = true
                local keyY = previousBlockY == 4 and 2 or 1
                local keyX
                if previousBlockX then
                    keyX = math.random(2, 4) + previousBlockX
                else
                    keyX = math.random(2, 4) + x
                end

                table.insert(objects,
                
                -- KEY
                GameObject{
                    texture = 'keys_and_locks',
                    x = (keyX - 1) * TILE_SIZE,
                    y = (keyY - 1) * TILE_SIZE,
                    width = 16,
                    height = 16,
                    -- Selecting a random color 
                    frame = math.random(4),
                    collidable = true,
                    consumable = true,
                    solid = false,

                    onConsume = function(player, object)
                        gSounds['pickup']:play()
                        player.hasKey = true
                    end
                }
                )
            end
        ::continue::
        end
    end

    local map = TileMap(width, height)
    map.tiles = tiles
    
    return GameLevel(entities, objects, map)
end

function LevelMaker.insertLockedBlock(objects, x, blockHeight, FlagColor)
    table.insert(objects,
            
        -- LOCKED BLOCK
        GameObject{
            texture = 'keys_and_locks',
            x = (x - 1) * TILE_SIZE,
            y = (blockHeight - 1) * TILE_SIZE,
            width = 16,
            height = 16,
            -- Selecting a random color 
            frame = math.random(5, 8),
            collidable = true,
            consumable = false, -- Making our locked block consumable later will enable us to take it off the Game|levelMap once we've the key   
            hit = false,
            solid = true,
            breakable = true,

            -- Call back function - called when player in jump state collides with this block
            onCollide = function(obj, player)
                if player.hasKey then -- consumable component is activated for the locked block so 
                    obj.consumable = true
                    player.hasKey = false
                else
                    gSounds['empty-block']:play()
                end
            end,
            -- Play block-crash sound and generage a particle system when the brick is hit in possession of the key in the jumping state(The onCollide fn gets called only if the player is jumping).
            onConsume = function(object, levelObjects)
                local color = math.random(6)
                PSYSTEM:setColors(
                    PALETTE_COLORS[color].r,
                    PALETTE_COLORS[color].g,
                    PALETTE_COLORS[color].b,
                    255,
                    PALETTE_COLORS[color].r,
                    PALETTE_COLORS[color].g,
                    PALETTE_COLORS[color].b,
                    0
                )
                PSYSTEM:emit(64)
                gSounds['block-crash']:play()

                table.insert(
                    levelObjects,

                    -- A Pole
                    GameObject{
                        texture = 'poles',
                        x = (POLE_X - 1) * TILE_SIZE,
                        y = ((7 - 3) * TILE_SIZE) - POLE_LENGTH,
                        width = 16,
                        height = 48,
                        frame = FlagColor,
                    }
                )
                -- Flag Inserted as an Entity in PlayState
            end
        }
    )
end

function LevelMaker.generatePillar (x, tileID, topper, tileset, topperset, objects, tiles, collidable)
    -- chance to generate bush on pillar
    if math.random(8) == 1 then
        table.insert(objects,
            GameObject {
                texture = 'bushes',
                x = (x - 1) * TILE_SIZE,
                y = (4 - 1) * TILE_SIZE,
                width = 16,
                height = 16,
                
                -- select random frame from bush_ids whitelist, then random row for variance
                frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7
            }
        )
    end
    
    if collidable then 
        -- Pillar tiles
        tiles[5][x] = Tile(x, 5, tileID, topper, tileset, topperset)
        tiles[6][x] = Tile(x, 6, tileID, nil, tileset, topperset)
        tiles[7][x].topper = nil
    else
        local standTileID = 3
        -- Flag Stand
        tiles[5][x] = Tile(x, 5, standTileID, topper, tileset, topperset)
        tiles[6][x] = Tile(x, 6, standTileID, nil, tileset, topperset)
        tiles[7][x].topper = nil
        
    end
end

