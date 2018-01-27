--------------------------------------------------------------------------
--[[ NaturalRegrowth class definition ]]
-- A modified version of the original desolationspawner.lua
-- It acts as a standalone regrowth manager and is independent of the 3 existing ones
-- It's unlikely affected by game updates as long as Klei doesn't change the API (they shouldn't)
-- by lolo Jan. 2018
--------------------------------------------------------------------------

return Class(function(self, inst)

    assert(inst.ismastersim, "natrual_regrowth should not exist on client")
    
    require "map/terrain"
    
    --------------------------------------------------------------------------
    --[[ Constants ]]
    --------------------------------------------------------------------------
    local DEBUG = false
    local DEBUG_TELE = false
    local UPDATE_PERIOD = 9
    local BASE_RADIUS = 20
    local EXCLUDE_RADIUS = 3
    local MIN_PLAYER_DISTANCE = 40
    local THREADS_PER_BATCH = 5
    --------------------------------------------------------------------------
    --[[ Member variables ]]
    --------------------------------------------------------------------------
    
    --Public
    self.inst = inst
    
    --Private
    local regrowth_table = {}
    local area_data = {}
    local intervals = {}
    
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
        
        if not (inst.Map:CanPlantAtPoint(x, y, z) and
                inst.Map:CanPlacePrefabFilteredAtPoint(x, y, z, prefab))
            or (RoadManager ~= nil and RoadManager:IsOnRoad(x, 0, z)) then
            -- Not ground we can grow on
            return false
        end
        return true
    end
    
    local function TryRegrowth(area, prefab, product)
        if inst.topology.nodes[area] == nil then
            return false
        end

        local points_x, points_y = inst.Map:GetRandomPointsForSite(inst.topology.nodes[area].x, inst.topology.nodes[area].y, inst.topology.nodes[area].poly, 1)
        if #points_x < 1 or #points_y < 1 then
            return false
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
            if DEBUG then
                print("[NaturalRegrowth] Failed to spawn a ",product," for prefab ",prefab," at ", "(", x,0,z, ")", " in ", area)
            end
            return false
        end
    end

    local function PrintDensities()
        for area, densities in pairs(inst.generated.densities) do
            for k,v in pairs(densities) do
                print(area, k, v)
            end
        end
    end

    local function PopulateAreaData(prefab)
        if inst.generated == nil then
            -- Still starting up, not ready yet.
            return
        end

        -- PrintDensities()

        for area, densities in pairs(inst.generated.densities) do
            if densities[prefab] ~= nil then
                for id, v in ipairs(inst.topology.ids) do
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

        if DEBUG then
            print("[NaturalRegrowth] Populated ", area_data[prefab] == nil and 0 or #area_data[prefab], " areas for ", prefab)
        end
    end   
    
    local function PopulateAllAreaData()
        -- This has to be run after 1 frame from startup
        for prefab in pairs(regrowth_table) do
            PopulateAreaData(prefab)
        end
    end
    
    --------------------------------------------------------------------------
    --[[ Public member functions ]]
    --------------------------------------------------------------------------
    
    function self:RegisterRegrowth(prefab, product, interval)
        if DEBUG then
            print("[NaturalRegrowth] Registered ", product, " for prefab " ,prefab )
        end
        regrowth_table[prefab] = {product = product, interval = interval}

        if intervals[prefab] == nil then
            intervals[prefab] = interval
        end

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

    local function RegrowPrefabTask(areas, prefab)
        local rand = math.random(1, #areas)
        local success = TryRegrowth(areas[rand], prefab, regrowth_table[prefab].product)
        if success then
            -- success, reset the timer
            intervals[prefab] = regrowth_table[prefab] == nil and nil or regrowth_table[prefab].interval
        end
    end
    
    function self:LongUpdate(dt)
        local count = 0
        local delay = 0
        for prefab in pairs(area_data) do
            local areas = area_data[prefab]

            if regrowth_table[prefab] == nil then
                area_data[prefab] = nil
                intervals[prefab] = nil
            else
                if intervals[prefab] > UPDATE_PERIOD then
                    intervals[prefab] = intervals[prefab] - UPDATE_PERIOD
                else
                    intervals[prefab] = 0
                end
                
                if DEBUG then
                    print("[NaturalRegrowth]", prefab, " has interval ", intervals[prefab])
                end

                if intervals[prefab] == 0 then
                    -- use multiple threads? In the future a threadpool maybe?
                    inst:DoTaskInTime(delay, function() RegrowPrefabTask(areas,prefab) end)
                    -- try not to flood the server with threads
                    count = count + 1
                    if math.fmod( count,THREADS_PER_BATCH ) == 0 then
                        delay = delay + 1
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
            areas = {},
            intervals = {}
        }
        for prefab in pairs(area_data) do
            data.areas[prefab] = {}

            for i = 1, #area_data[prefab] do
                table.insert(data.areas[prefab], area_data[prefab][i])
            end
        end
        for prefab, interval in pairs(intervals) do
            data.intervals[prefab] = interval
        end
        return data
    end
    
    function self:OnLoad(data)
        for prefab in pairs(data.areas) do
            if area_data[prefab] == nil then
                area_data[prefab] = {}
            end
            for i = 1, #data.areas[prefab] do
                table.insert(area_data[prefab], data.areas[prefab][i])
            end
        end

        for prefab, interval in pairs(data.intervals) do
            intervals[prefab] = interval
        end
    end
    
    --------------------------------------------------------------------------
    --[[ End ]]
    --------------------------------------------------------------------------
    
end)
