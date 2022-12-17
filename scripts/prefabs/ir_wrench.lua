local assets =
{
    Asset("ANIM", "anim/spear.zip"),
    Asset("ANIM", "anim/swap_spear.zip"),
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_spear", "swap_spear")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    SendModRPCToClient(GetClientModRPC("IndustrialRevolution", "ToggleIRVision"), true)
    owner:AddTag("wrench_user")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    SendModRPCToClient(GetClientModRPC("IndustrialRevolution", "ToggleIRVision"), false)
    owner:RemoveTag("wrench_user")
end

local function CanCast(doer, target, pos)
    if target:HasTag("wrench_configurable") then
        return true
    end
    return false
end

local ICON_SCALE = .6
local ICON_RADIUS = 50
local SPELLBOOK_RADIUS = 100
local SPELLBOOK_FOCUS_RADIUS = SPELLBOOK_RADIUS + 2

local SPELLS =
{
    {
        onselect = function(inst)
            inst.mode = "Connect"
        end,
        label = "Mode: Connect",
        atlas = "images/spell_icons.xml",
        normal = "shadow_worker.tex",
        widget_scale = ICON_SCALE,
        hit_radius = ICON_RADIUS,
    },
    {
        onselect = function(inst)
            inst.mode = "Configure"
        end,
        label = "Mode: Configure",
        atlas = "images/spell_icons.xml",
        normal = "shadow_worker.tex",
        widget_scale = ICON_SCALE,
        hit_radius = ICON_RADIUS,
    }
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("spear")
    inst.AnimState:SetBuild("swap_spear")
    inst.AnimState:PlayAnimation("idle")

    --weapon (from weapon component) added to pristine state for optimization

    MakeInventoryFloatable(inst, "med", 0.05, { 1.1, 0.5, 1.1 }, true, -9)

    inst.entity:SetPristine()

    inst:AddComponent("spellbook")

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(17)

    -------

    inst:AddComponent("spellcaster")
    inst.components.spellcaster.canuseontargets = true
    inst.components.spellcaster.veryquickcast   = true
    inst.components.spellcaster:SetCanCastFn(CanCast)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("ir_wrench", fn, assets)
