--TODO: SUPPORT FOR NEW FLUIDS!!!!!

local function OnFluidgridsChanged(self, fluid_grids)
    self:ClearEmptyGrids()
end

local FluidNetwork = Class(function(self, inst)
    self.inst = inst

    self.fluid_grids = {}
    self.fluid_type = nil --"saltwater", "water"
end, nil,
    {
        fluid_grids = OnFluidgridsChanged
    }
)

--creates grids, returns the grid as well.
function FluidNetwork:CreateGrid() --inst
    self.fluid_grids[#self.fluid_grids + 1] = {
        buildings = {},
        grid_fluid = 0,
        fluid_type = nil, --"saltwater", "water"
    }
    return self.fluid_grids[#self.fluid_grids]
end

function FluidNetwork:ClearEmptyGrids()
    for k, v in pairs(self.fluid_grids) do
        if #v.buildings == 0 then
            self.fluid_grids[k] = nil
        end
    end
end

--gets the grid of an existing ent inside a grid.
function FluidNetwork:GetCurrentGrid(inst)
    for k, grid in pairs(self.fluid_grids) do
        for k, v in pairs(grid.buildings) do
            if v.inst == inst then
                return grid
            end
        end
    end
end

--checks if the grid parameter array is inside in self.fluid_grids
function FluidNetwork:IsGridValid(grid)
    if table.contains(self.fluid_grids, grid) then
        return true
    end
    return false
end

function FluidNetwork:CalculateGridFluid(grid)
    if grid == nil then
        print("FLUID GRID IS NIL!")
        return
    end
    --assert(self:IsGridValid(grid), "Attempted to calculate fluid of invalid grid!")
    local fluid = 0
    local old_grid_fluid = grid.grid_fluid
    local has_pump = false

    for k, v in pairs(grid.buildings) do
        if v.inst.components.ir_fluid.is_pump then
            has_pump = true
        end
        grid.fluid_type = v.inst.components.ir_fluid.fluid_type
        fluid = fluid + v.inst.components.ir_fluid.fluid
    end

    if has_pump then
        grid.grid_fluid = fluid
    else
        grid.grid_fluid = -999
        fluid = -999
        grid.fluid_type = nil
    end

    if old_grid_fluid ~= grid.grid_fluid then
        for k, v in pairs(grid.buildings) do
            v.inst:DoTaskInTime(0, function()
                v.inst:PushEvent("ir_ongridfluidchanged", fluid)
            end)
        end
    end
    return fluid
end

--calculates the fluid
function FluidNetwork:CalculateInstGridFluid(inst)
    local grid = self:GetCurrentGrid(inst)
    return self:CalculateGridFluid(grid)
end

--adds an inst to a grid.
function FluidNetwork:AddInstToGrid(inst, grid)
    assert(inst ~= nil, "Attempted to add invalid entity to grid " .. tostring(grid) .. "!")
    assert(inst.components.ir_fluid ~= nil, "Attempted to add entity without ir_fluid component!")

    for k, v in pairs(grid.buildings) do
        if v.inst == inst then
            return
        end
    end

    --buildings cannot be in more than 1 grid.
    for k, v in pairs(self.fluid_grids) do
        for i, b in pairs(v.buildings) do
            if b.inst == inst and v ~= grid then
                b = nil
            end
        end
    end

    if grid == nil then
        grid = self:CreateGrid()
    end

    table.insert(grid.buildings, { inst = inst })

    inst:PushEvent("ir_addedtogrid_fluid", { grid = grid })
    --self:ClearEmptyGrids()
    self:CalculateGridFluid(grid)
end

function FluidNetwork:RemoveInstFromGrids(inst)
    for k, v in ipairs(self.fluid_grids) do
        for i, building in ipairs(v) do
            if building.inst == inst then
                building = nil
            end
        end
    end
end

return FluidNetwork
