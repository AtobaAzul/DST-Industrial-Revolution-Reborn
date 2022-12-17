local function onmodechanged(self, power)
    self.inst:PushEvent("ir_onmodechanged")
end

local valid_types = {"I", "O", "IO", "None"}

local ItemNetworkable = Class(function(self, inst)
    self.inst = inst

    self.mode = "None"

    self.inst:AddTag("ir_power") --Add this to pristine state in the prefabs for optimization
end,
    nil,
    {
        mode = onmodechanged
    }
)

function ItemNetworkable:SetMode(mode)
    assert(table.contains(valid_types, mode), "Attempted to set invalid mode! (\'"..mode.."\')\nValid modes are \"I\", \"O\", \"IO\" and \"None\"")
    self.mode = mode
end

return ItemNetworkable
