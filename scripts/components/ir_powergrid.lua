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
    }
    return self.power_grids[#self.power_grids]
end

function PowerGrid:ClearEmptyGrids()
    for k, v in pairs(self.power_grids) do
        if #v.buildings == 0 then
            self.power_grids[k] = nil
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
        power = power + v.inst.components.ir_power.power
    end
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

    table.insert(grid.buildings, { inst = inst })

    inst:PushEvent("ir_addedtogrid", { grid = grid })
    self:ClearEmptyGrids()
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
    local refs = {}
    local data = {}

    for k, grid in pairs(self.power_grids) do
        refs[k] = {}
        data[k] = {}
        for i, building in pairs(grid.buildings) do
            data[k].building = building.inst.GUID
            table.insert(refs[k], building.inst.GUID)
        end
    end
    printwrap("refs", refs)
    printwrap("data", data)

    return data, refs
end

function PowerGrid:OnLoadPostPass(ents, data)
    printwrap("ents", "data")
end

return PowerGrid
