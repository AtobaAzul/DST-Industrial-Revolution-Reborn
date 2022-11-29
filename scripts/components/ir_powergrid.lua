local function OnPowergridsChanged(self, power_grids)
    self:ClearEmptyGrids()
end

local PowerGrid = Class(function(self, inst)
    self.inst = inst

    self.power_grids = {}
end, nil,
    {
        power_grids = OnPowergridsChanged
    }
)

--creates grids, returns the grid as well.
function PowerGrid:CreateGrid() --inst
    self.power_grids[#self.power_grids + 1] = {
        buildings = {},
        total_power = 0
    }
    return self.power_grids[#self.power_grids]
end

function PowerGrid:ClearEmptyGrids()
    for k, v in pairs(self.power_grids) do
        if #v.buildings == 0 then
            v = nil
        end
    end
end

--gets the grid of an existing ent inside a grid.
function PowerGrid:GetCurrentGrid(inst)
    for k, grid in pairs(self.power_grids) do
        if grid.buildings[inst.GUID] ~= nil then
            return grid
        end
    end
end

--checks if the grid parameter array is inside in self.power_grids
function PowerGrid:IsGridValid(grid)
    if table.contains(self.power_grids, grid) then
        return true
    end
    return false
end

function PowerGrid:CalculateGridPower(grid)
    --assert(self:IsGridValid(grid), "Attempted to calculate power of invalid grid!")
    local power = 0
    for k, v in pairs(grid.buildings) do
        power = power + v
    end
    grid.total_power = power
    return power
end

--calculates the power
function PowerGrid:CalculateInstGridPower(inst)
    local grid = self:GetCurrentGrid(inst)
    return self:CalculateGridPower(grid)
end

--adds a inst to a grid.
function PowerGrid:AddInstToGrid(inst, grid)
    if grid ~= nil and table.contains(grid.buildings, inst) then
        return
    end

    if grid == nil then
        grid = self:CreateGrid()
    end

    assert(inst ~= nil, "Attempted to add invalid entity to grid " .. tostring(grid) .. "!")
    assert(inst.components.ir_power ~= nil, "Attempted to add entity with invalid ir_power component!")

    --buildings cannot be in more than 1 grid.
    for k, v in pairs(self.power_grids) do
        if v.buildings[inst.GUID] ~= nil and v ~= grid then
            v.buildings[inst.GUID] = nil
            break
        end
    end

    self:ClearEmptyGrids()

    grid.buildings[inst.GUID] = inst.components.ir_power.power
    inst:PushEvent("ir_addedtogrid", { grid = grid })
    self:CalculateGridPower(grid)
end

function PowerGrid:RemoveInstFromGrids(inst)
    for k,v in ipairs(self.power_grids)do
        v.buildings[inst.GUID] = nil
    end
end

function PowerGrid:OnSave()
    return {
        power_grids = self.power_grids
    }
end

function PowerGrid:OnLoad(data)
    if data.power_grids ~= nil then
        self.power_grids = data.power_grids
    end
end

return PowerGrid
