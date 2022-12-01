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

local brain = require("brains/winonacatapultbrain")

local RETARGET_MUST_TAGS = { "_combat" }
local RETARGET_CANT_TAGS = { "INLIMBO", "player", "engineering" }

local function RetargetFn(inst)
    local target = inst.components.combat.target
    if target ~= nil and
        target:IsValid() and
        inst:IsNear(target, TUNING.WINONA_CATAPULT_MAX_RANGE) and
        not
        inst:IsNear(target,
            math.max(0, TUNING.WINONA_CATAPULT_MIN_RANGE - TUNING.WINONA_CATAPULT_AOE_RADIUS - target:GetPhysicsRadius(0))) then
        --keep current target
        return
    end

    local playertargets = {}
    for i, v in ipairs(AllPlayers) do
        if v.components.combat.target ~= nil then
            playertargets[v.components.combat.target] = true
        end
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, TUNING.WINONA_CATAPULT_MAX_RANGE, RETARGET_MUST_TAGS, RETARGET_CANT_TAGS)
    local tooclosetarget = nil
    for i, v in ipairs(ents) do
        if v ~= inst and
            v ~= target and
            v.entity:IsVisible() and
            inst.components.combat:CanTarget(v) and
            (playertargets[v] or
                v.components.combat:TargetIs(inst) or
                (v.components.combat.target ~= nil and v.components.combat.target:HasTag("player"))
            ) then
            if not
                inst:IsNear(v,
                    math.max(0,
                        TUNING.WINONA_CATAPULT_MIN_RANGE - TUNING.WINONA_CATAPULT_AOE_RADIUS - v:GetPhysicsRadius(0))) then
                --new target between the attackable ranges
                return v, target ~= nil
            elseif tooclosetarget == nil then
                tooclosetarget = v
            end
        end
    end
    return tooclosetarget, target ~= nil
end

local function ShouldKeepTarget(inst, target)
    return target ~= nil
        and target:IsValid()
        and target.components.health ~= nil
        and not target.components.health:IsDead()
        and inst:IsNear(target, TUNING.WINONA_CATAPULT_MAX_RANGE + TUNING.WINONA_CATAPULT_KEEP_TARGET_BUFFER)
end

local function ShareTargetFn(dude)
    return dude:HasTag("catapult")
end

local function OnAttacked(inst, data)
    local attacker = data ~= nil and data.attacker or nil
    if attacker ~= nil and not PreventTargetingOnAttacked(inst, attacker, "player") then
        if inst:IsNear(attacker, TUNING.WINONA_CATAPULT_MAX_RANGE) and
            not
            inst:IsNear(attacker,
                math.max(0,
                    TUNING.WINONA_CATAPULT_MIN_RANGE - TUNING.WINONA_CATAPULT_AOE_RADIUS - attacker:GetPhysicsRadius(0))) then
            inst.components.combat:SetTarget(attacker)
        end
        inst.components.combat:ShareTarget(attacker, 15, ShareTargetFn, 10)
    end
    if data ~= nil and data.damage == 0 and data.weapon ~= nil and
        (data.weapon:HasTag("rangedlighter") or data.weapon:HasTag("extinguisher")) then
        --V2C: weapon may be invalid by the time it reaches stategraph event handler, so ues a lua property instead
        data.weapon._nocatapulthit = true
    end
end

local function OnWorked(inst, worker, workleft, numworks)
    inst.components.workable:SetWorkLeft(4)
    inst.components.combat:GetAttacked(worker, numworks * TUNING.WINONA_CATAPULT_HEALTH / 4,
        worker.components.inventory ~= nil and worker.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil)
end

local function OnWorkedBurnt(inst)
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function OnDeath(inst)
    if inst._inittask ~= nil then
        inst._inittask:Cancel()
        inst._inittask = nil
    end
    inst.components.workable:SetWorkable(false)
    if inst.components.burnable ~= nil then
        if inst.components.burnable:IsBurning() then
            inst.components.burnable:Extinguish()
        end
        inst.components.burnable.canlight = false
    end
    inst.Physics:SetActive(false)
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("none")
end

local function OnBurnt(inst)
    DefaultBurntStructureFn(inst)

    inst:SetBrain(nil)
    inst:ClearStateGraph()
    inst.SoundEmitter:KillAllSounds()

    inst:RemoveEventCallback("attacked", OnAttacked)
    inst:RemoveEventCallback("death", OnDeath)

    inst.components.workable:SetOnWorkCallback(nil)
    inst.components.workable:SetOnFinishCallback(OnWorkedBurnt)

    if inst._inittask ~= nil then
        inst._inittask:Cancel()
        inst._inittask = nil
    end

    inst:RemoveComponent("health")
    inst:RemoveComponent("combat")

    inst:AddTag("notarget") -- just in case???
end

local function OnBuilt(inst) --, data)
    inst.sg:GoToState("place")
end

--------------------------------------------------------------------------

local function OnHealthDelta(inst)
    if inst.components.health:IsHurt() then
        inst.components.health:StartRegen(TUNING.WINONA_CATAPULT_HEALTH_REGEN, TUNING.WINONA_CATAPULT_HEALTH_REGEN_PERIOD)
    else
        inst.components.health:StopRegen()
    end
end

local function OnSave(inst, data)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() or inst:HasTag("burnt") then
        data.burnt = true
    else
        data.power = inst._powertask ~= nil and math.ceil(GetTaskRemaining(inst._powertask) * 1000) or nil
    end
end

local function OnLoad(inst, data)
    if data ~= nil and data.burnt then
        inst.components.burnable.onburnt(inst)
    else
        OnHealthDelta(inst)
    end
end

local function OnLoadPostPass(inst, newents, data)
    if inst.components.savedrotation then
        local savedrotation = data ~= nil and data.savedrotation ~= nil and data.savedrotation.rotation or 0
        inst.components.savedrotation:ApplyPostPassRotation(savedrotation)
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

local function PowerOff(inst)
    inst:SetBrain(nil)
    inst.components.combat:SetTarget(nil)
    inst:PushEvent("togglepower", { ison = false })
end

local function OnGridPowerChanged(inst, power)
    if not inst.components.machine.ison then
        inst:DoTaskInTime(0, PowerOff)
        return
    end

    if power >= 0 then
        inst:SetBrain(brain)
        if not inst:IsAsleep() then
            inst:RestartBrain()
        end
        inst:PushEvent("togglepower", { ison = true })
    else
        inst:DoTaskInTime(0, PowerOff)
    end
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
    SpawnPrefab("winona_battery_sparks").entity:AddFollower():FollowSymbol(inst.GUID, "wire", 0, 0, 0)
    if inst.components.updatelooper ~= nil then
        if inst._flash == nil then
            inst.components.updatelooper:AddOnUpdateFn(OnUpdateSparks)
        end
        inst._flash = 1
        OnUpdateSparks(inst)
    end
end

local function OnConnectCircuit(inst) --, node)
    if not inst._wired then
        inst._wired = true
        inst.AnimState:ClearOverrideSymbol("wire")
        if not POPULATING then
            DoWireSparks(inst)
        end
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

    MakeObstaclePhysics(inst, .5)

    inst.Transform:SetSixFaced()

    inst:AddTag("companion")
    inst:AddTag("noauradamage")
    inst:AddTag("engineering")
    inst:AddTag("catapult")
    inst:AddTag("structure")
    inst:AddTag("ir_power") --added to pristine state for optimization

    carratrace_common.AddDeployHelper(inst, { "ir_powerline", "ir_generator_burnable", "ir_power" })

    inst.AnimState:SetBank("winona_catapult")
    inst.AnimState:SetBuild("winona_catapult")
    inst.AnimState:PlayAnimation("idle_off")
    --This will remove mouseover as well (rather than just :Hide("wire"))
    inst.AnimState:OverrideSymbol("wire", "winona_catapult", "dummy")

    inst.MiniMapEntity:SetIcon("winona_catapult.png")

    carratrace_common.AddDeployHelper(inst, { "ir_powerline", "ir_generator_burnable", "ir_power" })

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst._state = 1

    MakeDefaultIRStructure(inst, { power = -12.5, toggleable = true })

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("updatelooper")
    inst:AddComponent("colouradder")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.WINONA_CATAPULT_HEALTH)

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.WINONA_CATAPULT_DAMAGE)
    inst.components.combat:SetRange(TUNING.WINONA_CATAPULT_MAX_RANGE)
    inst.components.combat:SetAttackPeriod(TUNING.WINONA_CATAPULT_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(1, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(ShouldKeepTarget)

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnWorkCallback(OnWorked)

    inst:AddComponent("savedrotation")

    inst:ListenForEvent("onbuilt", OnBuilt)
    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("healthdelta", OnHealthDelta)
    inst:ListenForEvent("ir_addedtogrid", OnConnectCircuit)
    inst:ListenForEvent("ir_ongridpowerchanged", OnGridPowerChanged)

    MakeHauntableWork(inst)
    MakeMediumBurnable(inst, nil, nil, true)
    MakeMediumPropagator(inst)
    inst.components.burnable:SetOnBurntFn(OnBurnt)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnLoadPostPass = OnLoadPostPass
    inst.IsPowered = IsPowered

    inst:SetStateGraph("SGwinona_catapult")
    --inst:SetBrain(brain)

    inst._wired = nil
    inst._flash = nil

    return inst
end

--------------------------------------------------------------------------

return Prefab("ir_catapult", fn, assets, prefabs),
    MakePlacer("ir_catapult_placer", "winona_catapult_placement", "winona_catapult_placement", "idle", false, nil, nil,
        nil, nil, nil, function(inst)
        return carratrace_common.PlacerPostInit_AddPlacerRing(inst, "ir_power")
    end)
