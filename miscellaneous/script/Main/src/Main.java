import java.util.Arrays;
import java.util.List;

public class Main
{
    private static List<String> list = Arrays.asList(
            "evergreen", "Evergreen", "Natural", "0.5",
            "deciduoustree", "Birchnut Tree", "Natural", "0.5",
            "marsh_tree", "Spiky Tree", "Natural", "1",
            "twiggytree", "Twiggy Tree", "Natural", "1",
            "marbletree", "Marble Tree", "Event-based", "2",
            "livingtree", "Totally Normal Tree", "Event-based", "2",

            "berrybush", "Berry Bush", "Natural", "3",
            "berrybush2", "Spiky Berry Bush", "Natural", "3",
            "berrybush_juicy", "Juicy Berry Bush", "Natural", "3",

            "carrot_planted", "Carrot", "Natural", "0.5",
            "flower", "Flower", "Natural", "0.5",
            "flower_evil", "Evil Flower", "Event-based", "1",
            "blue_mushroom", "Blue Mushroom", "Natural", "0.5",
            "red_mushroom", "Red Mushroom", "Natural", "0.5",
            "green_mushroom", "Green Mushroom", "Natural", "0.5",
            "cactus", "Cactus", "Natural", "1",
            "mandrake", "Mandrake", "Event-based", "2",

            "reeds", "Reeds", "Natural", "1",
            "sapling", "Saplings", "Natural", "0.5",
            "grass", "Grass", "Natural", "0.5",
            "marsh_bush", "Spiky Bush", "Natural", "1",

            "rock1", "Boulder", "Natural", "0.5",
            "rock2", "Gold Vein", "Natural","0.5",
            "rock_flintless", "Flintless Boulder", "Natural", "0.5",
            "rock_moon", "Moon Rock", "Natural", "1",

            "stalagmite", "Stalagmite", "Natural", "1",
            "stalagmite_tall", "Tall Stalagmite", "Natural", "1",

            "beehive", "Beehive", "Event-based", "1",
            "wasphive", "Killer Bee Hive", "Event-based", "2",
            "houndmound", "Hound Mound", "Event-based", "3",
            "pighouse", "Pig House", "Event-based", "2",
            "mermhouse", "Rundown House", "Event-based", "2",
            "spiderden", "Spider Den", "Event-based", "3",
            "catcoonden", "Hollow Stump", "Event-based", "2",
            "rabbithouse", "Rabbit Hutch", "Event-based", "2",
            "monkeypods", "Splumonkey Pod", "Event-based","2",
            "slurtle", "Slurtle Mound", "Event-based", "2",

            "fireflies", "Fireflies", "Event-based", "1",
            "tentacle", "Tentacle", "Event-based", "1",
            "knight", "Clockwork Knight", "Event-based", "3",
            "bishop", "Clockwork Bishop", "Event-based", "3",
            "rook", "Clockwork Rook", "Event-based", "3",
            "knight_nightmare", "Damaged Knight", "Event-based", "3",
            "bishop_nightmare", "Damaged Bishop", "Event-based", "3",
            "rook_nightmare", "Damaged Rook", "Event-based", "3",

            "ruins_statue_mage", "Ancient Mage Statue", "Event-based", "2",
            "ruins_statue_mage_nogem", "Ancient Mage Statue (No Gem)", "Event-based", "2",
            "ruins_statue_head", "Ancient Head Statue", "Event-based", "2",
            "ruins_statue_head_nogem", "Ancient Head Statue (No Gem)", "Event-based", "2"
            );

    public static void main(String[] args)
    {
        for (int i = 0; i < list.size(); i = i + 4)
        {
            System.out.println(list.get(i+1) + " - " + list.get(i+2) + " / " + list.get(i+3));
        }

    }
}
