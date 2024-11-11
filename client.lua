local PlayerJob, Props, Targets, Peds, Blip, soundId = {}, {}, {}, {}, {}, GetSoundId()
------------------------------------------------------------
-- Define only K4MB1 props
local propTable = Config.PropTable

--Hide the mineshaft doors
CreateModelHide(vec3(-596.04, 2089.01, 131.41), 10.5, -1241212535, true)

function removeJob()
	for k in pairs(Targets) do exports.ox_target:removeZone(k)	end
	for _, v in pairs(Peds) do unloadModel(GetEntityModel(v)) DeletePed(v) end
	for i = 1, #Props do unloadModel(GetEntityModel(Props[i])) DeleteObject(Props[i]) end
	for i = 1, #Blip do RemoveBlip(Blip[i]) end
end

function HasItemClient(item, amount)
    if amount == nil then amount = 1 end
	local itemCount = exports.ox_inventory:GetItemCount(item)
	if not itemCount then
		return false
	elseif itemCount >= amount then
		return true
	else
		return false
	end
end

function GetItemLabel(item)
	return exports.ox_inventory:Items(item).label
end

function GetItemImage(item)
	if exports.ox_inventory:Items(item).client.image ~= nil then
		return exports.ox_inventory:Items(item).client.image
	else
		return "nui://" .. Config.img .. item .. ".png"
	end
end

function makeJob()
	removeJob()
	--Ore Spawning
	for mine in pairs(Config.Locations["Mines"]) do
		local loc = Config.Locations["Mines"][mine]
		if loc.Enable then
		--[[Blips]]--
			if loc.Blip.Enable then Blip[#Blip+1] = makeBlip(loc["Blip"]) end
		--[[Ores]]--
		--[[Ores]]--
        if loc["OrePositions"] then
            for i = 1, #loc["OrePositions"] do
                local name = "Ore_"..mine.."_"..i
                local coords = loc["OrePositions"][i]

                function pickPropByWeight(propTable)
                    local totalWeight = 0
                    for _, prop in ipairs(propTable) do
                        totalWeight = totalWeight + prop.weight
                    end

                    local randomWeight = math.random() * totalWeight
                    local currentWeight = 0

                    for _, prop in ipairs(propTable) do
                        currentWeight = currentWeight + prop.weight
                        if randomWeight <= currentWeight then
                            return prop
                        end
                    end
                end        

                -- Pick a prop based on weights
                local propPick = pickPropByWeight(propTable)
                local propType = propPick.type
				local propItem = propPick.item
                local fullProp = makeProp({coords = vec4(coords.x, coords.y, coords.z + 0.8, coords.a), prop = propPick.full}, 1, false)

                local rot = GetEntityRotation(fullProp)
                rot = vec3(rot.x - math.random(60,100), rot.y, rot.z)
                SetEntityRotation(fullProp, rot.x, rot.y, rot.z, 0, 0)
                Targets[name] =
				exports.ox_target:addSphereZone({
					name = name,
					coords = vec3(coords.x, coords.y, coords.z),
					radius = 1.2,
					debug = Config.Debug,
					options = {
						{
							onSelect = function()
								local data = {
									name = name,
									job = Config.Job,
									stone = fullProp,
									type = propType,
									giveItem = propItem,
									item = "pickaxe",
								}
								TriggerEvent("jim-mining:MineOre:Pick", data)
							end,
							icon = "fas fa-hammer",
							label = string.format("Mine %s with %s", propType, GetItemLabel("pickaxe")),
							canInteract = function()
								return HasItemClient('pickaxe', 1)
							end
						},
						{
							onSelect = function()
								local data = {
									name = name,
									job = Config.Job,
									stone = fullProp,
									type = propType,
									giveItem = propItem,
									item = "miningdrill",
								}
								TriggerEvent("jim-mining:MineOre:Drill", data)
							end,
							icon = "fas fa-screwdriver",
							label = string.format("Mine %s with %s", propType, GetItemLabel("miningdrill")),
							canInteract = function()
								return HasItemClient('miningdrill', 1)
							end
						},
						{
							onSelect = function()
								local data = {
									name = name,
									job = Config.Job,
									stone = fullProp,
									type = propType,
									giveItem = propItem,
									item = "mininglaser",
								}
								TriggerEvent("jim-mining:MineOre:Laser", data)
							end,
							icon = "fas fa-screwdriver-wrench",
							label = string.format("Mine %s with %s", propType, GetItemLabel("mininglaser")),
							canInteract = function()
								return HasItemClient('mininglaser', 1)
							end
						},
					},
					distance = 1.7  -- Interaction distance for mining
				})
            end
        end
		--[[LIGHTS]]--
			if loc["Lights"] then
				if loc["Lights"].Enable then
					for i = 1, #loc["Lights"].positions do
						Props[#Props+1] = makeProp({coords = loc["Lights"].positions[i], prop = loc["Lights"].prop}, 1, false)
					end
				end
			end
		--[[Smelting]]--
			if loc["Smelting"] then
				for i = 1, #loc["Smelting"] do local name = "Smelting".."_"..mine.."_"..i
					if loc["Smelting"][i].blipEnable then Blip[#Blip+1] = makeBlip(loc["Smelting"][i]) end
					Targets[name] =
					exports.ox_target:addSphereZone({
						name = name,
						coords = loc["Smelting"][i].coords.xyz,
						radius = 3.0,
						debug = Config.Debug,
						options = {
							{
								name = name,
								event = "jim-mining:CraftMenu",
								icon = "fas fa-fire-burner",
								label = Loc[Config.Lan].info["use_smelter"],
								craftable = Crafting.SmeltMenu,
								job = loc.Job
							}
						},
						distance = 10.0  -- Adjusted targetable distance to match qb-target distance
					})
				end
			end
		--[[Jewel Cutting]]--
		if loc["JewelCut"] then
			for i = 1, #loc["JewelCut"] do 
				local name = "JewelCut_" .. mine .. "_" .. i
				local pointData = loc["JewelCut"][i]
		
				-- Create the blip if enabled
				if pointData.blipEnable then 
					Blip[#Blip + 1] = makeBlip(pointData) 
				end
		
				-- Create a prop at the JewelCut location
				Props[#Props + 1] = makeProp(pointData, 1, false)
				local prop = Props[#Props]
		
				-- Define the point for interaction
				lib.points.new({
					coords = GetEntityCoords(prop),
					distance = 2.0, -- 2 meters interaction distance
					onEnter = function()
						-- Show text UI when entering interaction range
						lib.showTextUI(Loc[Config.Lan].info["jewelcut"] or "Cut Jewel", { icon = "fas fa-gem" })
					end,
					onExit = function()
						-- Hide text UI when leaving interaction range
						lib.hideTextUI()
					end,
					nearby = function()
						-- Trigger the jewel cutting event when player presses 'E'
						if IsControlJustPressed(1, 38) then -- 'E' key
							local data = {
								bench = Props[#Props]
							}
							TriggerEvent("jim-mining:JewelCut", data)
						end
					end
				})
			end
		end		
		end
	end
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
	local PlayerData = QBX.PlayerData
	PlayerJob = PlayerData.job
	if Config.Job then if PlayerJob.name == Config.Job then makeJob() else removeJob() end else makeJob() end
end)
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
	PlayerJob = JobInfo
	if Config.Job then if PlayerJob.name == Config.Job then makeJob() else removeJob() end end
end)
AddEventHandler('onResourceStart', function(resource) if GetCurrentResourceName() ~= resource then return end
	local PlayerData = QBX.PlayerData
	PlayerJob = PlayerData.job
	if Config.Job then if PlayerJob.name == Config.Job then makeJob() else removeJob() end else makeJob() end
end)

--------------------------------------------------------
function pickNewPropByWeight(propTable)
    return pickPropByWeight(propTable)
end

function stoneBreak(name, stone)
	print("Stone Break: ", name, stone)
    CreateThread(function()
        local rockcoords = GetEntityCoords(stone)
        if Config.Debug then print("^5Debug^7: ^2Hiding prop and target^7: '^6"..name.."^7' ^2at coords^7: ^6"..rockcoords) end

        -- Hide the current stone and remove the target
        SetEntityAlpha(stone, 0, false)
		exports.ox_target:removeZone(name)
        Targets[name] = nil

        -- Wait for respawn time
        Wait(Config.Debug and 2000 or Config.Timings["OreRespawn"])

        -- Pick a new prop based on weights
        local newPropPick = pickNewPropByWeight(propTable)
        local newPropType = newPropPick.type
        local newPropItem = newPropPick.item
        local newFullProp = makeProp({coords = vec4(rockcoords.x, rockcoords.y, rockcoords.z+1.03, 0), prop = newPropPick.full}, 1, false)

		-- Create new target zone for the new stone
        Targets[name] =
			exports.ox_target:addSphereZone({
				name = name,
				coords = vec3(rockcoords.x, rockcoords.y, rockcoords.z),
				radius = 1.2,
				debug = Config.Debug,
				options = {
					{
						onSelect = function()
							local data = {
								name = name,
								job = Config.Job,
								stone = newFullProp,
								type = newPropType,
								giveItem = newPropItem,
								item = "pickaxe",
							}
							TriggerEvent("jim-mining:MineOre:Pick", data)
						end,
						icon = "fas fa-hammer",
						label = string.format("Mine %s with %s", newPropType, GetItemLabel("pickaxe")),
						canInteract = function()
							return HasItemClient('pickaxe', 1)
						end
					},
					{
						onSelect = function()
							local data = {
								name = name,
								job = Config.Job,
								stone = newFullProp,
								type = newPropType,
								giveItem = newPropItem,
								item = "miningdrill",
							}
							TriggerEvent("jim-mining:MineOre:Drill", data)
						end,
						icon = "fas fa-screwdriver",
						label = string.format("Mine %s with %s", newPropType, GetItemLabel("miningdrill")),
						canInteract = function()
							return HasItemClient('miningdrill', 1)
						end
					},
					{
						onSelect = function()
							local data = {
								name = name,
								job = Config.Job,
								stone = newFullProp,
								type = newPropType,
								giveItem = newPropItem,
								item = "mininglaser",
							}
							TriggerEvent("jim-mining:MineOre:Laser", data)
						end,
						icon = "fas fa-screwdriver-wrench",
						label = string.format("Mine %s with %s", newPropType, GetItemLabel("miningdrill")),
						canInteract = function()
							return HasItemClient('mininglaser', 1)
						end
					},
				},
				distance = 1.7  -- Interaction distance for mining
			})
        if Config.Debug then print("^5Debug^7: ^2Remaking Prop and Target^7: '^6"..name.."^7' ^2at coords^7: ^6"..rockcoords) end
    end)
end

local isMining = false
RegisterNetEvent('jim-mining:MineOre:Pick', function(data) 
	local Ped = PlayerPedId()
	print("here")
	if isMining then return else isMining = true end -- Stop players from doubling up the event
	-- Anim Loading
	local dict = "amb@world_human_hammering@male@base"
	local anim = "base"
	loadAnimDict(tostring(dict))
	loadDrillSound()
	--Create Pickaxe and Attach
	local PickAxe = makeProp({ prop = "prop_tool_pickaxe", coords = vec4(0,0,0,0)}, 0, 1)
	DisableCamCollisionForObject(PickAxe)
	DisableCamCollisionForEntity(PickAxe)
	AttachEntityToEntity(PickAxe, Ped, GetPedBoneIndex(Ped, 57005), 0.09, -0.53, -0.22, 252.0, 180.0, 0.0, false, true, true, true, 0, true)
	local IsDrilling = true
	local rockcoords = GetEntityCoords(data.stone)
	--Calculate if you're facing the stone--
	lookEnt(data.stone)
	if #(rockcoords - GetEntityCoords(Ped)) > 1.5 then TaskGoStraightToCoord(Ped, rockcoords, 0.5, 400, 0.0, 0) Wait(400) end
	loadPtfxDict("core")
	CreateThread(function()
		while IsDrilling do
			UseParticleFxAssetNextCall("core")
			TaskPlayAnim(Ped, tostring(dict), tostring(anim), 8.0, -8.0, -1, 2, 0, false, false, false)
			Wait(200)
			local pickcoords = GetOffsetFromEntityInWorldCoords(PickAxe, -0.4, 0.0, 0.7)
			local dust = StartNetworkedParticleFxNonLoopedAtCoord("ent_dst_rocks", pickcoords.x, pickcoords.y, pickcoords.z, 0.0, 0.0, 0.0, 0.4, 0.0, 0.0, 0.0)
			Wait(350)
		end
	end)
	if progressBar({label = Loc[Config.Lan].info["drilling_ore"], time = Config.Debug and 1000 or Config.Timings["Pickaxe"], cancel = true, icon = "pickaxe"}) then
		TriggerServerEvent('jim-mining:Reward', { mine = true, cost = nil }, data.giveItem)
		if math.random(1,10) >= 9 then
			local breakId = GetSoundId()
			PlaySoundFromEntity(breakId, "Drill_Pin_Break", Ped, "DLC_HEIST_FLEECA_SOUNDSET", 1, 0)
			toggleItem(false, "pickaxe", 1)
		end
		stoneBreak(data.name, data.stone)
	end
	StopAnimTask(Ped, tostring(dict), tostring(anim), 1.0)
	destroyProp(PickAxe)
	unloadPtfxDict("core")
	unloadAnimDict(dict)
	unloadDrillSound()
	StopSound(soundId)
	IsDrilling = false
	isMining = false
end)

RegisterNetEvent('jim-mining:MineOre:Drill', function(data) local Ped = PlayerPedId()
	if isMining then return else isMining = true end -- Stop players from doubling up the event
	if HasItemClient("drillbit", 1) then
		-- Sounds & Anim loading
		loadDrillSound()
		local dict = "anim@heists@fleeca_bank@drilling"
		local anim = "drill_straight_fail"
		loadAnimDict(tostring(dict))
		--Create Drill and Attach
		local DrillObject = makeProp({ prop = "hei_prop_heist_drill", coords = vec4(0,0,0,0)}, 0, 1)
		AttachEntityToEntity(DrillObject, Ped, GetPedBoneIndex(Ped, 57005), 0.14, 0, -0.01, 90.0, -90.0, 180.0, true, true, false, true, 1, true)
		local IsDrilling = true
		local rockcoords = GetEntityCoords(data.stone)
		--Calculate if you're heading is within 20.0 degrees -
		lookEnt(data.stone)
		if #(rockcoords - GetEntityCoords(Ped)) > 1.5 then TaskGoStraightToCoord(Ped, rockcoords, 0.5, 400, 0.0, 0) Wait(400) end
		TaskPlayAnim(Ped, tostring(dict), tostring(anim), 3.0, 3.0, -1, 1, 0, false, false, false)
		Wait(200)
		if Config.DrillSound then PlaySoundFromEntity(soundId, "Drill", DrillObject, "DLC_HEIST_FLEECA_SOUNDSET", 1, 0) end
		CreateThread(function() -- Dust/Debris Animation
			loadPtfxDict("core")
			while IsDrilling do
				UseParticleFxAssetNextCall("core")
				local dust = StartNetworkedParticleFxNonLoopedAtCoord("ent_dst_rocks", rockcoords.x, rockcoords.y, rockcoords.z, 0.0, 0.0, GetEntityHeading(Ped)-180.0, 1.0, 0.0, 0.0, 0.0)
				Wait(600)
			end
		end)
		if progressBar({label = Loc[Config.Lan].info["drilling_ore"], time = Config.Debug and 1000 or Config.Timings["Pickaxe"], cancel = true, icon = "pickaxe"}) then
			TriggerServerEvent('jim-mining:Reward', { mine = true, cost = nil }, data.giveItem)
			--Destroy drill bit chances
			if math.random(1, 10) >= 8 then
				local breakId = GetSoundId()
				PlaySoundFromEntity(breakId, "Drill_Pin_Break", Ped, "DLC_HEIST_FLEECA_SOUNDSET", 1, 0)
				toggleItem(0, "drillbit", 1)
				stoneBreak(data.name, data.stone)
			end
		end
		StopAnimTask(Ped, "anim@heists@fleeca_bank@drilling", "drill_straight_idle", 1.0)
		unloadDrillSound()
		StopSound(soundId)
		destroyProp(DrillObject)
		unloadPtfxDict("core")
		unloadAnimDict(dict)
		IsDrilling = false
		isMining = false
	else
		triggerNotify(nil, Loc[Config.Lan].error["no_drillbit"], nil) isMining = false return
	end
end)

RegisterNetEvent('jim-mining:MineOre:Laser', function(data) local Ped = PlayerPedId()
	if isMining then return else isMining = true end -- Stop players from doubling up the event
	-- Sounds & Anim Loading
	RequestAmbientAudioBank("DLC_HEIST_BIOLAB_DELIVER_EMP_SOUNDS", 0)
	RequestAmbientAudioBank("dlc_xm_silo_laser_hack_sounds", 0)
	local dict = "anim@heists@fleeca_bank@drilling"
	local anim = "drill_straight_fail"
	loadAnimDict(dict)
	--Create Drill and Attach
	local DrillObject = makeProp({ prop = "ch_prop_laserdrill_01a", coords = vec4(0,0,0,0)}, 0, 1)
	AttachEntityToEntity(DrillObject, Ped, GetPedBoneIndex(Ped, 57005), 0.14, 0, -0.01, 90.0, -90.0, 180.0, true, true, false, true, 1, true)
	local IsDrilling = true
	local rockcoords = GetEntityCoords(data.stone)
	--Calculate if you're facing the stone--
	lookEnt(data.stone)
	--Activation noise & Anims
	TaskPlayAnim(Ped, tostring(dict), 'drill_straight_idle' , 3.0, 3.0, -1, 1, 0, false, false, false)
	PlaySoundFromEntity(soundId, "Pass", DrillObject, "dlc_xm_silo_laser_hack_sounds", 1, 0) Wait(1000)
	TaskPlayAnim(Ped, tostring(dict), tostring(anim), 3.0, 3.0, -1, 1, 0, false, false, false)
	PlaySoundFromEntity(soundId, "EMP_Vehicle_Hum", DrillObject, "DLC_HEIST_BIOLAB_DELIVER_EMP_SOUNDS", 1, 0) --Not sure about this sound, best one I could find as everything else wouldn't load
	--Laser & Debris Effect
	local lasercoords = GetOffsetFromEntityInWorldCoords(DrillObject, 0.0,-0.5, 0.02)
	CreateThread(function()
		loadPtfxDict("core")
		while IsDrilling do
			UseParticleFxAssetNextCall("core")
			local laser = StartNetworkedParticleFxNonLoopedAtCoord("muz_railgun", lasercoords.x, lasercoords.y, lasercoords.z, 0, -10.0, GetEntityHeading(DrillObject)+270, 1.0, 0.0, 0.0, 0.0)
			UseParticleFxAssetNextCall("core")
			local dust = StartNetworkedParticleFxNonLoopedAtCoord("ent_dst_rocks", rockcoords.x, rockcoords.y, rockcoords.z, 0.0, 0.0, GetEntityHeading(Ped)-180.0, 1.0, 0.0, 0.0, 0.0)
			Wait(60)
		end
	end)
	if progressBar({label = Loc[Config.Lan].info["drilling_ore"], time = Config.Debug and 1000 or Config.Timings["Laser"], cancel = true, icon = "mininglaser"}) then
		TriggerServerEvent('jim-mining:Reward', { mine = true, cost = nil }, data.giveItem)
		stoneBreak(data.name, data.stone)
	end
	IsDrilling = false
	isMining = false
	StopAnimTask(Ped, tostring(dict), tostring(anim), 1.0)
	ReleaseAmbientAudioBank("DLC_HEIST_BIOLAB_DELIVER_EMP_SOUNDS")
	ReleaseAmbientAudioBank("dlc_xm_silo_laser_hack_sounds")
	StopSound(soundId)
	destroyProp(DrillObject)
	unloadPtfxDict("core")
	unloadAnimDict(dict)
end)
------------------------------------------------------------
--Cutting Jewels
RegisterNetEvent('jim-mining:JewelCut', function(data)
	local cutMenu = {}
    local table = {
		{ header = Loc[Config.Lan].info["gem_cut"],	txt = Loc[Config.Lan].info["gem_cut_section"], craftable = Crafting.GemCut, },
		{ header = Loc[Config.Lan].info["make_ring"], txt = Loc[Config.Lan].info["ring_craft_section"], craftable = Crafting.RingCut, },
		{ header = Loc[Config.Lan].info["make_neck"], txt = Loc[Config.Lan].info["neck_craft_section"], craftable = Crafting.NeckCut, },
		{ header = Loc[Config.Lan].info["make_ear"], txt = Loc[Config.Lan].info["ear_craft_section"], craftable = Crafting.EarCut, },
	}
	for i = 1, #table do
		cutMenu[#cutMenu+1] = {
			header = table[i].header, txt = table[i].txt, params = { event = "jim-mining:CraftMenu", args = { craftable = table[i].craftable, ret = true, bench = data.bench } },
			title = table[i].header, description = table[i].txt, event = "jim-mining:CraftMenu", args = { craftable = table[i].craftable, ret = true, bench = data.bench },
		}
	end
	exports.ox_lib:registerContext({id = 'cutMenu', title = Loc[Config.Lan].info["craft_bench"], position = 'top-right', options = cutMenu })
	exports.ox_lib:showContext("cutMenu")
end)

RegisterNetEvent('jim-mining:CraftMenu', function(data)
	local CraftMenu = {} local header = (data and data.ret) and Loc[Config.Lan].info["craft_bench"] or Loc[Config.Lan].info["smelter"]
	if data.ret then
		CraftMenu[#CraftMenu + 1] = { icon = "fas fa-circle-arrow-left", header = "", txt = Loc[Config.Lan].info["return"], title = Loc[Config.Lan].info["return"], event = "jim-mining:JewelCut", args = data, params = { event = "jim-mining:JewelCut", args = data } }
	end
	for i = 1, #data.craftable do
		for k in pairs(data.craftable[i]) do
			if k ~= "amount" then
					local text = ""
					setheader = GetItemLabel(tostring(k))
					if data.craftable[i]["amount"] ~= nil then setheader = setheader.." x"..data.craftable[i]["amount"] end
					local disable = false
					local checktable = {}
					for l, b in pairs(data.craftable[i][tostring(k)]) do
						if b == 0 or b == 1 then number = "" else number = " x"..b end
						print(l)
						text = text..GetItemLabel(l)..number.."\n"
						settext = text
						checktable[l] = HasItemClient(l, b)
					end
					for _, v in pairs(checktable) do if v == false then disable = true break end end
					if not disable then setheader = setheader.." ✔️" end
					local event = Config.MultiCraft and "jim-mining:Crafting:MultiCraft" or "jim-mining:Crafting:MakeItem"
					CraftMenu[#CraftMenu + 1] = {
						disabled = disable,
						icon = GetItemImage(tostring(k)),
						header = setheader, txt = settext, --qb-menu
						title = setheader, description = settext, -- ox_lib
						event = event, args = { item = k, craft = data.craftable[i], craftable = data.craftable, header = header, ret = data.ret, bench = data.bench }, -- ox_lib
						params = { event = event, args = { item = k, craft = data.craftable[i], craftable = data.craftable, header = header, ret = data.ret, bench = data.bench } } -- qb-menu
					}
					settext, setheader = nil
				end
			end
		end

	exports.ox_lib:registerContext({id = 'CraftMenu', title = data.ret and Loc[Config.Lan].info["craft_bench"] or Loc[Config.Lan].info["smelter"], position = 'top-right', options = CraftMenu })
	exports.ox_lib:showContext("CraftMenu")
	lookEnt(data.coords)
end)

RegisterNetEvent('jim-mining:Crafting:MultiCraft', function(data)
    local success = Config.MultiCraftAmounts local Menu = {}
    for k in pairs(success) do success[k] = true
        for l, b in pairs(data.craft[data.item]) do
            local has = HasItemClient(l, (b * k)) if not has then success[k] = false break else success[k] = true end
		end end
	Menu[#Menu+1] = { icon = "fas fa-arrow-left", title = Loc[Config.Lan].info["return"], header = "", txt = Loc[Config.Lan].info["return"], params = { event = "jim-mining:CraftMenu", args = data }, event = "jim-mining:CraftMenu", args = data }
	for k in pairsByKeys(success) do
		Menu[#Menu+1] = {
			disabled = not success[k],
			icon = GetItemImage(data.item), header = GetItemLabel(data.item).." (x"..k * (data.craft.amount or 1)..")", title = GetItemLabel(data.item).." (x"..k * (data.craft.amount or 1)..")",
			event = "jim-mining:Crafting:MakeItem", args = { item = data.item, craft = data.craft, craftable = data.craftable, header = data.header, anim = data.anim, amount = k, ret = data.ret, bench = data.bench },
			params = { event = "jim-mining:Crafting:MakeItem", args = { item = data.item, craft = data.craft, craftable = data.craftable, header = data.header, anim = data.anim, amount = k, ret = data.ret, bench = data.bench } }
		}
	end
	exports.ox_lib:registerContext({id = 'Crafting', title = data.ret and Loc[Config.Lan].info["craft_bench"] or Loc[Config.Lan].info["smelter"], position = 'top-right', options = Menu })
	exports.ox_lib:showContext("Crafting")
end)

RegisterNetEvent('jim-mining:Crafting:MakeItem', function(data) local bartext, animDictNow, animNow, scene, Ped = "", nil, nil, nil, PlayerPedId()
	if not data.ret then bartext = Loc[Config.Lan].info["smelting"]..GetItemLabel(data.item)
	else bartext = Loc[Config.Lan].info["cutting"]..GetItemLabel(data.item) end
	local bartime = Config.Timings["Crafting"]
	if (data.amount and data.amount ~= 1) then data.craft.amount = data.craft.amount or 1 data.craft["amount"] *= data.amount
		for k in pairs(data.craft[data.item]) do data.craft[data.item][k] *= data.amount end
		bartime *= data.amount bartime *= 0.9
	end
	lockInv(true)
	local isDrilling = true
	if data.ret then -- If jewelcutting
		if not HasItemClient("drillbit", 1) then
			triggerNotify(nil, Loc[Config.Lan].error["no_drillbit"], 'error')
			TriggerEvent('jim-mining:JewelCut', data)
			lockInv(false)
			return
		else
			local dict = "anim@amb@machinery@speed_drill@"
			local anim = "operate_02_hi_amy_skater_01"
			loadAnimDict(tostring(dict))
			lockInv(true)
			loadDrillSound()
			if Config.DrillSound then
				PlaySoundFromEntity(soundId, "Drill", PlayerPedId(), "DLC_HEIST_FLEECA_SOUNDSET", 0.5, 0)
			end
			local drillcoords = GetOffsetFromEntityInWorldCoords(data.bench, 0.0, -0.15, 1.1)
			scene = NetworkCreateSynchronisedScene(GetEntityCoords(data.bench), GetEntityRotation(data.bench), 2, false, false, 1065353216, 0, 1.3)
			NetworkAddPedToSynchronisedScene(Ped, scene, tostring(dict), tostring(anim), 0, 0, 0, 16, 1148846080, 0)
			NetworkStartSynchronisedScene(scene)
			CreateThread(function()
				loadPtfxDict("core")
				while isDrilling do
					UseParticleFxAssetNextCall("core")
					local dust = StartNetworkedParticleFxNonLoopedAtCoord("glass_side_window", drillcoords.x, drillcoords.y, drillcoords.z, 0.0, 0.0, GetEntityHeading(Ped)+math.random(0, 359), 0.2, 0.0, 0.0, 0.0)
					Wait(100)
				end
				unloadAnimDict(dict)
			end)
		end
	else -- If not Jewel Cutting, you'd be smelting (need to work out what is possible for this)
		animDictNow = "amb@prop_human_parking_meter@male@idle_a"
		animNow = "idle_a"
	end
	if progressBar({ label = bartext, time = Config.Debug and 2000 or bartime, cancel = true, dict = animDictNow, anim = animNow, flag = 8, icon = data.item }) then
		TriggerServerEvent('jim-mining:Crafting:GetItem', data.item, data.craft)
		if data.ret then
			if math.random(1, 1000) <= 75 then
				local breakId = GetSoundId()
				PlaySoundFromEntity(breakId, "Drill_Pin_Break", Ped, "DLC_HEIST_FLEECA_SOUNDSET", 1, 0)
				toggleItem(false, "drillbit", 1)
			end
		end
		Wait(500)
		TriggerEvent("jim-mining:CraftMenu", data)
	end
	lockInv(false)
	StopSound(soundId)
	unloadDrillSound()
	lockInv(false)
	NetworkStopSynchronisedScene(scene)
	unloadPtfxDict("core")
	isDrilling = false
	StopAnimTask(Ped, animDictNow, animNow, 1.0)
	FreezeEntityPosition(Ped, false)
end)

AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() then removeJob() end end)
