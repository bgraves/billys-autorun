
--[[
Walking State Details
    1. Movement key pressed......walking = false
    2. 1st tick after keypress...walking = false
    3. 2nd tick after keypress...walking = true
--]]

local OFF = 0
local MOVEKEY_PRESSED = 1
local READY = 2
local ACTIVE = 3

local enable = false

local function copy(tbl)
    local clone = {}
    for key, value in pairs(tbl) do
        clone[key] = value
    end
    return clone
end

local state = {
    mode = OFF,
    autorun_direction = nil,
}
local prev_state = copy(state)

-- hardcoding player_index so it'll only work in single player
local player_index = 1
local function on_tick(event)
    local player = game.get_player(player_index)
    if state.mode == OFF then
        -- we maintain a fresh prev_state only in OFF and ACTIVE modes
        prev_state = copy(state)
    elseif state.mode == MOVEKEY_PRESSED then
        -- this mode is just to skip the 1st tick after a movekey is pressed since the player.walking_state won't reflect the input until the next tick
        state.mode = READY
    elseif state.mode == READY then
        if not player.walking_state.walking then
            -- this should happen when in a menu which disables or hijacks the movekeys
            state = copy(prev_state)
        elseif state.autorun_direction == player.walking_state.direction then
            -- autorun is canceled by moving in the same direction as autorun
            state.mode = OFF
            state.autorun_direction = nil
        else
            state.mode = ACTIVE
            state.autorun_direction = player.walking_state.direction
        end
    elseif state.mode == ACTIVE then
        -- we maintain a fresh prev_state only in OFF and ACTIVE modes
        prev_state = copy(state)
        player.walking_state = {
            walking = true,
            direction = player.walking_state.direction,
        }
    end
end

local function disable_autorun()
    enable = false
    state.mode = OFF
    state.autorun_direction = nil
    game.print('Autorun disabled.')
end

local function enable_autorun()
    enable = true
    local player = game.get_player(player_index)
    if player.walking_state.walking then
        state.mode = ACTIVE
        state.autorun_direction = player.walking_state.direction
    else
        state.mode = OFF
        state.autorun_direction = nil
    end
    game.print('Autorun enabled.')
end

local function toggle_autorun()
    if enable then
        disable_autorun()
    else
        enable_autorun()
    end
end

local function on_movekey(event)
    local player = game.get_player(player_index)
    if enable then
        state.mode = MOVEKEY_PRESSED
    end
end

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

