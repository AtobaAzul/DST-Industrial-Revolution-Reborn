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

local BATTERY_COST = TUNING.WINONA_BATTERY_LOW_MAX_FUEL_TIME * 0.9
local function CanBeUsedAsBattery(inst, user)
    if inst.components.fueled ~= nil and inst.components.fueled.currentfuel >= BATTERY_COST then
        return true
    else
        return false, "NOT_ENOUGH_CHARGE"
    end
end

local function UseAsBattery(inst, user)
    inst.components.fueled:DoDelta(-BATTERY_COST, user)
end

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
end

local function OnFuelSectionChange(new, old, inst)
    if inst.components.fueled.accepting then
        inst.AnimState:OverrideSymbol("m2", "winona_battery_low", "m" .. tostring(math.clamp(new + 1, 1, 7)))
        inst.AnimState:ClearOverrideSymbol("plug")
        UpdateSoundLoop(inst, new)
    end
end

local function OnAddFuel(inst)
    inst.components.ir_power.power = 10
    inst.components.fueled:StartConsuming()

    if not inst:IsAsleep() then
        StartSoundLoop(inst)
    end

    inst.SoundEmitter:PlaySound("dontstarve/common/together/battery/up")
end

local function OnWorked(inst)
    if inst.components.fueled.accepting then
        PlayHitAnim(inst)
    end
    inst.SoundEmitter:PlaySound("dontstarve/common/together/catapult/hit")
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

local function fn()
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
    inst:AddTag("battery")

    carratrace_common.AddDeployHelper(inst, { "ir_powerline", "ir_generator_t1", "ir_power"})

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("fueled")
    inst.components.fueled:SetDepletedFn(OnFuelEmpty)
    inst.components.fueled:SetTakeFuelFn(OnAddFuel)
    inst.components.fueled:InitializeFuelLevel(TUNING.WINONA_BATTERY_LOW_MAX_FUEL_TIME)
    inst.components.fueled.fueltype = FUELTYPE.CHEMICAL
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

    inst:AddComponent("battery")
    inst.components.battery.canbeused = CanBeUsedAsBattery
    inst.components.battery.onused = UseAsBattery

    MakeHauntableWork(inst)
    MakeMediumBurnable(inst, nil, nil, true)
    MakeMediumPropagator(inst)
    MakeDefaultIRStructure(inst, {power = 10})
    
    inst.components.burnable:SetOnBurntFn(OnBurnt)
    inst.components.burnable.ignorefuel = true --igniting/extinguishing should not start/stop fuel consumption

    return inst
end

return Prefab("ir_generator_t1", fn, assets, prefabs),
    MakePlacer("ir_generator_t1_placer", "winona_battery_low", "winona_battery_low", "idle_empty", false, nil, nil,
        nil, nil, nil, function(inst)
            return carratrace_common.PlacerPostInit_AddPlacerRing(inst, "ir_power")
        end)
