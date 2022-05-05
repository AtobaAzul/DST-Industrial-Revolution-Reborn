local assets =
{
    Asset("ANIM", "anim/quagmire_hoe.zip"),
    Asset("ANIM", "anim/goldenhoe.zip"),
    Asset("ANIM", "anim/swap_goldenhoe.zip"),
}

local prefabs =
{
    "farm_soil",
}

local function onattack(inst, attacker, target)
    if target ~= nil and target:IsValid() and attacker ~= nil and attacker:IsValid() and inst.components.weapon.stimuli == "electric" then
        SpawnPrefab("electrichitsparks"):AlignToTarget(target, attacker, true)
    end
end

local function turnon(inst)
    if not inst.components.fueled:IsEmpty() then
		inst.components.weapon:SetElectric()
		inst.SoundEmitter:PlaySound("dontstarve/wilson/lantern_on")
        inst.components.fueled:StartConsuming()
    end
end

local function turnoff(inst)

    inst.components.weapon.stimuli = nil
		
	inst.SoundEmitter:PlaySound("dontstarve/wilson/lantern_on")
    if inst.components.fueled ~= nil then
        inst.components.fueled:StopConsuming()
    end
end

local function nofuel(inst)
    if inst.components.equippable:IsEquipped() and inst.components.inventoryitem.owner ~= nil then
       local data =
       {
           prefab = inst.prefab,
           equipslot = inst.components.equippable.equipslot,
       }
       turnoff(inst)
       inst.components.inventoryitem.owner:PushEvent("torchranout", data)
   else
       turnoff(inst)
   end
end 

local function onfuelchange(newsection, oldsection, inst)
    if newsection <= 0 then
        --when we burn out
        if inst.components.burnable ~= nil then
            inst.components.burnable:Extinguish()
        end
        local equippable = inst.components.equippable
        if equippable ~= nil and equippable:IsEquipped() then
            local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
            if owner ~= nil then
                local data =
                {
                    prefab = inst.prefab,
                    equipslot = equippable.equipslot,
                    announce = "ANNOUNCE_TORCH_OUT",
                }
                turnoff(inst)
                owner:PushEvent("itemranout", data)
                return
            end
        end
        turnoff(inst)
    end
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "quagmire_hoe", "swap_quagmire_hoe")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    owner:AddTag("batteryuser")
    if not inst.components.fueled:IsEmpty() then
        turnon(inst)
    end
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    if owner.components.upgrademoduleowner == nil then
        owner:RemoveTag("batteryuser")
    end
    turnoff(inst)
end

local function common_fn(build)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(build)
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("electricaltool")
    inst:AddTag("sharp")

    --weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")
    inst.components.weapon:SetOnAttack(onattack)
    inst.components.weapon:SetElectric()

    MakeInventoryFloatable(inst, "med", 0.05, {0.8, 0.4, 0.8})

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("fueled")
    inst.components.fueled:SetSectionCallback(onfuelchange)
    inst.components.fueled:InitializeFuelLevel(TUNING.NIGHTSTICK_FUEL)
    inst.components.fueled:SetDepletedFn(nofuel)
    inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)


    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.FARM_HOE_DAMAGE)

    inst:AddInherentAction(ACTIONS.TILL)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("farmtiller")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    return inst
end

local function fn()
    local inst = common_fn("quagmire_hoe")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.floater:SetBankSwapOnFloat(true, -7, {bank  = "quagmire_hoe", sym_build = "quagmire_hoe", sym_name = "swap_quagmire_hoe"})

	return inst
end

return Prefab("farm_hoe_electrical", fn, assets, prefabs)
