local assets =
{
    Asset("ANIM", "anim/shovel.zip"),
    Asset("ANIM", "anim/goldenshovel.zip"),
    Asset("ANIM", "anim/swap_shovel.zip"),
    Asset("ANIM", "anim/swap_goldenshovel.zip"),
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
    owner:AddTag("batteryuser")
    if not inst.components.fueled:IsEmpty() then
        turnon(inst)
    end
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    if owner.components.upgrademoduleowner == nil then
        owner:RemoveTag("batteryuser")
    end
    turnoff(inst)
end

local function common_fn(bank, build)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation("idle")

    --tool (from tool component) added to pristine state for optimization
    inst:AddTag("tool")
    inst:AddTag("electricaltool")

    inst:AddTag("weapon")
    inst.components.weapon:SetOnAttack(onattack)
    inst.components.weapon:SetElectric()

    MakeInventoryFloatable(inst, "med", 0.05, {0.8, 0.4, 0.8})

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -----
    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.DIG)

    inst:AddComponent("fueled")
    inst.components.fueled:SetSectionCallback(onfuelchange)
    inst.components.fueled:InitializeFuelLevel(TUNING.NIGHTSTICK_FUEL)
    inst.components.fueled:SetDepletedFn(nofuel)
    inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)

    inst:AddInherentAction(ACTIONS.DIG)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    return inst
end

local function normal()
    local inst = common_fn("shovel", "shovel")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.floater:SetBankSwapOnFloat(true, 7, {sym_build = "swap_shovel"})

    return inst
end

return Prefab("shovel_electrical", normal, assets)
