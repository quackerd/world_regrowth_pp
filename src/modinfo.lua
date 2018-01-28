name = "World Regrowth++"
version = "0.1.2"
description = "Version "..version.."\n\nAdvanced world regrowth including caves! See the Steam Workshop page for more information.\n\nHappy hunting and do starve!"
author = "lolo"

forumthread = ""

api_version = 10

--icon_atlas = "modicon.xml"
--icon = "modicon.tex"

all_clients_require_mod = false
client_only_mod = false
dst_compatible = true

-- Configuration Generation
local config_table = 
{
    {"evergreen","Evergreen","Natural"},
    {"deciduoustree","Birchnut Tree","Natural"},
    {"marsh_tree","Spiky Tree","Natural"},
    {"twiggytree","Twiggy Tree","Natural"},
    {"marbletree","Marble Tree","Event-based"},
    {"livingtree","Totally Normal Tree","Event-based"},

    {"berrybush","Berry Bush","Natural"},
    {"berrybush2","Spiky Berry Bush","Natural"},
    {"berrybush_juicy","Juicy Berry Bush","Natural"},

    {"carrot_planted","Carrot","Natural"},
    {"flower","Flower","Natural"},
    {"flower_evil","Evil Flower","Event-based"},
    {"blue_mushroom","Blue Mushroom","Natural"},
    {"red_mushroom","Red Mushroom","Natural"},
    {"green_mushroom","Green Mushroom","Natural"},
    {"cactus","Cactus","Natural"},
    {"mandrake","Mandrake","Event-based"},

    {"reeds","Reeds","Natural"},
    {"sapling","Sapling","Natural"},
    {"grass","Grass","Natural"},
    {"marsh_bush","Spiky Bush","Natural"},

    {"rock1","Boulder","Natural"},
    {"rock2","Gold Vein","Natural"},
    {"rock_flintless","Flintless Boulder","Natural"},
    {"rock_moon","Moon Rock","Natural"},

    {"stalagmite","Stalagmite","Natural"},
    {"stalagmite_tall","Tall Stalagmite","Natural"},

    {"beehive","Beehive","Event-based"},
    {"wasphive","Killer Bee Hive","Event-based"},
    {"houndmound","Hound Mound","Event-based"},
    {"pighouse","Pig House","Event-based"},
    {"mermhouse","Rundown House","Event-based"},
    {"spiderden","Spider Den","Event-based"},
    {"catcoonden","Hollow Stump","Event-based"},
    {"rabbithouse","Rabbit Hutch","Event-based"},
    {"monkeypods","Splumonkey Pod","Event-based"},
    {"slurtlehole", "Slurtle Mound", "Event-based"},
    {"tallbirdnest", "Tallbird Nest", "Event-based"},

    {"fireflies","Fireflies","Event-based"},
    {"tentacle","Tentacle","Event-based"},
    {"knight","Clockwork Knight","Event-based"},
    {"bishop","Clockwork Bishop","Event-based"},
    {"rook","Clockwork Rook","Event-based"},
    {"knight_nightmare","Damaged Knight","Event-based"},
    {"bishop_nightmare","Damaged Bishop","Event-based"},
    {"rook_nightmare","Damaged Rook","Event-based"},

    {"ruins_statue_mage","Ancient Mage Statue","Event-based"},
    {"ruins_statue_mage_nogem","Gemless Ancient Mage Statue","Event-based"},
    {"ruins_statue_head","Ancient Head Statue","Event-based"},
    {"ruins_statue_head_nogem", "Gemless Ancient Head Statue", "Event-based"}
}

local config_options = {}

for i = 1, #config_table do
    local entry = 
    {
        name = config_table[i][1],
        label = config_table[i][2],
        hover = config_table[i][3],
        options = 
        {
            {
                description = "Disabled",
                data = false
            },
            {
                description = "Enabled",
                data = true
            }
        },
        default = true
    }
    config_options[#config_options+1] = entry
end

configuration_options = config_options