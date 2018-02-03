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
    STRUCT = 1,
    CACHE = 2,
    PLAYER = 3,
    DENSITY = 4,
    TILE = 5,
    ROAD = 6
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

local function CanPlaceAtPoint(x, y, z)
    local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
    return tile ~= GROUND.IMPASSABLE and
        tile ~= GROUND.INVALID and
        not GROUND_FLOORING[tile]
end

local function TestPlayers(x, y, z, radius)
    return not IsAnyPlayerInRange(x,y,z, MIN_PLAYER_DISTANCE, nil)
end

local function TestEntities(x, y, z, radius)
    local ents = TheSim:FindEntities(x,y,z, EXCLUDE_RADIUS)
    return not (#ents > 0)
end

function TestRegrowth(x, y, z, prefab, tile)

    if not TestPlayers(x,y,z, MIN_PLAYER_DISTANCE) then
        return REGROW_STATUS.PLAYER
    end

    if not TestStructures(x, y, z, BASE_RADIUS) then
        -- No regrowth around players and their bases
        return REGROW_STATUS.STRUCT
    end

    if not TestEntities(x,y,z, EXCLUDE_RADIUS) then
        -- Too dense
        return REGROW_STATUS.DENSITY
    end

    if (RoadManager ~= nil) and (RoadManager:IsOnRoad(x, 0, z)) then
        return REGROW_STATUS.ROAD
    end

    if  (CanPlaceAtPoint(x, y, z) and TheWorld.Map:CanPlacePrefabFilteredAtPoint(x, y, z, prefab)) or ((tile ~= nil) and (TheWorld.Map:GetTileAtPoint(x, y, z) == tile)) then
        return REGROW_STATUS.SUCCESS
    end

    return REGROW_STATUS.TILE
end

function GetPosStr(pos)
    return  "( " .. pos.x .. " , " .. pos.y .. " , ".. pos.z .. " )"
end

function GetCoordStr(x,y,z)
    return  "( " .. x .. " , " .. y .. " , ".. z .. " )"
end

function GetRStatusStr(status)
    for k, v in pairs(REGROW_STATUS) do
        if v == status then
            return k
        end
    end
    return nil
end