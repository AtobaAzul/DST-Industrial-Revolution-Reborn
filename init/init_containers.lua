local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------
local containers = require("containers")

local function CheckRefineable(container, item, slot)
    if table.contains(TUNING.IR.REFINERY_ITEMS, item.prefab) then
        return true
    end
end

local modparams = {}

containers.params.ir_refinery =
{
    widget =
    {
        slotpos = {},
        slotbg = {},
        animbank = "ui_tacklecontainer_3x2",
        animbuild = "ui_tacklecontainer_3x2",
        pos = Vector3(0, 200, 0),
        side_align_tip = 160,
    },
    type = "chest",
    itemtestfn = CheckRefineable,
}

for y = 1, 0, -1 do
    for x = 0, 2 do
        table.insert(containers.params.ir_refinery.widget.slotpos,
            Vector3(80 * x - 80 * 2 + 80, 80 * y - 80 * 2 + 120, 0))
    end
end

for k, v in pairs(modparams) do
    containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, v.widget.slotpos ~= nil and #v.widget.slotpos or 0)
end

local function addItemSlotNetvarsInContainer(inst)
    if (#inst._itemspool < containers.MAXITEMSLOTS) then
        for i = #inst._itemspool + 1, containers.MAXITEMSLOTS do
            table.insert(inst._itemspool,
                net_entity(inst.GUID, "container._items[" .. tostring(i) .. "]", "items[" .. tostring(i) .. "]dirty"))
        end
    end
end

env.AddPrefabPostInit("container_classified", addItemSlotNetvarsInContainer)
