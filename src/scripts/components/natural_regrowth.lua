--------------------------------------------------------------------------
--[[ NaturalRegrowth class definition ]]
-- A modified version of the original desolationspawner.lua
-- It acts as a standalone regrowth manager and is independent of the 3 existing ones
-- It's unlikely affected by game updates as long as Klei doesn't change the API (they shouldn't)
-- by lolo Jan. 2018
--------------------------------------------------------------------------

return Class(function(self, inst)

    assert(inst.ismastersim, "natural_regrowth should not exist on client")
    
    require "map/terrain"
    require "wrpp_util"
    
    --------------------------------------------------------------------------
    --[[ Constants ]]
    --------------------------------------------------------------------------
    local DEBUG = false
    local DEBUG_TELE = false
    local UPDATE_PERIOD = 11
    local THREADS_PER_BATCH = 3
    --------------------------------------------------------------------------
    --[[ Member variables ]]
    --------------------------------------------------------------------------
    
    --Public
    self.inst = inst
    
    --Private
    local regrowth_table = {}
    local area_data = {}
    local intervals = {}
    local regrowth_table_populated_by_mod = false
    
    --------------------------------------------------------------------------
    --[[ Private member functions ]]
    --------------------------------------------------------------------------
    
    local function TryRegrowth(x, y, z , prefab, product)
        local status = TestRegrowth(x,0,z, product, nil)
        if status == REGROW_STATUS.SUCCESS then
            local instance = SpawnPrefab(product)
                
            if instance ~= nil then
                instance.Transform:SetPosition(x,0,z)
            end

            if DEBUG then
                print("[NaturalRegrowth] Spawned a product " .. product .. " at " .. GetCoordStr(x,0,z) .. " for prefab " .. prefab)
            end

            if DEBUG_TELE then
                c_teleport(x,0,z)
            end

            return true
        else
            if DEBUG then
                print("[NaturalRegrowth] Failed to spawn a product " .. product .. " at " .. GetCoordStr(x,0,z) .. " for prefab " .. prefab .. " due to " .. GetRStatusStr(status))
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
            -- Still starting up
            return
        end

        if area_data[prefab] ~= nil then
            if DEBUG then
                print("[NaturalRegrowth] Already populated prefab " .. prefab)
            end
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

                        area_data[prefab][#area_data[prefab] + 1] = id
                        break
                    end
                end
            end
        end

        if DEBUG then
            print("[NaturalRegrowth] Populated " .. (area_data[prefab] == nil and 0 or #area_data[prefab]) .. " areas for prefab " .. prefab)
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
    function self:GetUpdatePeriod()
        return UPDATE_PERIOD
    end

    function self:FinishModConfig()
        regrowth_table_populated_by_mod = true
    end
    
    function self:RegisterRegrowth(prefab, product, interval)

        if interval == nil then
            if DEBUG then
                print("[NaturalRegrowth] WARNING: interval for prefab " .. prefab .. " is null. Using default.")
            end
            interval = 480
        end

        if DEBUG then
            print("[NaturalRegrowth] Registered product " .. product .. " for prefab " .. prefab .. " with interval " .. interval)
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
        local success = false
        local rand = math.random(1, #areas)
        local area = areas[rand]

        if inst.topology.nodes[area] == nil then
            return false
        end

        local points_x, points_y = inst.Map:GetRandomPointsForSite(inst.topology.nodes[area].x, inst.topology.nodes[area].y, inst.topology.nodes[area].poly, 1)
            
        if #points_x < 1 or #points_y < 1 then
            return false
        end

        success = TryRegrowth(points_x[1], 0, points_y[1], prefab, regrowth_table[prefab].product)

        if success then
            -- success, reset the timer
            intervals[prefab] = regrowth_table[prefab] == nil and nil or regrowth_table[prefab].interval
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

        -- area data because we only care about stuff that can naturally spawn
        for prefab in pairs(area_data) do
                if regrowth_table[prefab] == nil or area_data[prefab] == nil then
                    -- if regrowth table didn't register, or the entity doesn't have a natural density, do nothing
                    intervals[prefab] = nil
                else
                    if intervals[prefab] > UPDATE_PERIOD then
                        intervals[prefab] = intervals[prefab] - UPDATE_PERIOD
                    else
                        intervals[prefab] = 0
                    end
                    
                    if DEBUG then
                        print("[NaturalRegrowth] Prefab " .. prefab .. " has interval " .. intervals[prefab])
                    end

                    if intervals[prefab] == 0 then
                        local area = area_data[prefab]
                        -- use multiple threads? In the future a threadpool maybe?
                        inst:DoTaskInTime(delay, function() RegrowPrefabTask(area, prefab) end)
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
                data.areas[prefab][#data.areas[prefab] + 1] = area_data[prefab][i]
            end
            
            if DEBUG then
                print("[NaturalRegrowth] Saved " .. #data.areas[prefab] .. " areas for prefab " .. prefab)
            end
        end
        for prefab, interval in pairs(intervals) do
            if interval ~= nil then
                -- it can be set to nil in the event loop
                data.intervals[prefab] = interval
                if DEBUG then
                    print("[NaturalRegrowth] Saved interval " .. data.intervals[prefab] .. " for prefab " .. prefab)
                end
            end
        end
        return data
    end
    
    function self:OnLoad(data)
        for prefab in pairs(data.areas) do
                if area_data[prefab] == nil then
                    area_data[prefab] = {}
                for i = 1, #data.areas[prefab] do
                    area_data[prefab][#area_data[prefab] + 1] = data.areas[prefab][i]
                end

                if DEBUG then
                    print("[NaturalRegrowth] Loaded " .. #area_data[prefab] .. " areas for prefab " .. prefab)
                end
            end
        end

        for prefab, interval in pairs(data.intervals) do
            intervals[prefab] = interval
            if DEBUG then
                print("[NaturalRegrowth] Loaded interval " .. intervals[prefab] .. " for prefab " .. prefab)
            end
        end
    end
    
    --------------------------------------------------------------------------
    --[[ End ]]
    --------------------------------------------------------------------------
    
end)
