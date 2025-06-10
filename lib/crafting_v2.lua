-- Simplified Crafting Library for TurtleCraft
-- Cleaner implementation with better error handling

local crafting_v2 = {}

-- Get turtle's current inventory
function crafting_v2.getInventory()
    local inventory = {}
    for slot = 1, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item then
            inventory[slot] = {
                name = item.name,
                count = item.count
            }
        end
    end
    return inventory
end

-- Clear turtle inventory by requesting Jobs Computer to pull everything
function crafting_v2.clearInventory(network, jobsComputerID)
    print("Clearing inventory...")
    local inventory = crafting_v2.getInventory()
    
    for slot, item in pairs(inventory) do
        turtle.select(slot)
        
        -- Request Jobs Computer to pull this item
        network.send(jobsComputerID, "PULL_ITEM", {
            slot = slot,
            item = item.name,
            count = item.count
        })
        
        -- Wait for confirmation
        local timeout = os.startTimer(3)
        while true do
            local event, p1, p2, p3 = os.pullEvent()
            if event == "timer" and p1 == timeout then
                print("Timeout pulling item from slot " .. slot)
                break
            elseif event == "rednet_message" then
                local sender, message = p1, p2
                if sender == jobsComputerID and message and message.type == "PULL_RESPONSE" then
                    os.cancelTimer(timeout)
                    if not message.data.success then
                        print("Failed to pull: " .. (message.data.error or "Unknown"))
                    end
                    break
                end
            end
        end
    end
    
    turtle.select(1)
end

-- Request specific items from Jobs Computer
function crafting_v2.requestItems(network, jobsComputerID, itemsNeeded)
    local received = {}
    
    for itemName, count in pairs(itemsNeeded) do
        print("Requesting " .. count .. "x " .. itemName .. "...")
        
        network.send(jobsComputerID, "REQUEST_ITEMS", {
            item = itemName,
            count = count
        })
        
        -- Wait for response
        local timeout = os.startTimer(10)
        local success = false
        
        while not success do
            local event, p1, p2, p3 = os.pullEvent()
            if event == "timer" and p1 == timeout then
                return nil, "Timeout waiting for " .. itemName
            elseif event == "rednet_message" then
                local sender, message = p1, p2
                if sender == jobsComputerID and message and message.type == "ITEMS_RESPONSE" then
                    os.cancelTimer(timeout)
                    if message.data.success then
                        received[itemName] = message.data.count
                        success = true
                    else
                        return nil, "Failed to get " .. itemName .. ": " .. (message.data.error or "Unknown")
                    end
                end
            end
        end
        
        -- Give time for items to arrive
        sleep(0.5)
    end
    
    return received
end

-- Arrange items in crafting grid
function crafting_v2.arrangeCraftingGrid(recipe)
    local recipes = dofile("recipes.lua")
    local slots = recipes.patternToSlots(recipe.pattern, recipe.ingredients)
    
    print("Arranging items for recipe:")
    print("Pattern slots needed:")
    for slot, item in pairs(slots) do
        print("  Slot " .. slot .. ": " .. item)
    end
    
    -- First, move everything to storage area (slots 12-16)
    for slot = 1, 11 do
        turtle.select(slot)
        if turtle.getItemCount() > 0 then
            for storage = 12, 16 do
                if turtle.transferTo(storage) then
                    break
                end
            end
        end
    end
    
    -- Now place items according to pattern
    for targetSlot, itemName in pairs(slots) do
        local placed = false
        
        -- Find the item in inventory
        for searchSlot = 1, 16 do
            turtle.select(searchSlot)
            local item = turtle.getItemDetail()
            if item and item.name == itemName then
                -- Transfer one to the target slot
                if turtle.transferTo(targetSlot, 1) then
                    placed = true
                    print("Placed " .. itemName .. " in slot " .. targetSlot)
                    break
                end
            end
        end
        
        if not placed then
            return false, "Could not place " .. itemName .. " in slot " .. targetSlot
        end
    end
    
    -- Show final grid state
    print("Final crafting grid:")
    for slot = 1, 11 do
        if slot == 4 or slot == 8 then
            -- Skip slots 4 and 8 (not part of crafting grid)
        else
            turtle.select(slot)
            local count = turtle.getItemCount()
            if count > 0 then
                local item = turtle.getItemDetail()
                print("  Slot " .. slot .. ": " .. (item and item.name or "unknown") .. " x" .. count)
            end
        end
    end
    
    return true
end

-- Perform the actual crafting
function crafting_v2.craft(recipe, quantity)
    local crafted = 0
    local batches = math.ceil(quantity / recipe.count)
    
    print("Crafting " .. batches .. " batch(es)...")
    
    for batch = 1, batches do
        -- Arrange the grid
        local success, err = crafting_v2.arrangeCraftingGrid(recipe)
        if not success then
            return crafted, err
        end
        
        -- Select slot 1 and craft
        turtle.select(1)
        print("Attempting to craft...")
        if turtle.craft() then
            crafted = crafted + recipe.count
            print("Batch " .. batch .. " complete (" .. recipe.count .. " items)")
            
            -- Show what's in inventory after crafting
            print("After crafting:")
            for slot = 1, 16 do
                local item = turtle.getItemDetail(slot)
                if item then
                    print("  Slot " .. slot .. ": " .. item.name .. " x" .. item.count)
                end
            end
        else
            print("Craft failed! Current inventory:")
            for slot = 1, 16 do
                local item = turtle.getItemDetail(slot)
                if item then
                    print("  Slot " .. slot .. ": " .. item.name .. " x" .. item.count)
                end
            end
            return crafted, "Crafting failed at batch " .. batch
        end
    end
    
    return crafted
end

-- Return all items to ME system
function crafting_v2.returnItems(network, jobsComputerID)
    print("Returning items to ME...")
    local returned = {}
    
    for slot = 1, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item then
            -- Tell Jobs Computer to pull this item
            network.send(jobsComputerID, "PULL_ITEM", {
                slot = slot,
                item = item.name,
                count = item.count
            })
            
            -- Wait for confirmation
            local timeout = os.startTimer(3)
            while true do
                local event, p1, p2 = os.pullEvent()
                if event == "timer" and p1 == timeout then
                    print("Timeout returning " .. item.name)
                    break
                elseif event == "rednet_message" then
                    local sender, message = p1, p2
                    if sender == jobsComputerID and message and message.type == "PULL_RESPONSE" then
                        os.cancelTimer(timeout)
                        if message.data.success then
                            returned[item.name] = (returned[item.name] or 0) + item.count
                        end
                        break
                    end
                end
            end
        end
    end
    
    return returned
end

-- Main crafting workflow
function crafting_v2.performCraft(network, jobsComputerID, recipeName, quantity)
    print("\n=== Starting Craft Job ===")
    print("Recipe: " .. recipeName)
    print("Quantity: " .. quantity)
    
    -- Load recipe
    local recipes = dofile("recipes.lua")
    local recipe = recipes.get(recipeName)
    if not recipe then
        return false, "Recipe not found: " .. recipeName
    end
    
    -- Calculate what we need
    local needed, batches = recipes.calculateIngredients(recipe, quantity)
    print("Batches needed: " .. batches)
    print("\nIngredients required:")
    for item, count in pairs(needed) do
        print("  " .. item .. " x" .. count)
    end
    
    -- Step 1: Clear inventory
    crafting_v2.clearInventory(network, jobsComputerID)
    
    -- Step 2: Request items
    local received, err = crafting_v2.requestItems(network, jobsComputerID, needed)
    if not received then
        return false, err
    end
    
    -- Step 3: Craft
    local crafted, err = crafting_v2.craft(recipe, quantity)
    if crafted == 0 then
        return false, err
    end
    
    -- Give a moment for items to settle
    sleep(0.5)
    
    -- Step 4: Return everything to ME
    print("\nReturning all items to ME system...")
    local returned = crafting_v2.returnItems(network, jobsComputerID)
    
    print("\n=== Craft Job Complete ===")
    print("Crafted: " .. crafted .. " items")
    
    return true, crafted, returned
end

return crafting_v2