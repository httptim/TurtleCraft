-- Recipe Definitions for TurtleCraft
-- Defines crafting recipes in a format that turtles can execute

local recipes = {}

-- Recipe format:
-- {
--     result = "item_name",
--     count = number,
--     pattern = {
--         "ABC",
--         "DEF", 
--         "GHI"
--     },
--     ingredients = {
--         A = "item_name" or nil,
--         B = "item_name" or nil,
--         ...
--     }
-- }
-- Pattern maps to turtle inventory slots:
-- 1 2 3
-- 5 6 7
-- 9 10 11

-- Basic recipes for testing

-- Planks from logs
recipes["minecraft:oak_planks"] = {
    result = "minecraft:oak_planks",
    count = 4,
    pattern = {
        "A  ",
        "   ",
        "   "
    },
    ingredients = {
        A = "minecraft:oak_log"
    }
}

-- Sticks from planks
recipes["minecraft:stick"] = {
    result = "minecraft:stick",
    count = 4,
    pattern = {
        "A  ",
        "A  ",
        "   "
    },
    ingredients = {
        A = "minecraft:oak_planks"
    }
}

-- Crafting table
recipes["minecraft:crafting_table"] = {
    result = "minecraft:crafting_table",
    count = 1,
    pattern = {
        "AA ",
        "AA ",
        "   "
    },
    ingredients = {
        A = "minecraft:oak_planks"
    }
}

-- Chest
recipes["minecraft:chest"] = {
    result = "minecraft:chest",
    count = 1,
    pattern = {
        "AAA",
        "A A",
        "AAA"
    },
    ingredients = {
        A = "minecraft:oak_planks"
    }
}

-- Furnace
recipes["minecraft:furnace"] = {
    result = "minecraft:furnace",
    count = 1,
    pattern = {
        "AAA",
        "A A",
        "AAA"
    },
    ingredients = {
        A = "minecraft:cobblestone"
    }
}

-- Torch
recipes["minecraft:torch"] = {
    result = "minecraft:torch",
    count = 4,
    pattern = {
        "A  ",
        "B  ",
        "   "
    },
    ingredients = {
        A = "minecraft:coal",
        B = "minecraft:stick"
    }
}

-- Stone pickaxe
recipes["minecraft:stone_pickaxe"] = {
    result = "minecraft:stone_pickaxe",
    count = 1,
    pattern = {
        "AAA",
        " B ",
        " B "
    },
    ingredients = {
        A = "minecraft:cobblestone",
        B = "minecraft:stick"
    }
}

-- Iron ingot (for testing - normally smelted)
-- This is just for testing crafting, not a real recipe
recipes["minecraft:iron_ingot"] = {
    result = "minecraft:iron_ingot", 
    count = 9,
    pattern = {
        "A  ",
        "   ",
        "   "
    },
    ingredients = {
        A = "minecraft:iron_block"
    }
}

-- Hopper
recipes["minecraft:hopper"] = {
    result = "minecraft:hopper",
    count = 1,
    pattern = {
        "A A",
        "ABA",
        " A "
    },
    ingredients = {
        A = "minecraft:iron_ingot",
        B = "minecraft:chest"
    }
}

-- Helper functions

-- Get recipe by result item
function recipes.get(itemName)
    return recipes[itemName]
end

-- Get all recipes that produce a specific item
function recipes.findByResult(itemName)
    local found = {}
    for name, recipe in pairs(recipes) do
        if type(recipe) == "table" and recipe.result == itemName then
            table.insert(found, recipe)
        end
    end
    return found
end

-- Get all recipes that use a specific ingredient
function recipes.findByIngredient(itemName)
    local found = {}
    for name, recipe in pairs(recipes) do
        if type(recipe) == "table" and recipe.ingredients then
            for _, ingredient in pairs(recipe.ingredients) do
                if ingredient == itemName then
                    table.insert(found, recipe)
                    break
                end
            end
        end
    end
    return found
end

-- Convert pattern to slot assignments
function recipes.patternToSlots(pattern, ingredients)
    local slots = {}
    local slotMap = {
        -- Row 1
        {1, 2, 3},
        -- Row 2  
        {5, 6, 7},
        -- Row 3
        {9, 10, 11}
    }
    
    for row = 1, 3 do
        local rowPattern = pattern[row] or "   "
        for col = 1, 3 do
            local char = rowPattern:sub(col, col)
            if char ~= " " and ingredients[char] then
                local slot = slotMap[row][col]
                slots[slot] = ingredients[char]
            end
        end
    end
    
    return slots
end

-- Calculate total ingredients needed
function recipes.calculateIngredients(recipe, quantity)
    local needed = {}
    quantity = quantity or 1
    local batches = math.ceil(quantity / recipe.count)
    
    -- Count each ingredient
    for row = 1, 3 do
        local rowPattern = recipe.pattern[row] or "   "
        for col = 1, 3 do
            local char = rowPattern:sub(col, col)
            if char ~= " " and recipe.ingredients[char] then
                local item = recipe.ingredients[char]
                needed[item] = (needed[item] or 0) + batches
            end
        end
    end
    
    return needed, batches
end

-- Check if recipe can be crafted with available items
function recipes.canCraft(recipe, available)
    local needed = recipes.calculateIngredients(recipe, 1)
    
    for item, count in pairs(needed) do
        if not available[item] or available[item] < count then
            return false, item, count - (available[item] or 0)
        end
    end
    
    return true
end

return recipes