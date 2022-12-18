local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------


local function OnModeChanged_chest(inst, mode)
    if inst.components.ir_itemnetworkable.mode == "IO" or inst.components.ir_itemnetworkable.mode == "I" then
        if inst._senditemtask ~= nil then
            inst._senditemtask:Cancel()
            inst._senditemtask = nil
        end

        inst._senditemtask = inst:DoPeriodicTask(3, function()
            local grid = TheWorld.components.ir_resourcenetwork_item:GetCurrentGrid(inst)

            if grid ~= nil and
                (inst.components.ir_itemnetworkable.mode == "I" or inst.components.ir_itemnetworkable.mode == "IO") then
                local valid_outputs = {}
                for k, v in pairs(grid.buildings) do
                    if (
                        v.inst.components.ir_itemnetworkable:GetMode() == "O" or
                            v.inst.components.ir_itemnetworkable:GetMode() == "IO" and v ~= inst) and
                        v.inst.components.container ~= nil then
                        table.insert(valid_outputs, v.inst)
                    end
                end

                if #valid_outputs > 0 then
                    for k, v in ipairs(inst.components.container:GetAllItems()) do
                        valid_outputs[math.random(#valid_outputs)].components.container:GiveItem(inst.components.container
                            :RemoveItem(v, true))
                        if k == 3 then break end
                    end
                end
            end
        end)
    else
        if inst._senditemtask ~= nil then
            inst._senditemtask:Cancel()
            inst._senditemtask = nil
        end
    end
end

local function OnUpgrade_chest(inst)
    MakeDefaultItemNetworkableStructure(inst, { valid_modes = { "I", "O" } })
    inst.components.upgradeable.upgradetype = nil

    inst:ListenForEvent("ir_onmodechanged", OnModeChanged_chest)
end

env.AddPrefabPostInit("treasurechest", function(inst)
    inst:AddTag(UPGRADETYPES.ITEM_NETWORKABLE .. "_upgradeable")

    if not TheWorld.ismastersim then
        return
    end

    inst:ListenForEvent("itemget", function(inst, slot, item, src_pos)
        if inst.components.ir_itemnetworkable == nil then
            local upgrader = inst.components.container:FindItem(function(item) return item.prefab ==
                    "ir_upgrader_itemnetwork"
            end)
            local upgrader_item = inst.components.container:RemoveItem(upgrader, false)
            if upgrader_item ~= nil then
                OnUpgrade_chest(inst)
                upgrader_item:Remove()
            end
        end
    end)

    --sure, whatever.
    inst:AddComponent("upgradeable")
    inst.components.upgradeable.upgradetype = UPGRADETYPES.ITEM_NETWORKABLE
    inst.components.upgradeable.onupgradefn = OnUpgrade_chest

    local _OnSave = inst.OnSave

    inst.OnSave = function(inst, data)
        if inst.components.ir_itemnetworkable ~= nil then
            data.upgraded = true
            data.mode = inst.components.ir_itemnetworkable.mode
        end
        if _OnSave ~= nil then
            _OnSave(inst, data)
        end
    end

    local _OnLoad = inst.OnLoad

    inst.OnLoad = function(inst, data)
        if data ~= nil and data.upgradeable then
            OnUpgrade_chest(inst)
            if data.mode ~= nil then
                inst.components.ir_itemnetworkable.mode = data.mode
            end
        end
        if _OnLoad ~= nil then
            _OnLoad(inst, data)
        end
    end

end)
