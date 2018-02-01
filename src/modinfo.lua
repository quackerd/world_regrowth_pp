name = "World Regrowth++"
version = "0.2.1"
description = "Version "..version.."\nPlease reset the mod configuration after updating from 0.1.X to 0.2.0 and above\n\nWorld regrowth with caves support. Please see the Steam Workshop page for changes notes.\n\nHappy hunting and do starve!"
author = "lolo"

forumthread = ""

api_version = 10

--icon_atlas = "modicon.xml"
--icon = "modicon.tex"

all_clients_require_mod = false
client_only_mod = false
dst_compatible = true

local REGROWTH_TYPE = 
{
    NATURAL = 1,
    EVENT = 2
}

-- Configuration Generation
-- I can't reference this from another file... duplicate
local config_table = 
{
    {"evergreen","Evergreen", REGROWTH_TYPE.NATURAL, 1},
    {"deciduoustree","Birchnut Tree",REGROWTH_TYPE.NATURAL, 1},
    {"marsh_tree","Spiky Tree",REGROWTH_TYPE.NATURAL, 2},
    {"twiggytree","Twiggy Tree",REGROWTH_TYPE.NATURAL, 2},
    {"marbletree","Marble Tree",REGROWTH_TYPE.EVENT, 4},
    {"livingtree","Totally Normal Tree",REGROWTH_TYPE.EVENT, 4},
    {"mushtree_tall","Blue Mushtree", REGROWTH_TYPE.NATURAL, 1},
	{"mushtree_medium","Red Mushtree",REGROWTH_TYPE.NATURAL, 1},
	{"mushtree_small","Green Mushtree", REGROWTH_TYPE.NATURAL, 1},

    {"berrybush","Berry Bush",REGROWTH_TYPE.NATURAL, 6},
    {"berrybush2","Spiky Berry Bush",REGROWTH_TYPE.NATURAL, 6},
    {"berrybush_juicy","Juicy Berry Bush",REGROWTH_TYPE.NATURAL, 6},

    {"carrot_planted","Carrot",REGROWTH_TYPE.NATURAL, 1},
    {"flower","Flower",REGROWTH_TYPE.NATURAL, 1},
	{"flower_evil","Evil Flower",REGROWTH_TYPE.EVENT, 2},
	{"flower_cave","Light Flower",REGROWTH_TYPE.EVENT, 2},
	{"flower_cave_double","Double Light Flower",REGROWTH_TYPE.EVENT, 2},
	{"flower_cave_triple","Triple Light Flower",REGROWTH_TYPE.EVENT, 2},
    {"blue_mushroom","Blue Mushroom",REGROWTH_TYPE.NATURAL, 1},
    {"red_mushroom","Red Mushroom",REGROWTH_TYPE.NATURAL, 1},
    {"green_mushroom","Green Mushroom",REGROWTH_TYPE.NATURAL, 1},
    {"cactus","Cactus",REGROWTH_TYPE.NATURAL, 2},
    {"mandrake_planted","Mandrake",REGROWTH_TYPE.EVENT, 6},

    {"reeds","Reeds",REGROWTH_TYPE.NATURAL, 2},
    {"sapling","Sapling",REGROWTH_TYPE.NATURAL, 1},
    {"grass","Grass",REGROWTH_TYPE.NATURAL, 1},
    {"marsh_bush","Spiky Bush",REGROWTH_TYPE.NATURAL, 2},

    {"rock1","Boulder",REGROWTH_TYPE.NATURAL, 1},
    {"rock2","Gold Vein",REGROWTH_TYPE.NATURAL, 1},
    {"rock_flintless","Flintless Boulder",REGROWTH_TYPE.NATURAL, 1},
    {"rock_moon","Moon Rock",REGROWTH_TYPE.NATURAL, 2},

    {"stalagmite","Stalagmite",REGROWTH_TYPE.NATURAL, 1},
    {"stalagmite_tall","Tall Stalagmite",REGROWTH_TYPE.NATURAL, 1},

    {"beehive","Beehive",REGROWTH_TYPE.EVENT, 2},
    {"wasphive","Killer Bee Hive",REGROWTH_TYPE.EVENT, 4},
    {"houndmound","Hound Mound",REGROWTH_TYPE.EVENT, 6},
    {"pighouse","Pig House",REGROWTH_TYPE.EVENT, 4},
    {"mermhouse","Rundown House",REGROWTH_TYPE.EVENT, 6},
    {"spiderden","Spider Den",REGROWTH_TYPE.EVENT, 6},
    {"catcoonden","Hollow Stump",REGROWTH_TYPE.EVENT, 4},
    {"rabbithouse","Rabbit Hutch",REGROWTH_TYPE.EVENT, 4},
    {"monkeybarrel","Splumonkey Pod",REGROWTH_TYPE.EVENT, 4},
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
    {"ruins_statue_head_nogem", "Gemless Ancient Head Statue", REGROWTH_TYPE.EVENT, 4}
}


local config_options = {}

for i = 1, #config_table do
    local opt = {}
    for j = 0,20 do
        opt[#opt+1] = 
        {
            description = (j == 0) and "Disabled" or (j * 0.5 .. ((j == 2) and " day" or " days")),
            data = j
        }
    end

    local entry = 
    {
        name = config_table[i][1],
        label = config_table[i][2],
        hover = config_table[i][3] == REGROWTH_TYPE.EVENT and "Event-based" or "Natural",
        options = opt,
        default = config_table[i][4]
    }

    config_options[i] = entry
end

configuration_options = config_options