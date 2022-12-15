local function OnPowergridsChanged(self, power_grids)
    --self:ClearEmptyGrids()
end

local ItemNetwork = Class(function(self, inst)
    self.inst = inst

    self.item_grid = {}
end, nil,
    {
       --item_grid = OnPowergridsChanged
    }
)

function ItemNetwork:CreateGrid()
    self.item_grid[#self.item_grid + 1] = {
        inputs = {},    --input means things that insert items to the output
        outputs = {},   
        nodes = {},     --nodes are for connecting inputs and outputs.
    }
    return self.item_grid[#self.item_grid]
end

function ItemNetwork:AddInputInst(inst, grid)
    for k, v in pairs(grid.inputs) do
        if v.inst == inst then
            return
        end
    end

    table.insert(self.item_grid[grid].AddInputInst, inst)

    inst:PushEvent("ir_addedtogrid_item", {grid = grid, type = "Input"})
end

function ItemNetwork:AddOutputInst(inst, grid)
    assert(inst ~= nil, "Attempted to add invalid entity to grid " .. tostring(grid) .. "!")

    for k, v in pairs(grid.outputs) do
        if v.inst == inst then
            return
        end
    end

    table.insert(self.item_grid[grid].outputs, inst)

    inst:PushEvent("ir_addedtogrid_item", {grid = grid, type = "Output"})
end

function ItemNetwork:AddNodeInst(inst, grid)
    for k, v in pairs(grid.nodes) do
        if v.inst == inst then
            return
        end
    end

    table.insert(self.item_grid[grid].nodes, inst)

    inst:PushEvent("ir_addedtogrid_item", {grid = grid, type = "Node"})
end

--gets the grid of an existing ent inside a grid.
function PowerNetwork:GetCurrentGrid(inst)
    for k, grid in pairs(self.item_grid) do
        for k, v in pairs(grid.inputs) do
            if v.inst == inst then
                return grid, "Input"
            end
        end
        for k, v in pairs(grid.outputs) do
            if v.inst == inst then
                return grid, "Output"
            end
        end
        for k, v in pairs(grid.nodes) do
            if v.inst == inst then
                return grid, "Node"
            end
        end
    end
end

return ItemNetwork
