local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local carratrace_common = require("prefabs/yotc_carrat_race_common")

local function OnGridPowerChanged(inst, power)
    if power >= -5 then
        inst:AddTag("fridge")
        inst.SoundEmitter:PlaySound("dontstarve/common/ice_box_LP", "idlesound")
    else
        inst:RemoveTag("fridge")
        inst.SoundEmitter:KillSound("idlesound")
    end
end


local function GetStatus(inst)
    return not inst:HasTag("fridge") and "OFF"
        or nil
end

env.AddPrefabPostInit("icebox", function(inst)
    inst:AddTag("ir_power") --added to pristine state for optimization

    carratrace_common.AddDeployHelper(inst, { "ir_node_power", "ir_generator_burnable", "ir_power" })

    if not TheWorld.ismastersim then
        return
    end

    inst.components.inspectable.getstatus = GetStatus

    MakeDefaultPoweredStructure(inst, {power = -5})

    inst:ListenForEvent("ir_ongridpowerchanged", OnGridPowerChanged)
end)

env.AddPrefabPostInit("icebox_placer", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    carratrace_common.PlacerPostInit_AddPlacerRing(inst, "ir_power")
end)