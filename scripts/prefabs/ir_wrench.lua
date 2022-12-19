local assets =
{
    Asset("ANIM", "anim/spear.zip"),
    Asset("ANIM", "anim/swap_spear.zip"),
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_spear", "swap_spear")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    owner:AddTag("ir_wrenchuser")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    owner:RemoveTag("ir_wrenchuser")
end

local ICON_SCALE = .6
local ICON_RADIUS = 50
local SPELLBOOK_RADIUS = 100
local SPELLBOOK_FOCUS_RADIUS = SPELLBOOK_RADIUS + 2

local SPELLS =
{
    {
        onselect = function(inst)
            inst.mode = "O"
            SendModRPCToServer(GetModRPC("IndustrialRevolution", "SetWrenchMode"), inst, "O")
        end,
        execute = function(inst)
            inst.mode = "O"
            SendModRPCToServer(GetModRPC("IndustrialRevolution", "SetWrenchMode"), inst, "O")
        end,
        label = "Mode: Output",
        atlas = "images/spell_icons.xml",
        normal = "shadow_worker.tex",
        widget_scale = ICON_SCALE,
        hit_radius = ICON_RADIUS,
    },
    {
        onselect = function(inst)
            inst.mode = "I"
            SendModRPCToServer(GetModRPC("IndustrialRevolution", "SetWrenchMode"), inst, "I")
        end,
        execute = function(inst)
            inst.mode = "I"
            SendModRPCToServer(GetModRPC("IndustrialRevolution", "SetWrenchMode"), inst, "I")
        end,
        label = "Mode: Input",
        atlas = "images/spell_icons.xml",
        normal = "shadow_worker.tex",
        widget_scale = ICON_SCALE,
        hit_radius = ICON_RADIUS,
    },
    {
        onselect = function(inst)
            inst.mode = "IO"
            SendModRPCToServer(GetModRPC("IndustrialRevolution", "SetWrenchMode"), inst, "IO")
        end,
        execute = function(inst)
            inst.mode = "IO"
            SendModRPCToServer(GetModRPC("IndustrialRevolution", "SetWrenchMode"), inst, "IO")
        end,
        label = "Mode: Input/Output",
        atlas = "images/spell_icons.xml",
        normal = "shadow_worker.tex",
        widget_scale = ICON_SCALE,
        hit_radius = ICON_RADIUS,
    },
    {
        onselect = function(inst)
            inst.mode = "None"
            SendModRPCToServer(GetModRPC("IndustrialRevolution", "SetWrenchMode"), inst, "None")
        end,
        execute = function(inst)
            inst.mode = "None"
            SendModRPCToServer(GetModRPC("IndustrialRevolution", "SetWrenchMode"), inst, "None")
        end,
        label = "Mode: None",
        atlas = "images/spell_icons.xml",
        normal = "shadow_worker.tex",
        widget_scale = ICON_SCALE,
        hit_radius = ICON_RADIUS,
    },
}

local function OnSpellCast(inst, target, pos, doer)
    if target:HasTag("ir_itemnetworkable") and not target:HasTag("burnt") then
        target.components.ir_itemnetworkable:SetMode(inst.mode)
    end
end

local function CanCast(doer, target, pos)
    if target:HasTag("ir_itemnetworkable") and not target:HasTag("burnt") then
        return true
    end
    return false
end

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
    inst:AddTag("weapon")
    
    MakeInventoryFloatable(inst, "med", 0.05, { 1.1, 0.5, 1.1 }, true, -9)

    inst.entity:SetPristine()

    inst:AddComponent("spellbook")
    inst.components.spellbook:SetItems(SPELLS)
    inst.components.spellbook:SetRequiredTag("ir_wrenchuser")
	inst.components.spellbook:SetRadius(SPELLBOOK_RADIUS)
	inst.components.spellbook:SetFocusRadius(SPELLBOOK_FOCUS_RADIUS)

    inst.mode = "None"

    inst:AddTag("castontargets")
    inst:AddTag("castonworkable")

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(17)

    -------

    inst:AddComponent("spellcaster")
    inst.components.spellcaster.canuseontargets = true
    inst.components.spellcaster.veryquickcast   = true
    inst.components.spellcaster.canonlyuseonworkable = true
    inst.components.spellcaster:SetCanCastFn(CanCast)
    inst.components.spellcaster:SetSpellFn(OnSpellCast)
     
    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("ir_wrench", fn, assets)
