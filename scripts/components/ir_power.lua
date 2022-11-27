local function onpowerchanged(self, power)
    if TheWorld ~= nil and TheWorld.components.ir_powergrid:GetCurrentGrid(self.inst) ~= nil then
        TheWorld.components.ir_powergrid:CalculateInstGridPower(self.inst)
    end
end

local Power = Class(function(self, inst)
    self.inst = inst

    self.power = 0
end,
    nil,
    {
        power = onpowerchanged
    }
)

function Power:SetPower(val)
    self.power = val
end

function Power:AddPower(val)
    self.power = self.power + val
end

return Power
