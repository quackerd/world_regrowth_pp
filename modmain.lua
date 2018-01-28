if GLOBAL.STRINGS.NAMES.MIGRATION_PORTAL then
	-- we have caves
	AddPrefabPostInit("forest", function(inst)
		if inst.ismastersim then
			inst:AddComponent("natural_regrowth")
			inst:AddComponent("event_regrowth")
		end
	end)
	AddPrefabPostInit("cave", function(inst)
		if inst.ismastersim then
			inst:AddComponent("natural_regrowth")
			inst:AddComponent("event_regrowth")
		end
	end)
else
	-- only overworld
	AddPrefabPostInit("world", function(inst)
		if inst.ismastersim then
			inst:AddComponent("natural_regrowth")
			inst:AddComponent("event_regrowth")
		end
	end)
end

local natural = 
{	
	berrybush = 1451,
	berrybush2 = 1429,
	berrybush_juicy = 1429,
	carrot_planted = 240,
	evergreen = 251,
	deciduoustree = 251,
	marsh_tree = 480,
	twiggytree = 491,
	flower = 229,
	grass = 229,
	blue_mushroom = 251,
	red_mushroom = 240,
	green_mushroom = 240,
	reeds = 480,
	sapling = 240,
	marsh_bush = 480,
	cactus = 479,
	rock1 = 229,
	rock2 = 240,
	rock_flintless = 251,
	rock_moon = 480,
	stalagmite = 489,
	stalagmite_tall = 240,
}

local event = 
{
	flower_evil = 480,
	marbletree= 960,
	livingtree = 969,
	mandrake = 969,
	beehive = 489,
	wasphive = 969,
	houndmound = 1449,
	pighouse = 960,
	mermhouse = 960,
	spiderden = 1431,
	catcoonden = 951,
	tentacle = 489,
	rabbithole = 471,
	fireflies = 471,
	knight = 1431,
	bishop = 1431,
	rook = 1449,
	knight_nightmare = 1449,
	bishop_nightmare = 1440,
	rook_nightmare = 1440,
	monkeypods = 951,
	ruins_statue_mage = 969,
	ruins_statue_mage_nogem = 969,
	ruins_statue_head = 960,
	ruins_statue_head_nogem = 951,
	rabbithouse = 951,
	slurtlehole = 951
}

AddComponentPostInit("natural_regrowth", function(component)
	for prefab, time in pairs(natural) do
		if GetModConfigData(prefab) then
			component:RegisterRegrowth(prefab, prefab, time)
		end
	end
	component:FinishModConfig()
end)

AddComponentPostInit("event_regrowth", function(component)
	for prefab, time in pairs(event) do
		if GetModConfigData(prefab) then
			component:RegisterRegrowth(prefab, prefab, time)
		end
	end
	component:FinishModConfig()
end)  


--"forest" for the overworld
--"cave" for the caves. 
--No more "world" prefab.