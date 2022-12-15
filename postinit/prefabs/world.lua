local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

env.AddPrefabPostInit("world", function(inst)
    TheWorld:AddComponent("ir_resourcenetwork_power")
end)