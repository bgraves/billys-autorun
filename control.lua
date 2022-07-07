
local function on_init()
    global.movekey = false
    global.autorun = false
end

local player_index = 1
local function on_tick()
    if global.autorun and not global.movekey then
        player = game.get_player(player_index)
        player.walking_state = {
            walking = true,
            direction = player.walking_state.direction,
        }
        game.print(player.walking_state.direction)
    end
    global.movekey = false
end

local function disable_autorun()
    global.autorun = false
end

local function toggle_autorun()
    global.autorun = not global.autorun
    game.print('toggle-autorun')
end

local function flag_movekey()
    global.movekey = true
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
    script.on_event(movekey, flag_movekey)
end
