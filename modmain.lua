if GLOBAL.STRINGS.NAMES.MIGRATION_PORTAL then
	AddPrefabPostInit("world", function(inst)
		if inst.ismastersim then
			inst:AddComponent("natural_regrowth")
		end
	end)
else
	AddPrefabPostInit("forest", function(inst)
		if inst.ismastersim then
			inst:AddComponent("natural_regrowth")
		end
	end)
end

AddComponentPostInit("natural_regrowth", function(component)
	component:RegisterRegrowth("grass", "grass")
end)

AddComponentPostInit("natural_regrowth", function(component)
	component:RegisterRegrowth("evergreen", "evergreen")
end)


--"forest" for the overworld
--"cave" for the caves. 
--No more "world" prefab.