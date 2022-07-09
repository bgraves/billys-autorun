
--[[
Walking State Details
    1. Movement key pressed......walking = false
    2. 1st tick after keypress...walking = false
    3. 2nd tick after keypress...walking = true
--]]

local DISABLED = 0
local STATIONARY = 1
local WAIT_A_TICK = 2
local CHECK_WALKING_STATE = 3
local AUTORUNNING = 4

local flags = {
    feature_toggled = false,
    movekey_pressed = false,
    stopkey_pressed = false,
}

local function copy(tbl)
    local clone = {}
    for key, value in pairs(tbl) do
        clone[key] = value
    end
    return clone
end

local state = {
    mode = STATIONARY,
    autorun_direction = nil,
}
local prev_state = copy(state)

-- hardcoding player_index; it'll only work in single player
local player_index = 1
local function on_tick(event)
    local player = game.get_player(player_index)
    local next_mode = nil
    if state.mode == DISABLED then
        if flags.feature_toggled then
            game.print('Autorun enabled')
            if player.walking_state.walking then
                state.mode = AUTORUNNING
                state.autorun_direction = player.walking_state.direction
            else
                state.mode = STATIONARY
                state.autorun_direction = nil
            end
        else
            state.mode = DISABLED
        end
    elseif state.mode == STATIONARY then
        prev_state = copy(state)
        if flags.feature_toggled then
            state.mode = DISABLED
            state.autorun_direction = nil
        elseif flags.movekey_pressed then
            state.mode = WAIT_A_TICK
        elseif player.mining_state.mining then
            state.mode = WAIT_A_TICK
        else
            state.mode = STATIONARY
        end
    elseif state.mode == WAIT_A_TICK then
        if flags.feature_toggled then
            state.mode = DISABLED
            state.autorun_direction = nil
        elseif flags.movekey_pressed then
            state.mode = WAIT_A_TICK
        elseif player.mining_state.mining then
            state.mode = WAIT_A_TICK
        else
            state.mode = CHECK_WALKING_STATE
        end
    elseif state.mode == CHECK_WALKING_STATE then
        if flags.feature_toggled then
            state.mode = DISABLED
            state.autorun_direction = nil
        elseif flags.movekey_pressed then
            state.mode = WAIT_A_TICK
        elseif player.mining_state.mining then
            state.mode = WAIT_A_TICK
        elseif not player.walking_state.walking then
            state = copy(prev_state)
        else
            state.mode = AUTORUNNING
            state.autorun_direction = player.walking_state.direction
        end
    elseif state.mode == AUTORUNNING then
        prev_state = copy(state)
        player.walking_state = {
            walking = true,
            direction = state.autorun_direction,
        }
        if flags.feature_toggled then
            state.mode = DISABLED
            state.autorun_direction = nil
        elseif flags.movekey_pressed then
            state.mode = WAIT_A_TICK
        elseif player.mining_state.mining then
            state.mode = WAIT_A_TICK
        elseif flags.stopkey_pressed then
            state.mode = STATIONARY
            state.autorun_direction = nil
        else
            state.mode = AUTORUNNING
        end
    else
        game.print('Autorun reached invalid state')
        state.mode = DISABLED
        state.autorun_direction = nil
    end
    for flag in pairs(flags) do
        flags[flag] = false
    end
end

local function set_flag(flag)
    return function ()
         flags[flag] = true
    end
end

script.on_event(defines.events.on_tick, on_tick)
script.on_event('toggle-autorun', set_flag('feature_toggled'))
script.on_event('stop-running', set_flag('stopkey_pressed'))
local movekeys = {
    'move-up',
    'move-down',
    'move-left',
    'move-right',
}
for _, movekey in ipairs(movekeys) do
    script.on_event(movekey, set_flag('movekey_pressed'))
end

