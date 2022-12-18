local env = env
GLOBAL.setfenv(1, GLOBAL)

local function ToggleIRVision(toggle)
    local x, y, z = ThePlayer.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 30, nil, { "burnt" }, { "irvisionhighlighter" })

    for k, v in ipairs(ents) do
        if v.OnIRVision ~= nil then
            v.OnIRVision(toggle)
        end
    end
end

AddModRPCHandler("IndustrialRevolution", "ToggleIRVision", ToggleIRVision)

local function SetWrenchMode(player, wrench, mode)
    print(wrench, mode)
    wrench.mode = mode
    wrench.spelltype = "Mode: "..mode
end

AddModRPCHandler("IndustrialRevolution", "SetWrenchMode", SetWrenchMode)

