--------------------------------------------------------------------------
--[[ EventRegrowth class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

    assert(TheWorld.ismastersim, "event_regrowth should not exist on client")
    
    require "map/terrain"
    
    --------------------------------------------------------------------------
    --[[ Constants ]]
    --------------------------------------------------------------------------

    local DEBUG = true
    local DEBUG_TELE = true
    local RETRY_PER_PREFAB = 10 -- retry 5 times for each prefab
    local UPDATE_PERIOD = 3 -- less likely to update on the same frame as others
    local BASE_RADIUS = 20
    local EXCLUDE_RADIUS = 2
    local JITTER_RADIUS = 10
    local MIN_PLAYER_DISTANCE = 40 -- this is our "outer" sleep radius
    
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

        table.insert(entity_list[ent.prefab], position)
        ent:RemoveEventCallback("onremove", EntityDeathEventHandler, nil)

        if DEBUG then
            print("[EventRegrowth] Entity of type ", ent.prefab, " was removed at ", position)
        end
    end

    local function TestForRegrow(x, y, z, tile)
        if TheWorld.Map:GetTileAtPoint(x, y, z) ~= tile then
            -- keep things in their biome (more or less)
            return false
        end
    
        local ents = TheSim:FindEntities(x,y,z, EXCLUDE_RADIUS)
        if #ents > 0 then
            -- Too dense
            return false
        end

        if IsAnyPlayerInRange(x,y,z, MIN_PLAYER_DISTANCE, nil) then
            return false
        end
    
        local ents = TheSim:FindEntities(x,y,z, BASE_RADIUS, nil, nil, { "structure", "wall" })
        if #ents > 0 then
            -- No regrowth around players and their bases
            return false
        end
        return true
    end

    local function TryRegrowth(prefab, product, position)
        local x = position.x
        local y = position.y
        local z = position.z
    
        local orig_tile = TheWorld.Map:GetTileAtPoint(x,y,z)

        local theta = math.random() * 2 * PI
        local radius = math.random() * JITTER_RADIUS
        local x = x + radius * math.cos(theta)
        local z = z - radius * math.sin(theta)
    
        if TestForRegrow(x,y,z, orig_tile) then
            local instance = SpawnPrefab(product)
            if instance ~= nil then
                instance.Transform:SetPosition(x,y,z)
                instance:ListenForEvent("onremove", EntityDeathEventHandler, nil)

                if DEBUG then
                    print("[EventRegrowth] Spawned a ",product," for prefab ",prefab," at ", "(", x,0,z, ")")
                end

                if DEBUG_TELE then
                    c_teleport(x,0,z)
                end
            end
            return true
        else
            return false
        end
    end

    local function HookAllEntities()
        while next(Ents) == nil do
        end
        local count = 0
        for k, v in pairs(Ents) do
            if regrowth_table[v.prefab] ~= nil then
                v:RemoveEventCallback("onremove", EntityDeathEventHandler, nil)
                v:ListenForEvent("onremove", EntityDeathEventHandler, nil)
                count = count + 1
            end
        end
        if DEBUG then
            print("[EventRegrowth] Hooked ", count, " entities.")
        end
    end

    --------------------------------------------------------------------------
    --[[ Public member functions ]]
    --------------------------------------------------------------------------
    function self:FinishModConfig()
        regrowth_table_populated_by_mod = true
    end

    function self:RegisterRegrowth(prefab, product)
        if regrowth_table[prefab] == nil then
            -- avoid duplicate registration
            regrowth_table[prefab] = product
            HookAllEntities()
        end

        if DEBUG then
            print("[EventRegrowth] Registered ", product ," for ", prefab)
        end
    end
    
    --------------------------------------------------------------------------
    --[[ Initialization ]]
    --------------------------------------------------------------------------
    
    inst:DoPeriodicTask(UPDATE_PERIOD, function() self:LongUpdate(UPDATE_PERIOD) end)

    inst:DoPeriodicTask(99, HookAllEntities, 0)
    --------------------------------------------------------------------------
    --[[ Update ]]
    --------------------------------------------------------------------------
    
    function self:LongUpdate(dt)
        if not regrowth_table_populated_by_mod then
            -- do nothing if the table is not fully initialized
            -- in case we accidentally drop some saved entities due to the respawn_table[prefab] == nil check
            return
        end

        for prefab in pairs(entity_list) do
            if entity_list[prefab] == nil or #entity_list[prefab] == 0 then
                -- only do meaningful work
            else
                if DEBUG then
                    print("[EventRegrowth] Regrowing ", prefab, "...")
                end
                if regrowth_table[prefab] == nil then
                    -- if we don't have it registered, discard
                    entity_list[prefab] = nil
                    if DEBUG then
                        print("[EventRegrowth] Discarded")
                    end
                else
                    for i = #entity_list[prefab],1,-1 do
                        if DEBUG then
                            print("[EventRegrowth] Spawning at location", entity_list[prefab][i])
                        end
                        local attempts = 0
                        while attempts < RETRY_PER_PREFAB do
                            local success = TryRegrowth(prefab, regrowth_table[prefab], entity_list[prefab][i])
                            attempts = attempts + 1
        
                            if success then
                                print("[EventRegrowth] Succeeded after ", attempts, " attempts.")
                                -- we respawned this guy, remove from the list
                                table.remove(entity_list[prefab], i)
                                break
                            end
                        end
        
                        if DEBUG and attempts == RETRY_PER_PREFAB then
                            print("[EventRegrowth] Failed after ", attempts, " attempts.")
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

    end
    
    function self:OnLoad(data)

    end
    
    --------------------------------------------------------------------------
    --[[ End ]]
    --------------------------------------------------------------------------
    
end)
    