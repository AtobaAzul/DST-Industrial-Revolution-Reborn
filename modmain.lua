Assets = {
    Asset("ANIM", "anim/swap_nightstick_off.zip"), --borrowed from UM.
    Asset("ANIM", "anim/wx78module_discharge.zip")
}
PrefabFiles = {
    "axe_electrical",
    "hammer_electrical",
    "pickaxe_electrical",
    "pitchfork_electrical",
    "shovel_electrical",
    "electricalstaff",
    "lantern_electrical"
}

local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
--TODO:
--Fabricator
--Refinery
--Recipes
--Quotes & Strings
--Art



STRINGS.CHARACTERS.GENERIC.DESCRIBE.AXE_ELECTRICAL = "Let's get to it, chop chop!"
STRINGS.CHARACTERS.WILLOW.DESCRIBE.AXE_ELECTRICAL = "So, hm, does it burn the trees?"
STRINGS.CHARACTERS.WICKERBOTTOM.DESCRIBE.AXE_ELECTRICAL = "A rather ingenious invention\nI wonder how she made the circuitry resist the forces applied against it."
STRINGS.CHARACTERS.WAXWELL.DESCRIBE.AXE_ELECTRICAL = "Hmph, rather unnecessary."
STRINGS.CHARACTERS.WOODIE.DESCRIBE.AXE_ELECTRICAL = "Trying to copy Lucy, eh?"
STRINGS.CHARACTERS.WOLFGANG.DESCRIBE.AXE_ELECTRICAL = "Axe full of power just like Wolfgang!"
STRINGS.CHARACTERS.WENDY.DESCRIBE.AXE_ELECTRICAL = "I'll cut myself an electric chair."
STRINGS.CHARACTERS.WX78.DESCRIBE.AXE_ELECTRICAL = "OVERALLS REMAINS MY FAVORITE FLESHLING"
STRINGS.CHARACTERS.WINONA.DESCRIBE.AXE_ELECTRICAL = "It ain't the good old chainsaw but it'll do."
STRINGS.CHARACTERS.WANDA.DESCRIBE.AXE_ELECTRICAL = "How do people use this stuff over clockwork?"
STRINGS.CHARACTERS.WURT.DESCRIBE.AXE_ELECTRICAL = "Makes scales feel tingly..."
STRINGS.CHARACTERS.WORTOX.DESCRIBE.AXE_ELECTRICAL = "An axe of mine, ready to power. Charge it up and get ready to devour!"
STRINGS.CHARACTERS.WORMWOOD.DESCRIBE.AXE_ELECTRICAL = "Zzzt friend hurter (sob)"

STRINGS.CHARACTERS.GENERIC.DESCRIBE.HAMMER_ELECTRICAL = "It's sdafaega!"
STRINGS.CHARACTERS.WILLOW.DESCRIBE.HAMMER_ELECTRICAL = "Another non-firey tool. Shocking."
STRINGS.CHARACTERS.WICKERBOTTOM.DESCRIBE.HAMMER_ELECTRICAL = "Her knowledge of plantlife rivals even mine..."
STRINGS.CHARACTERS.WAXWELL.DESCRIBE.HAMMER_ELECTRICAL = "I think she's angry at me."
STRINGS.CHARACTERS.WOODIE.DESCRIBE.HAMMER_ELECTRICAL = "Trying to copy Lucy, eh?"
STRINGS.CHARACTERS.WOLFGANG.DESCRIBE.HAMMER_ELECTRICAL = "She good for healing, not fighting."
STRINGS.CHARACTERS.WENDY.DESCRIBE.HAMMER_ELECTRICAL = "You can't heal a broken heart."
STRINGS.CHARACTERS.WX78.DESCRIBE.HAMMER_ELECTRICAL = "OVERALLS REMAINS MY FAVORITE FLESHLING"
STRINGS.CHARACTERS.WINONA.DESCRIBE.HAMMER_ELECTRICAL = "It ain't the good old chainsaw but it'll do."
STRINGS.CHARACTERS.WANDA.DESCRIBE.HAMMER_ELECTRICAL = "How do people use this stuff over clockwork?"
STRINGS.CHARACTERS.WURT.DESCRIBE.HAMMER_ELECTRICAL = "Makes scales feel tingly..."
STRINGS.CHARACTERS.WORTOX.DESCRIBE.HAMMER_ELECTRICAL = "It ain't the good old chainsaw but it'll do."
STRINGS.CHARACTERS.WORMWOOD.DESCRIBE.HAMMER_ELECTRICAL = "Zzzt friend hurter (sob)"

local um = KnownModIndex:IsModEnabled("workshop-2039181790")
if not um then --I've addedthis already for UM, prevents overlap.
    env.AddPlayerPostInit(function(inst) --the main charge code
        local function ChargeItem(item)
            if item ~= nil then
                if item.components.fueled ~= nil then
                    local percent = item.components.fueled:GetPercent()
                    local refuelnumber = 0
    
                    if percent + 0.33 > 1 then
                        refuelnumber = 1
                    else
                        refuelnumber = percent + 0.33
                    end
    
                    item.components.fueled:SetPercent(refuelnumber)
                elseif item.components.finiteuses ~= nil then
                    local percent = item.components.finiteuses:GetPercent()
                    local refuelnumber = 0
    
                    if percent + 0.33 > 1 then
                        refuelnumber = 1
                    else
                        refuelnumber = percent + 0.33
                    end
    
                    item.components.finiteuses:SetPercent(refuelnumber)
                end
            end
        end
    
        local function OnChargeFromBattery(inst, battery)
            local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    
            if item == nil then
                item =  inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
            end
            if item == nil then
                item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
            end
            if item == nil and (inst.components.upgrademoduleowner ~= nil and inst.components.upgrademoduleowner:ChargeIsMaxed()) then
                return false, "CHARGE_FULL"
            end
    
            if inst.components.upgrademoduleowner == nil then
                if (item ~= nil and item.components.finiteuses ~= nil and item.components.finiteuses:GetPercent() == 1) or (item ~= nil and item.components.fueld ~= nil and item.components.fueled:GetPercent() >= 0.995) then
                    return false, "CHARGE_FULL"
                else
                    if item ~= nil and item:HasTag("electricaltool") then
                        ChargeItem(item)
                        if not inst.components.inventory:IsInsulated() then
                            inst.sg:GoToState("electrocute")
                            inst.components.health:DoDelta(-TUNING.HEALING_SMALL, false, "lightning")
                            inst.components.sanity:DoDelta(-TUNING.SANITY_SMALL)
                            if inst.components.talker ~= nil then
                                inst:DoTaskInTime(FRAMES * 30, inst.components.talker:Say(GetString(inst, "ANNOUNCE_CHARGE_SUCCESS_ELECTROCUTED")))
                            end
                        else
                            if inst.components.talker ~= nil then
                                inst:DoTaskInTime(FRAMES * 30, inst.components.talker:Say(GetString(inst, "ANNOUNCE_CHARGE_SUCCESS_INSULATED")))
                            end
                        end
                        return true
                    end
                end
            else
                if ((item ~= nil and item.components.finiteuses ~= nil and item.components.finiteuses:GetPercent() == 1) or (item ~= nil and item.components.fueld ~= nil and item.components.fueled:GetPercent() >= 0.995)) and inst.components.upgrademoduleowner:ChargeIsMaxed() or not item:HasTag("electricaltool") then
                    return false, "CHARGE_FULL"
                else
                    if item ~= nil and item:HasTag("electricaltool") then
                        ChargeItem(item)
                        if not inst.components.upgrademoduleowner:ChargeIsMaxed() then
                            inst.components.upgrademoduleowner:AddCharge(1)
                        end
                        if not inst.components.inventory:IsInsulated() then
                            inst.sg:GoToState("electrocute")
                            inst.components.health:DoDelta(-TUNING.HEALING_SMALL, false, "lightning")
                            inst.components.sanity:DoDelta(-TUNING.SANITY_SMALL)
                            if inst.components.talker ~= nil then
                                inst:DoTaskInTime(FRAMES * 30, inst.components.talker:Say(GetString(inst, "ANNOUNCE_CHARGE_SUCCESS_ELECTROCUTED")))
                            end
                        else
                            if inst.components.talker ~= nil then
                                inst:DoTaskInTime(FRAMES * 30, inst.components.talker:Say(GetString(inst, "ANNOUNCE_CHARGE_SUCCESS_INSULATED")))
                            end
                        end
                        return true
                    end
                end
            end
         end
    
         inst:AddComponent("batteryuser") --just the component by itself doesn't do anything
         inst.components.batteryuser.onbatteryused = OnChargeFromBattery
    end)

    local function onlightningground(inst)
        local percent = inst.components.fueled:GetPercent()
        local refuelnumber = 0
        if percent + 0.33 > 1 then
            refuelnumber = 1
        else
            refuelnumber = percent + 0.33
        end
        inst.components.fueled:SetPercent(refuelnumber)
    end

    local function Strike(owner)
        local fx = SpawnPrefab("electrichitsparks")
        --onlightningground(inst)
        if owner ~= nil then
            fx.entity:SetParent(owner.entity)
            fx.entity:AddFollower()
            fx.Follower:FollowSymbol(owner.GUID, "swap_object", 0, -145, 0)
        --fx.Transform:SetScale(.66, .66, .66)
        end
    end

    local function onremovefire(fire)
        fire.nightstick._fire = nil
    end

    local function turnon(inst)
        if not inst.components.fueled:IsEmpty() then
            inst.components.weapon:SetElectric()
            inst.SoundEmitter:PlaySound("dontstarve/wilson/lantern_on")
            inst.components.fueled:StartConsuming()

            local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil

            if owner ~= nil then
                if inst.components.equippable:IsEquipped() and inst.components.inventoryitem.owner ~= nil then
                    owner.AnimState:OverrideSymbol("swap_object", "swap_nightstick", "swap_nightstick")
                end
            end

            inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/morningstar", "torch")

            if inst._fire == nil and not inst.components.fueled:IsEmpty() then
                inst._fire = SpawnPrefab("nightstickfire")
                inst._fire.nightstick = inst
                inst:ListenForEvent("onremove", onremovefire, inst._fire)
            end
            inst._fire.entity:SetParent(owner.entity)
        end
    end

    local function turnoff(inst)
        inst.components.weapon.stimuli = nil

        local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
        if owner ~= nil then
            if inst.components.equippable:IsEquipped() and inst.components.inventoryitem.owner ~= nil then
                owner.AnimState:OverrideSymbol("swap_object", "swap_nightstick_off", "swap_nightstick_off")
            end
        end

        inst.SoundEmitter:KillSound("torch")
        inst.SoundEmitter:PlaySound("dontstarve/wilson/lantern_on")
        if inst.components.fueled ~= nil then
            inst.components.fueled:StopConsuming()
        end

        if inst._fire ~= nil then
            if inst._fire:IsValid() then
                inst._fire:Remove()
            end
        end
    end

    local function ontakefuel(inst, owner)
        if inst.components.equippable:IsEquipped() then
            inst.SoundEmitter:PlaySound("dontstarve/common/lightningrod")
            turnon(inst)
        end
    end

    local function nofuel(inst)
        if inst.components.equippable:IsEquipped() and inst.components.inventoryitem.owner ~= nil then
            local data = {
                prefab = inst.prefab,
                equipslot = inst.components.equippable.equipslot
            }
            turnoff(inst)
            inst.components.inventoryitem.owner:PushEvent("torchranout", data)
        else
            turnoff(inst)
        end
    end

    local function onequip(inst, owner)
        inst.components.burnable:Ignite()
        owner.AnimState:OverrideSymbol("swap_object", "swap_nightstick", "swap_nightstick")
        owner.AnimState:Show("ARM_carry")
        owner.AnimState:Hide("ARM_normal")

        --inst.SoundEmitter:SetParameter("torch", "intensity", 1)

        if inst.components.fueled:IsEmpty() then
            owner.AnimState:OverrideSymbol("swap_object", "swap_nightstick_off", "swap_nightstick_off")
        else
            inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/morningstar", "torch")
            owner.AnimState:OverrideSymbol("swap_object", "swap_nightstick", "swap_nightstick")
            turnon(inst)
        end

        owner:AddTag("lightningrod")

        owner.lightningpriority = 0
        owner:ListenForEvent("lightningstrike", Strike, owner)
        owner:AddTag("batteryuser") -- from batteryuser component
    end

    local function onunequip(inst, owner)
        inst.components.burnable:Extinguish()
        owner.AnimState:Hide("ARM_carry")
        owner.AnimState:Show("ARM_normal")
        inst.SoundEmitter:KillSound("torch")

        turnoff(inst)

        owner:RemoveTag("lightningrod")
        owner.lightningpriority = nil
        owner:ListenForEvent("lightningstrike", nil)

        if owner.components.upgrademoduleowner == nil then
            owner:RemoveTag("batteryuser") -- from batteryuser component
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
                    local data = {
                        prefab = inst.prefab,
                        equipslot = equippable.equipslot,
                        announce = "ANNOUNCE_TORCH_OUT"
                    }
                    turnoff(inst)
                    owner:PushEvent("itemranout", data)
                    return
                end
            end
            turnoff(inst)
        elseif newsection > 0 then
            turnon(inst)
        end
    end

    local function onattack(inst, attacker, target)
        if
            target ~= nil and target:IsValid() and attacker ~= nil and attacker:IsValid() and
                inst.components.weapon.stimuli == "electric"
         then
            SpawnPrefab("electrichitsparks"):AlignToTarget(target, attacker, true)
        end
    end

    env.AddPrefabPostInit(
        "nightstick",
        function(inst)
            if not TheWorld.ismastersim then
                return
            end

            if inst.components.fueled ~= nil then
                inst.components.fueled:SetSectionCallback(onfuelchange)
                --inst.components.fueled.maxfuel = TUNING.NIGHTSTICK_FUEL / 2
                --inst.components.fueled:InitializeFuelLevel(TUNING.NIGHTSTICK_FUEL / 2)
                inst.components.fueled.rate = 2
                --inst.components.fueled:InitializeFuelLevel(TUNING.LANTERN_LIGHTTIME / 1.25)
                --inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION * 2, TUNING.TURNON_FULL_FUELED_CONSUMPTION * 2)

                inst.components.fueled:SetDepletedFn(nofuel)
                inst.components.fueled:SetTakeFuelFn(ontakefuel)
                inst.components.fueled.fueltype = FUELTYPE.BATTERYPOWER
                --inst.components.fueled.secondaryfueltype = FUELTYPE.CHEMICAL
                inst.components.fueled.accepting = true
                inst.components.fueled.rate = 1
                inst:AddTag("lightningrod")
                inst:ListenForEvent("lightningstrike", onlightningground)
            end

            if inst.components.equippable ~= nil then
                inst.components.equippable:SetOnEquip(onequip)
                inst.components.equippable:SetOnUnequip(onunequip)
            end

            if inst.components.weapon ~= nil then
                inst.components.weapon.stimuli = nil
                inst.components.weapon:SetOnAttack(onattack)
            end
            inst:AddTag("electricaltool")
        end
    )
end

env.AddPrefabPostInit(
    "winona_battery_low",
    function(inst)
        if inst.components.fueled ~= nil then
            inst.components.fueled.secondaryfueltype = FUELTYPE.BURNABLE
        end
    end
)

env.AddPrefabPostInit(
    "sewing_tape",
    function(inst)
        local function OnHealFn(inst, target)
            if target.SoundEmitter ~= nil then
                target.SoundEmitter:PlaySound("dontstarve/common/chesspile_repair")
            end

            -- We heal wx manually instead of through the healer component because only wx should be healed by it
            if target.components.upgrademoduleowner ~= nil then
                target.components.health:DoDelta(20, false, inst.prefab)
            end
        end

        inst:AddComponent("healer")
        inst.components.healer:SetHealthAmount(0)
        inst.components.healer.onhealfn = OnHealFn
    end
)

local ModuleDefs = require("wx78_moduledefs")


local function doDischarge(inst, wx)
    local hands = wx.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    local head = wx.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
    if hands ~= nil then
        print(hands)

        if hands.components.finiteuses ~= nil then
            if
                hands.components.finiteuses:GetPercent() < 0.5 and hands:HasTag("electricaltool") and
                    not wx.components.upgrademoduleowner:IsChargeEmpty()
             then
                hands.components.finiteuses:SetPercent(hands.components.finiteuses:GetPercent() + 0.5)
                wx.components.upgrademoduleowner:AddCharge(-2)
                wx.components.talker:Say("DISCHARGE SUCCESSFUL: TOOL RECHARGED")
            end
        end
        if hands.components.fueled ~= nil then
            if
                hands.components.fueled:GetPercent() < 0.5 and hands:HasTag("electricaltool") and
                    not wx.components.upgrademoduleowner:IsChargeEmpty()
             then
                hands.components.fueled:SetPercent(hands.components.fueled:GetPercent() + 0.5)
                wx.components.upgrademoduleowner:AddCharge(-2)
                wx.components.talker:Say("DISCHARGE SUCCESSFUL: TOOL RECHARGED")
            end
        end
    end
    if head ~= nil then
        print(head)
        if head.components.finiteuses ~= nil then
            if
                head.components.finiteuses:GetPercent() < 0.5 and head:HasTag("electricaltool") and
                    wx.components.upgrademoduleowner.charge_level < 2
             then
                head.components.finiteuses:SetPercent(head.components.finiteuses:GetPercent() + 0.5)
                wx.components.upgrademoduleowner:AddCharge(-2)
                wx.components.talker:Say("DISCHARGE SUCCESSFUL: TOOL RECHARGED")
            end
        end
        if head.components.fueled ~= nil then
            if
                head.components.fueled:GetPercent() < 0.5 and head:HasTag("electricaltool") and
                    wx.components.upgrademoduleowner.charge_level < 2
             then
                head.components.fueled:SetPercent(head.components.fueled:GetPercent() + 0.5)
                wx.components.upgrademoduleowner:AddCharge(-2)
                wx.components.talker:Say("DISCHARGE SUCCESSFUL: TOOL RECHARGED")
            end
        end
    end
end

local function module_activate(inst, wx)
    if inst._cdtask == nil then
        inst._cdtask = inst:DoPeriodicTask(10, doDischarge, 1, wx)
    end
    print("activated!")
end

local function module_deactivate(inst, wx)
    print("deactivated!")
    if inst._cdtask ~= nil then
        inst._cdtask:Cancel()
    end
    inst._cdtask = nil
end

local DISCHARGE_MODULE_DATA = {
    name = "discharge",
    slots = 1,
    activatefn = module_activate,
    deactivatefn = module_deactivate
}

ModuleDefs.AddNewModuleDefinition(DISCHARGE_MODULE_DATA)
table.insert(ModuleDefs.module_definitions, DISCHARGE_MODULE_DATA)

ModuleDefs.AddCreatureScanDataDefinition("knight", "discharge", 6)
ModuleDefs.AddCreatureScanDataDefinition("bishop", "discharge", 6)
ModuleDefs.AddCreatureScanDataDefinition("rook", "discharge", 6)
ModuleDefs.AddCreatureScanDataDefinition("winona", "discharge", 6)
--funny, might not keep it

if um then
    ModuleDefs.AddCreatureScanDataDefinition("bight", "discharge", 6)
    ModuleDefs.AddCreatureScanDataDefinition("roship", "discharge", 6)
    ModuleDefs.AddCreatureScanDataDefinition("knook", "discharge", 6)
end
