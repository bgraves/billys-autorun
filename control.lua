
local function on_init()
    global.autorun_direction = nil
    global.movekeys = {}
    global.enable = false
end

local direction_by_xy = {[-1]={}, [0]={}, [1]={}}
direction_by_xy[ 0][ 1] = defines.direction.north 
direction_by_xy[ 0][-1] = defines.direction.south 
direction_by_xy[ 1][ 0] = defines.direction.east 
direction_by_xy[-1][ 0] = defines.direction.west 
direction_by_xy[ 1][ 1] = defines.direction.northeast 
direction_by_xy[-1][ 1] = defines.direction.northwest 
direction_by_xy[ 1][-1] = defines.direction.southeast 
direction_by_xy[-1][-1] = defines.direction.southwest 

local function get_direction_from_movekeys(movekeys)
    local x, y = 0, 0
    for movekey in pairs(movekeys) do
        if movekey == 'move-up' then
            y = y + 1
        elseif movekey == 'move-down' then
            y = y - 1
        elseif movekey == 'move-left' then
            x = x - 1
        elseif movekey == 'move-right' then
            x = x + 1
        end
    end
    return direction_by_xy[x][y]
end

local player_index = 1
local function on_tick()
    -- needed for migration
    if global.movekeys == nil then
        global.movekeys = {}
    end
    local input_direction = get_direction_from_movekeys(global.movekeys)
    if input_direction then
        if global.autorun_direction == input_direction then
            global.autorun_direction = nil
        else
            global.autorun_direction = input_direction
        end
    end
    local player = game.get_player(player_index)
    if global.enable and global.autorun_direction and not input_direction then
        player.walking_state = {
            walking = true,
            direction = player.walking_state.direction,
        }
    end
    global.movekeys = {}
end

local function toggle_autorun()
    global.enable = not global.enable
    if global.enable then
        local player = game.get_player(player_index)
        -- this helps with the case where we enable while already moving
        if player.walking_state.walking then
            global.autorun_direction = player.walking_state.direction
        end
        game.print('Autorun enabled.')
    else
        game.print('Autorun disabled.')
    end
end

local function flag_movekey(event)
    global.movekeys[event.input_name] = true
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

