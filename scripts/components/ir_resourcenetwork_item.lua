--[[
Simpler because most of the item network things will be handled by the prefabs themselves.
Just need this to have the whole control over various entities
]]
local ItemNetwork = Class(function(self, inst)
    self.inst = inst

    self.item_grids = {}
end, nil,
    {
    }
)

function ItemNetwork:CreateGrid()
    self.item_grids[#self.item_grids + 1] = {
        buildings = {},
    }
    return self.item_grids[#self.item_grids]
end

--adds an inst to a grid.
function ItemNetwork:AddInstToGrid(inst, grid)
    assert(inst ~= nil, "Attempted to add invalid entity to grid " .. tostring(grid) .. "!")
    assert(inst.components.ir_itemnetworkable ~= nil, "Attempted to add entity without ir_itemnetworkable component!")--Just in case...


    for k, v in pairs(grid.buildings) do
        if v.inst == inst then
            return
        end
    end

    --buildings cannot be in more than 1 grid.
    for k, v in pairs(self.item_grids) do
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

    inst:PushEvent("ir_addedtogrid_item", { grid = grid })
end

--gets the grid of an existing ent inside a grid.
function ItemNetwork:GetCurrentGrid(inst)
    for k, grid in pairs(self.item_grids) do
        for k, v in pairs(grid.buildings) do
            if v.inst == inst then
                return grid
            end
        end
    end
end

function ItemNetwork:RemoveInstFromGrids(inst)
    for k, grid in pairs(self.item_grids) do
        for k, v in pairs(grid) do
            for k, v in pairs(v) do
                if v.inst == inst then
                    v = nil
                end
            end
        end
    end
end

return ItemNetwork
