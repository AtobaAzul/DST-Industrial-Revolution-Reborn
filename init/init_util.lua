--currently only used for IA, but if we ever need more advanced mod checks, put 'em here!

local env = env
GLOBAL.setfenv(1, GLOBAL)

--improved check for IA, instead of just checking for the mod, it checks for the world tags *and* the mod.
--returns true if IA.
--not sure if we'll ever use this here.
function TestForIA()
    if TheWorld ~= nil and not (TheWorld:HasTag("forest") or TheWorld:HasTag("cave")) and (TheWorld:HasTag("island") or TheWorld:HasTag("volcano")) and KnownModIndex:IsModEnabled("workshop-1467214795") then
        print("TestForIA: is IA world!")
        return true
    else
        print("TestForIA: not IA world!")
        return false
    end
end

function FindGrid(inst, radius)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, radius, { "ir_power" }, { "burnt" })
    local found_grid = false

    for k, v in pairs(ents) do
        local grid = TheWorld.components.ir_powergrid:GetCurrentGrid(v)
        if grid ~= nil then
            TheWorld.components.ir_powergrid:AddInstToGrid(inst, grid)
            TheWorld.components.ir_powergrid:AddInstToGrid(v, grid)
            found_grid = true
        end
    end

    if not found_grid then
        local grid = TheWorld.components.ir_powergrid:CreateGrid()
        TheWorld.components.ir_powergrid:AddInstToGrid(inst, grid)
    end
end