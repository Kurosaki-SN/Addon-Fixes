_addon.name = 'KillTracker'
_addon.author = 'Kurosaki'
_addon.version = '1.7'
_addon.command = 'kt'

require('luau')
texts = require('texts')
config = require('config')

local defaults = {}
defaults.display = {
    pos = {x = 500, y = 500},
    text = {font = 'Consolas', size = 18, color = {alpha = 255, red = 255, green = 255, blue = 255}},
    bg = {alpha = 150, red = 0, green = 0, blue = 0},
    flags = {draggable = true}
}

local settings = config.load(defaults)
local kill_count = 0

local display_box = texts.new('Kills: 0', settings.display)
display_box:show()

-- Dynamic tracking logic
windower.register_event('incoming text', function(new, old, mode)
    local player = windower.ffxi.get_player()
    if not player then return end -- Safety check if player isn't loaded
    
    local player_name = player.name:lower()
    local clean_text = new:gsub('\7', ''):gsub('[\1-\31]', ''):lower()
    
    -- Checks for your current character's name + "defeats"
    if clean_text:contains(player_name) and clean_text:contains('defeats') then
        kill_count = kill_count + 1
        display_box:text('Kills: ' .. tostring(kill_count))
        
        if kill_count % 10 == 0 then
            windower.add_to_chat(207, 'KillTracker: ' .. kill_count .. ' kills reached.')
        end
    end
end)

-- Save position on drag-end
windower.register_event('mouse', function(type, x, y, delta, blocked)
    if type == 2 then 
        settings.display.pos.x = display_box:pos_x()
        settings.display.pos.y = display_box:pos_y()
        config.save(settings)
    end
end)

-- Reset command: //kt reset
windower.register_event('addon command', function(input, ...)
    if input == 'reset' then
        kill_count = 0
        display_box:text('Kills: 0')
    end
end)