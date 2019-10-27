local REGROWTH_TYPE = 
{
    EVENT = 1
}

-- Configuration Generation
-- I can't reference this from another file... duplicate
local config_table = 
{
    {"evergreen","Evergreen", REGROWTH_TYPE.EVENT, 1},
    {"deciduoustree","Birchnut Tree",REGROWTH_TYPE.EVENT, 1},
    {"marsh_tree","Spiky Tree",REGROWTH_TYPE.EVENT, 2},
    {"twiggytree","Twiggy Tree",REGROWTH_TYPE.EVENT, 2},
    {"marbletree","Marble Tree",REGROWTH_TYPE.EVENT, 4},
    {"livingtree","Totally Normal Tree",REGROWTH_TYPE.EVENT, 4},
    {"mushtree_tall","Blue Mushtree", REGROWTH_TYPE.EVENT, 1},
	{"mushtree_medium","Red Mushtree",REGROWTH_TYPE.EVENT, 1},
	{"mushtree_small","Green Mushtree", REGROWTH_TYPE.EVENT, 1},

    {"berrybush","Berry Bush",REGROWTH_TYPE.EVENT, 4},
    {"berrybush2","Spiky Berry Bush",REGROWTH_TYPE.EVENT, 4},
    {"berrybush_juicy","Juicy Berry Bush",REGROWTH_TYPE.EVENT, 4},

    {"carrot_planted","Carrot",REGROWTH_TYPE.EVENT, 1},
    {"flower","Flower",REGROWTH_TYPE.EVENT, 1},
	{"flower_evil","Evil Flower",REGROWTH_TYPE.EVENT, 1},
	{"flower_cave","Light Flower",REGROWTH_TYPE.EVENT, 1},
	{"flower_cave_double","Double Light Flower",REGROWTH_TYPE.EVENT, 1},
	{"flower_cave_triple","Triple Light Flower",REGROWTH_TYPE.EVENT, 1},
    {"blue_mushroom","Blue Mushroom",REGROWTH_TYPE.EVENT, 1},
    {"red_mushroom","Red Mushroom",REGROWTH_TYPE.EVENT, 1},
    {"green_mushroom","Green Mushroom",REGROWTH_TYPE.EVENT, 1},
    {"cactus","Cactus",REGROWTH_TYPE.EVENT, 2},
    {"mandrake_planted","Mandrake",REGROWTH_TYPE.EVENT, 6},
    {"cave_fern","Fern",REGROWTH_TYPE.EVENT, 1},
    {"lichen","Lichen",REGROWTH_TYPE.EVENT, 1},

    {"reeds","Reeds",REGROWTH_TYPE.EVENT, 2},
    {"sapling","Sapling",REGROWTH_TYPE.EVENT, 1},
    {"grass","Grass",REGROWTH_TYPE.EVENT, 1},
    {"marsh_bush","Spiky Bush",REGROWTH_TYPE.EVENT, 2},

    {"rock1","Boulder",REGROWTH_TYPE.EVENT, 1},
    {"rock2","Gold Vein",REGROWTH_TYPE.EVENT, 1},
    {"rock_flintless","Flintless Boulder",REGROWTH_TYPE.EVENT, 2},
    {"rock_moon","Moon Rock",REGROWTH_TYPE.EVENT, 2},

    {"stalagmite","Stalagmite",REGROWTH_TYPE.EVENT, 1},
    {"stalagmite_tall","Tall Stalagmite",REGROWTH_TYPE.EVENT, 1},

    {"rabbithole","Rabbit Hole",REGROWTH_TYPE.EVENT, 2},
    {"beehive","Beehive",REGROWTH_TYPE.EVENT, 4},
    {"wasphive","Killer Bee Hive",REGROWTH_TYPE.EVENT, 6},
    {"houndmound","Hound Mound",REGROWTH_TYPE.EVENT, 6},
    {"pighouse","Pig House",REGROWTH_TYPE.EVENT, 4},
    {"pighead","Pig Head",REGROWTH_TYPE.EVENT, 2},
    {"pigtorch","Pig Torch",REGROWTH_TYPE.EVENT, 2},
    {"mermhouse","Rundown House",REGROWTH_TYPE.EVENT, 4},
    {"mermhead","Merm Head",REGROWTH_TYPE.EVENT, 2},
    {"spiderden","Spider Den",REGROWTH_TYPE.EVENT, 6},
    {"catcoonden","Hollow Stump",REGROWTH_TYPE.EVENT, 4},
    {"rabbithouse","Rabbit Hutch",REGROWTH_TYPE.EVENT, 4},
    {"monkeybarrel","Splumonkey Pod",REGROWTH_TYPE.EVENT, 6},
    {"slurtlehole", "Slurtle Mound", REGROWTH_TYPE.EVENT, 4},
    {"tallbirdnest", "Tallbird Nest", REGROWTH_TYPE.EVENT, 4},

    {"fireflies","Fireflies",REGROWTH_TYPE.EVENT, 2},
    {"tentacle","Tentacle",REGROWTH_TYPE.EVENT, 2},
    {"knight","Clockwork Knight",REGROWTH_TYPE.EVENT, 6},
    {"bishop","Clockwork Bishop",REGROWTH_TYPE.EVENT, 6},
    {"rook","Clockwork Rook",REGROWTH_TYPE.EVENT, 6},
    {"knight_nightmare","Damaged Knight",REGROWTH_TYPE.EVENT, 6},
    {"bishop_nightmare","Damaged Bishop",REGROWTH_TYPE.EVENT, 6},
    {"rook_nightmare","Damaged Rook",REGROWTH_TYPE.EVENT, 6},

    {"ruins_statue_mage","Ancient Mage Statue",REGROWTH_TYPE.EVENT, 4},
    {"ruins_statue_mage_nogem","Gemless Ancient Mage Statue",REGROWTH_TYPE.EVENT, 4},
    {"ruins_statue_head","Ancient Head Statue",REGROWTH_TYPE.EVENT, 4},
    {"ruins_statue_head_nogem", "Gemless Ancient Head Statue", REGROWTH_TYPE.EVENT, 4},
    {"ancient_altar", "Ancient Pseudoscience Station", REGROWTH_TYPE.EVENT, 6},
    {"ancient_altar_broken", "Broken A. Pseudoscience Station", REGROWTH_TYPE.EVENT, 6}
}


if GLOBAL.STRINGS.NAMES.MIGRATION_PORTAL then
	-- we have caves
	AddPrefabPostInit("forest", function(inst)
		if inst.ismastersim then
			inst:AddComponent("extra_regrowth")
		end
	end)
	AddPrefabPostInit("cave", function(inst)
		if inst.ismastersim then
			inst:AddComponent("extra_regrowth")
		end
	end)
else
	-- only overworld
	AddPrefabPostInit("world", function(inst)
		if inst.ismastersim then
			inst:AddComponent("extra_regrowth")
		end
	end)
end

AddComponentPostInit("extra_regrowth", function(component)
	for i = 1, #config_table do
        local entry = config_table[i]
        local prefab = entry[1]
		if GetModConfigData(prefab) ~= 0 then
            local delay = GetModConfigData(prefab) * 240
            component:RegisterRegrowth(prefab, prefab, delay)
		end
    end
    component:FinishModConfig()
end)
