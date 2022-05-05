local assets =
{
    Asset("ANIM", "anim/staffs.zip"),
    Asset("ANIM", "anim/swap_staffs.zip"),
}

local prefabs =
{
    blue =
    {
        "bishop_charge",
    },
}
---------BLUE STAFF---------
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

local function onattack_blue(inst, attacker, target, skipsanity)
    if not target:IsValid() then
        --target killed or removed in combat damage phase
        return
    end

    if target.components.sleeper ~= nil and target.components.sleeper:IsAsleep() then
        target.components.sleeper:WakeUp()
    end

    if target.components.combat ~= nil then
        target.components.combat:SuggestTarget(attacker)
    end

    if target ~= nil and target:IsValid() and attacker ~= nil and attacker:IsValid() and inst.components.weapon.stimuli == "electric" then
        SpawnPrefab("electrichitsparks"):AlignToTarget(target, attacker, true)
    end
    
    inst.SoundEmitter:PlaySound("dontstarve/creatures/bishop/shotexplo")

    target:PushEvent("attacked", { attacker = attacker, damage = 34.5, weapon = inst })

end


---------COMMON FUNCTIONS---------

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    if owner.components.upgrademoduleowner == nil then
        owner:RemoveTag("batteryuser")
    end
    turnoff(inst)
end

local function commonfn(colour, tags, hasskin)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("staffs")
    inst.AnimState:SetBuild("staffs")
    inst.AnimState:PlayAnimation("yellowstaff")

    if tags ~= nil then
        for i, v in ipairs(tags) do
            inst:AddTag(v)
        end
    end

    local floater_swap_data =
    {
        sym_build = "swap_staffs",
        sym_name = "swap_yellowstaff",
        bank = "staffs",
        anim = "yellowstaff"
    }
    MakeInventoryFloatable(inst, "med", 0.1, {0.9, 0.4, 0.9}, true, -13, floater_swap_data)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -------
    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("tradable")

    inst:AddComponent("equippable")

        inst.components.equippable:SetOnEquip(function(inst, owner)
            owner.AnimState:OverrideSymbol("swap_object", "swap_staffs", "swap_yellowstaff")
            owner.AnimState:Show("ARM_carry")
            owner.AnimState:Hide("ARM_normal")
            owner:AddTag("batteryuser")
            if not inst.components.fueled:IsEmpty() then
                turnon(inst)
            end
        end)
        inst.components.equippable:SetOnUnequip(onunequip)

    return inst
end

local function blue()
    --weapon (from weapon component) added to pristine state for optimization
    local inst = commonfn("blue", { "electricalstaff", "weapon", "rangedweapon", "extinguisher" }, true)

    inst.projectiledelay = FRAMES

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddTag("electricaltool")
    
    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.SPEAR_DAMAGE)
    inst.components.weapon:SetRange(8, 10)
    inst.components.weapon:SetOnAttack(onattack_blue)
    inst.components.weapon:SetProjectile("bishop_charge")
    inst.components.weapon:SetElectric()

    inst:AddComponent("fueled")
    inst.components.fueled:SetSectionCallback(onfuelchange)
    inst.components.fueled:InitializeFuelLevel(TUNING.NIGHTSTICK_FUEL)
    inst.components.fueled:SetDepletedFn(nofuel)
    inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)

    inst.components.floater:SetScale({0.8, 0.4, 0.8})

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("electricalstaff", blue, assets, prefabs.blue)

