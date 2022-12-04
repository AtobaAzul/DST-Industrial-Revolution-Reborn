require("prefabutil")

local assets =
{
    Asset("ANIM", "anim/magician_chest.zip"),
}

local prefabs =
{
    "collapse_small",
}

local function OnOpen(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("open")

        if inst.skin_open_sound then
            inst.SoundEmitter:PlaySound(inst.skin_open_sound)
        else
            inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_open")
        end
    end
end

local function OnClose(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("close")
        inst.AnimState:PushAnimation("closed", false)


        inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_close")
    end
end

local function OnHammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()
    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
    end
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function OnHit(inst, worker)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("closed", false)
        if inst.components.container ~= nil then
            inst.components.container:DropEverything()
            inst.components.container:Close()
        end
    end
end

local function OnBuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("closed", false)
    inst.SoundEmitter:PlaySound("dontstarve/common/chest_craft")
end

local function OnSave(inst, data)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() or inst:HasTag("burnt") then
        data.burnt = true
    end
end

local function OnLoad(inst, data)
    if data ~= nil and data.burnt and inst.components.burnable ~= nil then
        inst.components.burnable.onburnt(inst)
    end
end

local function Refine(item, count, product, container)
    local product_item = SpawnPrefab(product)
    local item = container.components.container:FindItem(function(_item) return _item.prefab == item end)
    if item ~= nil and item.components.stackable ~= nil then
        for i = 1, count do
            container.components.container:RemoveItem(item, false):Remove()
        end
        container.components.container:GiveItem(product_item)
    end
end

local function DoRefine(inst)
    if inst.components.container:Has("goldnugget", 2) and inst.components.container:Has("cutstone", 1) then
        local gold = inst.components.container:FindItem(function(item) return item.prefab == "goldnugget" end)
        local cutstone = inst.components.container:FindItem(function(item) return item.prefab == "cutstone" end)

        if gold ~= nil and gold.components ~= nil and gold.components.stackable ~= nil then
            for i = 1, 2 do
                inst.components.container:RemoveItem(gold, false):Remove()
            end
        end

        if cutstone ~= nil and cutstone.components.stackable ~= nil then
            inst.components.container:RemoveItem(cutstone, false):Remove()
        end
        local product = SpawnPrefab("transistor")
        inst.components.container:GiveItem(product)
    end
    if inst.components.container:Has("cutgrass", 3) then
        inst.Refine("cutgrass", 3, "rope", inst)
    end
    if inst.components.container:Has("rocks", 3) then
        inst.Refine("rocks", 3, "cutstone", inst)
    end
    if inst.components.container:Has("log", 4) then
        inst.Refine("log", 4, "boards", inst)
    end
    if inst.components.container:Has("cutreeds", 4) then
        inst.Refine("cutreeds", 4, "papyrus", inst)
    end
    if inst.components.container:Has("honeycomb", 1) then
        inst.Refine("honeycomb", 1, "beeswax", inst)
    end
    if inst.components.container:Has("moonrocknugget", 1) then
        inst.Refine("moonrocknugget", 1, "moonrockcrater", inst)
    end
    if inst.components.container:Has("marble", 1) then
        inst.Refine("marble", 1, "marblebean", inst)
    end
end

local function OnGridPowerChanged(inst, power)
    if power >= 0 and inst.components.machine.ison then
        if inst._refinetask ~= nil then
            inst._refinetask:Cancel()
            inst._refinetask = nil
        end
        inst._refinetask = inst:DoPeriodicTask(1, inst.DoRefine)
    else
        if inst._refinetask ~= nil then
            inst._refinetask:Cancel()
            inst._refinetask = nil
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst:AddTag("structure")

    inst.AnimState:SetBank("chest")
    inst.AnimState:SetBuild("treasure_chest")
    inst.AnimState:PlayAnimation("closed")

    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    MakeDefaultIRStructure(inst, { power = -7.5, toggleable = true })

    if not TheWorld.ismastersim then
        return inst
    end

    inst.DoRefine = DoRefine--just so other mods may be able to alter.
    inst.Refine = Refine

    inst:AddComponent("inspectable")

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("ir_refinery")
    inst.components.container.onopenfn = OnOpen
    inst.components.container.onclosefn = OnClose
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(2)
    inst.components.workable:SetOnFinishCallback(OnHammered)
    inst.components.workable:SetOnWorkCallback(OnHit)

    MakeSmallBurnable(inst, nil, nil, true)
    MakeMediumPropagator(inst)
    --inst.components.burnable:SetOnBurntFn(OnBurnt)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:ListenForEvent("onbuilt", OnBuilt)
    MakeSnowCovered(inst)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:ListenForEvent("ir_ongridpowerchanged", OnGridPowerChanged)

    return inst
end

return Prefab("ir_refinery", fn, assets, prefabs),
    MakePlacer("ir_refinery_placer", "treasurechest", "skull_chest", "closed", false, nil, nil
        , nil, nil, nil, function(inst)
        return carratrace_common.PlacerPostInit_AddPlacerRing(inst, "ir_power")
    end)
