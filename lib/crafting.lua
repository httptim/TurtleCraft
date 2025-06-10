-- Crafting Library for TurtleCraft
-- Handles turtle-side crafting operations

local crafting = {}

-- Clear all turtle inventory slots
function crafting.clearInventory(turtle)
    for slot = 1, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item then
            -- Try to drop items down (into chest or ME system)
            if not turtle.dropDown() then
                -- If can't drop down, try other directions
                if not turtle.drop() then
                    turtle.dropUp()
                end
            end
        end
    end
    turtle.select(1)
end

-- Organize items in turtle inventory according to recipe pattern
function crafting.arrangeItems(turtle, slots, items)
    -- First, clear crafting area (slots 1-3, 5-7, 9-11)
    local craftingSlots = {1, 2, 3, 5, 6, 7, 9, 10, 11}
    
    -- Move any items in crafting slots to storage slots
    for _, slot in ipairs(craftingSlots) do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item then
            -- Find empty storage slot (4, 8, 12-16)
            for storageSlot = 12, 16 do
                if turtle.transferTo(storageSlot) then
                    break
                end
            end
        end
    end
    
    -- Now place items according to recipe
    for slot, itemName in pairs(slots) do
        -- Find the item in inventory
        local found = false
        for searchSlot = 1, 16 do
            turtle.select(searchSlot)
            local item = turtle.getItemDetail()
            if item and item.name == itemName then
                -- Move one item to the crafting slot
                turtle.transferTo(slot, 1)
                found = true
                break
            end
        end
        
        if not found then
            return false, "Missing item: " .. itemName
        end
    end
    
    return true
end

-- Execute crafting operation
function crafting.craft(turtle, recipe, quantity)
    quantity = quantity or 1
    local crafted = 0
    
    -- Calculate how many batches we need
    local batchesNeeded = math.ceil(quantity / recipe.count)
    
    -- Get slot arrangement from recipe
    local slots = dofile("recipes.lua").patternToSlots(recipe.pattern, recipe.ingredients)
    
    -- Craft each batch
    for batch = 1, batchesNeeded do
        -- Arrange items
        local success, err = crafting.arrangeItems(turtle, slots, recipe.ingredients)
        if not success then
            return crafted, err
        end
        
        -- Select any slot to trigger crafting
        turtle.select(1)
        
        -- Craft
        if turtle.craft() then
            crafted = crafted + recipe.count
        else
            return crafted, "Crafting failed - check recipe"
        end
        
        -- If we have enough, stop
        if crafted >= quantity then
            break
        end
    end
    
    return crafted
end

-- Check turtle inventory for items
function crafting.getInventory(turtle)
    local inventory = {}
    
    for slot = 1, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item then
            inventory[item.name] = (inventory[item.name] or 0) + item.count
        end
    end
    
    return inventory
end

-- Request items from Jobs Computer for crafting
function crafting.requestItems(network, jobsComputerID, itemList)
    local received = {}
    
    for itemName, count in pairs(itemList) do
        -- Request each item
        network.send(jobsComputerID, "REQUEST_ITEMS", {
            item = itemName,
            count = count
        })
        
        -- Wait for response
        local timeout = os.startTimer(5)
        while true do
            local event, p1, p2, p3 = os.pullEvent()
            if event == "rednet_message" then
                local sender, message, protocol = p1, p2, p3
                if sender == jobsComputerID and message and message.type == "ITEMS_RESPONSE" then
                    os.cancelTimer(timeout)
                    if message.data.success then
                        received[itemName] = message.data.count
                    else
                        return received, "Failed to get " .. itemName .. ": " .. (message.data.error or "Unknown error")
                    end
                    break
                end
            elseif event == "timer" and p1 == timeout then
                return received, "Timeout requesting " .. itemName
            end
        end
    end
    
    return received
end

-- Deposit crafted items back to ME system
function crafting.depositItems(turtle, network, jobsComputerID)
    local deposited = {}
    
    for slot = 1, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item then
            -- Drop the items
            if turtle.dropDown(item.count) then
                -- Notify Jobs Computer
                network.send(jobsComputerID, "DEPOSIT_ITEMS", {
                    item = item.name,
                    count = item.count
                })
                
                -- Track what we deposited
                deposited[item.name] = (deposited[item.name] or 0) + item.count
                
                -- Wait for confirmation (optional)
                local timeout = os.startTimer(2)
                while true do
                    local event, p1 = os.pullEvent()
                    if event == "timer" and p1 == timeout then
                        break
                    elseif event == "rednet_message" then
                        local sender, message = p1, p2
                        if sender == jobsComputerID and message and message.type == "DEPOSIT_RESPONSE" then
                            os.cancelTimer(timeout)
                            break
                        end
                    end
                end
            end
        end
    end
    
    return deposited
end

-- Full crafting workflow
function crafting.performCraft(turtle, network, jobsComputerID, recipeName, quantity)
    -- Load recipes
    local recipes = dofile("recipes.lua")
    local recipe = recipes.get(recipeName)
    
    if not recipe then
        return false, "Recipe not found: " .. recipeName
    end
    
    print("Crafting " .. quantity .. "x " .. recipeName)
    
    -- Calculate needed ingredients
    local needed, batches = recipes.calculateIngredients(recipe, quantity)
    print("Need " .. batches .. " batches")
    
    -- Clear inventory first
    print("Clearing inventory...")
    crafting.clearInventory(turtle)
    
    -- Request ingredients
    print("Requesting ingredients...")
    local received, err = crafting.requestItems(network, jobsComputerID, needed)
    if err then
        return false, err
    end
    
    -- Wait a moment for items to arrive
    sleep(1)
    
    -- Craft the items
    print("Crafting...")
    local crafted, err = crafting.craft(turtle, recipe, quantity)
    if err then
        return false, err
    end
    
    print("Crafted " .. crafted .. " items")
    
    -- Deposit everything back
    print("Depositing items...")
    local deposited = crafting.depositItems(turtle, network, jobsComputerID)
    
    return true, crafted, deposited
end

return crafting