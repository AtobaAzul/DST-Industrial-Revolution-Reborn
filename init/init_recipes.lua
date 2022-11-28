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

------------------
--RECIPE CHANGES--
------------------

---------------
--NEW RECIPES--
---------------

AddRecipe2(
    "ir_generator_t1",
    { Ingredient("nitre", 2), Ingredient("gears", 1), Ingredient("cutstone", 2) },
    TECH.SCIENCE_ONE,
    { placer = "ir_generator_t1_placer" },
    { "STRUCTURES" }
)

AddRecipe2(
    "ir_powerline",
    { Ingredient("boards", 2), Ingredient("goldnugget", 2), Ingredient("cutstone", 2) },
    TECH.SCIENCE_ONE,
    { placer = "ir_powerline_placer" },
    { "STRUCTURES" }
)
------------------
--RECIPE STRINGS--
------------------