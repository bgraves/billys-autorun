
--[[
went through quite a few iterations of this
in the end it works like this:
    1. a movement key is pressed
    2. wait a tick and see how the player moves
    3. latch that movement if it's different than our existing autorun direction
the reason this was difficult is because there's no indication of key-up events
that means it's tough to tell if the player is holding 2 keys simultaneously
or if they've already release the first key
for this reason we have to rely on the player movement direction
--]]

-- movement key pressed......walking = false
-- 1st tick after keypress...walking = false
-- 2nd tick after keypress...walking = true

local OFF = 0
local MOVEKEY_PRESSED = 1
local READY = 2
local ACTIVE = 3
local function on_init()
    global.autorun_direction = nil
    global.enable = false
    global.state = OFF
end

local player_index = 1
local function on_tick()
    local player = game.get_player(player_index)
    if global.state == OFF then
        -- do nothing
    elseif global.state == MOVEKEY_PRESSED then
        global.state = READY
    elseif global.state == READY then
        if global.autorun_direction == player.walking_state.direction then
            global.state = OFF
            global.autorun_direction = nil
        else
            global.state = ACTIVE
            global.autorun_direction = player.walking_state.direction
        end
    elseif global.state == ACTIVE then
        player.walking_state = {
            walking = true,
            direction = player.walking_state.direction,
        }
    end
end

local function disable_autorun()
    global.enable = false
    global.state = OFF
    global.autorun_direction = nil
    game.print('Autorun disabled.')
end

local function enable_autorun()
    global.enable = true
    local player = game.get_player(player_index)
    if player.walking_state.walking then
        global.state = ACTIVE
        global.autorun_direction = player.walking_state.direction
    else
        global.state = OFF
        global.autorun_direction = nil
    end
    game.print('Autorun enabled.')
end

local function toggle_autorun()
    if global.enable then
        disable_autorun()
    else
        enable_autorun()
    end
end

local function on_movekey(event)
    if global.enable then
        global.state = MOVEKEY_PRESSED
    end
end

script.on_init(on_init)
script.on_event(defines.events.on_tick, on_tick)
script.on_event('toggle-autorun', toggle_autorun)
local movekeys = {
    'move-up',
    'move-down',
    'move-left',
    'move-right',
}
for _, movekey in ipairs(movekeys) do
    script.on_event(movekey, on_movekey)
end

