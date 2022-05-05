local assets =
{
    Asset("ANIM", "anim/pitchfork.zip"),
    --Asset("ANIM", "anim/goldenpitchfork.zip"),
    Asset("ANIM", "anim/swap_pitchfork.zip"),
    --Asset("ANIM", "anim/swap_goldenpitchfork.zip"),
}

local prefabs =
{
    "sinkhole_spawn_fx_1",
    "sinkhole_spawn_fx_2",
    "sinkhole_spawn_fx_3",
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
    owner.AnimState:OverrideSymbol("swap_object", "swap_pitchfork", "swap_pitchfork")
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

--local function common_fn(bank, build)
local function electrical()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    --inst.AnimState:SetBank(bank)
    --inst.AnimState:SetBuild(build)
    inst.AnimState:SetBank("pitchfork")
    inst.AnimState:SetBuild("pitchfork")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("sharp")

    --weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")

    MakeInventoryFloatable(inst, "med", 0.05, {0.78, 0.4, 0.78}, true, 7, {sym_build = "swap_pitchfork"})

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -------
    inst:AddComponent("fueled")
    inst.components.fueled:SetSectionCallback(onfuelchange)
    inst.components.fueled:InitializeFuelLevel(TUNING.NIGHTSTICK_FUEL)
    inst.components.fueled:SetDepletedFn(nofuel)
    inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)


    -------
    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.PICK_DAMAGE)
    inst.components.weapon:SetOnAttack(onattack)

    inst:AddInherentAction(ACTIONS.TERRAFORM)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("terraformer")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    return inst
end

--local function onequipgold(inst, owner)
    --owner.AnimState:OverrideSymbol("swap_object", "swap_goldenpitchfork", "swap_goldenpitchfork")
    --owner.SoundEmitter:PlaySound("dontstarve/wilson/equip_item_gold")
    --owner.AnimState:Show("ARM_carry")
    --owner.AnimState:Hide("ARM_normal")
--end

--local function normal()
    --return common_fn("pitchfork", "pitchfork")
--end

--local function golden()
    --local inst = common_fn("pitchfork", "goldenpitchfork")

    --if not TheWorld.ismastersim then
        --return inst
    --end

    --inst.components.finiteuses:SetConsumption(ACTIONS.TERRAFORM, .125 / TUNING.GOLDENTOOLFACTOR)
    --inst.components.weapon.attackwear = 1 / TUNING.GOLDENTOOLFACTOR
    --inst.components.researchvalue.basevalue = TUNING.RESEARCH_VALUE_GOLD_TOOL

    --inst.components.equippable:SetOnEquip(onequipgold)

    --return inst
--end

return Prefab("pitchfork_electrical", electrical, assets, prefabs)--,
    --Prefab("goldenpitchfork", golden, assets, prefabs)
