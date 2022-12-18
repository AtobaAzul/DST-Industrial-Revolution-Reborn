local valid_types = {"I", "O", "IO", "None"}
--I(nput): Items added to this are sent to outputs.
--O(utput): Items send from inputs end here.
--I(nput/)O(utput): Items are sent here, and sends items to something that isn't itself unless blocked. For use in producers.


local function onmodechanged(self, mode)--in case *someone* tries to bypass the functions. May need to add support for custom modes in the future, however.
    assert(table.contains(valid_types, mode), "Attempted to set invalid mode! (\'"..mode.."\')\nValid modes are \"I\", \"O\", \"IO\" and \"None\" - Make sure you typed it right!")
    self.inst:PushEvent("ir_onmodechanged", mode)
end

local ItemNetworkable = Class(function(self, inst)
    self.inst = inst

    self.inst:AddTag("ir_itemnetworkable")

    self.mode = "None"
    self.valid_modes = {"None"}
end,
    nil,
    {
        mode = onmodechanged
    }
)

function ItemNetworkable:SetMode(mode)
    assert(table.contains(valid_types, mode), "Attempted to set invalid mode!\nValid modes are \"I\", \"O\", \"IO\" and \"None\" - Make sure you typed it right! Mode:", mode)
    self.mode = mode
end

function ItemNetworkable:SetValidModes(mode)
    --assert(table.contains(valid_types, mode), "Attempted to set invalid mode!\nValid modes are \"I\", \"O\", \"IO\" and \"None\" - Make sure you typed it right! Mode:", mode)

    if type(mode) == "table" then
        for k,v in pairs(mode) do
            table.insert(self.valid_modes, v)
        end
    else
        table.insert(self.valid_modes, mode)
    end
end

function ItemNetworkable:GetMode()
    return self.mode
end

function ItemNetworkable:GetValidMode()
    return self.valid_modes
end

function ItemNetworkable:OnSave()
    local data = {
        mode = self.mode
    }
    return data
end

function ItemNetworkable:OnLoad(data)
    self.mode = data.mode or "None"
end

return ItemNetworkable
