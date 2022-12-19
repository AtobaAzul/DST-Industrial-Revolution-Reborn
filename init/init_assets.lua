--Items
--Registering all item atlas so we don't have to keep doing it on each craft/prefab.
--PLEASE keep atlas names and image names the same so we can continue to do this like this.
local inventoryitems =
{

}

for k, v in ipairs(inventoryitems) do
	RegisterInventoryItemAtlas("images/inventoryimages/" .. v .. ".xml", v .. ".tex")
end

Assets =
{

}
