
--[[
Response of player.walking_state
    1. Movement key pressed......walking = false
    2. 1st tick after keypress...walking = false
    3. 2nd tick after keypress...walking = true
--]]

--[[
mode descriptions
    DISABLED: autorun feature is disabled and all movement is normal/non-latching
    STATIONARY: feature enabled but character is not moving
    WAIT_A_TICK: some trigger received which will necessitate checking walking state on next tick
    CHECK_WALKING_STATE: if walking, latch that movement; else roll back to previous state before trigger
    AUTORUNNING: keep moving in latched direction until some other trigger received
--]]
local modes = {
    DISABLED            = 0,
    STATIONARY          = 1,
    WAIT_A_TICK         = 2,
    CHECK_WALKING_STATE = 3,
    AUTORUNNING         = 4,
}

-- flags are set true by an async event and then reset to false after every tick
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
    mode = modes.DISABLED,
    autorun_direction = nil,
}
local rollback_state = copy(state)

local function common_conditionals(player)
    -- common_conditionals is a handful of state transition logic which is
    -- shared by several modes
    local some_condition_met = true
    if flags.feature_toggled then
        game.print('Autorun disabled')
        state.mode = modes.DISABLED
        state.autorun_direction = nil
    elseif flags.movekey_pressed then
        state.mode = modes.WAIT_A_TICK
    elseif player.mining_state.mining then
        -- Movement is disabled while mining, but if the user presses a movekey
        -- while mining and holds it as mining finishes, they should move in the
        -- desired direction. That means we need to wait a tick after mining
        -- finishes and then check how the player is moving.
        state.mode = modes.WAIT_A_TICK
    elseif flags.stopkey_pressed then
        state.mode = modes.STATIONARY
        state.autorun_direction = nil
    else
        some_condition_met = false
    end
    return some_condition_met
end

-- hardcoding player_index; this'll only work in single player
local player_index = 1
local function on_tick(event)
    local player = game.get_player(player_index)
    if state.mode == modes.DISABLED then
        if flags.feature_toggled then
            game.print('Autorun enabled')
            if player.walking_state.walking then
                state.mode = modes.AUTORUNNING
                state.autorun_direction = player.walking_state.direction
            else
                state.mode = modes.STATIONARY
                state.autorun_direction = nil
            end
        else
            state.mode = modes.DISABLED
        end
    elseif state.mode == modes.STATIONARY then
        rollback_state = copy(state)
        if common_conditionals(player) then
            -- taken care of in common_conditionals
        else
            state.mode = modes.STATIONARY
        end
    elseif state.mode == modes.WAIT_A_TICK then
        if common_conditionals(player) then
            -- taken care of in common_conditionals
        else
            state.mode = modes.CHECK_WALKING_STATE
        end
    elseif state.mode == modes.CHECK_WALKING_STATE then
        if common_conditionals(player) then
            -- taken care of in common_conditionals
        elseif not player.walking_state.walking then
            -- whatever triggered this modes.CHECK_WALKING_STATE didn't result in
            -- movement, so roll back to the previous terminal state (either
            -- modes.STATIONARY or modes.AUTORUNNING)
            state = copy(rollback_state)
        else
            state.mode = modes.AUTORUNNING
            state.autorun_direction = player.walking_state.direction
        end
    elseif state.mode == modes.AUTORUNNING then
        rollback_state = copy(state)
        -- this is what actually causes the player to autorun
        player.walking_state = {
            walking = true,
            direction = state.autorun_direction,
        }
        if common_conditionals(player) then
            -- taken care of in common_conditionals
        else
            state.mode = modes.AUTORUNNING
        end
    else
        game.print('Autorun reached invalid state')
        state.mode = modes.DISABLED
        state.autorun_direction = nil
    end
    for flag in pairs(flags) do
        flags[flag] = false
    end
end

-- returns a function handle which will set the specified flag when called
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

