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
	--plants
	berrybush = 1440,
	berrybush2 = 1440,
	berrybush_juicy = 1440,
	carrot_planted = 240,
	evergreen = 30,
	deciduoustree = 30,
	marsh_tree = 480,
	twiggytree = 480,
	flower = 240,
	flower_evil = 480,
	grass = 240,
	blue_mushroom = 240,
	red_mushroom = 240,
	green_mushroom = 240,
	reeds = 480,
	sapling = 240,
	marsh_bush = 480,
	cactus = 480,
	rock1 = 240,
	rock2 = 240,
	rock_flintless = 240,
	marbletree=1440,
	rock_moon = 480,
	stalagmite = 240,
	stalagmite_tall = 240,
}

local event = 
{
	houndbone = 960,
	pighead = 960,
	marblepillar = 1440,
	livingtree = 960,
	mandrake = 960,
	beehive = 480,
	wasphive = 960,
	houndmound = 1440,
	pighouse = 960,
	mermhouse = 960,
	spiderden = 960,
	molehill = 960,
	catcoonden = 960,
	tentacle = 480,
	rabbithole = 480,
	fireflies = 480,
	knight = 23,
	bishop = 9,
	rook = 34,
	knight_nightmare = 1440,
	bishop_nightmare = 1440,
	rook_nightmare = 1440,
	monkeypods = 1440,
	ruins_statue_mage = 960,
	ruins_statue_mage_nogem = 960,
	ruins_statue_head = 960,
	ruins_statue_head_nogem = 960,
	rabbithouse = 960
}

AddComponentPostInit("natural_regrowth", function(component)
	for prefab, time in pairs(natural) do
		component:RegisterRegrowth(prefab, prefab, time)
	end
end)

AddComponentPostInit("event_regrowth", function(component)
	for prefab, time in pairs(event) do
		component:RegisterRegrowth(prefab, prefab, time)
	end
	component:FinishModConfig()
end)  


--"forest" for the overworld
--"cave" for the caves. 
--No more "world" prefab.