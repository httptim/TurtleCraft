-- Recipe definitions for TurtleCraft
-- Each recipe defines the pattern and result for crafting

local recipes = {
    -- Wooden Planks (from any log)
    ["minecraft:oak_planks"] = {
        result = "minecraft:oak_planks",
        count = 4,
        pattern = {
            {"minecraft:oak_log", nil, nil},
            {nil, nil, nil},
            {nil, nil, nil}
        }
    },
    
    -- Sticks
    ["minecraft:stick"] = {
        result = "minecraft:stick",
        count = 4,
        pattern = {
            {"minecraft:oak_planks", nil, nil},
            {"minecraft:oak_planks", nil, nil},
            {nil, nil, nil}
        }
    },
    
    -- Crafting Table
    ["minecraft:crafting_table"] = {
        result = "minecraft:crafting_table",
        count = 1,
        pattern = {
            {"minecraft:oak_planks", "minecraft:oak_planks", nil},
            {"minecraft:oak_planks", "minecraft:oak_planks", nil},
            {nil, nil, nil}
        }
    },
    
    -- Chest
    ["minecraft:chest"] = {
        result = "minecraft:chest",
        count = 1,
        pattern = {
            {"minecraft:oak_planks", "minecraft:oak_planks", "minecraft:oak_planks"},
            {"minecraft:oak_planks", nil, "minecraft:oak_planks"},
            {"minecraft:oak_planks", "minecraft:oak_planks", "minecraft:oak_planks"}
        }
    },
    
    -- Wooden Pickaxe
    ["minecraft:wooden_pickaxe"] = {
        result = "minecraft:wooden_pickaxe",
        count = 1,
        pattern = {
            {"minecraft:oak_planks", "minecraft:oak_planks", "minecraft:oak_planks"},
            {nil, "minecraft:stick", nil},
            {nil, "minecraft:stick", nil}
        }
    },
    
    -- Furnace
    ["minecraft:furnace"] = {
        result = "minecraft:furnace",
        count = 1,
        pattern = {
            {"minecraft:cobblestone", "minecraft:cobblestone", "minecraft:cobblestone"},
            {"minecraft:cobblestone", nil, "minecraft:cobblestone"},
            {"minecraft:cobblestone", "minecraft:cobblestone", "minecraft:cobblestone"}
        }
    },
    
    -- Torch
    ["minecraft:torch"] = {
        result = "minecraft:torch",
        count = 4,
        pattern = {
            {"minecraft:coal", nil, nil},
            {"minecraft:stick", nil, nil},
            {nil, nil, nil}
        }
    }
}

-- Function to get recipe by result item
function recipes.getRecipe(itemName)
    return recipes[itemName]
end

-- Function to get all recipe names
function recipes.getAllRecipeNames()
    local names = {}
    for name, _ in pairs(recipes) do
        if type(recipes[name]) == "table" then
            table.insert(names, name)
        end
    end
    table.sort(names)
    return names
end

-- Function to check if we can craft with available items
function recipes.canCraft(recipe, inventory)
    -- This will be implemented when we integrate with turtle inventory
    -- For now, just return the recipe requirements
    local required = {}
    for row = 1, 3 do
        for col = 1, 3 do
            local item = recipe.pattern[row][col]
            if item then
                required[item] = (required[item] or 0) + 1
            end
        end
    end
    return required
end

return recipes