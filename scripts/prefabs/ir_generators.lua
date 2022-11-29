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

local PLACER_SCALE = 1.5

local function OnUpdatePlacerHelper(helperinst)
    if not helperinst.placerinst:IsValid() then
        helperinst.components.updatelooper:RemoveOnUpdateFn(OnUpdatePlacerHelper)
        helperinst.AnimState:SetAddColour(0, 0, 0, 0)
    elseif helperinst:IsNear(helperinst.placerinst, TUNING.WINONA_BATTERY_RANGE) then
        local hp = helperinst:GetPosition()
        local p1 = TheWorld.Map:GetPlatformAtPoint(hp.x, hp.z)

        local pp = helperinst.placerinst:GetPosition()
        local p2 = TheWorld.Map:GetPlatformAtPoint(pp.x, pp.z)

        if p1 == p2 then
            helperinst.AnimState:SetAddColour(helperinst.placerinst.AnimState:GetAddColour())
        else
            helperinst.AnimState:SetAddColour(0, 0, 0, 0)
        end
    else
        helperinst.AnimState:SetAddColour(0, 0, 0, 0)
    end
end

local function OnEnableHelper(inst, enabled, recipename, placerinst)
    if enabled then
        if inst.helper == nil and inst:HasTag("HAMMER_workable") and not inst:HasTag("burnt") then
            inst.helper = CreateEntity()

            --[[Non-networked entity]]
            inst.helper.entity:SetCanSleep(false)
            inst.helper.persists = false

            inst.helper.entity:AddTransform()
            inst.helper.entity:AddAnimState()

            inst.helper:AddTag("CLASSIFIED")
            inst.helper:AddTag("NOCLICK")
            inst.helper:AddTag("placer")

            inst.helper.AnimState:SetBank("winona_battery_placement")
            inst.helper.AnimState:SetBuild("winona_battery_placement")
            inst.helper.AnimState:PlayAnimation("idle")
            inst.helper.AnimState:SetLightOverride(1)
            inst.helper.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
            inst.helper.AnimState:SetLayer(LAYER_BACKGROUND)
            inst.helper.AnimState:SetSortOrder(1)
            inst.helper.AnimState:SetScale(PLACER_SCALE, PLACER_SCALE)

            inst.helper.entity:SetParent(inst.entity)

            if placerinst ~= nil then
                inst.helper:AddComponent("updatelooper")
                inst.helper.components.updatelooper:AddOnUpdateFn(OnUpdatePlacerHelper)
                inst.helper.placerinst = placerinst
                OnUpdatePlacerHelper(inst.helper)
            end
        end
    elseif inst.helper ~= nil then
        inst.helper:Remove()
        inst.helper = nil
    end
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

    if not TheNet:IsDedicated() then
        inst:AddComponent("deployhelper")
        inst.components.deployhelper:AddRecipeFilter("ir_generator_t1")
        inst.components.deployhelper.onenablehelper = OnEnableHelper
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.has_grid = false

    inst:DoTaskInTime(0, function()
        FindGrid(inst, 5)
    end)

    inst:AddComponent("inspectable")

    inst:AddComponent("ir_power")
    inst.components.ir_power.power = 10

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
    inst.components.burnable:SetOnBurntFn(OnBurnt)
    inst.components.burnable.ignorefuel = true --igniting/extinguishing should not start/stop fuel consumption

    return inst
end

local PLACER_SCALE = 1.5

local function placer_postinit_fn(inst)
    --Show the battery placer on top of the battery range ground placer

    local placer2 = CreateEntity()

    --[[Non-networked entity]]
    placer2.entity:SetCanSleep(false)
    placer2.persists = false

    placer2.entity:AddTransform()
    placer2.entity:AddAnimState()

    placer2:AddTag("CLASSIFIED")
    placer2:AddTag("NOCLICK")
    placer2:AddTag("placer")

    placer2.AnimState:SetBank("winona_battery_low")
    placer2.AnimState:SetBuild("winona_battery_low")
    placer2.AnimState:PlayAnimation("idle_placer")
    placer2.AnimState:SetLightOverride(1)

    placer2.entity:SetParent(inst.entity)

    inst.components.placer:LinkEntity(placer2)

    inst.AnimState:SetScale(PLACER_SCALE, PLACER_SCALE)
end

return Prefab("ir_generator_t1", fn, assets, prefabs),
    MakePlacer("ir_generator_t1_placer", "winona_battery_placement", "winona_battery_placement", "idle", true, nil, nil,
        nil, nil, nil, placer_postinit_fn)
