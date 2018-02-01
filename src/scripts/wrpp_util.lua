EXCLUDE_TAGS = 
{
    "statue", -- marble stuff on the ground, ancient statues
    "hive", --spiderden, wasphive, beehive
}

EXCLUDE_PREFABS = 
{
    catcoonden = 1,
    ancient_altar = 1,
    ancient_altar_broken = 1,
    houndmound = 1,
    mermhouse = 1,
    pigtorch = 1,
    mermhead = 1,
    pighead = 1,
    pandoraschest = 1,
    minotaurchest = 1
}

BASE_RADIUS = 20
EXCLUDE_RADIUS = 2
MIN_PLAYER_DISTANCE = 40

REGROW_STATUS = 
{
    SUCCESS = 0,
    FAILED = 1,
    CACHE = 2
}

local function TestStructures(x, y, z, radius)
    local ents = TheSim:FindEntities(x,y,z, BASE_RADIUS, nil, EXCLUDE_TAGS, { "structure", "wall" })

    for i, v in ipairs(ents) do
        if EXCLUDE_PREFABS[v.prefab] == nil then
            -- if we cannot find it from the exclude table, then it is a structure and we failed the test
            return false
        end
    end

    return true
end

local function TestPlayers(x, y, z, radius)
    return not IsAnyPlayerInRange(x,y,z, MIN_PLAYER_DISTANCE, nil)
end

local function TestEntities(x, y, z, radius)
    local ents = TheSim:FindEntities(x,y,z, EXCLUDE_RADIUS)
    return not (#ents > 0)
end

function TestRegrowthByTile(x, y, z, tile)

    if not TestPlayers(x,y,z, MIN_PLAYER_DISTANCE) then
        return REGROW_STATUS.CACHE
    end

    if not TestStructures(x, y, z, BASE_RADIUS) then
        -- No regrowth around players and their bases
        return REGROW_STATUS.FAILED
    end

    if not TestEntities(x,y,z, EXCLUDE_RADIUS) then
        -- Too dense
        return REGROW_STATUS.CACHE
    end

    if not (TheWorld.Map:CanPlantAtPoint(x, y, z)) then
        return REGROW_STATUS.CACHE
    end

    if TheWorld.Map:GetTileAtPoint(x, y, z) ~= tile then
        -- keep things in their biome (more or less)
        return REGROW_STATUS.CACHE
    end

    return REGROW_STATUS.SUCCESS
end

function TestRegrowthByPrefab(x, y, z, prefab)

    if not TestPlayers(x,y,z, MIN_PLAYER_DISTANCE) then
        return REGROW_STATUS.CACHE
    end

    if not TestStructures(x, y, z, BASE_RADIUS) then
        -- No regrowth around players and their bases
        return REGROW_STATUS.FAILED
    end

    if not TestEntities(x,y,z, EXCLUDE_RADIUS) then
        -- Too dense
        return REGROW_STATUS.CACHE
    end
    
    if not (TheWorld.Map:CanPlantAtPoint(x, y, z) and
            TheWorld.Map:CanPlacePrefabFilteredAtPoint(x, y, z, prefab))
        or (RoadManager ~= nil and RoadManager:IsOnRoad(x, 0, z)) then
        -- Not ground we can grow on
        return REGROW_STATUS.CACHE
    end

    return REGROW_STATUS.SUCCESS
end

function GetPosStr(pos)
    return  "( " .. pos.x .. " , " .. pos.y .. " , ".. pos.z .. " )"
end

function GetCoordStr(x,y,z)
    return  "( " .. x .. " , " .. y .. " , ".. z .. " )"
end