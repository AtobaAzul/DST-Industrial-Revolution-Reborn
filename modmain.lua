PrefabFiles = require("ir_prefabs")

local inits = 
{
    "actions",
    "assets",
    "containers",
    "loadingtips",
    "names",
    "postinit",
    "recipes",
    "rpctrackers",
    "strings",
    "tuning",
    "util",
    "widgets",
    "minimap_icons",
}

for k,v in ipairs(inits) do
    modimport("init/init_"..v)
end

GLOBAL.UPGRADETYPES.ITEM_NETWORKABLE = "ITEM_NETWORKABLE"