--  [           Required stuff          ]   --
-- The global objects needed for recipe changes
-- Find the default recipes in recipes.lua
local require = GLOBAL.require
require("recipe")

local TechTree = require("techtree")
local TECH = GLOBAL.TECH
local Ingredient = GLOBAL.Ingredient
local AllRecipes = GLOBAL.AllRecipes
local STRINGS = GLOBAL.STRINGS
local CONSTRUCTION_PLANS = GLOBAL.CONSTRUCTION_PLANS
local CRAFTING_FILTERS = GLOBAL.CRAFTING_FILTERS
local RECIPE_DESC = STRINGS.RECIPE_DESC

-- List of Vanilla Recipe Filters
-- "FAVORITES", "CRAFTING_STATION", "SPECIAL_EVENT", "MODS", "CHARACTER", "TOOLS", "LIGHT",
-- "PROTOTYPERS", "REFINE", "WEAPONS", "ARMOUR", "CLOTHING", "RESTORATION", "MAGIC", "DECOR",
-- "STRCUTURES", "CONTAINERS", "COOKING", "GARDENING", "FISHING", "SEAFARING", "RIDING",
-- "WINTER", "SUMMER", "RAIN", "EVERYTHING"

--- Change the sort key of an existing recipe in a particular crafting filter.
--- Note: Recipes are automatically added to the end of a crafting filter tab
--- when the function AddRecipe2 is used. -- KoreanWaffles
-- @recipe_name: (str) the recipe to sort
-- @recipe_reference:(str) the recipe to place the given recipe next to
-- @filter: (str) the crafting filter to sort in
-- @after: (bool) whether the recipe should be sorted after the reference
-- Copied from UM. Pretty sure KoreanWaffles made this.

local function ChangeSortKey(recipe_name, recipe_reference, filter, after)
    local recipes = CRAFTING_FILTERS[filter].recipes
    local recipe_name_index
    local recipe_reference_index

    for i = #recipes, 1, -1 do
        if recipes[i] == recipe_name then
            recipe_name_index = i
        elseif recipes[i] == recipe_reference then
            recipe_reference_index = i + (after and 1 or 0)
        end
        if recipe_name_index and recipe_reference_index then
            if recipe_name_index >= recipe_reference_index then
                table.remove(recipes, recipe_name_index)
                table.insert(recipes, recipe_reference_index, recipe_name)
            else
                table.insert(recipes, recipe_reference_index, recipe_name)
                table.remove(recipes, recipe_name_index)
            end
            break
        end
    end
end

local TechTree = require("techtree")
table.insert(TechTree.AVAILABLE_TECH, "IR_TECH")

TECH.NONE.IR_TECH = 0
TECH.IR_TECH_ONE = { IR_TECH = 1 }
TECH.IR_TECH_TWO = { IR_TECH = 2 }

for k, v in pairs(TUNING.PROTOTYPER_TREES) do
    v.CUSTOM_TECH = 0
end

TUNING.PROTOTYPER_TREES.IR_TECH_ONE = TechTree.Create({ IR_TECH = 1 })
TUNING.PROTOTYPER_TREES.IR_TECH_TWO = TechTree.Create({ IR_TECH = 2 })

for i, v in pairs(GLOBAL.AllRecipes) do
    if v.level.IR_TECH == nil then
        v.level.IR_TECH = 0
    end
end

AddRecipeFilter({ name = "ELECTRICITY", atlas = GLOBAL.resolvefilepath(GLOBAL.CRAFTING_ICONS_ATLAS),
    image = "filter_science.tex" })
STRINGS.UI.CRAFTING_FILTERS.ELECTRICITY = "Electricity"
AddRecipeFilter({ name = "POWERED_BUILDINGS", atlas = GLOBAL.resolvefilepath(GLOBAL.CRAFTING_ICONS_ATLAS),
    image = "filter_science.tex" })
STRINGS.UI.CRAFTING_FILTERS.POWERED_BUILDINGS = "Powered Structures"
AddRecipeFilter({ name = "POWER_GENERATION", atlas = GLOBAL.resolvefilepath(GLOBAL.CRAFTING_ICONS_ATLAS),
    image = "filter_science.tex" })
STRINGS.UI.CRAFTING_FILTERS.POWER_GENERATION = "Power Production"


------------------
--RECIPE CHANGES--
------------------

AllRecipes["winona_catapult"] = nil
AllRecipes["winona_spotlight"] = nil
AllRecipes["winona_battery_low"] = nil
AllRecipes["winona_battery_high"] = nil

AllRecipes["researchlab2"].level = TechTree.Create(TECH.IR_TECH_ONE)

---------------
--NEW RECIPES--
---------------

AddRecipe2(
    "ir_generator_burnable",
    { Ingredient("goldnugget", 2), Ingredient("gears", 1), Ingredient("cutstone", 2) },
    TECH.IR_TECH_ONE,
    { placer = "ir_generator_burnable_placer" },
    { "STRUCTURES", "ELECTRICITY", "POWER_GENERATION" }
)

AddRecipe2(
    "ir_generator_battery",
    { Ingredient("goldnugget", 2), Ingredient("nitre", 2), Ingredient("cutstone", 1) },
    TECH.IR_TECH_ONE,
    { placer = "ir_generator_battery_placer" },
    { "STRUCTURES", "ELECTRICITY", "POWER_GENERATION" }
)

AddRecipeToFilter("lightning_rod", "ELECTRICITY")
AddRecipeToFilter("lightning_rod", "POWER_GENERATION")

AddRecipe2(
    "ir_powerline",
    { Ingredient("boards", 2), Ingredient("goldnugget", 4), Ingredient("cutstone", 2) },
    TECH.IR_TECH_ONE,
    { placer = "ir_powerline_placer" },
    { "STRUCTURES", "ELECTRICITY" }
)

AddRecipe2(
    "ir_spotlight",
    { Ingredient("lightbulb", 1), Ingredient("gears", 2), Ingredient("boards", 2), Ingredient("goldnugget", 3) },
    --TODO: ACtual recipe ingredients
    TECH.IR_TECH_ONE,
    { placer = "ir_spotlight_placer" },
    { "LIGHT", "STRUCTURES", "ELECTRICITY", "POWERED_BUILDINGS" }
)

AddRecipe2(
    "ir_lightpost",
    { Ingredient("lightbulb", 2), Ingredient("goldnugget", 6), Ingredient("cutstone", 2) },
    --TODO: ACtual recipe ingredients
    TECH.IR_TECH_ONE,
    { placer = "ir_lightpost_placer" },
    { "LIGHT", "STRUCTURES", "ELECTRICITY", "POWERED_BUILDINGS" }
)

AddRecipe2(
    "ir_catapult",
    { Ingredient("cutstone", 5), Ingredient("gears", 2), Ingredient("boards", 2) }, --TODO: ACtual recipe ingredients
    TECH.IR_TECH_ONE,
    { placer = "ir_catapult_placer" },
    { "STRUCTURES", "ELECTRICITY", "POWERED_BUILDINGS" }
)
AddRecipeToFilter("icebox", "POWERED_BUILDINGS")
AddRecipeToFilter("icebox", "ELECTRICITY")

AddRecipeToFilter("researchlab2", "ELECTRICITY")
AddRecipeToFilter("researchlab2", "POWERED_BUILDINGS")

AddRecipe2(
    "ir_tech_prototyper",
    { Ingredient("cutstone", 5), Ingredient("gears", 2), Ingredient("boards", 2) }, --TODO: ACtual recipe ingredients
    TECH.SCIENCE_ONE,
    { placer = "ir_tech_prototyper_placer" },
    { "STRUCTURES", "ELECTRICITY", "PROTOTYPERS" }
)

AddRecipe2(
    "ir_tech_prototyper2",
    { Ingredient("cutstone", 5), Ingredient("gears", 2), Ingredient("boards", 2) }, --TODO: ACtual recipe ingredients
    TECH.SCIENCE_ONE,
    { placer = "ir_tech_prototyper2_placer" },
    { "STRUCTURES", "ELECTRICITY", "PROTOTYPERS" }
)




------------------
--RECIPE STRINGS--
------------------
