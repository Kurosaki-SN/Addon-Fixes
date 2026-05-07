_addon.name = 'Debuffed'
_addon.author = 'original: Auk, improvements and additions: Kenshi'
_addon.version = '1.5'
_addon.commands = {'debuffed'}


require('luau')
packets = require('packets')
texts = require('texts')
images = require('images') -- Added images library
res = require('resources')

defaults = {}
-- ... (keep all the defaults) ...

settings = config.load(defaults)

base_pos_x = settings.pos.x
base_pos_y = settings.pos.y

settings.buff_pos = settings.buff_pos or {x = base_pos_x, y = base_pos_y + 100}
buff_pos_x = settings.buff_pos.x
buff_pos_y = settings.buff_pos.y

defaults.blacklist = S{'name of mob to ignore', 'another trash mob'}
defaults.whitelist = S{'specific nm name', 'another nm'}

local is_setup_mode = false
local dummy_images = {}
local anchor_box = nil

-- Remove the single 'box' text object. 
-- Instead, we will store individual icons and timers for active debuffs.
ui_icons = {}
ui_timers = {}
text_box = texts.new()
buff_text_box = texts.new()
icon_size = 24 -- Adjust this to match your .png dimensions

frame_time = 0
debuffed_mobs = {}

helixes = S{278,279,280,281,282,283,284,285,
	885,886,887,888,889,890,891,892}

ja_spells = S{496,497,498,499,500,501}

-- Broad song bucket for mob Bard songs. Display as 220.
mob_song_statuses = S{195,196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222}

step_duration = {}

erase_abilities = S{2370, 2571, 2714, 2718, 2775, 2831}

status_remove_action_messages = S{64,159,204,206}
dispelling_action_ids = S{260,462}

partial_erase_abilities = S{1245, 1273}

additional_effect_status_messages = S{160, 164}
additional_effect_long_duration_statuses = S{130, 149}



debuffs = {
	[2] = S{253,584,678}, --Sleep I
	[650] = S{273}, --Sleepga I
	[651] = S{274,576,598}, --Sleepga II
	[3] = S{220,225,350,351,513,716}, --Poison I, Poisonga, and others
	[652] = S{221,226}, --Poison II & Poisonga II
	[4] = S{58,80,341,644,704}, --Paralyze
	[5] = S{254,276,347,348,621}, --Blind
	[6] = S{59,582,687,727}, --Silence
	[7] = S{255,365,722}, --Break
	[10] = S{252,616}, --Stun
	[11] = S{258,531}, --Bind
	[12] = S{216,217,708}, --Gravity
	[13] = S{56,79,344,345,548,703}, --Slow
	[19] = S{98,259,274,576,598}, --sleep II | Repose
	[21] = S{286,884}, ----addle
	[28] = S{575,720,738,746}, --terror
	[31] = S{588,682}, --plague
	[128] = S{235}, --burn
	[129] = S{236,535}, --frost
	[130] = S{237}, --choke
	[131] = S{238}, --rasp
	[132] = S{239}, --shock
	[133] = S{240,705}, --drown
	--[136] = S{606}, --str down
	--[138] = S{537}, --vit down
	--[140] = S{572}, -- int down
	[146] = S{242,524,699}, --Accuracy Down & Absorb ACC
	[147] = S{319,651,659,726}, --attack down
	[148] = S{610,841,842,882}, --Evasion Down
	[149] = S{561,633,651,717,728}, -- defense down
	[156] = S{112,612,707,725}, --Flash
	[167] = S{633,656}, --Magic Def. Down
	[168] = S{508}, --inhibit TP
	[192] = S{368,369,370,371,372,373,374,375}, --requiem
	[193] = S{463,471}, --Foe Lullaby
	[640] = S{376,377}, --Horde Lullaby
	[194] = S{421,422,423}, --elegy
	[641] = S{454,871}, --Fire Threnody
	[642] = S{455,872}, --Ice Threnody
	[643] = S{456,873}, --Wind Threnody
	[644] = S{457,874}, --Earth Threnody
	[645] = S{458,875}, --Lightning Threnody
	[646] = S{459,876}, --Water Threnody
	[647] = S{460,877}, --Light Threnody
	[648] = S{461,878}, --Dark Threnody
	[223] = S{472}, --nocturne
	--[242] = S{242}, --Absorb ACC
	[136] = S{266,606}, --STR Down & Absorb STR
	[137] = S{267}, --DEX Down & Absorb DEX
	[138] = S{268,537}, --VIT Down & Absorb VIT
	[139] = S{269}, --AGI Down & Absorb AGI
	[140] = S{270,572}, --INT Down & Absorb INT
	[141] = S{271}, --MND Down & Absorb MND
	[142] = S{272}, --CHR Down & Absorb CHR
	[404] = S{843,844,883}, --Magic Evasion Down
	[597] = S{879}, --inundation
	[134] = S{23,33}, --Dia I & Diaga
	[655] = S{24}, --Dia II
	[656] = S{25}, --Dia III
    [135] = S{230}, --Bio I
	[653] = S{231}, --Bio II
	[654] = S{232}, --Bio III
	[657] = S{80},  -- Paralyze II
	[658] = S{79},  -- Slow II
	[659] = S{276}, -- Blind II

}

hierarchy = {
    [23] = 1,   -- Dia
    [33] = 1,   -- Diaga
    [230] = 2,  -- Bio
    [24] = 3,   -- Dia II
    [231] = 4,  -- Bio II
    [25] = 5,   -- Dia III
    [232] = 6,  -- Bio III
}

sleep_hierarchy = {
    [463] = 1,  -- Foe Lullaby
    [376] = 1,  -- Horde Lullaby
    [253] = 2,  -- Sleep
    [273] = 2,  -- Sleepga
    [584] = 2,  -- Sheep Song
    [678] = 2,  -- Pinecone Bomb
    [98]  = 3,  -- Repose
    [259] = 3,  -- Sleep II
    [274] = 3,  -- Sleepga II
    [576] = 3,  -- Soporific
    [598] = 3,  -- Yawn
}

function apply_dot(target, spell)
	if not debuffed_mobs[target] then
		debuffed_mobs[target] = {}
	end

	local priority = 0
	local current = debuffed_mobs[target][134] or debuffed_mobs[target][655] or debuffed_mobs[target][656] or debuffed_mobs[target][135] or debuffed_mobs[target][653] or debuffed_mobs[target][654]
	if current then
		priority = hierarchy[current.name] or hierarchy[current]
	end
	
	local addTime = 0
	if windower.ffxi.get_player().main_job == "RDM" and windower.ffxi.get_player().main_job_level == 75 then addTime = 30 end -- add time for RDM group 2 5/5 merits in Enfeebling Duration

	if (hierarchy[spell] or 0) > priority then
		if T{23,24,25,33}:contains(spell) then
			debuffed_mobs[target][134] = nil
			debuffed_mobs[target][655] = nil
			debuffed_mobs[target][656] = nil
			if spell == 23 then
				debuffed_mobs[target][134] = {name = spell, timer = os.clock() + 60 + addTime}
			elseif spell == 33 then
				debuffed_mobs[target][134] = {name = spell, timer = os.clock() + 60 + addTime}
			elseif spell == 24 then
				debuffed_mobs[target][655] = {name = spell, timer = os.clock() + 120 + addTime}
			else
				debuffed_mobs[target][656] = {name = spell, timer = os.clock() + 180 + addTime}
			end
			debuffed_mobs[target][135] = nil
			debuffed_mobs[target][653] = nil
			debuffed_mobs[target][654] = nil
		elseif T{230,231,232}:contains(spell) then
			debuffed_mobs[target][134] = nil
			debuffed_mobs[target][135] = nil
			debuffed_mobs[target][653] = nil
			debuffed_mobs[target][654] = nil
			if spell == 230 then
				debuffed_mobs[target][135] = {name = spell, timer = os.clock() + 60}
			elseif spell == 231 then
				debuffed_mobs[target][653] = {name = spell, timer = os.clock() + 120}
			else
				debuffed_mobs[target][654] = {name = spell, timer = os.clock() + 180}
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
	
	-- CLEAR SAFETY: A mob can only have one Helix active at a time. 
	-- This wipes out any old Helix icons before applying the new one so they don't overlap visually!
	for i = 178, 186 do
		debuffed_mobs[target][i] = nil
	end

	-- ELEMENTAL ROUTER: Maps the exact spell ID to your specific element icons
	local effect = 186 -- Fallback generic ID
	if T{281, 888}:contains(spell) then effect = 178 -- Fire (Pyrohelix)
	elseif T{282, 889}:contains(spell) then effect = 179 -- Ice (Cryohelix)
	elseif T{280, 887}:contains(spell) then effect = 180 -- Wind (Anemohelix)
	elseif T{278, 885}:contains(spell) then effect = 181 -- Earth (Geohelix)
	elseif T{283, 890}:contains(spell) then effect = 182 -- Lightning (Ionohelix)
	elseif T{279, 886}:contains(spell) then effect = 183 -- Water (Hydrohelix)
	elseif T{285, 892}:contains(spell) then effect = 184 -- Light (Luminohelix)
	elseif T{284, 891}:contains(spell) then effect = 185 -- Dark (Noctohelix)
	end

	debuffed_mobs[target][effect] = {name = spell, timer = os.clock() + addTime}
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

function apply_additional_effect_status(target, msg, effect)
	effect = effect or 0
	if not additional_effect_status_messages:contains(msg) or effect <= 0 then return end

	local duration = 30
	if additional_effect_long_duration_statuses:contains(effect) then duration = 60 end

	if not debuffed_mobs[target] then debuffed_mobs[target] = {} end
	debuffed_mobs[target][effect] = {name = "Additional Effect", timer = os.clock() + duration}
end

local buff_anchor_box = nil

local function enable_setup_mode()
    -- RED BOX FOR DEBUFFS
    anchor_box = images.new()
    anchor_box:size((icon_size + 5) * 10, icon_size + 15)
    anchor_box:color(255, 0, 0) 
    anchor_box:alpha(100)
    anchor_box:pos(base_pos_x, base_pos_y)
    anchor_box:draggable(true)
    anchor_box:show()

    -- BLUE BOX FOR BUFFS
    buff_anchor_box = images.new()
    buff_anchor_box:size((icon_size + 5) * 10, icon_size + 15)
    buff_anchor_box:color(0, 0, 255) 
    buff_anchor_box:alpha(100)
    buff_anchor_box:pos(buff_pos_x, buff_pos_y)
    buff_anchor_box:draggable(true)
    buff_anchor_box:show()
    
    windower.add_to_chat(207, 'Debuffed: Drag the RED box for Debuffs, BLUE box for Buffs.')
end

local function disable_setup_mode()
    local function snap(val)
        return math.floor((val + 5) / 10) * 10
    end

    if anchor_box then
        local ax, ay = anchor_box:pos()
        base_pos_x = snap(ax)
        base_pos_y = snap(ay)
        
        anchor_box:hide()
        anchor_box:destroy()
        anchor_box = nil
    end
    
    if buff_anchor_box then
        local bx, by = buff_anchor_box:pos()
        buff_pos_x = snap(bx)
        buff_pos_y = snap(by)
        
        buff_anchor_box:hide()
        buff_anchor_box:destroy()
        buff_anchor_box = nil
    end

    settings.pos.x = base_pos_x
    settings.pos.y = base_pos_y
    settings.buff_pos.x = buff_pos_x
    settings.buff_pos.y = buff_pos_y
    config.save(settings, 'all') 
end




function update_box()
    local target = windower.ffxi.get_mob_by_target('st') or windower.ffxi.get_mob_by_target('t')
    local active_debuffs = {}
    local active_buffs = {}

    local current_filter = settings.filter_mode or 'blacklist'
    local is_allowed = true

    if target and target.valid_target then
        if current_filter == 'blacklist' and settings.blacklist:contains(target.name:lower()) then
            is_allowed = false
        elseif current_filter == 'whitelist' and not settings.whitelist:contains(target.name:lower()) then
            is_allowed = false
        end
    end

    if is_allowed and target and target.valid_target and target.is_npc and (target.claim_id ~= 0 or target.spawn_type == 16) then
        local debuff_table = debuffed_mobs[target.id]
        if debuff_table then
            for effect_id, spell_data in pairs(debuff_table) do
                if spell_data and type(spell_data) == 'table' then
                    local remaining = spell_data.timer - os.clock()
                    if remaining >= 0 then
                        local eff = {id = effect_id, time = remaining, name = spell_data.name}
                        if spell_data.is_buff then table.insert(active_buffs, eff)
                        else table.insert(active_debuffs, eff) end
                    else
                        debuff_table[effect_id] = nil
                    end
                end
            end
        end
    end

    table.sort(active_debuffs, function(a, b) return a.id < b.id end)
    table.sort(active_buffs, function(a, b) return a.id < b.id end)
    settings.display_mode = settings.display_mode or 'icon'

    if settings.display_mode == 'text' then
        for _, img in pairs(ui_icons) do img:hide() end
        for _, txt in pairs(ui_timers) do txt:hide() end

        local function format_text(effect_list, title)
            if #effect_list == 0 then return nil end
            local lines = {' \\cs(255,255,0)[' .. target.name .. '] ' .. title .. '\\cr'}
            for _, eff in ipairs(effect_list) do
                local time_str = eff.time and string.format('%.0f', eff.time)..'s' or 'N/A'
                local name_str = eff.name
                if type(name_str) == 'number' then
                    if res.buffs and res.buffs[eff.id] then name_str = res.buffs[eff.id].en 
                    elseif res.spells and res.spells[name_str] then name_str = res.spells[name_str].en 
                    elseif res.job_abilities and res.job_abilities[name_str] then name_str = res.job_abilities[name_str].en 
                    else name_str = "Effect ID: " .. tostring(eff.id) end
                end
                table.insert(lines, ' ' .. (name_str or "Unknown") .. ' : ' .. time_str)
            end
            return table.concat(lines, '\n')
        end

        local d_text = format_text(active_debuffs, "(Debuffs)")
        if d_text then
            text_box:text(d_text); text_box:pos(base_pos_x, base_pos_y)
            text_box:font(settings.text.font); text_box:size(settings.text.size)
            text_box:color(settings.text.red, settings.text.green, settings.text.blue)
            text_box:bg_alpha(200); text_box:show()
        else text_box:hide() end

        local b_text = format_text(active_buffs, "(Buffs)")
        if b_text then
            buff_text_box:text(b_text); buff_text_box:pos(buff_pos_x, buff_pos_y)
            buff_text_box:font(settings.text.font); buff_text_box:size(settings.text.size)
            buff_text_box:color(settings.text.red, settings.text.green, settings.text.blue)
            buff_text_box:bg_alpha(200); buff_text_box:show()
        else buff_text_box:hide() end

    else
        text_box:hide(); buff_text_box:hide()
        for _, img in pairs(ui_icons) do img:hide() end
        for _, txt in pairs(ui_timers) do txt:hide() end

        local function draw_grid(effect_list, start_x, start_y, is_reversed)
            for i, eff in ipairs(effect_list) do
                if i > 20 then break end 
                local e_id = eff.id
                if not ui_icons[e_id] then
                    ui_icons[e_id] = images.new()
                    ui_icons[e_id]:path(windower.windower_path .. 'addons/Debuffed/BuffIcons/' .. e_id .. '.png')
                    ui_icons[e_id]:draggable(false)
                end
				
				ui_icons[e_id]:size(icon_size, icon_size)

                if not ui_timers[e_id] then
                    ui_timers[e_id] = texts.new(); ui_timers[e_id]:draggable(false)
                    ui_timers[e_id]:font(settings.text.font); ui_timers[e_id]:size(settings.text.size)
                    ui_timers[e_id]:color(settings.text.red, settings.text.green, settings.text.blue)
                    ui_timers[e_id]:stroke_alpha(0); ui_timers[e_id]:bg_alpha(0)
                end

                local col, row = (i - 1) % 10, math.floor((i - 1) / 10) 
                
                local cur_x
                if is_reversed then
                    local right_edge = start_x + (9 * (icon_size + 5))
                    cur_x = right_edge - (col * (icon_size + 5))
                else
                    cur_x = start_x + (col * (icon_size + 5))
                end
                
                local cur_y = start_y + (row * (icon_size + 15)) 
                
                ui_icons[e_id]:pos(cur_x, cur_y); ui_icons[e_id]:show()
                if eff.time then
                    ui_timers[e_id]:pos(cur_x, cur_y + icon_size)
                    ui_timers[e_id]:text(string.format('%.0f', eff.time)); ui_timers[e_id]:show()
                end
            end
        end

        draw_grid(active_debuffs, base_pos_x, base_pos_y, false)
        
        -- Buffs check your toggle setting
        local is_buffs_reversed = true -- Default to your preference
        if settings.buff_direction == 'normal' then
            is_buffs_reversed = false
        end
        
        draw_grid(active_buffs, buff_pos_x, buff_pos_y, is_buffs_reversed)
    end
end

function inc_action(act)

    -- ==================================================
	-- DISPEL & MAGIC FINALE CATCHER
	-- ==================================================
	if act.targets then
		for i, v in pairs(act.targets) do
			if v.actions then
				for j, a in pairs(v.actions) do
					local msg = a.message or 0
					local effect = a.param or 0

					-- If the action is Dispel/Finale, OR the message means a status was removed
					if effect > 0 and (status_remove_action_messages:contains(msg) or dispelling_action_ids:contains(act.param)) then
						if debuffed_mobs[v.id] then
							debuffed_mobs[v.id][effect] = nil
						end
					end
				end
			end
		end
	end
    
	-- ==================================================
	-- 2-HOUR (SP ABILITY) CATCH-ALL
	-- ==================================================
	if act.category == 14 then
		for i, v in pairs(act.targets) do
			local target_mob = windower.ffxi.get_mob_by_id(v.id)
			
			if target_mob and target_mob.is_npc and target_mob.spawn_type == 16 then
				local ability_id = act.param
				local image_id = nil

				if ability_id == 16 then image_id = 44      -- Mighty Strikes
				elseif ability_id == 17 then image_id = 46  -- Hundred Fists
				elseif ability_id == 19 then image_id = 47  -- Manafont
				elseif ability_id == 20 then image_id = 48  -- Chainspell
				elseif ability_id == 21 then image_id = 49  -- Perfect Dodge
				elseif ability_id == 22 then image_id = 50  -- Invincible
				elseif ability_id == 23 then image_id = 51  -- Blood Weapon
				elseif ability_id == 25 then image_id = 52  -- Soul Voice
				elseif ability_id == 27 then image_id = 54  -- Meikyo Shisui
				elseif ability_id == 30 then image_id = 55  -- Astral Flow
				end
				
				if image_id then
					if not debuffed_mobs[v.id] then debuffed_mobs[v.id] = {} end
					debuffed_mobs[v.id][image_id] = {name = "2-Hour", timer = os.clock() + 45, is_buff = true}
				end
			end
		end
	end
	-- ==================================================
	-- ==================================================
	-- MOB BUFF CATCH-ALL
	-- ==================================================
	-- Cat 4: Magic Finish | Cat 11: TP Move Finish | Cat 13: Avatar Pact Finish
	if T{4, 11, 13}:contains(act.category) then
		for i, v in pairs(act.targets) do
			local target_mob = windower.ffxi.get_mob_by_id(v.id)
			
			if target_mob and target_mob.is_npc and target_mob.spawn_type == 16 then
				for j, a in pairs(v.actions) do
					local msg = a.message or 0
					local effect = a.param or 0
					
					-- 230: Magic Buffs (Protect, Haste, etc.)
					-- 186: TP Move Buffs (Stoneskin, Evasion Boost, etc.)
					-- 237: Standard Retail TP Buffs (Safety net)
					if T{230, 186, 237}:contains(msg) and effect > 0 then
						if not debuffed_mobs[v.id] then 
							debuffed_mobs[v.id] = {} 
						end
						
				if mob_song_statuses:contains(effect) then 
                            effect = 220 
                        end		
						-- Applies the buff icon. Defaults to a 3-minute (180s) timer 
						debuffed_mobs[v.id][effect] = {name = "Mob Buff", timer = os.clock() + 180, is_buff = true}
					end
				end
			end
		end
	end
	-- ==================================================

    -- ==================================================
	-- DEFENSIVE GEAR PROC CATCH-ALL
	-- ==================================================
	local player = windower.ffxi.get_player()
	
	-- GEAR PROCS (Curse, etc.)
	if act.actor_id ~= player.id then 
		for i, v in pairs(act.targets) do
			for j, a in pairs(v.actions) do
				local spk_msg = a.spike_effect_message or 0
				local effect = a.spike_effect_param or 0
				
				if T{374}:contains(spk_msg) and effect > 0 then
					local mob_id = act.actor_id 
					if not debuffed_mobs[mob_id] then debuffed_mobs[mob_id] = {} end
					debuffed_mobs[mob_id][effect] = {name = "Gear Proc", timer = os.clock() + 60}
				end
			end
		end
	end
	-- ==================================================


    -- ==================================================
	-- WIDE NET HUNTER: Catches Angon!
	-- ==================================================
	-- if act.category ~= 1 then -- Ignores normal melee swings
		-- if act.targets[1] and act.targets[1].actions[1] then
			-- local act_id = act.param
			-- local msg = act.targets[1].actions[1].message
			-- local param = act.targets[1].actions[1].param
			
			-- windower.add_to_chat(200, 'WIDE HUNTER -> Cat: '..tostring(act.category)..' | ID: '..tostring(act_id)..' | Msg: '..tostring(msg)..' | Param: '..tostring(param))
		-- end
	-- end
	-- ==================================================
	
	-- ==================================================
	-- JA HUNTER:
	-- ==================================================
	-- if act.category == 6 or act.category == 14 then
		-- if act.targets[1] and act.targets[1].actions[1] then
			-- local ja_id = act.param
			-- local msg = act.targets[1].actions[1].message
			-- local param = act.targets[1].actions[1].param
			
			-- windower.add_to_chat(200, 'JA HUNTER -> Cat: '..tostring(act.category)..' | JA ID: '..tostring(ja_id)..' | Msg: '..tostring(msg)..' | Param: '..tostring(param))
		-- end
	-- end
	-- ==================================================

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
				elseif T{242,266,267,268,269,270,271,272}:contains(act.param) then
					-- PRIVATE SERVER CATCH-ALL FOR ABSORB SPELLS
					local effect = act.param
					if effect == 242 then effect = 146	
					elseif effect == 266 then effect = 136
					elseif effect == 267 then effect = 137
					elseif effect == 268 then effect = 138
					elseif effect == 269 then effect = 139
					elseif effect == 270 then effect = 140
					elseif effect == 271 then effect = 141
					elseif effect == 272 then effect = 142
					end
					if not debuffed_mobs[act.targets[i].id] then debuffed_mobs[act.targets[i].id] = {} end
					debuffed_mobs[act.targets[i].id][effect] = {name = act.param, timer = os.clock() + 90}
				end	
			elseif T{236,237,266,267,268,269,270,271,272,277,278,279,280}:contains(act.targets[i].actions[1].message) then
				local effect = act.targets[i].actions[1].param
				local target = act.targets[i].id
				local spell = act.param
				local duration
				
				-- ABSOLUTE OVERRIDE FOR ABSORB SPELLS
				if spell == 242 then effect = 146
				elseif spell == 266 then effect = 136
				elseif spell == 267 then effect = 137
				elseif spell == 268 then effect = 138
				elseif spell == 269 then effect = 139
				elseif spell == 270 then effect = 140
				elseif spell == 271 then effect = 141
				elseif spell == 272 then effect = 142
				end
				
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
				elseif T{253,258,273,531,561,584,588,610,651,678,682,687,707,722,725}:contains(spell) then -- 1 min spells durations
					duration = os.clock() + 60
				elseif T{454,455,456,457,458,459,460,461,606}:contains(spell) then
					duration = os.clock() + 72
				elseif T{368}:contains(spell) then
					duration = os.clock() + 75
				elseif T{98,220,242,259,266,267,268,269,270,271,272,274,548,576,598,871,872,873,874,875,876,877,878}:contains(spell) then -- 1 min 30 secs spells durations & Absorbs
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
				elseif T{58,59,80,216,217,221,226,319,341,344,351,374,375,621,644,656,704,708,717,841,843}:contains(spell) then -- 2 min spells durations
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

				-- CUSTOM ICON ROUTER
				if effect == 3 and T{221,226}:contains(spell) then
					effect = 652 -- Reroutes Poison II & Poisonga II
					if debuffed_mobs[target] then debuffed_mobs[target][3] = nil end -- Clears Poison I
				
				elseif effect == 2 or T{376,377,463,471}:contains(spell) then
					local current_prio = 0
					
					local current = debuffed_mobs[target][2] or debuffed_mobs[target][650] or debuffed_mobs[target][19] or debuffed_mobs[target][651] or debuffed_mobs[target][193] or debuffed_mobs[target][640]
					
					if current then
						current_prio = sleep_hierarchy[current.name] or 0
					end

					local incoming_prio = sleep_hierarchy[spell] or 0

					if incoming_prio >= current_prio then
						debuffed_mobs[target][2] = nil
						debuffed_mobs[target][650] = nil
						debuffed_mobs[target][19] = nil
						debuffed_mobs[target][651] = nil
						debuffed_mobs[target][193] = nil
						debuffed_mobs[target][640] = nil
						
						if T{273}:contains(spell) then effect = 650
						elseif T{274,576,598}:contains(spell) then effect = 651
						elseif T{98,259}:contains(spell) then effect = 19
						elseif T{376,377}:contains(spell) then effect = 640
						elseif T{463,471}:contains(spell) then effect = 193
						else effect = 2 end
					else
						effect = 0 
					end
				-- Paralyze Hierarchy
				elseif effect == 4 then
					if T{80}:contains(spell) then -- Spell ID for Paralyze II
						effect = 657
						if debuffed_mobs[target] then debuffed_mobs[target][4] = nil end
					elseif debuffed_mobs[target] and debuffed_mobs[target][657] then
						effect = 0 -- Ignores Paralyze I if Paralyze II is already active
					end
					
				-- Slow Hierarchy
				elseif effect == 13 then
					if T{79}:contains(spell) then -- Spell ID for Slow II
						effect = 658
						if debuffed_mobs[target] then debuffed_mobs[target][13] = nil end
					elseif debuffed_mobs[target] and debuffed_mobs[target][658] then
						effect = 0 -- Ignores Slow I if Slow II is already active
					end
					
				-- Blind Hierarchy
				elseif effect == 5 then
					if T{276}:contains(spell) then -- Spell ID for Blind II
						effect = 659
						if debuffed_mobs[target] then debuffed_mobs[target][5] = nil end
					elseif debuffed_mobs[target] and debuffed_mobs[target][659] then
						effect = 0 -- Ignores Blind I if Blind II is already active
					end	
				elseif effect == 217 then
					if T{454,871}:contains(spell) then effect = 641
					elseif T{455,872}:contains(spell) then effect = 642
					elseif T{456,873}:contains(spell) then effect = 643
					elseif T{457,874}:contains(spell) then effect = 644
					elseif T{458,875}:contains(spell) then effect = 645
					elseif T{459,876}:contains(spell) then effect = 646
					elseif T{460,877}:contains(spell) then effect = 647
					elseif T{461,878}:contains(spell) then effect = 648
					end
				end

				if debuffs[effect] and debuffs[effect]:contains(spell) then
					debuffed_mobs[target][effect] = {name = spell, timer = duration}
				end	
			elseif T{242,329,330,331,332,333,334,335,533}:contains(act.targets[i].actions[1].message) then
				local effect = act.param
				local target = act.targets[i].id
				local spell = act.param
				local duration = os.clock() + 215

				-- ROUTES ABSORB SPELLS FROM DRAIN MESSAGES
				if spell == 242 then effect = 146; duration = os.clock() + 90
				elseif spell == 266 then effect = 136; duration = os.clock() + 90
				elseif spell == 267 then effect = 137; duration = os.clock() + 90
				elseif spell == 268 then effect = 138; duration = os.clock() + 90
				elseif spell == 269 then effect = 139; duration = os.clock() + 90
				elseif spell == 270 then effect = 140; duration = os.clock() + 90
				elseif spell == 271 then effect = 141; duration = os.clock() + 90
				elseif spell == 272 then effect = 142; duration = os.clock() + 90
				end

				if not debuffed_mobs[target] then
					debuffed_mobs[target] = {}
				end

				if debuffs[effect] then
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
		
	-- ==================================================
	-- CATEGORY 3: Weaponskills & Special Projectiles (Angon)
	-- ==================================================
	elseif act.category == 3 then
		for i, v in pairs(act.targets) do
			if act.targets[i].actions[1].message == 127 then
				local target = act.targets[i].id
				local effect = act.targets[i].actions[1].param
				
				if effect > 0 then
					local duration = os.clock() + 90 
					local ability_name = "Additional Effect"
					
					if act.param == 170 then
						effect = 170 
						ability_name = "Angon"
					end
					
					if not debuffed_mobs[target] then debuffed_mobs[target] = {} end
					debuffed_mobs[target][effect] = {name = ability_name, timer = duration}
				end
			end
		end
		
	-- ==================================================
	-- CATEGORY 6: Corsair Quick Draw & Pet Magic (Avatars)
	-- ==================================================
	elseif act.category == 6 then
		for i, v in pairs(act.targets) do
			local target = act.targets[i].id
			local msg = act.targets[i].actions[1].message
			local spell = act.param
			
			-- Handle Standard Corsair / Mob Debuffs (Message 127)
			if msg == 127 then
				local effect = act.targets[i].actions[1].param
				if effect > 0 then
					local duration = os.clock() + 60 
					local name_prefix = res.job_abilities[act.param] and res.job_abilities[act.param].en or "Quick Draw"
					if not debuffed_mobs[target] then debuffed_mobs[target] = {} end
					debuffed_mobs[target][effect] = {name = name_prefix, timer = duration}
				end
			
			-- Handle Avatar Magic (Message 0 / Generic)
			elseif msg == 0 or T{2,227,230,236,237,266,267,268,277,278,280}:contains(msg) then
				if not debuffed_mobs[target] then debuffed_mobs[target] = {} end
				
				if spell == 611 then -- Shiva: Sleepga
					debuffed_mobs[target][650] = {name = "Sleepga", timer = os.clock() + 60}
				elseif spell == 580 then -- Leviathan: Slowga
					debuffed_mobs[target][13] = {name = "Slowga", timer = os.clock() + 180}
				elseif spell == 657 then -- Diabolos: Somnolence (Weight)
					debuffed_mobs[target][12] = {name = "Somnolence", timer = os.clock() + 180}
				elseif spell == 659 then 
					local dur = os.clock() + 60
					debuffed_mobs[target][136] = {name = "Ultimate Terror", timer = dur} -- STR
					debuffed_mobs[target][137] = {name = "Ultimate Terror", timer = dur} -- DEX
					debuffed_mobs[target][138] = {name = "Ultimate Terror", timer = dur} -- VIT
					debuffed_mobs[target][139] = {name = "Ultimate Terror", timer = dur} -- AGI
					debuffed_mobs[target][140] = {name = "Ultimate Terror", timer = dur} -- INT
					debuffed_mobs[target][141] = {name = "Ultimate Terror", timer = dur} -- MND
					debuffed_mobs[target][142] = {name = "Ultimate Terror", timer = dur} -- CHR
				end
			end
		end

	-- ==================================================
	-- CATEGORY 13: Avatar Physical Pacts
	-- ==================================================
	elseif act.category == 13 then
		for i, v in pairs(act.targets) do
			local msg = act.targets[i].actions[1].message
			local effect = act.targets[i].actions[1].param
			local target = act.targets[i].id
			
			-- 1. Universal Catch (Msg 242 = Lands, Msg 266 = Falls Asleep)
			if T{242, 266}:contains(msg) and effect > 0 then
				if not debuffed_mobs[target] then debuffed_mobs[target] = {} end
				
				local duration = 120
				local ability_name = "Blood Pact"
				
				if act.param == 658 then
					ability_name = "Nightmare"
					duration = 60 
				end
				
				debuffed_mobs[target][effect] = {name = ability_name, timer = os.clock() + duration}
			
			elseif msg == 144 or act.param == 659 then
				if not debuffed_mobs[target] then debuffed_mobs[target] = {} end
				
				-- Fenrir: Lunar Cry
				if act.param == 530 then 
					debuffed_mobs[target][146] = {name = "Lunar Cry", timer = os.clock() + 180}
					debuffed_mobs[target][148] = {name = "Lunar Cry", timer = os.clock() + 180}
					
				-- Diabolos: Ultimate Terror (Cat 13)
				elseif act.param == 659 then 
					local dur = os.clock() + 60
					debuffed_mobs[target][136] = {name = "Ultimate Terror", timer = dur}
					debuffed_mobs[target][137] = {name = "Ultimate Terror", timer = dur}
					debuffed_mobs[target][138] = {name = "Ultimate Terror", timer = dur}
					debuffed_mobs[target][139] = {name = "Ultimate Terror", timer = dur}
					debuffed_mobs[target][140] = {name = "Ultimate Terror", timer = dur}
					debuffed_mobs[target][141] = {name = "Ultimate Terror", timer = dur}
					debuffed_mobs[target][142] = {name = "Ultimate Terror", timer = dur}
				end
			-- 3. SILENT PROC CATCH (Crescent Fang)
			-- ID 529 is Crescent Fang. Msg 317 is physical damage.
			elseif act.param == 529 and msg == 317 then
				if not debuffed_mobs[target] then debuffed_mobs[target] = {} end
				debuffed_mobs[target][4] = {name = "Crescent Fang", timer = os.clock() + 60}
			end
		end

	-- ==================================================
	-- CATEGORY 14: Job Abilities & Steps
	-- ==================================================
	elseif act.category == 14 then
		for i, v in pairs(act.targets) do
			if T{519,520,521,591}:contains(act.targets[i].actions[1].message) then
				local effect = act.param
				local target = act.targets[i].id
				local tier = act.targets[i].actions[1].param
				local name_prefix = res.job_abilities[effect].en
				
				-- FIX: Reroutes JA IDs to actual Daze Status IDs to prevent Bard Buff collision
				if effect == 201 then effect = 386 -- Quickstep -> Lethargic Daze
				elseif effect == 202 then effect = 391 -- Box Step -> Sluggish Daze
				elseif effect == 203 then effect = 396 -- Stutter Step -> Weakened Daze
				elseif effect == 312 then effect = 448 -- Feather Step -> Dazed
				end
				
				if tier == 1 or not step_duration[effect] then
					step_duration[effect] = os.clock() + 60
				elseif step_duration[effect] - os.clock() >= 90 then
					step_duration[effect] = os.clock() + 120
				else
					step_duration[effect] = step_duration[effect] + 30
				end
				
				if not debuffed_mobs[target] then
					debuffed_mobs[target] = {}
				end
				
				debuffed_mobs[target][effect] = {name = name_prefix.." lv."..tier, timer = step_duration[effect]}
			
			elseif act.targets[i].actions[1].message == 529 then
				local target = act.targets[i].id
				local effect = 430 -- Reroutes both to 430.png
				local duration = os.clock() + 7 -- Default to 7s for Konzen-ittai
				local ability_name = "Konzen-ittai"
				
				if act.param == 209 then
					duration = os.clock() + 7
					ability_name = "Wild Flourish"
				end
				
				if not debuffed_mobs[target] then
					debuffed_mobs[target] = {}
				end
				
				debuffed_mobs[target][effect] = {name = ability_name, timer = duration}
			end  
		end
	elseif act.category == 1 or act.category == 2 then
		for i, v in pairs(act.targets) do
			local target = v.id
			
			if debuffed_mobs[target] then
				if debuffed_mobs[target][2] or debuffed_mobs[target][19] or debuffed_mobs[target][193] or debuffed_mobs[target][640] or debuffed_mobs[target][650] or debuffed_mobs[target][651] then
					debuffed_mobs[target][2] = nil
					debuffed_mobs[target][19] = nil
					debuffed_mobs[target][193] = nil
					debuffed_mobs[target][640] = nil
					debuffed_mobs[target][650] = nil
					debuffed_mobs[target][651] = nil
				elseif debuffed_mobs[target][7] then
					debuffed_mobs[target][7] = nil
				elseif debuffed_mobs[target][28] then
					debuffed_mobs[target][28] = nil
				end
			end

			for j, action_data in pairs(v.actions) do
				local msg1 = action_data.message or 0
				local msg2 = action_data.add_effect_message or 0
				local param = action_data.add_effect_param or 0 

				local msg = 0
				if additional_effect_status_messages:contains(msg2) then 
					msg = msg2 
				elseif additional_effect_status_messages:contains(msg1) then 
					msg = msg1 
				end

				apply_additional_effect_status(target, msg, param)
			end
		end
	end
end

function inc_action_message(arr)
	if T{6,20,113,406,605,646}:contains(arr.message_id) then
		debuffed_mobs[arr.target_id] = nil
	elseif additional_effect_status_messages:contains(arr.message_id) then
		apply_additional_effect_status(arr.target_id, arr.message_id, arr.param_1)
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
					debuffed_mobs[arr.target_id][386] = nil
					step_duration[386] = 0
				elseif T{391,392,393,394,395}:contains(arr.param_1) then
					debuffed_mobs[arr.target_id][391] = nil
					step_duration[391] = 0
				elseif T{396,397,398,399,400}:contains(arr.param_1) then
					debuffed_mobs[arr.target_id][396] = nil
					step_duration[396] = 0
				elseif T{448,449,450,451,452}:contains(arr.param_1) then
					debuffed_mobs[arr.target_id][448] = nil
					step_duration[448] = 0
				elseif arr.param_1 == 3 then
					debuffed_mobs[arr.target_id][3] = nil
					debuffed_mobs[arr.target_id][652] = nil
				elseif arr.param_1 == 134 then
					debuffed_mobs[arr.target_id][134] = nil
					debuffed_mobs[arr.target_id][655] = nil
					debuffed_mobs[arr.target_id][656] = nil
				elseif arr.param_1 == 135 then
					debuffed_mobs[arr.target_id][135] = nil
					debuffed_mobs[arr.target_id][653] = nil
					debuffed_mobs[arr.target_id][654] = nil
				elseif arr.param_1 == 193 or arr.param_1 == 2 or arr.param_1 == 19 then
                    debuffed_mobs[arr.target_id][2] = nil
                    debuffed_mobs[arr.target_id][19] = nil
                    debuffed_mobs[arr.target_id][193] = nil
                    debuffed_mobs[arr.target_id][640] = nil
                    debuffed_mobs[arr.target_id][650] = nil
                    debuffed_mobs[arr.target_id][651] = nil
				elseif arr.param_1 == 217 then
			        debuffed_mobs[arr.target_id][arr.param_1] = nil
			        debuffed_mobs[arr.target_id][641] = nil
			        debuffed_mobs[arr.target_id][642] = nil
			        debuffed_mobs[arr.target_id][643] = nil
			        debuffed_mobs[arr.target_id][644] = nil
			        debuffed_mobs[arr.target_id][645] = nil
			        debuffed_mobs[arr.target_id][646] = nil
			        debuffed_mobs[arr.target_id][647] = nil
			        debuffed_mobs[arr.target_id][648] = nil
			        
			    -- ANGON / DEFENSE DOWN CLEAR LOGIC
				elseif arr.param_1 == 149 then
					debuffed_mobs[arr.target_id][149] = nil
					debuffed_mobs[arr.target_id][170] = nil
					
				-- HELIX CLEAR LOGIC
				elseif arr.param_1 >= 178 and arr.param_1 <= 186 then
					for i = 178, 186 do
						debuffed_mobs[arr.target_id][i] = nil
					end
					
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
		local packet = packets.parse('incoming', data)
		local arr = {}
		arr.target_id = packet['Target']
		arr.param_1 = packet['Param 1']
		arr.message_id = packet['Message']
		
		inc_action_message(arr)
	end
end)

windower.register_event('prerender', function()
    if is_setup_mode then 
        if anchor_box then
            local cur_x, cur_y = anchor_box:pos()
            
            for i, img in ipairs(dummy_images) do
                local col = (i - 1) % 10 
                img:pos(cur_x + (col * (icon_size + 5)), cur_y)
            end
        end
        return
    end
    
    local curr = os.clock()
    if curr > frame_time + .1 then
        frame_time = curr
        update_box()
    end
end)

windower.register_event('unload', function()
    for _, img in pairs(ui_icons) do
        if img then img:destroy() end
    end
    for _, txt in pairs(ui_timers) do
        if txt then txt:destroy() end
    end
    if text_box then text_box:destroy() end
	if buff_text_box then buff_text_box:destroy() end
end)

windower.register_event('addon command', function(...)
    local args = {...}
    local cmd = args[1] and args[1]:lower()

    if cmd == 'setup' then
        is_setup_mode = not is_setup_mode
        if is_setup_mode then
            for _, img in pairs(ui_icons) do img:hide() end
            for _, txt in pairs(ui_timers) do txt:hide() end
            
            windower.add_to_chat(207, 'Debuffed: Setup mode ON.')
            enable_setup_mode()
        else
            windower.add_to_chat(207, 'Debuffed: Setup mode OFF.')
            disable_setup_mode()
        end
		
    elseif cmd == 'mode' then
        settings.display_mode = settings.display_mode or 'icon'
        
        if settings.display_mode == 'icon' then
            settings.display_mode = 'text'
            windower.add_to_chat(207, 'Debuffed: Display mode set to TEXT.')
        else
            settings.display_mode = 'icon'
            windower.add_to_chat(207, 'Debuffed: Display mode set to ICON.')
        end
        
        config.save(settings, 'all')
		
    elseif cmd == 'pos' and is_setup_mode then
        local new_x = tonumber(args[2])
        local new_y = tonumber(args[3])
        
        if new_x and new_y then
            base_pos_x = new_x
            base_pos_y = new_y
            for i, img in ipairs(dummy_images) do
                local col = (i - 1) % 10 
                img:pos(base_pos_x + (col * (icon_size + 5)), base_pos_y)
            end
            windower.add_to_chat(207, 'Debuffed: Position updated to ' .. new_x .. ', ' .. new_y)
        else
            windower.add_to_chat(167, 'Debuffed: Invalid coordinates. Use //debuffed pos x y')
        end
		
	elseif cmd == 'align' then
        local diff_x = math.abs(settings.pos.x - settings.buff_pos.x)
        local diff_y = math.abs(settings.pos.y - settings.buff_pos.y)

        if diff_x < diff_y then
            settings.buff_pos.x = settings.pos.x
            buff_pos_x = settings.pos.x
            windower.add_to_chat(207, 'Debuffed: Vertically aligned! (Matched Left Edges)')
            
        else
            settings.buff_pos.y = settings.pos.y
            buff_pos_y = settings.pos.y
            windower.add_to_chat(207, 'Debuffed: Horizontally aligned! (Matched Top Edges)')
        end
        
        if is_setup_mode and buff_anchor_box then
            buff_anchor_box:pos(buff_pos_x, buff_pos_y)
        end
		
    elseif cmd == 'buffdir' then
        -- If it doesn't exist yet, default it to reversed (your preference)
        settings.buff_direction = settings.buff_direction or 'reverse'
        
        if settings.buff_direction == 'reverse' then
            settings.buff_direction = 'normal'
            windower.add_to_chat(207, 'Debuffed: Buffs will now draw Left-to-Right (Normal).')
        else
            settings.buff_direction = 'reverse'
            windower.add_to_chat(207, 'Debuffed: Buffs will now draw Right-to-Left (Reverse).')
        end
	
	elseif cmd == 'filter' then
        -- Uses a new setting name so it doesn't conflict with your text/icon 'mode'
        settings.filter_mode = settings.filter_mode or 'blacklist'
        
        if settings.filter_mode == 'blacklist' then
            settings.filter_mode = 'whitelist'
            windower.add_to_chat(207, 'Debuffed: Target filtering set to WHITELIST.')
        else
            settings.filter_mode = 'blacklist'
            windower.add_to_chat(207, 'Debuffed: Target filtering set to BLACKLIST.')
        end
        
        config.save(settings, 'all')
    end
end)