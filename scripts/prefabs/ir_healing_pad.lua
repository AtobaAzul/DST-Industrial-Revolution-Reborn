require("prefabutil")
local carratrace_common = require("prefabs/yotc_carrat_race_common")

local assets =
{
    Asset("ANIM", "anim/winona_catapult.zip"),
    Asset("ANIM", "anim/winona_catapult_placement.zip"),
    Asset("ANIM", "anim/winona_battery_placement.zip"),
}

local prefabs =
{
    "winona_catapult_projectile",
    "winona_battery_sparks",
    "collapse_small",
}

local function OnWorked(inst, worker, workleft, numworks)
    inst.components.workable:SetWorkLeft(workleft)
end

local function OnWorkedBurnt(inst)
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function OnBurnt(inst)
    DefaultBurntStructureFn(inst)
    inst.SoundEmitter:KillAllSounds()

    inst.components.workable:SetOnWorkCallback(nil)
    inst.components.workable:SetOnFinishCallback(OnWorkedBurnt)
end

local function OnBuilt(inst) --, data)
    inst.sg:GoToState("place")
end

--------------------------------------------------------------------------

local function OnSave(inst, data)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() or inst:HasTag("burnt") then
        data.burnt = true
    end
end

local function OnLoad(inst, data)
    if data ~= nil and data.burnt then
        inst.components.burnable.onburnt(inst)
    end
end


--------------------------------------------------------------------------

local function IsPowered(inst)
    local grid = TheWorld.components.ir_powergrid:GetCurrentGrid(inst)
    if grid ~= nil and grid.grid_power >= 0 and inst.components.machine.ison then
        return true
    end
    return false
end

local function GetStatus(inst)
    return (inst:HasTag("burnt") and "BURNT")
        or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning() and "BURNING")
        or not IsPowered(inst) and "OFF"
        or nil
end

local function OnUpdateSparks(inst)
    if inst._flash > 0 then
        local k = inst._flash * inst._flash
        inst.components.colouradder:PushColour("wiresparks", .3 * k, .3 * k, 0, 0)
        inst._flash = inst._flash - .15
    else
        inst.components.colouradder:PopColour("wiresparks")
        inst._flash = nil
        inst.components.updatelooper:RemoveOnUpdateFn(OnUpdateSparks)
    end
end

local function DoWireSparks(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/together/spot_light/electricity", nil, .5)
    SpawnPrefab("winona_battery_sparks").entity:AddFollower():FollowSymbol(inst.GUID, "m2", 0, 0, 0)
    if inst.components.updatelooper ~= nil then
        if inst._flash == nil then
            inst.components.updatelooper:AddOnUpdateFn(OnUpdateSparks)
        end
        inst._flash = 1
        OnUpdateSparks(inst)
    end
end

local function OnConnectCircuit(inst) --, node)
    if not POPULATING then
        DoWireSparks(inst)
    end
end

local function DoHeal(inst, power)
    local targets = {}
    local x, y, z = inst.Transform:GetWorldPosition()

    for i, v in ipairs(AllPlayers) do
        if v.components.health ~= nil and v.components.health:IsHurt() and not (v.components.health:IsDead() or v:HasTag("playerghost")) and v.entity:IsVisible() and v:GetDistanceSqToPoint(x, y, z) < (TUNING.WORTOX_SOULHEAL_RANGE * TUNING.WORTOX_SOULHEAL_RANGE)*0.5 then
            table.insert(targets, v)
        end
    end
    
    if #targets > 0 then
        local amt = ((TUNING.HEALING_MED/2 - math.min(8, #targets) + 1) * math.clamp(power, 1, 5)) * 0.25
        for i, v in ipairs(targets) do
            v.components.health:DoDelta(amt, nil, inst.prefab)
            if v.components.hunger ~= nil then
                v.components.hunger:DoDelta(-amt/2)
            end
        end
    end
end

local function OnGridPowerChanged(inst, power)
    if power >= 0 and inst.components.machine.ison then
        inst.AnimState:OverrideSymbol("m2", "winona_battery_low", "m6")
        if inst._healtask ~= nil then
            inst._healtask:Cancel()
            inst._healtask = nil
        end
        inst._healtask = inst:DoPeriodicTask(2.5, DoHeal, 2.5, power)
    else
        if inst._healtask ~= nil then
            inst._healtask:Cancel()
            inst._healtask = nil
        end
        inst.AnimState:OverrideSymbol("m2", "winona_battery_low", "m0")
        inst.AnimState:PlayAnimation("idle_empty", true)
    end
end
--------------------------------------------------------------------------

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst:AddTag("engineering")
    inst:AddTag("structure")
    inst:AddTag("ir_power") --added to pristine state for optimization

    carratrace_common.AddDeployHelper(inst, { "ir_powerline", "ir_generator_burnable", "ir_power" })

    inst.AnimState:SetBank("winona_battery_low")
    inst.AnimState:SetBuild("winona_battery_low")
    inst.AnimState:PlayAnimation("idle_charge", true)
    inst.AnimState:OverrideSymbol("m2", "winona_battery_low", "m7")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    MakeDefaultIRStructure(inst, { power = -20, toggleable = true })

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("updatelooper")
    inst:AddComponent("colouradder")

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnWorkCallback(OnWorked)

    inst:AddComponent("savedrotation")

    inst:ListenForEvent("onbuilt", OnBuilt)
    inst:ListenForEvent("ir_addedtogrid", OnConnectCircuit)

    MakeHauntableWork(inst)
    MakeMediumBurnable(inst, nil, nil, true)
    MakeMediumPropagator(inst)
    inst.components.burnable:SetOnBurntFn(OnBurnt)
    inst:ListenForEvent("ir_ongridpowerchanged", OnGridPowerChanged)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

--------------------------------------------------------------------------

return Prefab("ir_healing_pad", fn, assets, prefabs),
    MakePlacer("ir_healing_pad_placer", "winona_battery_low", "winona_battery_low", "idle_empty", false, nil, nil,
        nil, nil, nil, function(inst)
        return carratrace_common.PlacerPostInit_AddPlacerRing(inst, "ir_power")
    end)
