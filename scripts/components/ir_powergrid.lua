local PowerGrid = Class(function(self, inst)
    self.inst = inst

    self.power_grids = {}
end)

--creates grids, returns the grid as well.
function PowerGrid:CreateGrid() --inst
    self.power_grids[#self.power_grids+1] = {
        buildings = {},
        total_power = 0
    }
    return self.power_grids[#self.power_grids]
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

--adds a inst to a grid.
function PowerGrid:AddToGrid(inst, grid)
    if grid == nil then
        grid = self:CreateGrid()
    end
    assert(inst ~= nil and inst.GUID ~= nil, "Attempted to add invalid entity to grid "..tostring(grid).."!")

    --buildings cannot be in more than 1 grid.
    for k, v in pairs(self.power_grids) do
        if v.buildings[inst.GUID] ~= nil and v ~= grid then
            v.buildings[inst.GUID] = nil
        end
    end

    grid.buildings[inst.GUID] = inst.grid_power --TODO: make this a component?
end

function PowerGrid:CalculateGridPower(grid)
    assert(self:IsGridValid(grid), "Attempted to calculate power of invalid grid!")
    local power = 0
    for k, v in pairs(grid.buildings) do
        power = power + v
    end
    return power
end

--calculates the power 
function PowerGrid:CalculateInstGridPower(inst)
    local grid = self:GetCurrentGrid(inst)
    return self:CalculateGridPower(grid)
end

return PowerGrid