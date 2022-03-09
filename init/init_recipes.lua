-- The global objects needed for recipe changes
-- Find the default recipes in recipes.lua
GLOBAL.require("recipe")
TechTree = GLOBAL.require("techtree")
TECH = GLOBAL.TECH
Recipe = GLOBAL.Recipe
RECIPETABS = GLOBAL.RECIPETABS
Ingredient = GLOBAL.Ingredient
AllRecipes = GLOBAL.AllRecipes
STRINGS = GLOBAL.STRINGS
CUSTOM_RECIPETABS = GLOBAL.CUSTOM_RECIPETABS
CONSTRUCTION_PLANS = GLOBAL.CONSTRUCTION_PLANS
print("Loaded init_recipes successfully.")

--Registering all item atlas so we don't have to keep doing it on each craft.
--RegisterInventoryItemAtlas("images/inventoryimages/rat_whip.xml", "rat_whip.tex")
