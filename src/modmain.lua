local REGROWTH_TYPE = 
{
    NATURAL = 1,
    EVENT = 2
}

local DEBUG = false

-- Configuration Generation
-- I can't reference this from another file... duplicate
local config_table = 
{
    {"evergreen","Evergreen", REGROWTH_TYPE.NATURAL, 251},
    {"deciduoustree","Birchnut Tree",REGROWTH_TYPE.NATURAL, 251},
    {"marsh_tree","Spiky Tree",REGROWTH_TYPE.NATURAL, 480},
    {"twiggytree","Twiggy Tree",REGROWTH_TYPE.NATURAL, 491},
    {"marbletree","Marble Tree",REGROWTH_TYPE.EVENT, 960},
	{"livingtree","Totally Normal Tree",REGROWTH_TYPE.EVENT, 969},
	{"mushtree_tall","Blue Mushtree", REGROWTH_TYPE.NATURAL, 251},
	{"mushtree_medium","Red Mushtree",REGROWTH_TYPE.NATURAL, 229},
	{"mushtree_small","Green Mushtree", REGROWTH_TYPE.NATURAL, 240},

    {"berrybush","Berry Bush",REGROWTH_TYPE.NATURAL, 1451},
    {"berrybush2","Spiky Berry Bush",REGROWTH_TYPE.NATURAL, 1429},
    {"berrybush_juicy","Juicy Berry Bush",REGROWTH_TYPE.NATURAL, 1429},

    {"carrot_planted","Carrot",REGROWTH_TYPE.NATURAL, 240},
    {"flower","Flower",REGROWTH_TYPE.NATURAL, 229},
	{"flower_evil","Evil Flower",REGROWTH_TYPE.EVENT, 480},
	{"flower_cave","Light Flower",REGROWTH_TYPE.EVENT, 480},
	{"flower_cave_double","Double Light Flower",REGROWTH_TYPE.EVENT, 489},
	{"flower_cave_triple","Triple Light Flower",REGROWTH_TYPE.EVENT, 471},
    {"blue_mushroom","Blue Mushroom",REGROWTH_TYPE.NATURAL, 249},
    {"red_mushroom","Red Mushroom",REGROWTH_TYPE.NATURAL, 240},
    {"green_mushroom","Green Mushroom",REGROWTH_TYPE.NATURAL, 240},
    {"cactus","Cactus",REGROWTH_TYPE.NATURAL, 479},
    {"mandrake_planted","Mandrake",REGROWTH_TYPE.EVENT, 969},

    {"reeds","Reeds",REGROWTH_TYPE.NATURAL, 480},
    {"sapling","Sapling",REGROWTH_TYPE.NATURAL, 240},
    {"grass","Grass",REGROWTH_TYPE.NATURAL, 229},
    {"marsh_bush","Spiky Bush",REGROWTH_TYPE.NATURAL, 480},

    {"rock1","Boulder",REGROWTH_TYPE.NATURAL, 229},
    {"rock2","Gold Vein",REGROWTH_TYPE.NATURAL, 240},
    {"rock_flintless","Flintless Boulder",REGROWTH_TYPE.NATURAL, 251},
    {"rock_moon","Moon Rock",REGROWTH_TYPE.NATURAL, 480},

    {"stalagmite","Stalagmite",REGROWTH_TYPE.NATURAL, 229},
    {"stalagmite_tall","Tall Stalagmite",REGROWTH_TYPE.NATURAL, 240},

    {"beehive","Beehive",REGROWTH_TYPE.EVENT, 489},
    {"wasphive","Killer Bee Hive",REGROWTH_TYPE.EVENT, 969},
    {"houndmound","Hound Mound",REGROWTH_TYPE.EVENT, 1449},
    {"pighouse","Pig House",REGROWTH_TYPE.EVENT, 960},
    {"mermhouse","Rundown House",REGROWTH_TYPE.EVENT, 1429},
    {"spiderden","Spider Den",REGROWTH_TYPE.EVENT, 1431},
    {"catcoonden","Hollow Stump",REGROWTH_TYPE.EVENT, 951},
    {"rabbithouse","Rabbit Hutch",REGROWTH_TYPE.EVENT, 951},
    {"monkeypods","Splumonkey Pod",REGROWTH_TYPE.EVENT, 951},
    {"slurtlehole", "Slurtle Mound", REGROWTH_TYPE.EVENT, 951},
    {"tallbirdnest", "Tallbird Nest", REGROWTH_TYPE.EVENT, 960},

    {"fireflies","Fireflies",REGROWTH_TYPE.EVENT, 471},
    {"tentacle","Tentacle",REGROWTH_TYPE.EVENT, 489},
    {"knight","Clockwork Knight",REGROWTH_TYPE.EVENT, 1440},
    {"bishop","Clockwork Bishop",REGROWTH_TYPE.EVENT, 1431},
    {"rook","Clockwork Rook",REGROWTH_TYPE.EVENT, 1449},
    {"knight_nightmare","Damaged Knight",REGROWTH_TYPE.EVENT, 1449},
    {"bishop_nightmare","Damaged Bishop",REGROWTH_TYPE.EVENT, 1440},
    {"rook_nightmare","Damaged Rook",REGROWTH_TYPE.EVENT, 1440},

    {"ruins_statue_mage","Ancient Mage Statue",REGROWTH_TYPE.EVENT, 969},
    {"ruins_statue_mage_nogem","Gemless Ancient Mage Statue",REGROWTH_TYPE.EVENT, 969},
    {"ruins_statue_head","Ancient Head Statue",REGROWTH_TYPE.EVENT, 960},
    {"ruins_statue_head_nogem", "Gemless Ancient Head Statue", REGROWTH_TYPE.EVENT, 951}
}

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

AddComponentPostInit("natural_regrowth", function(component)
	for i = 1, #config_table do
		local entry = config_table[i]
		if entry[3] == REGROWTH_TYPE.NATURAL then
			local prefab = entry[1]
			local delay = entry[4]
			if GetModConfigData(prefab) then
				component:RegisterRegrowth(prefab, prefab, DEBUG and (delay / 100) or delay)
			end
		end
	end
	component:FinishModConfig()
end)

AddComponentPostInit("event_regrowth", function(component)
	for i = 1, #config_table do
		local entry = config_table[i]
		if entry[3] == REGROWTH_TYPE.EVENT then
			local prefab = entry[1]
			local delay = entry[4]
			if GetModConfigData(prefab) then
				component:RegisterRegrowth(prefab, prefab, DEBUG and (delay / 100) or delay)
			end
		end
	end
	component:FinishModConfig()
end)