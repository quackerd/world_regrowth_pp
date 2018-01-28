--------------------------------------------------------------------------
--[[ EventRegrowth class definition ]]
-- A modified version of the original regrowthmanager.lua
-- It acts as a standalone regrowth manager and is independent of the 3 existing ones
-- It's unlikely affected by game updates as long as Klei doesn't change the API (they shouldn't)
-- by lolo Jan. 2018
--------------------------------------------------------------------------

return Class(function(self, inst)
 
    assert(inst.ismastersim, "event_regrowth should not exist on client")
    
    require "map/terrain"
    
    --------------------------------------------------------------------------
    --[[ Constants ]]
    --------------------------------------------------------------------------
    local DEBUG = true
    local DEBUG_TELE = false

    local UPDATE_PERIOD = 9
    local BASE_RADIUS = 20
    local EXCLUDE_RADIUS = 3
    local JITTER_RADIUS = 6
    local TOTAL_RADIUS = 1000
    local MIN_PLAYER_DISTANCE = 40
    local THREADS_PER_BATCH = 3
    local THREADS_PER_BATCH_HOOK = 2
    local REGROW_STATUS = {
        SUCCESS = 0,
        FAILED = 1,
        CACHE = 2,
    }    
    
    --------------------------------------------------------------------------
    --[[ Member variables ]]
    --------------------------------------------------------------------------
    
    --Public
    self.inst = inst
    
    --Private
    local regrowth_table_populated_by_mod = false
    local regrowth_table = {}
    local entity_list = {}

    --------------------------------------------------------------------------
    --[[ Private member functions ]]
    --------------------------------------------------------------------------

    local function EntityDeathEventHandler(ent)
        if entity_list[ent.prefab] == nil then
            entity_list[ent.prefab] = {}
        end
        local position = ent:GetPosition()

        entity_list[ent.prefab][#entity_list[ent.prefab]+1] = {position = position, interval = regrowth_table[ent.prefab].interval}
        ent:RemoveEventCallback("onremove", EntityDeathEventHandler, nil)

        if DEBUG then
            print("[EventRegrowth] ", ent.prefab, " was removed at ", position)
        end
    end

    local function TestForRegrow(x, y, z, tile)

        if IsAnyPlayerInRange(x,y,z, MIN_PLAYER_DISTANCE, nil) then
            return REGROW_STATUS.CACHE
        end

        local ents = TheSim:FindEntities(x,y,z, BASE_RADIUS, nil, nil, { "structure", "wall" })
        if #ents > 0 then
            -- No regrowth around players and their bases
            return REGROW_STATUS.FAILED
        end
            
        local ents = TheSim:FindEntities(x,y,z, EXCLUDE_RADIUS)
        if #ents > 0 then
            -- Too dense
            return REGROW_STATUS.CACHE
        end

        if inst.Map:GetTileAtPoint(x, y, z) ~= tile then
            -- keep things in their biome (more or less)
            return REGROW_STATUS.CACHE
        end

        return REGROW_STATUS.SUCCESS
    end

    -- duplicate of canregrow in natural regrowth
    local function CanRegrow(x, y, z, prefab)

        if IsAnyPlayerInRange(x,y,z, MIN_PLAYER_DISTANCE, nil) then
            return false
        end
            
        local ents = TheSim:FindEntities(x,y,z, EXCLUDE_RADIUS)
        if #ents > 0 then
            -- Too dense
            return false
        end
    
        local ents = TheSim:FindEntities(x,y,z, BASE_RADIUS, nil, nil, { "structure", "wall" })
        if #ents > 0 then
            -- Don't spawn inside bases
            return false
        end
        
        if not (inst.Map:CanPlantAtPoint(x, y, z) and
                inst.Map:CanPlacePrefabFilteredAtPoint(x, y, z, prefab))
            or (RoadManager ~= nil and RoadManager:IsOnRoad(x, 0, z)) then
            -- Not ground we can grow on
            return false
        end
        return true
    end


    local function GetRandomLocation(x, y, z, radius)
        local theta = math.random() * 2 * PI
        local radius = math.random() * radius
        local x = x + radius * math.cos(theta)
        local z = z - radius * math.sin(theta)
        return x,y,z
    end

    local function TryRegrowth(prefab, product, position)
        local x,y,z = GetRandomLocation(position.x,position.y,position.z,JITTER_RADIUS)
        local orig_tile = inst.Map:GetTileAtPoint(x,y,z)
        local status = TestForRegrow(x,y,z, orig_tile)
        
        if status == REGROW_STATUS.CACHE then
            if DEBUG then
                print("[EventRegrowth] Cached a ",product," for prefab ",prefab," at ", x, ",", y,",",z)
            end
            return false
        end

        if status == REGROW_STATUS.FAILED then
            -- for the failed case, we want to try spawning at a random location
            x,y,z = GetRandomLocation(position.x,position.y,position.z,TOTAL_RADIUS)
            
            if not CanRegrow(x,y,z, product) then
                -- if cannot regrow, return CACHE status
                if DEBUG then
                    print("[EventRegrowth] Failed to spawn a ",product," for prefab ",prefab," at ", x, ",", y,",",z)
                end
                return false
            end
        end
        
        local instance = SpawnPrefab(product)
        if instance ~= nil then
            instance.Transform:SetPosition(x,y,z)
            instance:ListenForEvent("onremove", EntityDeathEventHandler, nil)

            if DEBUG then
                print("[EventRegrowth] Spawned a ",product," for prefab ",prefab," at ", x, ",", y,",",z)
            end

            if DEBUG_TELE then
                c_teleport(x,0,z)
            end

        end

        return true
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
            print("[EventRegrowth] Hooked ", count, " ",prefab)
        end
    end

    local function HookAllEntities(ents)
        local count = 0
        local delay = 0
        for prefab in pairs(ents) do
            inst:DoTaskInTime(delay, function() HookEntities(prefab) end)
            count = count + 1 
            if math.fmod(count, THREADS_PER_BATCH_HOOK) == 0 then
                delay = delay + 1
            end
        end
    end

    --------------------------------------------------------------------------
    --[[ Public member functions ]]
    --------------------------------------------------------------------------
    function self:FinishModConfig()
        regrowth_table_populated_by_mod = true
    end

    function self:RegisterRegrowth(prefab, product, interval)
        if regrowth_table[prefab] == nil then
            -- avoid duplicate registration
            regrowth_table[prefab] = 
            {
                product = product,
                interval = interval
            }

            HookEntities(prefab)
        end

        if DEBUG then
            print("[EventRegrowth] Registered ", product ," for ", prefab)
        end
    end
    
    --------------------------------------------------------------------------
    --[[ Initialization ]]
    --------------------------------------------------------------------------
    
    inst:DoPeriodicTask(UPDATE_PERIOD, function() self:LongUpdate(UPDATE_PERIOD) end)
    inst:ListenForEvent("ms_cyclecomplete", function() HookAllEntities(regrowth_table) end) -- every ~ 1 day we rehook every entities
    inst:DoTaskInTime(0, function() HookAllEntities(regrowth_table) end)

    --------------------------------------------------------------------------
    --[[ Update ]]
    --------------------------------------------------------------------------
    local function RegrowPrefabTask(prefab, position)
        for i = #entity_list[prefab],1,-1 do
            local success = TryRegrowth(prefab, regrowth_table[prefab].product, position)
                
            if success then
                -- remove from the list if it's success or failed
                table.remove(entity_list[prefab], i)
            end
        end
    end

    function self:LongUpdate(dt)
        if not regrowth_table_populated_by_mod then
            -- do nothing if the table is not fully initialized
            -- in case we accidentally drop some saved entities due to the respawn_table[prefab] == nil check
            return
        end

        local count = 0
        local delay = 0
        for prefab in pairs(entity_list) do
            if entity_list[prefab] == nil or #entity_list[prefab] == 0 then
                -- only do meaningful work
            else
                if regrowth_table[prefab] == nil then
                    -- if we don't have it registered, discard
                    entity_list[prefab] = nil
                else
                    for i = 1, #entity_list[prefab] do
                        -- decrease the interval
                        if entity_list[prefab][i].interval > UPDATE_PERIOD then
                            entity_list[prefab][i].interval = entity_list[prefab][i].interval - UPDATE_PERIOD
                        else
                            -- else set to 0 and regen
                            entity_list[prefab][i].interval = 0
                        end

                        if DEBUG then
                            print("[EventRegrowth]", prefab, " at ", entity_list[prefab][i].position, " has interval ", entity_list[prefab][i].interval )
                        end

                        if entity_list[prefab][i].interval == 0 then
                            -- different threads
                            inst:DoTaskInTime(delay, function() RegrowPrefabTask(prefab, entity_list[prefab][i].position) end)

                            -- try not to flood the server with threads
                            count = count + 1
                            if math.fmod( count,THREADS_PER_BATCH ) == 0 then
                                delay = delay + 1
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
                    data.entities[prefab][#data.entities[prefab] + 1] = {interval = entity_list[prefab][i].interval, position = entity_list[prefab][i].position}
                end
                if DEBUG then
                    print("[EventRegrowth] Saved ", #data.entities[prefab]," entities for ", prefab)
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
                    entity_list[prefab][#entity_list[prefab] + 1] = {interval = data.entities[prefab][i].interval, position = data.entities[prefab][i].position}
                end
                if DEBUG then
                    print("[EventRegrowth] Loaded ", #entity_list[prefab]," entities for ", prefab)
                end
            end
        end
    end
    
    --------------------------------------------------------------------------
    --[[ End ]]
    --------------------------------------------------------------------------
    
end)
    