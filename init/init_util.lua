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
    local current_grid = TheWorld.components.ir_resourcenetwork_power:GetCurrentGrid(inst)
    local grid_to_connect
    for k, v in pairs(ents) do
        local grid = TheWorld.components.ir_resourcenetwork_power:GetCurrentGrid(v)
        if grid ~= nil then
            table.insert(found_grids, #grid.buildings)
        end
    end

    for k, v in pairs(TheWorld.components.ir_resourcenetwork_power.power_grids) do
        if #found_grids ~= 0 and #v.buildings == math.max(unpack(found_grids)) then
            grid_to_connect = v
        end
    end

    for k, v in ipairs(ents) do
        local grid = TheWorld.components.ir_resourcenetwork_power:GetCurrentGrid(v)
        if grid ~= nil and grid_to_connect ~= nil and grid ~= grid_to_connect then
            for k, v in pairs(grid.buildings) do
                TheWorld.components.ir_resourcenetwork_power:AddInstToGrid(v.inst, grid_to_connect)
                grid.buildings[k] = nil
            end
        end
    end

    if grid_to_connect ~= nil then
        --[[if TheWorld.components.ir_resourcenetwork_power:GetCurrentGrid(inst) ~= nil then
            for k,v in pairs(TheWorld.components.ir_resourcenetwork_power:GetCurrentGrid(inst).buildings) do
                if v.inst == inst then
                    v = nil
                end
            end
        end]]
        TheWorld.components.ir_resourcenetwork_power:AddInstToGrid(inst, grid_to_connect)

    end

    if grid_to_connect == nil then
        local grid = TheWorld.components.ir_resourcenetwork_power:CreateGrid()
        TheWorld.components.ir_resourcenetwork_power:AddInstToGrid(inst, grid)
    end
end

--adds ir_power, DoTaskInTime for finding grids, and some other misc stuff
--@def.power; @def.range
function MakeDefaultIRStructure(inst, def)
    --inside so wecan access def.power

    local carratrace_common = require("prefabs/yotc_carrat_race_common")


    inst:AddTag("ir_power")

    carratrace_common.AddDeployHelper(inst, { "ir_powerline", "ir_generator_burnable", "ir_power" })

    if not TheWorld.ismastersim then
        return
    end

    inst.on_power = def.power

    local function TurnOnFn(inst)
        inst.components.ir_power.power = inst.on_power
        if inst.components.fueled ~= nil and inst.components.fueled.ontakefuelfn ~= nil and not inst.components.fueled:IsEmpty() then
            inst:DoTaskInTime(0, inst.components.fueled.ontakefuelfn)
        end
    end

    local function TurnOffFn(inst)
        inst.components.ir_power.power = 0
        if inst.components.fueled ~= nil and inst.components.fueled.depleted ~= nil then
            inst:DoTaskInTime(0, inst.components.fueled.depleted)
        end
    end

    inst:AddComponent("ir_power")

    if def.toggleable then
        inst:AddComponent("machine")
        inst.components.machine.turnonfn = TurnOnFn
        inst.components.machine.turnofffn = TurnOffFn
        inst.components.machine.cooldowntime = 0.5

        --god damnit why is component saving/loading so unreliable

        local _OnLoadPostPass = inst.OnLoadPostPass
        inst.OnLoadPostPass = function(inst, data)
            FindAndMergeGrid(inst)

            if inst.components.machine.ison and inst.components.fueled ~= nil and not inst.components.fueled:IsEmpty() then
                inst:DoTaskInTime(0, function()
                    print("TURN FUCKING ON")
                    inst.components.machine:TurnOn()
                end)
            end
            if _OnLoadPostPass ~= nil then
                _OnLoadPostPass(inst, data)
            end
        end

        if not POPULATING then
            inst.components.machine:TurnOn()
        end
    else
        inst:DoTaskInTime(FRAMES, function()
            inst.components.ir_power.power = 0 --just to force a update.
            inst.components.ir_power.power = def.power
        end)
    end
    if not POPULATING then
        FindAndMergeGrid(inst)
    end

    inst:DoTaskInTime(0, FindAndMergeGrid)

    local _OnRemoveEntity = inst.OnRemoveEntity
    inst.OnRemoveEntity = function(inst)
        local grid = TheWorld.components.ir_resourcenetwork_power:GetCurrentGrid(inst)
        TheWorld.components.ir_resourcenetwork_power:RemoveInstFromGrids(inst)
        if grid ~= nil then
            TheWorld.components.ir_resourcenetwork_power:CalculateGridPower(grid)
        end
        if _OnRemoveEntity ~= nil then
            _OnRemoveEntity(inst)
        end
    end
end

--Oposite of unpack.
pack = function(...) return { ... } end
