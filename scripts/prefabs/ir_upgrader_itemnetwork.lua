require "prefabutil"

local assets =
{
}

local prefabs =
{
    "mastupgrade_lightningrod_top",
    "mastupgrade_lightningrod_fx",
    "collapse_small",
}

local function itemfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    MakeInventoryFloatable(inst, "med", nil, 0.68)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetSinks(false)

    inst:AddComponent("upgrader")
    inst.components.upgrader.upgradetype = UPGRADETYPES.ITEM_NETWORKABLE
    inst.components.upgrader.upgradevalue = 2--hm

    MakeHauntableLaunchAndSmash(inst)

    return inst
end

return Prefab("ir_upgrader_itemnetwork", itemfn, assets, prefabs)
