require("prefabutil")
local carratrace_common = require("prefabs/yotc_carrat_race_common")

local assets =
{
    Asset("ANIM", "anim/winona_battery_low.zip"),
    Asset("ANIM", "anim/winona_battery_placement.zip"),
}

local prefabs =
{
    "collapse_small",
}


local function OnWorkFinished(inst)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function OnWorked(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/together/catapult/hit")
end

local function OnGridPowerChanged(inst, power)
    if power >= 10 then
        inst.components.ir_fluid.fluid = 10
    else
        inst.components.ir_fluid.fluid = 0
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddPhysics()

    inst.AnimState:SetBank("ocean_trawler")
    inst.AnimState:SetBuild("ocean_trawler")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("ir_power") --added to pristine state for optimization
    inst:AddTag("ir_fluid")

    carratrace_common.AddDeployHelper(inst, { "ir_fluid" })

    inst:SetPhysicsRadiusOverride(2.35)

    MakeWaterObstaclePhysics(inst, 0.80, 2, 0.75)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnWorkCallback(OnWorked)
    inst.components.workable:SetOnFinishCallback(OnWorkFinished)

    MakeHauntableWork(inst)
    MakeDefaultPoweredStructure(inst, { power = -10})
    MakeDefaultFluidStructure(inst, {fluid = 10, fluid_type = "saltwater", is_pump = true})

    inst:ListenForEvent("ir_ongridpowerchanged", OnGridPowerChanged)

    return inst
end

return Prefab("ir_oceanpump", fn, assets, prefabs),
    MakePlacer("ir_oceanpump_placer", "ocean_trawler", "ocean_trawler", "idle_empty", false, nil, nil
        ,
        nil, nil, nil, function(inst)
        return carratrace_common.PlacerPostInit_AddPlacerRing(inst, "ir_fluid")
    end)
