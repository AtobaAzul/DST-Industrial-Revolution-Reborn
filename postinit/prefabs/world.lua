local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

env.AddPrefabPostInit("world", function(inst)
    TheWorld:AddComponent("ir_resourcenetwork_power")
    TheWorld:AddComponent("ir_resourcenetwork_item")
    TheWorld:AddComponent("ir_resourcenetwork_fluid")
end)