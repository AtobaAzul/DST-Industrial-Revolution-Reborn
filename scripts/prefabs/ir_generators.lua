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

local NUM_LEVELS = 6

local function OnHitAnimOver(inst)
    inst:RemoveEventCallback("animover", OnHitAnimOver)
    if inst.AnimState:IsCurrentAnimation("hit") then
        if inst.components.fueled:IsEmpty() then
            inst.AnimState:PlayAnimation("idle_empty")
        else
            inst.AnimState:PlayAnimation("idle_charge", true)
        end
    end
end

local function PlayHitAnim(inst)
    inst:RemoveEventCallback("animover", OnHitAnimOver)
    inst:ListenForEvent("animover", OnHitAnimOver)
    inst.AnimState:PlayAnimation("hit")
end

local function UpdateSoundLoop(inst, level)
    if inst.SoundEmitter:PlayingSound("loop") then
        inst.SoundEmitter:SetParameter("loop", "intensity", 1 - level / NUM_LEVELS)
    end
end

local function StartSoundLoop(inst)
    if not inst.SoundEmitter:PlayingSound("loop") then
        inst.SoundEmitter:PlaySound("dontstarve/common/together/battery/on_LP", "loop")
        UpdateSoundLoop(inst, inst.components.fueled:GetCurrentSection())
    end
end

local function StopSoundLoop(inst)
    inst.SoundEmitter:KillSound("loop")
end

local function OnWorkFinished(inst)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()

    local grid = TheWorld.components.ir_resourcenetwork_power:GetCurrentGrid(inst)
    TheWorld.components.ir_resourcenetwork_power:RemoveInstFromGrids(inst)
    if grid ~= nil then
        TheWorld.components.ir_resourcenetwork_power:CalculateGridPower(grid)
    end
end

local function OnFuelEmpty(inst)
    inst.components.ir_power.power = 0
    inst.components.fueled:StopConsuming()

    inst.AnimState:OverrideSymbol("m2", "winona_battery_low", "m1")
    inst.AnimState:OverrideSymbol("plug", "winona_battery_low", "plug_off")
    if inst.AnimState:IsCurrentAnimation("idle_charge") then
        inst.AnimState:PlayAnimation("idle_empty")
    end
    if not POPULATING then
        inst.SoundEmitter:PlaySound("dontstarve/common/together/battery/down")
    end
    StopSoundLoop(inst)
end

local function OnFuelEmpty_Disposeable(inst)
    OnWorkFinished(inst)
end

local function OnFuelSectionChange(new, old, inst)
    if inst.components.fueled.accepting then
        inst.AnimState:OverrideSymbol("m2", "winona_battery_low", "m" .. tostring(math.clamp(new + 1, 1, 7)))
        inst.AnimState:ClearOverrideSymbol("plug")
        UpdateSoundLoop(inst, new)
        inst.fuelsection = new
    end
end

local function OnAddFuel(inst)
    inst.components.machine.ison = true
    inst.components.ir_power.power = 10
    inst.components.fueled:StartConsuming()

    if not inst:IsAsleep() then
        StartSoundLoop(inst)
    end
    if inst.fuelsection ~= nil then
        OnFuelSectionChange(inst.fuelsection, nil, inst)
    end
    inst.AnimState:PlayAnimation("idle_charge", true)
    inst.SoundEmitter:PlaySound("dontstarve/common/together/battery/up")
end

local function OnWorked(inst)
    if inst.components.fueled.accepting then
        PlayHitAnim(inst)
    end
    inst.SoundEmitter:PlaySound("dontstarve/common/together/catapult/hit")
end

local function OnBurnt(inst)
    DefaultBurntStructureFn(inst)
    StopSoundLoop(inst)
    if inst.components.fueled ~= nil then
        inst:RemoveComponent("fueled")
    end
    inst.components.workable:SetOnWorkCallback(nil)
    inst:RemoveTag("NOCLICK")
end

local function OnBuilt3(inst)
    inst:RemoveEventCallback("animover", OnBuilt3)
    if inst.AnimState:IsCurrentAnimation("place") then
        inst:RemoveTag("NOCLICK")
        inst.components.fueled.accepting = true
        if inst.components.fueled:IsEmpty() then
            OnFuelEmpty(inst)
        else
            OnFuelSectionChange(inst.components.fueled:GetCurrentSection(), nil, inst)
            inst.AnimState:PlayAnimation("idle_charge", true)
            if not inst.components.fueled.consuming then
                inst.components.fueled:StartConsuming()
            end
            if not inst:IsAsleep() then
                StartSoundLoop(inst)
            end
        end
    end
end

local function OnBuilt(inst) --, data)
    inst:ListenForEvent("animover", OnBuilt3)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:ClearAllOverrideSymbols()
    inst.SoundEmitter:PlaySound("dontstarve/common/together/battery/place")
end

local function OnSave(inst, data)
    if inst.fuelsection ~= nil then
        data.fuelsection = inst.fuelsection
    end
end

local function OnLoadPostPass(inst, data)
    if data ~= nil and data.fuelsection ~= nil then
        inst:DoTaskInTime(0, function()
            OnFuelSectionChange(data.fuelsection, nil, inst)
        end)
    end
end

local function fn_burnable()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddPhysics()

    inst.AnimState:SetBank("winona_battery_low")
    inst.AnimState:SetBuild("winona_battery_low")
    inst.AnimState:PlayAnimation("idle_empty", true)

    inst:AddTag("ir_power") --added to pristine state for optimization

    carratrace_common.AddDeployHelper(inst, { "ir_node_power", "ir_generator_burnable", "ir_power" })

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:ListenForEvent("onbuilt", OnBuilt)

    inst:AddComponent("fueled")
    inst.components.fueled:SetDepletedFn(OnFuelEmpty)
    inst.components.fueled:SetTakeFuelFn(OnAddFuel)
    inst.components.fueled:InitializeFuelLevel(TUNING.WINONA_BATTERY_LOW_MAX_FUEL_TIME)
    inst.components.fueled.fueltype = FUELTYPE.BURNABLE
    inst.components.fueled:SetSections(NUM_LEVELS)
    inst.components.fueled:SetSectionCallback(OnFuelSectionChange)
    inst.components.fueled.accepting = true
    inst.components.fueled:StartConsuming()

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnWorkCallback(OnWorked)
    inst.components.workable:SetOnFinishCallback(OnWorkFinished)

    MakeHauntableWork(inst)
    MakeMediumBurnable(inst, nil, nil, true)
    MakeMediumPropagator(inst)
    MakeDefaultPoweredStructure(inst, { power = 10, toggleable = true })

    inst.components.burnable:SetOnBurntFn(OnBurnt)
    inst.components.burnable.ignorefuel = true --igniting/extinguishing should not start/stop fuel consumption

    inst.OnSave = OnSave
    inst.OnLoadPostPass = OnLoadPostPass

    return inst
end

local function fn_battery()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddPhysics()

    inst.AnimState:SetBank("winona_battery_low")
    inst.AnimState:SetBuild("winona_battery_low")
    inst.AnimState:PlayAnimation("idle_charge", true)

    inst:AddTag("ir_power") --added to pristine state for optimization

    carratrace_common.AddDeployHelper(inst, { "ir_node_power", "ir_generator_burnable", "ir_power" })

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:ListenForEvent("onbuilt", OnBuilt)

    inst:AddComponent("fueled")
    inst.components.fueled:SetDepletedFn(OnFuelEmpty_Disposeable)
    inst.components.fueled:SetTakeFuelFn(OnAddFuel)
    inst.components.fueled:InitializeFuelLevel(TUNING.WINONA_BATTERY_LOW_MAX_FUEL_TIME * 2)
    inst.components.fueled.fueltype = FUELTYPE.MAGIC
    inst.components.fueled:SetSections(NUM_LEVELS)
    inst.components.fueled:SetSectionCallback(OnFuelSectionChange)
    inst.components.fueled.accepting = true
    inst.components.fueled:StartConsuming()

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({"goldnugget", "cutstone"})

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnWorkCallback(OnWorked)
    inst.components.workable:SetOnFinishCallback(OnWorkFinished)

    MakeHauntableWork(inst)
    MakeMediumBurnable(inst, nil, nil, true)
    MakeMediumPropagator(inst)
    MakeDefaultPoweredStructure(inst, { power = 15 })

    inst.components.burnable:SetOnBurntFn(OnBurnt)
    inst.components.burnable.ignorefuel = true --igniting/extinguishing should not start/stop fuel consumption

    inst.OnSave = OnSave
    inst.OnLoadPostPass = OnLoadPostPass

    return inst
end

return Prefab("ir_generator_burnable", fn_burnable, assets, prefabs),
    MakePlacer("ir_generator_burnable_placer", "winona_battery_low", "winona_battery_low", "idle_empty", false, nil, nil
        ,
        nil, nil, nil, function(inst)
        return carratrace_common.PlacerPostInit_AddPlacerRing(inst, "ir_power")
    end),
    Prefab("ir_generator_battery", fn_battery, assets, prefabs),
    MakePlacer("ir_generator_battery_placer", "winona_battery_low", "winona_battery_low", "idle_empty", false, nil, nil,
        nil, nil, nil, function(inst)
        return carratrace_common.PlacerPostInit_AddPlacerRing(inst, "ir_power")
    end)
