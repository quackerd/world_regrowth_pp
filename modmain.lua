if GLOBAL.STRINGS.NAMES.MIGRATION_PORTAL then
	AddPrefabPostInit("world", function(inst)
		if inst.ismastersim then
			inst:AddComponent("natural_regrowth")
			inst:AddComponent("event_regrowth")
		end
	end)
else
	AddPrefabPostInit("world", function(inst)
		if inst.ismastersim then
			inst:AddComponent("natural_regrowth")
			inst:AddComponent("event_regrowth")
		end
	end)
end

AddComponentPostInit("natural_regrowth", function(component)
	component:RegisterRegrowth("evergreen", "evergreen")
end)

AddComponentPostInit("event_regrowth", function(component)
	component:RegisterRegrowth("knight", "knight")
	component:RegisterRegrowth("evergreen", "evergreen")
	component:RegisterRegrowth("grass", "grass")
	component:RegisterRegrowth("rock1", "rock1")
	component:RegisterRegrowth("rock2", "rock2")
	component:FinishModConfig()
end)


--"forest" for the overworld
--"cave" for the caves. 
--No more "world" prefab.