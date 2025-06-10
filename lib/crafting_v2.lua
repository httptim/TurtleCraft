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
    
    -- First, send all item requests
    print("Sending item requests to Jobs Computer...")
    for itemName, count in pairs(itemsNeeded) do
        print("  Requesting " .. count .. "x " .. itemName)
        network.send(jobsComputerID, "REQUEST_ITEMS", {
            item = itemName,
            count = count
        })
        -- Small delay to prevent overwhelming the network
        sleep(0.1)
    end
    
    -- Wait for all responses
    local itemsToReceive = {}
    for itemName, count in pairs(itemsNeeded) do
        itemsToReceive[itemName] = count
    end
    
    local responseTimeout = os.startTimer(10)
    while next(itemsToReceive) do
        local event, p1, p2, p3 = os.pullEvent()
        if event == "timer" and p1 == responseTimeout then
            local missing = ""
            for item, _ in pairs(itemsToReceive) do
                missing = missing .. item .. ", "
            end
            return nil, "Timeout waiting for responses for: " .. missing
        elseif event == "rednet_message" then
            local sender, message = p1, p2
            if sender == jobsComputerID and message and message.type == "ITEMS_RESPONSE" then
                if message.data.success then
                    local itemName = message.data.item
                    received[itemName] = message.data.count
                    itemsToReceive[itemName] = nil
                    print("  Response received for " .. itemName)
                else
                    os.cancelTimer(responseTimeout)
                    local itemName = message.data.item or "unknown"
                    return nil, "Failed to get " .. itemName .. ": " .. (message.data.error or "Unknown")
                end
            end
        end
    end
    os.cancelTimer(responseTimeout)
    
    -- Now wait for ALL items to actually arrive in inventory
    print("\nWaiting for all items to arrive in inventory...")
    local waitStart = os.clock()
    local maxWaitTime = 10  -- 10 seconds for items to arrive
    
    local lastStatus = ""
    while os.clock() - waitStart < maxWaitTime do
        -- Check current inventory
        local currentInventory = {}
        local debugSlots = "Slot contents: "
        for slot = 1, 16 do
            local item = turtle.getItemDetail(slot)
            if item then
                currentInventory[item.name] = (currentInventory[item.name] or 0) + item.count
                debugSlots = debugSlots .. "[" .. slot .. ":" .. item.name .. "x" .. item.count .. "] "
            end
        end
        
        -- Check if we have all required items
        local allItemsPresent = true
        local status = "Current inventory:"
        for itemName, neededCount in pairs(itemsNeeded) do
            local haveCount = currentInventory[itemName] or 0
            status = status .. "\n  " .. itemName .. ": " .. haveCount .. "/" .. neededCount
            if haveCount < neededCount then
                allItemsPresent = false
            end
        end
        
        if allItemsPresent then
            print(status)
            print(debugSlots)
            print("\nAll items have arrived!")
            break
        end
        
        -- Show progress every second (but only if status changed or first time)
        local elapsed = math.floor(os.clock() - waitStart)
        if status ~= lastStatus or elapsed == 0 then
            print(status .. " (elapsed: " .. elapsed .. "s)")
            print(debugSlots)
            lastStatus = status
        end
        
        sleep(0.1)
    end
    
    -- Final inventory check and display
    local finalInventory = {}
    print("\nFinal inventory:")
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            print("  Slot " .. slot .. ": " .. item.name .. " x" .. item.count)
            finalInventory[item.name] = (finalInventory[item.name] or 0) + item.count
        end
    end
    
    -- Verify we have everything we need
    for itemName, neededCount in pairs(itemsNeeded) do
        local haveCount = finalInventory[itemName] or 0
        if haveCount < neededCount then
            return nil, "Missing items: " .. itemName .. " (have " .. haveCount .. ", need " .. neededCount .. ")"
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
    
    -- First, we need to consolidate items that might be spread across slots
    print("\nConsolidating items...")
    local itemSlots = {}  -- Track which slots contain which items
    
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            if not itemSlots[item.name] then
                itemSlots[item.name] = {}
            end
            table.insert(itemSlots[item.name], {slot = slot, count = item.count})
        end
    end
    
    -- Now arrange items for crafting
    -- For each required slot, find the item and place EXACTLY the amount needed
    for targetSlot, itemName in pairs(slots) do
        print("Need to place " .. itemName .. " in slot " .. targetSlot)
        local placed = false
        
        -- Check if target slot already has the right item
        turtle.select(targetSlot)
        local existing = turtle.getItemDetail()
        if existing and existing.name == itemName then
            print("  Slot " .. targetSlot .. " already has " .. itemName)
            placed = true
            -- Ensure we only have 1 item
            if existing.count > 1 then
                print("  Keeping only 1 item, moving " .. (existing.count - 1) .. " extras")
                -- Find empty slot for extras
                for emptySlot = 1, 16 do
                    if emptySlot ~= targetSlot and not slots[emptySlot] then
                        turtle.select(targetSlot)
                        if turtle.transferTo(emptySlot, existing.count - 1) then
                            break
                        end
                    end
                end
            end
        else
            -- Need to find and move the item
            local sourceSlots = itemSlots[itemName] or {}
            for _, source in ipairs(sourceSlots) do
                if source.slot ~= targetSlot then
                    turtle.select(source.slot)
                    if turtle.transferTo(targetSlot, 1) then
                        placed = true
                        print("  Moved 1x " .. itemName .. " from slot " .. source.slot .. " to slot " .. targetSlot)
                        break
                    end
                end
            end
        end
        
        if not placed then
            return false, "Could not place " .. itemName .. " in slot " .. targetSlot
        end
    end
    
    -- Verify the setup and clear non-recipe slots
    print("\nVerifying crafting setup and clearing non-recipe slots...")
    for slot = 1, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item then
            if slots[slot] then
                print("  Slot " .. slot .. ": " .. item.name .. " x" .. item.count .. " [RECIPE]")
                -- Make sure we have exactly 1 item in recipe slots  
                if item.count > 1 then
                    print("  WARNING: Slot " .. slot .. " has " .. item.count .. " items, need exactly 1")
                    -- Try to move extras to an empty slot first
                    local moved = false
                    for emptySlot = 1, 16 do
                        if not slots[emptySlot] and turtle.transferTo(emptySlot, item.count - 1) then
                            print("  Moved " .. (item.count - 1) .. " extras to slot " .. emptySlot)
                            moved = true
                            break
                        end
                    end
                    if not moved then
                        -- No space, we'll have to drop them temporarily
                        print("  No empty slots, dropping " .. (item.count - 1) .. " extras")
                        turtle.drop(item.count - 1)
                    end
                end
            else
                print("  Slot " .. slot .. ": " .. item.name .. " x" .. item.count .. " [EXTRA - CLEARING]")
                -- This slot shouldn't have items for crafting
                -- Try to consolidate with other slots first
                local consolidated = false
                for targetSlot = 1, 16 do
                    if targetSlot ~= slot and not slots[targetSlot] then
                        local targetItem = turtle.getItemDetail(targetSlot)
                        if targetItem and targetItem.name == item.name then
                            if turtle.transferTo(targetSlot) then
                                print("  Consolidated with slot " .. targetSlot)
                                consolidated = true
                                break
                            end
                        elseif not targetItem then
                            if turtle.transferTo(targetSlot) then
                                print("  Moved to empty slot " .. targetSlot)
                                consolidated = true
                                break
                            end
                        end
                    end
                end
                if not consolidated then
                    -- No space, drop temporarily
                    print("  No space to consolidate, dropping items")
                    turtle.drop()
                end
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