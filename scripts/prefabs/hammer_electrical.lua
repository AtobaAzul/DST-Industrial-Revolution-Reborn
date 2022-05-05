local assets =
{
    Asset("ANIM", "anim/hammer.zip"),
    Asset("ANIM", "anim/swap_hammer.zip"),
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
    inst:AddComponent("tool")
    if TheWorld.state.iswet then
        inst.components.tool:SetAction(ACTIONS.HAMMER, 1.5)
    else
        inst.components.tool:SetAction(ACTIONS.HAMMER, 0.75)
    end
end

local function turnoff(inst)

    inst.components.weapon.stimuli = nil
		
	inst.SoundEmitter:PlaySound("dontstarve/wilson/lantern_on")
    if inst.components.fueled ~= nil then
        inst.components.fueled:StopConsuming()
    end
    inst:RemoveComponent("tool")
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
    owner.AnimState:OverrideSymbol("swap_object", "swap_hammer", "swap_hammer")
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

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("hammer")
    inst.AnimState:SetBuild("swap_hammer")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("hammer")

    MakeInventoryFloatable(inst, "med", 0.05, {0.7, 0.4, 0.7}, true, -13, {sym_build = "swap_hammer"})

    --tool (from tool component) added to pristine state for optimization
    inst:AddTag("tool")

    --weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")
    inst:AddTag("electricaltool")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.HAMMER_DAMAGE)
    inst.components.weapon:SetOnAttack(onattack)

    inst:AddComponent("inventoryitem")
    -----
    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.HAMMER, 0.75)
    -------
    inst:AddComponent("fueled")
    inst.components.fueled:SetSectionCallback(onfuelchange)
    inst.components.fueled:InitializeFuelLevel(TUNING.NIGHTSTICK_FUEL)
    inst.components.fueled:SetDepletedFn(nofuel)
    inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)

    -------

    MakeHauntableLaunch(inst)

    inst:AddComponent("inspectable")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    return inst
end

return Prefab("hammer_electrical", fn, assets)
