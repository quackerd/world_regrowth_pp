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
    require "wrpp_util"
    
    --------------------------------------------------------------------------
    --[[ Constants ]]
    --------------------------------------------------------------------------
    local DEBUG = false
    local DEBUG_TELE = false
    local UPDATE_PERIOD = 9
    local JITTER_RADIUS = 6
    local MAX_RADIUS = 1000
    local INC_RADIUS = BASE_RADIUS / 2
    local THREADS_PER_BATCH = 3
    local THREADS_PER_BATCH_HOOK = 5
    
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

        entity_list[ent.prefab][#entity_list[ent.prefab]+1] = 
        {
            position = position, 
            interval = regrowth_table[ent.prefab].interval, 
            remove=false,
            retry = 0
        }
        ent:RemoveEventCallback("onremove", EntityDeathEventHandler, nil)

        if DEBUG then
            print("[EventRegrowth] " .. ent.prefab .. " was removed at " .. GetPosStr(position) .. " Tile: " .. TheWorld.Map:GetTileAtPoint(position.x, position.y, position.z))
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

        if status == REGROW_STATUS.STRUCT then
            if DEBUG then
                print("[EventRegrowth] Failed to spawn a product " .. product .. " at " .. GetCoordStr(x,y,z) .. " for prefab " .. prefab .. " at " .. GetPosStr(position) .. " with rand radius " .. rand_radius .. " due to " .. GetRStatusStr(status))
            end
            return status
        end

        if status ~= REGROW_STATUS.SUCCESS then
            if DEBUG then
                print("[EventRegrowth] Cached a product " .. product .. " at ".. GetCoordStr(x,y,z) .. " for prefab " .. prefab .. " at " .. GetPosStr(position) .. " with rand radius ".. rand_radius .. " due to " .. GetRStatusStr(status))
            end
            return status
        end
        
        local instance = SpawnPrefab(product)
        if instance ~= nil then
            instance.Transform:SetPosition(x,y,z)
            instance:ListenForEvent("onremove", EntityDeathEventHandler, nil)

            if DEBUG then
                print("[EventRegrowth] Spawned a product " .. product .. " at " .. GetCoordStr(x,y,z) .. " for prefab " .. prefab .. " at " .. GetPosStr(position) .. " with rand radius " .. rand_radius)
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
            print("[EventRegrowth] Hooked " .. count .. " " .. prefab)
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
    function self:GetUpdatePeriod()
        return UPDATE_PERIOD
    end

    function self:FinishModConfig()
        regrowth_table_populated_by_mod = true
    end

    function self:RegisterRegrowth(prefab, product, interval)

        if interval == nil then
            if DEBUG then
                print("[EventRegrowth] WARNING: interval for prefab " .. prefab .. " is null. Using default.")
            end
            interval = 480
        end

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
            print("[EventRegrowth] Registered product " .. product .. " for prefab " .. prefab .. " with interval " .. interval)
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
    local function RegrowPrefabTask(prefab, data)
        local rand_radius = JITTER_RADIUS + data.retry * INC_RADIUS
        if rand_radius > MAX_RADIUS then
            rand_radius = MAX_RADIUS
        end

        local success = TryRegrowth(prefab, regrowth_table[prefab].product, data.position, rand_radius)

        if success == REGROW_STATUS.SUCCESS then
            data.remove = true
        end

        if success == REGROW_STATUS.STRUCT then
            -- only increase radius when there are structures nearby
            data.retry = data.retry + 1
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
                    for i = #entity_list[prefab], 1, -1 do
                        if entity_list[prefab][i].remove then
                            -- handle expired objects first
                            if DEBUG then
                                print("[EventRegrowth] Removed prefab " .. prefab .. " at ".. GetPosStr(entity_list[prefab][i].position) .." from the entity list.")
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
                                print("[EventRegrowth] Prefab " ..  prefab .. " at " .. GetPosStr(entity_list[prefab][i].position) .. " has interval " .. entity_list[prefab][i].interval )
                            end

                            if entity_list[prefab][i].interval == 0 then
                                -- different threads
                                local data = entity_list[prefab][i]
                                inst:DoTaskInTime(delay, function() RegrowPrefabTask(prefab, data) end)

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
                    print("[EventRegrowth] Saved " .. #data.entities[prefab] .. " entities for prefab " .. prefab)
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
                    print("[EventRegrowth] Loaded " .. #entity_list[prefab] .. " entities for prefab " .. prefab)
                end
            end
        end
    end
    
    --------------------------------------------------------------------------
    --[[ End ]]
    --------------------------------------------------------------------------
    
end)
    