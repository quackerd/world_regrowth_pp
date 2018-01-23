--------------------------------------------------------------------------
--[[ NaturalRegrowth class definition ]]
-- A modified version of the original desolationspawner.lua
-- It acts as a standalone regrowth manager and is independent of the 3 existing ones
-- It's unlikely affected by game updates as long as Klei doesn't change the API (they shouldn't)
-- Klei has copyright over existing code used in this file.
-- by lolo Jan. 2018.
--------------------------------------------------------------------------

return Class(function(self, inst)

    assert(TheWorld.ismastersim, "natrual_regrowth should not exist on client")
    
    require "map/terrain"
    
    --------------------------------------------------------------------------
    --[[ Constants ]]
    --------------------------------------------------------------------------
    local RETRY_PER_PREFAB = 10 -- retry 5 times for each prefab
    local DEBUG = false
    local DEBUG_TELE = false
    local UPDATE_PERIOD = 31 -- less likely to update on the same frame as others
    local BASE_RADIUS = 20
    local EXCLUDE_RADIUS = 2
    local MIN_PLAYER_DISTANCE = 40 -- this is our "outer" sleep radius
    
    --------------------------------------------------------------------------
    --[[ Member variables ]]
    --------------------------------------------------------------------------
    
    --Public
    self.inst = inst
    
    --Private
    local regrowth_table = {}
    local area_data = {}
    
    --------------------------------------------------------------------------
    --[[ Private member functions ]]
    --------------------------------------------------------------------------
    
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
        
        if not (TheWorld.Map:CanPlantAtPoint(x, y, z) and
                TheWorld.Map:CanPlacePrefabFilteredAtPoint(x, y, z, prefab))
            or (RoadManager ~= nil and RoadManager:IsOnRoad(x, 0, z)) then
            -- Not ground we can grow on
            return false
        end
        return true
    end
    
    local function TryRegrowth(area, prefab, product)
        if TheWorld.topology.nodes[area] == nil then
            return false
        end

        local points_x, points_y = TheWorld.Map:GetRandomPointsForSite(TheWorld.topology.nodes[area].x, TheWorld.topology.nodes[area].y, TheWorld.topology.nodes[area].poly, 1)
        if #points_x < 1 or #points_y < 1 then
            return
        end
        local x = points_x[1]
        local z = points_y[1]

        if CanRegrow(x,0,z, product) then
            local instance = SpawnPrefab(product)
                
            if instance ~= nil then
                instance.Transform:SetPosition(x,0,z)
            end

            if DEBUG then
                print("[NaturalRegrowth] Spawned a ",product," for prefab ",prefab," at ", "(", x,0,z, ")", " in ", area)
            end

            if DEBUG_TELE then
                c_teleport(x,0,z)
            end

            return true
        else

            return false
        end
    end
    
    local function PopulateAreaData(prefab)
        if TheWorld.generated == nil then
            -- Still starting up, not ready yet.
            return
        end

        for area, densities in pairs(TheWorld.generated.densities) do
            if densities[prefab] ~= nil then
                for id, v in ipairs(TheWorld.topology.ids) do
                    if v == area then
                        if area_data[prefab] == nil then
                            area_data[prefab] = {}
                        end

                        table.insert(area_data[prefab], id)
                        break
                    end
                end
            end
        end
    end   
    
    local function PopulateAllAreaData()
        -- This has to be run after 1 frame from startup
        for prefab, _ in pairs(regrowth_table) do
            PopulateAreaData(prefab)
        end
    end
    
    --------------------------------------------------------------------------
    --[[ Public member functions ]]
    --------------------------------------------------------------------------
    
    function self:RegisterRegrowth(prefab, product)
        if DEBUG then
            print("Registered ", product, " for prefab " ,prefab )
        end
        regrowth_table[prefab] = product
        PopulateAreaData(prefab)
    end
    
    --------------------------------------------------------------------------
    --[[ Initialization ]]
    --------------------------------------------------------------------------
    
    inst:DoPeriodicTask(UPDATE_PERIOD, function() self:LongUpdate(UPDATE_PERIOD) end)
    
    inst:DoTaskInTime(0, PopulateAllAreaData)
    
    --------------------------------------------------------------------------
    --[[ Update ]]
    --------------------------------------------------------------------------
    
    function self:LongUpdate(dt)
        for prefab in pairs(area_data) do

            if DEBUG then
                print("[NaturalRegrowth] Regrowing ", prefab, "...")
            end

            local areas = area_data[prefab]

            if regrowth_table[prefab] == nil then
                if DEBUG then
                    print("[NaturalRegrowth] Discarded")
                end
                area_data[prefab] = nil
            else
                local rand = math.random(1, #areas)
                local attempts = 0

                while attempts < RETRY_PER_PREFAB do
                    local success = TryRegrowth(areas[rand], prefab, regrowth_table[prefab])
                    attempts = attempts + 1

                    if success then
                        if DEBUG then
                            print("[NaturalRegrowth] Succeeded after ", attempts, " attempts.")
                        end
                        break
                    end
                end

                if DEBUG and attempts == RETRY_PER_PREFAB then
                    print("[NaturalRegrowth] Failed after ", attempts, " attempts.")
                end
            end
        end
    end
    
    --------------------------------------------------------------------------
    --[[ Save/Load ]]
    --------------------------------------------------------------------------
    
    function self:OnSave()
        local data = {
            areas = {}
        }
        for prefab in pairs(area_data) do
            data.areas[prefab] = {}
            for area in pairs(area_data[prefab]) do
                table.insert(data.areas[prefab], area)
            end
        end
        return data
    end
    
    function self:OnLoad(data)
        for prefab in pairs(data.areas) do
            for area in pairs(data.areas) do
                if area_data[prefab] == nil then
                    area_data[prefab] = {}
                end
                table.insert(area_data[prefab], area)
            end
        end
    end
    
    --------------------------------------------------------------------------
    --[[ End ]]
    --------------------------------------------------------------------------
    
end)
