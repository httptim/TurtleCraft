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
        
        -- Wait for items to actually arrive in inventory
        print("Waiting for " .. count .. "x " .. itemName .. " to arrive...")
        local waitStart = os.clock()
        local itemsArrived = false
        
        while os.clock() - waitStart < 5 do  -- Wait up to 5 seconds
            -- Count how many of this item we have
            local totalCount = 0
            for slot = 1, 16 do
                local item = turtle.getItemDetail(slot)
                if item and item.name == itemName then
                    totalCount = totalCount + item.count
                end
            end
            
            if totalCount >= count then
                print("  Items arrived! Total: " .. totalCount)
                itemsArrived = true
                break
            end
            
            sleep(0.1)
        end
        
        if not itemsArrived then
            print("  WARNING: Items did not arrive in time!")
        end
    end
    
    -- Show what we received and where
    print("\nFinal inventory after all requests:")
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            print("  Slot " .. slot .. ": " .. item.name .. " x" .. item.count)
        end
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
    
    -- Show current inventory state
    print("\nCurrent inventory before arrangement:")
    local hasRequiredItems = true
    for _, itemName in pairs(recipe.ingredients) do
        local totalCount = 0
        for slot = 1, 16 do
            local item = turtle.getItemDetail(slot)
            if item and item.name == itemName then
                totalCount = totalCount + item.count
                print("  Slot " .. slot .. ": " .. item.count .. "x " .. item.name)
            end
        end
        if totalCount == 0 then
            print("  ERROR: Missing " .. itemName)
            hasRequiredItems = false
        end
    end
    
    if not hasRequiredItems then
        return false, "Missing required items for recipe"
    end
    
    -- Now arrange items for crafting
    -- For each required slot, find the item and place EXACTLY the amount needed
    for targetSlot, itemName in pairs(slots) do
        print("Need to place " .. itemName .. " in slot " .. targetSlot)
        local placed = false
        
        -- Find the item in any slot
        for searchSlot = 1, 16 do
            turtle.select(searchSlot)
            local item = turtle.getItemDetail()
            if item and item.name == itemName then
                print("  Found " .. item.name .. " in slot " .. searchSlot)
                -- Move exactly 1 item to the target slot
                if searchSlot ~= targetSlot then
                    if turtle.transferTo(targetSlot, 1) then
                        placed = true
                        print("  Transferred 1 item to slot " .. targetSlot)
                        break
                    else
                        print("  Failed to transfer!")
                    end
                else
                    -- Already in the right slot
                    placed = true
                    print("  Already in correct slot")
                    break
                end
            end
        end
        
        if not placed then
            return false, "Could not place " .. itemName .. " in slot " .. targetSlot
        end
    end
    
    -- Verify the setup and ensure only recipe slots have items
    print("Verifying crafting setup...")
    for slot = 1, 16 do
        turtle.select(slot)
        local count = turtle.getItemCount()
        if count > 0 then
            local item = turtle.getItemDetail()
            if slots[slot] then
                print("  Slot " .. slot .. ": " .. item.name .. " x" .. count .. " [RECIPE]")
                -- Make sure we have exactly 1 item in recipe slots
                if count > 1 then
                    print("  WARNING: Slot " .. slot .. " has " .. count .. " items, dropping extras")
                    turtle.drop(count - 1)
                end
            else
                print("  Slot " .. slot .. ": " .. item.name .. " x" .. count .. " [EXTRA - MUST BE REMOVED]")
                -- turtle.craft() requires ALL non-recipe slots to be empty
                -- We'll need to handle this carefully
            end
        end
    end
    
    -- Final state check
    print("Final crafting grid:")
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            print("  Slot " .. slot .. ": " .. item.name .. " x" .. item.count)
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
        
        -- Get the slots mapping for this recipe
        local recipes = dofile("recipes.lua")
        local slots = recipes.patternToSlots(recipe.pattern, recipe.ingredients)
        
        -- Find an empty slot for the craft result or select a slot with ingredients
        -- The crafted items will replace ingredients in the selected slot
        local craftSlot = nil
        for slot = 1, 16 do
            if slots[slot] then
                craftSlot = slot
                break
            end
        end
        
        if not craftSlot then
            -- No recipe slots? Use slot 1
            craftSlot = 1
        end
        
        turtle.select(craftSlot)
        print("Attempting to craft with slot " .. craftSlot .. " selected...")
        
        -- Call turtle.craft()
        local ok, err = turtle.craft()
        if ok then
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
            print("Craft failed! Error: " .. tostring(err))
            print("Current inventory:")
            for slot = 1, 16 do
                local item = turtle.getItemDetail(slot)
                if item then
                    print("  Slot " .. slot .. ": " .. item.name .. " x" .. item.count)
                end
            end
            return crafted, "Crafting failed at batch " .. batch .. ": " .. tostring(err)
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