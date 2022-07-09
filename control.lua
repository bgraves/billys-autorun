
--[[
Walking State Details
    1. Movement key pressed......walking = false
    2. 1st tick after keypress...walking = false
    3. 2nd tick after keypress...walking = true
--]]

local OFF = 0
local WAIT_A_TICK = 1
local CHECK_WALKING_STATE = 2
local AUTORUNNING = 3

local enable = false
local same_direction_cancels = false

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

-- hardcoding player_index; it'll only work in single player
local player_index = 1
local function on_tick(event)
    local player = game.get_player(player_index)
    if player.mining_state.mining then
        -- When mining, movement is disabled. If you push down movement keys during the mining and hold them until mining finishes, we want to move according to those keys. The only way to do that is to hand over control to the normal movement for a tick
        state.mode = WAIT_A_TICK
    end
    if state.mode == OFF then
        -- we maintain a fresh prev_state only in OFF and AUTORUNNING modes
        prev_state = copy(state)
    elseif state.mode == WAIT_A_TICK then
        -- this mode is just to skip the 1st tick after a movekey is pressed since the player.walking_state won't reflect the input until the next tick
        state.mode = CHECK_WALKING_STATE
    elseif state.mode == CHECK_WALKING_STATE then
        if not player.walking_state.walking then
            -- this should happen when in a menu which disables or hijacks the movekeys
            state = copy(prev_state)
        elseif same_direction_cancels and state.autorun_direction == player.walking_state.direction then
            -- autorun is canceled by moving in the same direction as autorun
            state.mode = OFF
            state.autorun_direction = nil
        else
            state.mode = AUTORUNNING
            state.autorun_direction = player.walking_state.direction
        end
    elseif state.mode == AUTORUNNING then
        -- we maintain a fresh prev_state only in OFF and AUTORUNNING modes
        prev_state = copy(state)
        -- important to use state.autorun_direction here. The problem with player.walking_state.direction is that when mining, it can be different from the direction we were actually moving
        player.walking_state = {
            walking = true,
            direction = state.autorun_direction,
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
        state.mode = AUTORUNNING
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

local function stop_running()
    state.mode = OFF
    state.autorun_direction = nil
end

local function on_movekey(event)
    local player = game.get_player(player_index)
    if enable then
        state.mode = WAIT_A_TICK
    end
end

script.on_event(defines.events.on_tick, on_tick)
script.on_event('toggle-autorun', toggle_autorun)
script.on_event('stop-running', stop_running)
local movekeys = {
    'move-up',
    'move-down',
    'move-left',
    'move-right',
}
for _, movekey in ipairs(movekeys) do
    script.on_event(movekey, on_movekey)
end

