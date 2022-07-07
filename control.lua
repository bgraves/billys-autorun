
local function on_init()
    global.inputs = {}
    global.autorun = false
end

local function on_input(event)
    global.inputs[event.input_name] = true
end

local xy2direction = {[-1]={}, [0]={}, [1]={}}
xy2direction[ 0][ 1] = defines.direction.north
xy2direction[ 0][-1] = defines.direction.south
xy2direction[ 1][ 0] = defines.direction.east
xy2direction[-1][ 0] = defines.direction.west
xy2direction[ 1][ 1] = defines.direction.northeast
xy2direction[-1][ 1] = defines.direction.northwest
xy2direction[ 1][-1] = defines.direction.southeast
xy2direction[-1][-1] = defines.direction.southwest

local player_index = 1
local function on_tick()
    local inputs = global.inputs
    global.inputs = {}
    for input in pairs(inputs) do
        game.print(input)
    end
    if inputs['toggle-autorun'] then
        global.autorun = not global.autorun
    end
    if not global.autorun then
        return
    end
    local x, y = 0, 0
    for input in pairs(inputs) do
        if input == 'move-up' then
            y = 1
        elseif input == 'move-down' then
            y = -1
        elseif input == 'move-left' then
            x = -1
        elseif input == 'move-right' then
            x = 1
        end
    end
    player = game.get_player(player_index)
    xy2direction[0][0] = player.walking_state.direction
    player.walking_state = {
        walking = true,
        direction = xy2direction[x][y],
    }
end

local function disable_autorun()
    global.autorun = false
end

script.on_init(on_init)
script.on_event(defines.events.on_tick, on_tick)
local input_events = {
    'move-up',
    'move-down',
    'move-left',
    'move-right',
    'toggle-autorun',
}
for _, input_event in ipairs(input_events) do
    script.on_event(input_event, on_input)
end
