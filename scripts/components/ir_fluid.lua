local function onfluidchanged(self, power)
    if TheWorld ~= nil and TheWorld.components.ir_resourcenetwork_fluid:GetCurrentGrid(self.inst) ~= nil then
        TheWorld.components.ir_resourcenetwork_fluid:CalculateInstGridFluid(self.inst)
    end
end

local Fluid = Class(function(self, inst)
    self.inst = inst

    self.fluid = 0
    self.is_pump = false--need to explicity state that a pump exists.
    self.fluid_type = nil

    self.inst:AddTag("ir_fluid") --Add this to pristine state in the prefabs for optimization
end,
    nil,
    {
        fluid = onfluidchanged
    }
)

function Fluid:SetFluid(val)
    self.fluid = val
end

function Fluid:AddFluid(val)
    self.fluid = self.fluid + val
end

return Fluid
