local carratrace_common = require("prefabs/yotc_carrat_race_common")
require("prefabutil")

local assets =
{
    Asset("ANIM", "anim/winona_battery_low.zip"),
    Asset("ANIM", "anim/winona_battery_placement.zip"),
}

local prefabs =
{
    "collapse_small",
}

local function onhammered(inst, worker)
    inst.components.lootdropper:DropLoot()

    local fx = SpawnPrefab("collapse_big")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function onhit(inst)
    if not inst:HasTag("burnt") and not inst.AnimState:IsCurrentAnimation("place") and not inst._active then
        inst.AnimState:PlayAnimation(inst.is_on and "hit_on" or "hit")
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddPhysics()

    inst.AnimState:SetBank("yotc_carrat_race_checkpoint")
    inst.AnimState:SetBuild("yotc_carrat_race_checkpoint")
    inst.AnimState:PlayAnimation("idle_off", true)

    inst:AddTag("ir_power") --added to pristine state for optimization

    carratrace_common.AddDeployHelper(inst, { "ir_node_fluid", "ir_generator_burnable", "ir_power" })

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnWorkCallback(onhit)
    inst.components.workable:SetOnFinishCallback(onhammered)

    MakeHauntableWork(inst)

    MakeDefaultFluidStructure(inst, {fluid = 0})

    return inst
end

return Prefab("ir_node_fluid", fn, assets, prefabs),
    MakePlacer("ir_node_fluid_placer", "yotc_carrat_race_checkpoint", "yotc_carrat_race_checkpoint", "idle_off", false,
        nil, nil,
        nil, nil, nil, function(inst)
        return carratrace_common.PlacerPostInit_AddPlacerRing(inst, "ir_fluid")
    end)