--currently only used for IA, but if we ever need more advanced mod checks, put 'em here!

local env = env
GLOBAL.setfenv(1, GLOBAL)

--improved check for IA, instead of just checking for the mod, it checks for the world tags *and* the mod.
--returns true if IA.
--not sure if we'll ever use this here.
function TestForIA()
    if TheWorld ~= nil and not (TheWorld:HasTag("forest") or TheWorld:HasTag("cave")) and
        (TheWorld:HasTag("island") or TheWorld:HasTag("volcano")) and KnownModIndex:IsModEnabled("workshop-1467214795") then
        print("TestForIA: is IA world!")
        return true
    else
        print("TestForIA: not IA world!")
        return false
    end
end

function FindAndMergeGrid(inst, radius)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, TUNING.YOTC_RACER_CHECKPOINT_FIND_DIST, { "ir_power" }, { "burnt" })
    local found_grids = {}
    local current_grid = TheWorld.components.ir_powergrid:GetCurrentGrid(inst)
    local grid_to_connect
    for k, v in pairs(ents) do
        local grid = TheWorld.components.ir_powergrid:GetCurrentGrid(v)
        if grid ~= nil then
            table.insert(found_grids, #grid.buildings)
        end
    end

    for k, v in pairs(TheWorld.components.ir_powergrid.power_grids) do
        if #found_grids ~= 0 and #v.buildings == math.max(unpack(found_grids)) then
            grid_to_connect = v
        end
    end

    for k, v in ipairs(ents) do
        local grid = TheWorld.components.ir_powergrid:GetCurrentGrid(v)
        if grid ~= nil and grid_to_connect ~= nil and grid ~= grid_to_connect then
            for k, v in pairs(grid.buildings) do
                TheWorld.components.ir_powergrid:AddInstToGrid(v.inst, grid_to_connect)
                grid.buildings[k] = nil
            end
        end
    end

    if grid_to_connect ~= nil then
        --[[if TheWorld.components.ir_powergrid:GetCurrentGrid(inst) ~= nil then
            for k,v in pairs(TheWorld.components.ir_powergrid:GetCurrentGrid(inst).buildings) do
                if v.inst == inst then
                    v = nil
                end
            end
        end]]
        TheWorld.components.ir_powergrid:AddInstToGrid(inst, grid_to_connect)

    end

    if grid_to_connect == nil then
        local grid = TheWorld.components.ir_powergrid:CreateGrid()
        TheWorld.components.ir_powergrid:AddInstToGrid(inst, grid)
    end
end

local function OnLoadPostPass(inst, data)
    FindAndMergeGrid(inst)
end

--adds ir_power, DoTaskInTime for finding grids, and some other misc stuff
--@def.power; @def.range
function MakeDefaultIRStructure(inst, def)
    inst:AddTag("ir_power")
    inst:AddComponent("ir_power")

    --inst.has_grid = false
    --inst:DoTaskInTime(0, function()
    --   if not inst.has_grid then
    --        FindAndMergeGrid(inst)
    --    end
    --end)

    if not POPULATING then
        FindAndMergeGrid(inst)
    end

    inst:DoTaskInTime(0, FindAndMergeGrid)
    inst:DoTaskInTime(0.5, function()
        inst.components.ir_power.power = def.power
    end)
    local _OnRemoveEntity = inst.OnRemoveEntity
    inst.OnRemoveEntity = function(inst)
        local grid = TheWorld.components.ir_powergrid:GetCurrentGrid(inst) 
        TheWorld.components.ir_powergrid:RemoveInstFromGrids(inst)
        if grid ~= nil then
            TheWorld.components.ir_powergrid:CalculateGridPower(grid)
        end
        if _OnRemoveEntity ~= nil then
            _OnRemoveEntity(inst)
        end
    end

    local _OnLoadPostPass = inst.OnLoadPostPass
    inst.OnLoadPostPass = function(inst, data)
        OnLoadPostPass(inst, data)
        if _OnLoadPostPass ~= nil then
            _OnLoadPostPass(inst, data)
        end
    end
end
