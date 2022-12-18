local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local carratrace_common = require("prefabs/yotc_carrat_race_common")


env.AddPrefabPostInit("researchlab2", function(inst)
    inst:AddTag("ir_power") --added to pristine state for optimization

    carratrace_common.AddDeployHelper(inst, { "ir_node_power", "ir_generator_burnable", "ir_power" })

    if not TheWorld.ismastersim then
        return
    end

    local _onturnon = inst.components.prototyper.onturnon
    local _onturnoff = inst.components.prototyper.onturnoff 
    local _onactivate = inst.components.prototyper.onactivate 

    local function OnGridPowerChanged(inst, power)
        if power >= 0 then
            inst:AddComponent("prototyper")
            inst.components.prototyper.onturnon = _onturnon
            inst.components.prototyper.onturnoff = _onturnoff
            inst.components.prototyper.onactivate = _onactivate
            inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.ALCHEMYMACHINE
        else
            inst:RemoveComponent("prototyper")
            if inst._activetask == nil and not inst:HasTag("burnt") then
                inst.AnimState:PushAnimation("idle", false)
                inst.SoundEmitter:KillSound("idlesound")
                inst.SoundEmitter:KillSound("loop")
            end        
        end
    end

    MakeDefaultPoweredStructure(inst, { power = -15 })

    inst:ListenForEvent("ir_ongridpowerchanged", OnGridPowerChanged)
end)

env.AddPrefabPostInit("researchlab2_placer", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    carratrace_common.PlacerPostInit_AddPlacerRing(inst, "ir_power")
end)