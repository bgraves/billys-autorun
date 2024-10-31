script.on_init(function()
    storage.info_by_player = {}
end)

--[[
Response of player.walking_state
    0. Movement key pressed......walking = false
    1. 1st tick after keypress...walking = false
    2. 2nd tick after keypress...walking = true
--]]

--[[
Mode Descriptions
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

-- flags (for each player) are set true by an async event and then reset to false after every tick
local init_flags = {
    feature_toggled = false,
    movekey_pressed = false,
    stopkey_pressed = false,
}

-- state is maintained for each player
local init_state = {
    mode = modes.DISABLED,
    autorun_direction = nil,
}

local function copy(tbl)
    local clone = {}
    for key, value in pairs(tbl) do
        clone[key] = value
    end
    return clone
end

-- set "dst" keys to same values as "src" keys (inplace)
local function update(dst, src)
    for key, value in pairs(src) do
        dst[key] = value
    end
end

local function common_conditionals(player, state, flags)
    -- common_conditionals is a handful of state transition logic which is
    -- shared by several modes
    local some_condition_met = true
    if flags.feature_toggled then
        player.print('Autorun disabled')
        state.mode = modes.DISABLED
        state.autorun_direction = nil
    elseif player.controller_type ~= defines.controllers.character then
        state.mode = modes.STATIONARY
        state.autorun_direction = nil
    elseif flags.stopkey_pressed then
        state.mode = modes.STATIONARY
        state.autorun_direction = nil
    elseif flags.movekey_pressed then
        state.mode = modes.WAIT_A_TICK
    elseif player.mining_state.mining then
        -- Movement is disabled while mining, but if the user presses a movekey
        -- while mining and holds it as mining finishes, they should move in the
        -- desired direction. That means we need to wait a tick after mining
        -- finishes and then check how the player is moving.
        state.mode = modes.WAIT_A_TICK
    else
        some_condition_met = false
    end
    return some_condition_met
end

local function on_tick_single(event, player, autorun_info)
    local state = autorun_info.state
    local rollback_state = autorun_info.rollback_state
    local flags = autorun_info.flags
    if state.mode == modes.DISABLED then
        if flags.feature_toggled then
            player.print('Autorun enabled')
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
        update(rollback_state, state)
        if common_conditionals(player, state, flags) then
            -- taken care of in common_conditionals
        else
            state.mode = modes.STATIONARY
        end
    elseif state.mode == modes.WAIT_A_TICK then
        if common_conditionals(player, state, flags) then
            -- taken care of in common_conditionals
        else
            state.mode = modes.CHECK_WALKING_STATE
        end
    elseif state.mode == modes.CHECK_WALKING_STATE then
        if common_conditionals(player, state, flags) then
            -- taken care of in common_conditionals
        elseif not player.walking_state.walking then
            -- whatever triggered this modes.CHECK_WALKING_STATE didn't result in
            -- movement, so roll back to the previous terminal state (either
            -- modes.STATIONARY or modes.AUTORUNNING)
            update(state, rollback_state)
        else
            state.mode = modes.AUTORUNNING
            state.autorun_direction = player.walking_state.direction
        end
    elseif state.mode == modes.AUTORUNNING then
        update(rollback_state, state)
        -- this is what actually causes the player to autorun
        if state.autorun_direction == nil then
            player.print('autorun_direction == nil')
        end
        player.walking_state = {
            walking = true,
            direction = state.autorun_direction,
        }
        if common_conditionals(player, state, flags) then
            -- taken care of in common_conditionals
        else
            state.mode = modes.AUTORUNNING
        end
    else
        player.print('Autorun reached invalid state')
        state.mode = modes.DISABLED
        state.autorun_direction = nil
    end
    for flag in pairs(flags) do
        flags[flag] = false
    end
end

local function on_tick(event)
    -- this handles when mod is added while game is in progress
    if storage.info_by_player == nil then
        storage.info_by_player = {}
    end
    local players_to_remove = {}
    for player_index, autorun_info in pairs(storage.info_by_player) do
        local player = game.get_player(player_index)
        if player == nil then
            table.insert(players_to_remove, player_index)
        else
            on_tick_single(event, player, autorun_info)
        end
    end
    for _, player_index in ipairs(players_to_remove) do
        storage.info_by_player[player_index] = nil
    end
end

-- returns a function handle which will set the specified flag when called
local function set_flag(flag)
    return function (event)
        local player_index = event.player_index
        if storage.info_by_player[player_index] == nil then
            storage.info_by_player[player_index] = {
                state = copy(init_state),
                rollback_state = copy(init_state),
                flags = copy(init_flags),
            }
        end
        storage.info_by_player[player_index].flags[flag] = true
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

