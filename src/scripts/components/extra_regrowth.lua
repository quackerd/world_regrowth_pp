--------------------------------------------------------------------------
--[[ EventRegrowth class definition ]]
-- A modified and more feature-rich version of the original regrowthmanager.lua
-- It acts as a standalone regrowth manager and is independent of the 3 existing ones
-- It's unlikely affected by game updates as long as Klei doesn't break the API (they shouldn't)
-- quackerd
--------------------------------------------------------------------------

return Class(function(self, inst)
 
    assert(inst.ismastersim, "extra_regrowth should not exist on client")
    
    require "map/terrain"
    require "ocean_util"
    
    --------------------------------------------------------------------------
    --[[ Constants ]]
    --------------------------------------------------------------------------
    local DEBUG = false
    local DEBUG_TELE = false
    local UPDATE_PERIOD = 9          -- 9 seconds per tick
    local JITTER_RADIUS = 1          -- random point within this radius
    local MAX_RADIUS = 1000          -- cap the max radius
    local INC_RADIUS = 3             -- increase this amount after we fail
    local BASE_RADIUS = 15           -- don't spawn near player's base
    local EXCLUDE_RADIUS = 2         -- no other entities in this radius within the spawn point
    local MIN_PLAYER_DISTANCE = 30   -- minimum distance of player to spawn entities

    local EXCLUDE_TAGS = 
    {
        "statue", -- marble stuff on the ground, ancient statues
        "hive", --spiderden, wasphive, beehive
    } -- these aren't considered structures

    local EXCLUDE_PREFABS = 
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
        minotaurchest = 1,
        pighouse = 1,
        rabbithouse = 1,
        chessjunk1 = 1,
        chessjunk2 = 1,
        chessjunk3 = 1,
        wall_ruins = 1,
    }  -- these aren't considered structures

    
    local REGROW_STATUS = 
    {
        SUCCESS = 0,
        STRUCT = 1,
        CACHE = 2,
        PLAYER = 3,
        DENSITY = 4,
        TILE = 5,
        ROAD = 6,
        OCEAN = 7
    }

    local CACHE_RETRY = 
    {
        [REGROW_STATUS.PLAYER] = true,
    } -- we don't increase the radius for these reasons
    
    
    --------------------------------------------------------------------------
    --[[ Member variables ]]
    --------------------------------------------------------------------------
    
    --Public
    self.inst = inst
    
    --Private
    local ready = false
    local regrowth_table = {}
    local entity_list = {}

    --------------------------------------------------------------------------
    --[[ Private member functions ]]
    --------------------------------------------------------------------------
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

    local function TestRegrowth(x, y, z, prefab, tile)
        local cur_tile = TheWorld.Map:GetTileAtPoint(x, y, z)

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

        -- hack to get away with it for now
        if IsOceanTile(cur_tile) then
            return REGROW_STATUS.OCEAN
        end

        if  (CanPlaceAtPoint(x, y, z) and TheWorld.Map:CanPlacePrefabFilteredAtPoint(x, y, z, prefab)) or ((tile ~= nil) and (cur_tile == tile)) then
            return REGROW_STATUS.SUCCESS
        end

        return REGROW_STATUS.TILE
    end

    local function GetPosStr(pos)
        return  "( " .. pos.x .. " , " .. pos.y .. " , ".. pos.z .. " )"
    end

    local function GetCoordStr(x,y,z)
        return  "( " .. x .. " , " .. y .. " , ".. z .. " )"
    end

    local function GetRStatusStr(status)
        for k, v in pairs(REGROW_STATUS) do
            if v == status then
                return k
            end
        end
        return nil
    end

    local function EntityDeathEventHandler(ent)
        if entity_list[ent.prefab] == nil then
            entity_list[ent.prefab] = {}
        end
        local position = ent:GetPosition()

        entity_list[ent.prefab][#entity_list[ent.prefab]+1] = 
        {
            position = position, 
            interval = regrowth_table[ent.prefab].interval, 
            remove=false,
            retry = 0
        }
        ent:RemoveEventCallback("onremove", EntityDeathEventHandler, nil)

        if DEBUG then
            print("[ExtraRegrowth] " .. ent.prefab .. " was removed at " .. GetPosStr(position) .. " Tile: " .. TheWorld.Map:GetTileAtPoint(position.x, position.y, position.z))
        end
    end

    local function GetRandomLocation(x, y, z, r)
        local theta = math.random() * 2 * PI
        local radius = math.random() * r
        local x = x + radius * math.cos(theta)
        local z = z - radius * math.sin(theta)
        return x,y,z
    end

    local function TryRegrowth(prefab, product, position, rand_radius)
        local x,y,z = GetRandomLocation(position.x,position.y,position.z, rand_radius)

        local orig_tile = inst.Map:GetTileAtPoint(position.x, position.y, position.z)
        local status = TestRegrowth(x,y,z, prefab, orig_tile)

        if CACHE_RETRY[status] ~= nil then
            if DEBUG then
                print("[ExtraRegrowth] Cached a " .. product .. " at " .. GetCoordStr(x,y,z) .. " for " .. prefab .. " at " .. GetPosStr(position) .. " with radius " .. rand_radius .. " due to " .. GetRStatusStr(status))
            end
            return status
        end

        if status ~= REGROW_STATUS.SUCCESS then
            if DEBUG then
                print("[ExtraRegrowth] Failed to spawn a " .. product .. " at ".. GetCoordStr(x,y,z) .. " for " .. prefab .. " at " .. GetPosStr(position) .. " with radius ".. rand_radius .. " due to " .. GetRStatusStr(status))
            end
            return status
        end
        
        local instance = SpawnPrefab(product)
        if instance ~= nil then
            instance.Transform:SetPosition(x,y,z)
            instance:ListenForEvent("onremove", EntityDeathEventHandler, nil)

            if DEBUG then
                print("[ExtraRegrowth] Spawned a " .. product .. " at " .. GetCoordStr(x,y,z) .. " for " .. prefab .. " at " .. GetPosStr(position) .. " with radius " .. rand_radius .. " tile: " .. TheWorld.Map:GetTileAtPoint(x,y,z))
            end

            if DEBUG_TELE then
                c_teleport(x,0,z)
            end

        end

        return status
    end

    local function HookEntities(prefab)
        while next(Ents) == nil do
        end

        local count = 0
        for k, v in pairs(Ents) do
            if v.prefab == prefab then
                v:RemoveEventCallback("onremove", EntityDeathEventHandler, nil)
                v:ListenForEvent("onremove", EntityDeathEventHandler, nil)
                count = count + 1
            end
        end
        if DEBUG then
            print("[ExtraRegrowth] Hooked " .. count .. " " .. prefab)
        end
    end

    local function HookAllRegisteredPrefabs()
        local count = 0
        for guid,ent in pairs(Ents) do
            if regrowth_table[ent.prefab] ~= nil then
                ent:RemoveEventCallback("onremove", EntityDeathEventHandler, nil)
                ent:ListenForEvent("onremove", EntityDeathEventHandler, nil)
                count = count + 1
            end
        end 

        if DEBUG then
            print("[ExtraRegrowth] Hooked " .. count .. " entities")
        end
    end

    --------------------------------------------------------------------------
    --[[ Public member functions ]]
    --------------------------------------------------------------------------
    function self:GetUpdatePeriod()
        return UPDATE_PERIOD
    end

    function self:FinishModConfig()
        HookAllRegisteredPrefabs()
        ready = true
    end

    function self:RegisterRegrowth(prefab, product, interval)

        if interval == nil then
            if DEBUG then
                print("[ExtraRegrowth] WARNING: interval for prefab " .. prefab .. " is null. Using default.")
            end
            interval = 480
        end

        if DEBUG then
            interval = interval / 100
        end

        if regrowth_table[prefab] == nil then
            -- avoid duplicate registration
            regrowth_table[prefab] = 
            {
                product = product,
                interval = interval
            }

        end

        if DEBUG then
            print("[ExtraRegrowth] Registered product " .. product .. " for prefab " .. prefab .. " with interval " .. interval)
        end
    end
    
    --------------------------------------------------------------------------
    --[[ Initialization ]]
    --------------------------------------------------------------------------
    inst:DoTaskInTime(0, function() HookAllRegisteredPrefabs() end)
    inst:DoPeriodicTask(UPDATE_PERIOD, function() self:LongUpdate() end)
    inst:ListenForEvent("ms_cyclecomplete", function() HookAllRegisteredPrefabs() end) -- every ~ 1 day we rehook every entities

    --------------------------------------------------------------------------
    --[[ Update ]]
    --------------------------------------------------------------------------
    local function RegrowPrefabTask(prefab, data)
        local rand_radius = JITTER_RADIUS + data.retry * INC_RADIUS
        if rand_radius > MAX_RADIUS then
            rand_radius = MAX_RADIUS
        end

        local success = TryRegrowth(prefab, regrowth_table[prefab].product, data.position, rand_radius)

        if success == REGROW_STATUS.SUCCESS then
            data.remove = true
        end

        if CACHE_RETRY[success] == nil then
            -- only increase radius when not cached
            data.retry = data.retry + 1
        end
    end

    function self:LongUpdate()
        if not ready then
            -- do nothing if the table is not fully initialized
            -- in case we accidentally drop some saved entities due to the respawn_table[prefab] == nil check
            return
        end

        local count = 0
        for prefab in pairs(entity_list) do
            if entity_list[prefab] == nil or #entity_list[prefab] == 0 then
                -- only do meaningful work
            else
                if regrowth_table[prefab] == nil then
                    -- if we don't have it registered, discard
                    entity_list[prefab] = nil
                else
                    for i = #entity_list[prefab], 1, -1 do
                        if entity_list[prefab][i].remove then
                            -- handle expired objects first
                            if DEBUG then
                                print("[ExtraRegrowth] Removed prefab " .. prefab .. " at ".. GetPosStr(entity_list[prefab][i].position) .." from the entity list.")
                            end
                            table.remove(entity_list[prefab], i)
                        else
                            -- decrease the interval
                            if entity_list[prefab][i].interval > UPDATE_PERIOD then
                                entity_list[prefab][i].interval = entity_list[prefab][i].interval - UPDATE_PERIOD
                            else
                                -- else set to 0 and regen
                                entity_list[prefab][i].interval = 0
                            end

                            if DEBUG then
                                print("[ExtraRegrowth] Prefab " ..  prefab .. " at " .. GetPosStr(entity_list[prefab][i].position) .. " has interval " .. entity_list[prefab][i].interval )
                            end

                            if entity_list[prefab][i].interval == 0 then
                                -- different threads
                                local data = entity_list[prefab][i]

                                RegrowPrefabTask(prefab, data)
                            end
                        end
                    end
                end
            end
        end
    end
    
    --------------------------------------------------------------------------
    --[[ Save/Load ]]
    --------------------------------------------------------------------------
    
    function self:OnSave()
        local data = {
            entities = {}
        }
        for prefab in pairs(entity_list) do
            if entity_list[prefab] ~= nil then
                -- could be nil (set in the event loop)
                data.entities[prefab] = {}
                for i = 1, #entity_list[prefab] do
                    data.entities[prefab][#data.entities[prefab] + 1] = 
                    {
                        interval = entity_list[prefab][i].interval, 
                        position = 
                        {
                            x = entity_list[prefab][i].position.x,
                            y = entity_list[prefab][i].position.y,
                            z = entity_list[prefab][i].position.z
                        },
                        remove = entity_list[prefab][i].remove, 
                        retry = entity_list[prefab][i].retry
                    }
                end
                if DEBUG then
                    print("[ExtraRegrowth] Saved " .. #data.entities[prefab] .. " entities for prefab " .. prefab)
                end
            end
        end
        return data
    end
    
    function self:OnLoad(data)
        for prefab in pairs(data.entities) do
            if entity_list[prefab] == nil then
                entity_list[prefab] = {}
                for i = 1, #data.entities[prefab] do
                    entity_list[prefab][#entity_list[prefab] + 1] = 
                    {
                        interval = data.entities[prefab][i].interval,
                        position =
                        {
                            x = data.entities[prefab][i].position.x,
                            y = data.entities[prefab][i].position.y,
                            z = data.entities[prefab][i].position.z
                        },
                        remove = (data.entities[prefab][i].remove == nil) and false or data.entities[prefab][i].remove, 
                        retry = (data.entities[prefab][i].retry == nil) and 0 or data.entities[prefab][i].retry
                    }
                end
                if DEBUG then
                    print("[ExtraRegrowth] Loaded " .. #entity_list[prefab] .. " entities for prefab " .. prefab)
                end
            end
        end
    end
    
    --------------------------------------------------------------------------
    --[[ End ]]
    --------------------------------------------------------------------------
    
end)
    