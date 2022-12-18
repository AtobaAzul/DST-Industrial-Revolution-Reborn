local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local carratrace_common = require("prefabs/yotc_carrat_race_common")


env.AddPrefabPostInit("lightning_rod", function(inst)
    inst:AddTag("ir_power") --added to pristine state for optimization

    carratrace_common.AddDeployHelper(inst, { "ir_node_power", "ir_generator_burnable", "ir_power" })

    if not TheWorld.ismastersim then
        return
    end

    MakeDefaultPoweredStructure(inst, { power = 0 })

    --inst:ListenForEvent("ir_ongridpowerchanged", OnGridPowerChanged)

    inst:DoTaskInTime(1, function()
        inst.components.ir_power.power = inst.chargeleft ~= nil and inst.chargeleft*3 or 0
    end)

    inst:WatchWorldState("cycles", function()
        inst.components.ir_power.power = inst.chargeleft ~= nil and inst.chargeleft*3 or 0
    end)
end)

env.AddPrefabPostInit("lightning_rod_placer", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    carratrace_common.PlacerPostInit_AddPlacerRing(inst, "ir_power")
end)
