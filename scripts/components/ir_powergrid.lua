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
        for k, v in pairs(grid.buildings) do
            if v.inst == inst then
                return grid
            end
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
        power = power + v.power
    end
    grid.total_power = power
    return power
end

--calculates the power
function PowerGrid:CalculateInstGridPower(inst)
    local grid = self:GetCurrentGrid(inst)
    return self:CalculateGridPower(grid)
end

--adds an inst to a grid.
function PowerGrid:AddInstToGrid(inst, grid)
    assert(inst ~= nil, "Attempted to add invalid entity to grid " .. tostring(grid) .. "!")
    assert(inst.components.ir_power ~= nil, "Attempted to add entity without ir_power component!")

    --buildings cannot be in more than 1 grid.
    for k, v in pairs(self.power_grids) do
        for i, b in pairs(v.buildings) do
            if b.inst == inst and v ~= grid then
                b = nil
            end
        end
    end


    if grid == nil then
        grid = self:CreateGrid()
        print("no grid found, creating grid.")
    end

    self:ClearEmptyGrids()

    table.insert(grid.buildings, { power = inst.components.ir_power.power, inst = inst })

    inst:PushEvent("ir_addedtogrid", { grid = grid })
    self:CalculateGridPower(grid)
end

function PowerGrid:RemoveInstFromGrids(inst)
    for k, v in ipairs(self.power_grids) do
        for i, building in ipairs(v) do
            if building.inst == inst then
                building = nil
            end
        end
    end
end

function PowerGrid:OnSave()
    return {
        power_grids = self.power_grids
    }
end

function PowerGrid:OnLoad(data)
    if data ~= nil and data.power_grids ~= nil then
        self.power_grids = data.power_grids
    end
end

return PowerGrid
