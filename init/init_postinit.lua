--Update this list when adding files
local component_post = {

}

local prefab_post = {
	"world",
	"icebox",
	"lightningrod",
	"researchlab2",
	"itemnetworkable"
}

local stategraph_post = {

}

local class_post = {

}

local brain_post = {

}

modimport("postinit/any")
modimport("postinit/player")

for _, v in pairs(component_post) do
	modimport("postinit/components/" .. v)
end

for _, v in pairs(prefab_post) do
	modimport("postinit/prefabs/" .. v)
end

for _, v in pairs(stategraph_post) do
	modimport("postinit/stategraphs/SG" .. v)
end

for _, v in pairs(brain_post) do
	modimport("postinit/brains/" .. v .. "brain")
end

for _, v in pairs(class_post) do
	--These contain a path already, e.g. v= "widgets/inventorybar"
	modimport("postinit/" .. v)
end
