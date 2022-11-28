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
		ToggleLights(inst, inst.is_on, true)
	end
end

local function OnBurnt(inst)
    DefaultBurntStructureFn(inst)
    inst.components.workable:SetOnWorkCallback(nil)
    inst:RemoveTag("NOCLICK")
end

local function OnSave(inst, data)
    data.grid = TheWorld.components.ir_powergrid:GetCurrentGrid(inst)
end

local function FindGrid(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, TUNING.YOTC_RACER_CHECKPOINT_FIND_DIST, { "ir_power" }, { "burnt" })
    local found_grid = false

    for k, v in pairs(ents) do
        local grid = TheWorld.components.ir_powergrid:GetCurrentGrid(v)
        if grid ~= nil then
            TheWorld.components.ir_powergrid:AddInstToGrid(inst, grid)
            found_grid = true
            break
        end
    end

    if not found_grid then
        local grid = TheWorld.components.ir_powergrid:CreateGrid()
        TheWorld.components.ir_powergrid:AddInstToGrid(inst, grid)
    end
end

local function OnLoad(inst, data)
    if data.grid ~= nil then
        inst.has_grid = true
    else
        FindGrid(inst)
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

    carratrace_common.AddDeployHelper(inst, {"ir_power"})

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.has_grid = false

    inst:DoTaskInTime(0, FindGrid)

    inst:AddComponent("inspectable")

    inst:AddComponent("ir_power")
    inst.components.ir_power.power = 0

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnWorkCallback(onhit)
    inst.components.workable:SetOnFinishCallback(onhammered)

    MakeHauntableWork(inst)
    MakeMediumBurnable(inst, nil, nil, true)
    MakeMediumPropagator(inst)

    inst.components.burnable:SetOnBurntFn(OnBurnt)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("ir_powerline", fn, assets, prefabs),
    MakePlacer("ir_powerline_placer", "yotc_carrat_race_checkpoint", "yotc_carrat_race_checkpoint", "idle_off", false, nil, nil,
        nil, nil, nil, function(inst)
        return carratrace_common.PlacerPostInit_AddPlacerRing(inst, "ir_power")
    end)
