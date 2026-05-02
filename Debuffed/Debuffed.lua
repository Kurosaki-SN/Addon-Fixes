_addon.name = 'Debuffed'
_addon.author = 'original: Auk, improvements and additions: Kenshi'
_addon.version = '1.5'

require('luau')
packets = require('packets')
texts = require('texts')
images = require('images') -- Added images library

defaults = {}
-- ... (keep all the defaults) ...

-- STOPS PROFILE CREATION: This disables the auto-save feature, 
-- forcing the addon to strictly read your <global> settings and never write new ones.
config.save = function() end 

settings = config.load(defaults)

base_pos_x = settings.pos.x
base_pos_y = settings.pos.y

-- Remove the single 'box' text object. 
-- Instead, we will store individual icons and timers for active debuffs.
ui_icons = {}
ui_timers = {}
icon_size = 20 -- Adjust this to match your .png dimensions

frame_time = 0
debuffed_mobs = {}

helixes = S{278,279,280,281,282,283,284,285,
	885,886,887,888,889,890,891,892}

ja_spells = S{496,497,498,499,500,501}

step_duration = {}

erase_abilities = S{2370, 2571, 2714, 2718, 2775, 2831}

partial_erase_abilities = S{1245, 1273}

debuffs = {
	[2] = S{98,253,259,273,274,576,584,598,678}, --Sleep I & II
	[3] = S{220,221,225,350,351,513,716}, --Poison
	[4] = S{58,80,341,644,704}, --Paralyze
	[5] = S{254,276,347,348,621}, --Blind
	[6] = S{59,582,687,727}, --Silence
	[7] = S{255,365,722}, --Break
	[10] = S{252,616}, --Stun
	[11] = S{258,531}, --Bind
	[12] = S{216,217,708}, --Gravity
	[13] = S{56,79,344,345,548,703}, --Slow
	[19] = S{98,259,274,576,598}, --sleep ii
	[21] = S{286,884}, ----addle
	[28] = S{575,720,738,746}, --terror
	[31] = S{588,682}, --plague
	[128] = S{235}, --burn
	[129] = S{236,535}, --frost
	[130] = S{237}, --choke
	[131] = S{238}, --rasp
	[132] = S{239}, --shock
	[133] = S{240,705}, --drown
	[136] = S{606}, --str down
	[138] = S{537}, --vit down
	[140] = S{572}, -- int down
	[146] = S{524,699}, --accuracy down
	[147] = S{319,651,659,726}, --attack down
	[148] = S{610,841,842,882}, --Evasion Down
	[149] = S{561,633,651,717,728}, -- defense down
	[156] = S{112,612,707,725}, --Flash
	[167] = S{633,656}, --Magic Def. Down
	[168] = S{508}, --inhibit TP
	[192] = S{368,369,370,371,372,373,374,375}, --requiem
	[193] = S{376,463}, --lullaby
	[194] = S{421,422,423}, --elegy
	[217] = S{454,455,456,457,458,459,460,461,871,872,873,874,875,876,877,878}, --threnodies
	[223] = S{472}, --nocturne
	[242] = 242, --Absorb ACC
	[266] = 266, --Absorb STR
	[267] = 267, --Absorb DEX
	[268] = 268, --Absorb VIT
	[269] = 269, --Absorb AGI
	[270] = 270, --Absorb INT
	[271] = 271, --Absorb MND
	[272] = 272, --Absorb CHR
	[404] = S{843,844,883}, --Magic Evasion Down
	[597] = S{879}, --inundation

}

hierarchy = {
    [134] = S{33,34,35,36,37,230,231,232}, -- Dia I, II, III and Diagas
	[134] = 60, -- Dia (Base duration, the script will update based on the spell cast)
    [135] = S{38,39,40,41,42,230,231,232}, -- Bio I, II, III and Biagas
	[135] = 60, -- Bio base duration
}

function apply_dot(target, spell)
	if not debuffed_mobs[target] then
		debuffed_mobs[target] = {}
	end

	local priority = 0
	local current = debuffed_mobs[target][134] or debuffed_mobs[target][135]
	if current then
		priority = hierarchy[current.name] or hierarchy[current]
	end
	
	local addTime = 0
	if windower.ffxi.get_player().main_job == "RDM" and windower.ffxi.get_player().main_job_level == 75 then addTime = 30 end -- add time for RDM group 2 5/5 merits in Enfeebling Duration

	if hierarchy[spell] > priority then
		if T{23,24,25,33}:contains(spell) then
			if spell == 23 then
				debuffed_mobs[target][134] = {name = spell, timer = os.clock() + 60 + addTime}
			elseif spell == 33 then
				debuffed_mobs[target][134] = {name = spell, timer = os.clock() + 60 + addTime}
			elseif spell == 24 then
				debuffed_mobs[target][134] = {name = spell, timer = os.clock() + 120 + addTime}
			else
				debuffed_mobs[target][134] = {name = spell, timer = os.clock() + 180 + addTime}
			end
			debuffed_mobs[target][135] = nil
		elseif T{230,231,232}:contains(spell) then
			debuffed_mobs[target][134] = nil
			if spell == 230 then
				debuffed_mobs[target][135] = {name = spell, timer = os.clock() + 60}
			elseif spell == 231 then
				debuffed_mobs[target][135] = {name = spell, timer = os.clock() + 120}
			else
				debuffed_mobs[target][135] = {name = spell, timer = os.clock() + 180}
			end
		end
	end
end

function apply_helix(target, spell)
	local addTime = 90
	if not debuffed_mobs[target] then
		debuffed_mobs[target] = {}
	end
	if windower.ffxi.get_player().main_job_level < 40 then
		addTime = 30
	elseif windower.ffxi.get_player().main_job_level < 60 then
		addTime = 60
	end
	debuffed_mobs[target][186] = {name = spell, timer = os.clock() + addTime}
end

ja_spells_names = {
	[496] = {
		[1] = 'Fire Damage + 5%',
		[2] = 'Fire Damage + 10%',
		[3] = 'Fire Damage + 15%',
		[4] = 'Fire Damage + 20%',
		[5] = 'Fire Damage + 25%',
		},
	[497] = {
		[1] = 'Ice Damage + 5%',
		[2] = 'Ice Damage + 10%',
		[3] = 'Ice Damage + 15%',
		[4] = 'Ice Damage + 20%',
		[5] = 'Ice Damage + 25%',
		},
	[498] = {
		[1] = 'Wind Damage + 5%',
		[2] = 'Wind Damage + 10%',
		[3] = 'Wind Damage + 15%',
		[4] = 'Wind Damage + 20%',
		[5] = 'Wind Damage + 25%',
		},
	[499] = {
		[1] = 'Earth Damage + 5%',
		[2] = 'Earth Damage + 10%',
		[3] = 'Earth Damage + 15%',
		[4] = 'Earth Damage + 20%',
		[5] = 'Earth Damage + 25%',
		},
	[500] = {
		[1] = 'Lightning Damage + 5%',
		[2] = 'Lightning Damage + 10%',
		[3] = 'Lightning Damage + 15%',
		[4] = 'Lightning Damage + 20%',
		[5] = 'Lightning Damage + 25%',
		},
	[501] = {
		[1] = 'Water Damage + 5%',
		[2] = 'Water Damage + 10%',
		[3] = 'Water Damage + 15%',
		[4] = 'Water Damage + 20%',
		[5] = 'Water Damage + 25%',
		},
}

function apply_ja_spells(target, spell)
	if not debuffed_mobs[target] then
		debuffed_mobs[target] = {}
	end
	
	local current = debuffed_mobs[target][1000]
	if current and current.name == spell then
		if ja_tier < 5 then
			ja_tier = current.tier + 1
		end
	else
		ja_tier = 1
		ja_timer = os.clock() + 60
	end
	
	debuffed_mobs[target][1000] = {name = spell, tier = ja_tier, timer = ja_timer}
end

function update_box()
    local target = windower.ffxi.get_mob_by_target('st') or windower.ffxi.get_mob_by_target('t')
    local active_effects = {}

    -- 1. Only process if we have a valid NPC target
    if target and target.valid_target and target.is_npc and (target.claim_id ~= 0 or target.spawn_type == 16) then
        local debuff_table = debuffed_mobs[target.id]

        if debuff_table then
            for effect_id, spell_data in pairs(debuff_table) do
                if spell_data then
                    if type(spell_data) == 'table' then
                        local remaining = spell_data.timer - os.clock()
                        if remaining >= 0 then
                            table.insert(active_effects, {id = effect_id, time = remaining})
                        else
                            debuff_table[effect_id] = nil
                        end
                    else
                        -- For debuffs without a timer (like Absorb spells)
                        table.insert(active_effects, {id = effect_id, time = nil})
                    end
                end
            end
        end
    end

    -- 2. Hide all elements so we can redraw from the current anchor
    for _, img in pairs(ui_icons) do img:hide() end
    for _, txt in pairs(ui_timers) do txt:hide() end

    -- 3. Draw the icons and single timers side-by-side
    for i, eff in ipairs(active_effects) do
        -- Limit to exactly 3 rows of 10 (30 debuffs maximum)
        if i > 30 then break end 

        local effect_id = eff.id

        -- Image Setup
        if not ui_icons[effect_id] then
            ui_icons[effect_id] = images.new()
            ui_icons[effect_id]:path(windower.windower_path .. 'addons/Debuffed/BuffIcons/' .. effect_id .. '.png')
            ui_icons[effect_id]:draggable(false)
        end

            ui_icons[effect_id]:size(icon_size, icon_size)

        -- Timer Setup
        if not ui_timers[effect_id] then
            ui_timers[effect_id] = texts.new()
            ui_timers[effect_id]:draggable(false)
            ui_timers[effect_id]:font(settings.text.font)
            ui_timers[effect_id]:size(settings.text.size)
            ui_timers[effect_id]:color(settings.text.red, settings.text.green, settings.text.blue)
            ui_timers[effect_id]:stroke_width(0)
            ui_timers[effect_id]:stroke_alpha(0)
            ui_timers[effect_id]:bg_alpha(0)
        end

        -- GRID POSITION MATH
        -- 'col' counts 0 to 9, then resets to 0 for the next row
        local col = (i - 1) % 10 
        -- 'row' stays 0 for the first 10, becomes 1 for the next 10, etc.
        local row = math.floor((i - 1) / 10) 

        -- Calculate X based on column (with 5 pixels padding between icons)
        local current_x = base_pos_x + (col * (icon_size + 5))
        
        -- Calculate Y based on row. 
        -- We add 15 extra pixels to the row height to leave room for the timer text.
        local current_y = base_pos_y + (row * (icon_size + 15)) 
        
        ui_icons[effect_id]:pos(current_x, current_y)
        ui_icons[effect_id]:show()

        if eff.time then
            ui_timers[effect_id]:pos(current_x, current_y + icon_size)
            ui_timers[effect_id]:text(string.format('%.0f', eff.time))
            ui_timers[effect_id]:show()
        end
    end
end

function inc_action(act)
	if act.category == 4 then
	
		local addTime = 0
		if windower.ffxi.get_player().main_job == "RDM" and windower.ffxi.get_player().main_job_level == 75 then addTime = 30 end -- add time for RDM group 2 5/5 merits in Enfeebling Duration
	
		for i, v in pairs(act.targets) do
			if T{2,252,264,265}:contains(act.targets[i].actions[1].message) then
				if T{23,24,25,33,230,231,232}:contains(act.param) then
					apply_dot(act.targets[i].id, act.param)
				elseif helixes:contains(act.param) then
					apply_helix(act.targets[i].id, act.param)
				elseif ja_spells:contains(act.param) then
					apply_ja_spells(act.targets[i].id, act.param)
				end
			elseif T{236,237,266,267,268,269,270,271,272,277,278,279,280}:contains(act.targets[i].actions[1].message) then
				local effect = act.targets[i].actions[1].param
				local target = act.targets[i].id
				local spell = act.param
				local duration
				
				if not debuffed_mobs[target] then
					debuffed_mobs[target] = {}
				end
			
				if T{252,575,616}:contains(spell) then -- stun, jettatura
					duration = os.clock() + 5
				elseif T{112}:contains(spell) then -- flash
					duration = os.clock() + 12
				elseif T{612}:contains(spell) then -- actinic burst
					duration = os.clock() + 20
				elseif T{225,255,365,350,537,572,633,659,716,720,738,746}:contains(spell) then -- 30 secs spells durations
					duration = os.clock() + 30
				elseif T{376,463}:contains(spell) then -- horde and foe lullaby, assuming lullaby +2 on instrument because it's easier to see a debuff wear early rather than late
					duration = os.clock() + 36
					if debuffed_mobs[target] and debuffed_mobs[target][2] then
						debuffed_mobs[target][2] = nil
					end
				elseif T{253,258,273,531,561,584,588,610,651,678,682,687,707,722,725}:contains(spell) then -- 1 min spells durations
					duration = os.clock() + 60
				elseif T{454,455,456,457,458,459,460,461,606}:contains(spell) then
					duration = os.clock() + 72
				elseif T{368}:contains(spell) then
					duration = os.clock() + 75
				elseif T{98,220,259,274,548,576,598,871,872,873,874,875,876,877,878}:contains(spell) then -- 1 min 30 secs spells durations
					duration = os.clock() + 90
				--elseif T{98,259,274,576,598}:contains(spell) then -- sleep II level spells overwrite sleep I and lullaby, dsp/topaz is using incorrect statuses for them
					--duration = os.clock() + 90
					--[[if debuffed_mobs[target] and debuffed_mobs[target][2] then
						debuffed_mobs[target][2] = nil
					end
					if debuffed_mobs[target] and debuffed_mobs[target][193] then
						debuffed_mobs[target][193] = nil
					end]]
				elseif T{377,471}:contains(spell) then -- horde and foe lullaby II
					duration = os.clock() + 90
					if debuffed_mobs[target] and debuffed_mobs[target][2] then
						debuffed_mobs[target][2] = nil
					end
				elseif T{369}:contains(spell) then
					duration = os.clock() + 94
				elseif T{370}:contains(spell) then
					duration = os.clock() + 114
				elseif T{240,705}:contains(spell) then -- Drown overwrittes Burn
					duration = os.clock() + 120
					if debuffed_mobs[target] and debuffed_mobs[target][128] then
						debuffed_mobs[target][128] = nil
					end
				elseif T{235,572,719}:contains(spell) then -- Burn overwrittes Frost
					duration = os.clock() + 120
					if debuffed_mobs[target] and debuffed_mobs[target][129] then
						debuffed_mobs[target][129] = nil
					end
				elseif T{236,535}:contains(spell) then -- Frost overwrittes Choke
					duration = os.clock() + 120
					if debuffed_mobs[target] and debuffed_mobs[target][130] then
						debuffed_mobs[target][130] = nil
					end
				elseif T{237}:contains(spell) then -- Choke overwrittes Rasp
					duration = os.clock() + 120
					if debuffed_mobs[target] and debuffed_mobs[target][131] then
						debuffed_mobs[target][131] = nil
					end
				elseif T{238}:contains(spell) then -- Rasp overwrittes Shock
					duration = os.clock() + 120
					if debuffed_mobs[target] and debuffed_mobs[target][132] then
						debuffed_mobs[target][132] = nil
					end
				elseif T{239}:contains(spell) then -- Shock overwrittes Drown
					duration = os.clock() + 120
					if debuffed_mobs[target] and debuffed_mobs[target][133] then
						debuffed_mobs[target][133] = nil
					end
				elseif T{58,59,80,216,217,221,319,341,344,351,374,375,621,644,656,704,708,717,841,843}:contains(spell) then -- 2 min spells durations
					duration = os.clock() + 120
				elseif T{882,883}:contains(spell) then -- 2 min 10 secs spells durations
					duration = os.clock() + 130
				elseif T{371}:contains(spell) then
					duration = os.clock() + 133
				elseif T{421}:contains(spell) then -- 3 min 36 for Battlefield Elegy with +2 instrument
					duration = os.clock() + 144
				elseif T{372}:contains(spell) then
					duration = os.clock() + 152
				elseif T{373}:contains(spell) then
					duration = os.clock() + 171
				elseif T{56,79,254,276,286,347,348,508,513,524,582,699,703}:contains(spell) then -- 3 min spells durations
					duration = os.clock() + 180
				elseif T{884}:contains(spell) then -- 3 min 10 secs spells durations
					duration = os.clock() + 190
					if debuffed_mobs[target] and debuffed_mobs[target][223] then
						debuffed_mobs[target][223] = nil
					end
				elseif T{422}:contains(spell) then -- 3 min 36 for Carnage Elegy with +2 instrument
					duration = os.clock() + 216
				elseif T{423,472}:contains(spell) then -- 4 min spells durations
					duration = os.clock() + 240
				elseif T{345,726,727,728,842,844,879}:contains(spell) then -- 5 min spells durations
					duration = os.clock() + 300
				end
			
				-- add time for RDM group 2 5/5 merits in Enfeebling Duration
				if T{56,58,59,79,80,216,220,221,225,253,254,258,259,273,276,841,843}:contains(spell) then 
					duration = duration + addTime
				end
			
			
				if not debuffed_mobs[target] then
					debuffed_mobs[target] = {}
				end

				if debuffs[effect] and debuffs[effect]:contains(spell) then
					if effect == 19 or effect == 193 then -- workaround for topaz handling of higher level sleeps
						effect = 2
					end
					debuffed_mobs[target][effect] = {name = spell, timer = duration}
				end
			elseif T{329,330,331,332,333,334,335,533}:contains(act.targets[i].actions[1].message) then
				local effect = act.param
				local target = act.targets[i].id
				local spell = act.param
				local duration = os.clock() + 215

				if not debuffed_mobs[target] then
					debuffed_mobs[target] = {}
				end

				if debuffs[effect] and tostring(debuffs[effect]):contains(spell) then
					debuffed_mobs[target][effect] = {name = spell, timer = duration}
				end
			end
		end
	elseif act.category == 11 then
		for i, v in pairs(act.targets) do
			if T{101}:contains(act.targets[i].actions[1].message) then
				
				if erase_abilities:contains(act.param) and debuffed_mobs[act.targets[i].id] then
					debuffed_mobs[act.targets[i].id] = nil
				end
			elseif T{159}:contains(act.targets[i].actions[1].message) then
				if partial_erase_abilities:contains(act.param) and debuffed_mobs[act.targets[i].id] and debuffed_mobs[act.targets[i].id][act.targets[i].actions[1].param] then
					debuffed_mobs[act.targets[i].id][act.targets[i].actions[1].param] = nil
				end
			end
		end
	elseif act.category == 14 then
		for i, v in pairs(act.targets) do
			if T{519,520,521,591}:contains(act.targets[i].actions[1].message) then
				local effect = act.param
				local target = act.targets[i].id
				local tier = act.targets[i].actions[1].param
				
				if tier == 1 then
					step_duration[effect] = os.clock() + 60
				elseif step_duration[effect] - os.clock() >= 90 then
					step_duration[effect] = os.clock() + 120
				else
					step_duration[effect] = step_duration[effect] + 30
				end
				
				if not debuffed_mobs[target] then
					debuffed_mobs[target] = {}
				end
				
				debuffed_mobs[target][effect] = {name = res.job_abilities[effect].en.." lv."..tier, timer = step_duration[effect]}
			end  
		end
	elseif act.category == 1 and debuffed_mobs[act.actor] then
		if debuffed_mobs[act.actor][2] then
			debuffed_mobs[act.actor][2] = nil
		elseif debuffed_mobs[act.actor][7] then
			debuffed_mobs[act.actor][7] = nil
		elseif debuffed_mobs[act.actor][28] then
			debuffed_mobs[act.actor][28] = nil
		end
	end
end

function inc_action_message(arr)
	if T{6,20,113,406,605,646}:contains(arr.message_id) then
		debuffed_mobs[arr.target_id] = nil
	elseif T{204,206}:contains(arr.message_id) then
		if debuffed_mobs[arr.target_id] then
			if arr.message_id == 206 then
				if arr.param_1 == 136 then
					debuffed_mobs[arr.target_id][arr.param_1] = nil
					debuffed_mobs[arr.target_id][266] = nil
				elseif arr.param_1 == 137 then
					debuffed_mobs[arr.target_id][arr.param_1] = nil
					debuffed_mobs[arr.target_id][267] = nil
				elseif arr.param_1 == 138 then
					debuffed_mobs[arr.target_id][arr.param_1] = nil
					debuffed_mobs[arr.target_id][268] = nil
				elseif arr.param_1 == 139 then
					debuffed_mobs[arr.target_id][arr.param_1] = nil
					debuffed_mobs[arr.target_id][269] = nil
				elseif arr.param_1 == 140 then
					debuffed_mobs[arr.target_id][arr.param_1] = nil
					debuffed_mobs[arr.target_id][270] = nil
				elseif arr.param_1 == 141 then
					debuffed_mobs[arr.target_id][arr.param_1] = nil
					debuffed_mobs[arr.target_id][271] = nil
				elseif arr.param_1 == 142 then
					debuffed_mobs[arr.target_id][arr.param_1] = nil
					debuffed_mobs[arr.target_id][272] = nil
				elseif arr.param_1 == 146 then
					debuffed_mobs[arr.target_id][arr.param_1] = nil
					debuffed_mobs[arr.target_id][242] = nil
				elseif T{386,387,388,389,390}:contains(arr.param_1) then
					debuffed_mobs[arr.target_id][201] = nil
					step_duration[201] = 0
				elseif T{391,392,393,394,395}:contains(arr.param_1) then
					debuffed_mobs[arr.target_id][202] = nil
					step_duration[202] = 0
				elseif T{396,397,398,399,400}:contains(arr.param_1) then
					debuffed_mobs[arr.target_id][203] = nil
					step_duration[203] = 0
				elseif T{448,449,450,451,452}:contains(arr.param_1) then
					debuffed_mobs[arr.target_id][312] = nil
					step_duration[312] = 0
				else
					debuffed_mobs[arr.target_id][arr.param_1] = nil
				end
			else
				debuffed_mobs[arr.target_id][arr.param_1] = nil
			end
		end
	end
end

windower.register_event('logout','zone change', function()
	debuffed_mobs = {}
end)

windower.register_event('incoming chunk', function(id, data)
	if id == 0x028 then
		inc_action(windower.packets.parse_action(data))
	elseif id == 0x029 then
		local arr = {}
		arr.target_id = data:unpack('I',0x09)
		arr.param_1 = data:unpack('I',0x0D)
		arr.message_id = data:unpack('H',0x19)%32768
		
		inc_action_message(arr)
	end
end)

windower.register_event('prerender', function()
	local curr = os.clock()
	if curr > frame_time + .1 then
		frame_time = curr
		update_box()
	end
end)

windower.register_event('unload', function()
    -- This destroys all icons and timers when you reload or unload the addon
    for _, img in pairs(ui_icons) do
        if img then img:destroy() end
    end
    for _, txt in pairs(ui_timers) do
        if txt then txt:destroy() end
    end
end)