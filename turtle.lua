-- Simple Crafting Turtle with Recipes

-- Load config or use defaults
local config
if fs.exists("config.lua") then
    config = dofile("config.lua")
else
    -- Use default config if file doesn't exist
    config = {
        PROTOCOL = "turtlecraft",
        HEARTBEAT_INTERVAL = 30,
        DEBUG = false
    }
end

local ITEM_WAIT_TIME = 15  -- Max seconds to wait for items

-- State
local jobsComputerId = nil
local running = true
local peripheralName = nil

-- Recipes (add more as needed)
local recipes = {
    ["minecraft:stick"] = {
        name = "Stick",
        result = {item = "minecraft:stick", count = 4},
        ingredients = {
            {item = "minecraft:oak_planks", count = 1, slot = 2},
            {item = "minecraft:oak_planks", count = 1, slot = 6}
        }
    },
    ["minecraft:oak_planks"] = {
        name = "Oak Planks",
        result = {item = "minecraft:oak_planks", count = 4},
        ingredients = {
            {item = "minecraft:oak_log", count = 1, slot = 1}
        }
    },
    ["minecraft:crafting_table"] = {
        name = "Crafting Table",
        result = {item = "minecraft:crafting_table", count = 1},
        ingredients = {
            {item = "minecraft:oak_planks", count = 1, slot = 1},
            {item = "minecraft:oak_planks", count = 1, slot = 2},
            {item = "minecraft:oak_planks", count = 1, slot = 5},
            {item = "minecraft:oak_planks", count = 1, slot = 6}
        }
    },
    ["minecraft:chest"] = {
        name = "Chest",
        result = {item = "minecraft:chest", count = 1},
        ingredients = {
            {item = "minecraft:oak_planks", count = 1, slot = 1},
            {item = "minecraft:oak_planks", count = 1, slot = 2},
            {item = "minecraft:oak_planks", count = 1, slot = 3},
            {item = "minecraft:oak_planks", count = 1, slot = 5},
            {item = "minecraft:oak_planks", count = 1, slot = 7},
            {item = "minecraft:oak_planks", count = 1, slot = 9},
            {item = "minecraft:oak_planks", count = 1, slot = 10},
            {item = "minecraft:oak_planks", count = 1, slot = 11}
        }
    }
}

-- Initialize
print("Simple Crafting Turtle Starting...")
print("Turtle ID: " .. os.getComputerID())

-- Open rednet
peripheral.find("modem", rednet.open)

-- Helper functions
local function clear()
    term.clear()
    term.setCursorPos(1, 1)
end

-- Clear inventory
local function clearInventory()
    for slot = 1, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item then
            turtle.drop()
        end
    end
    turtle.select(1)
end

-- Count items in inventory
local function countItem(itemName)
    local count = 0
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item and item.name == itemName then
            count = count + item.count
        end
    end
    return count
end

-- Find and register with Jobs Computer
local function findJobsComputer()
    print("Looking for Jobs Computer...")
    
    while not jobsComputerId do
        local id = rednet.lookup(config.PROTOCOL, "jobs")
        if id then
            print("Found Jobs Computer at ID " .. id)
            rednet.send(id, {type = "REGISTER"}, config.PROTOCOL)
            
            local sender, msg = rednet.receive(config.PROTOCOL, 5)
            if sender == id and msg and msg.type == "REGISTER_ACK" then
                jobsComputerId = id
                print("Registered successfully!")
                break
            end
        end
        
        print("Retrying in 5 seconds...")
        sleep(5)
    end
end

-- Handle identify request
local function handleIdentify(sender, message)
    if message.peripheralName then
        -- Check if this peripheral could be us
        local myPeripheral = peripheral.wrap(message.peripheralName)
        if myPeripheral and peripheral.getType(message.peripheralName) == "turtle" then
            peripheralName = message.peripheralName
            rednet.send(sender, {
                type = "IDENTIFY_RESPONSE",
                peripheralName = peripheralName
            }, config.PROTOCOL)
            print("Identified as: " .. peripheralName)
        end
    end
end

-- Send heartbeat
local function sendHeartbeat()
    if jobsComputerId then
        rednet.send(jobsComputerId, {type = "HEARTBEAT"}, config.PROTOCOL)
    end
end

-- Request items and wait for them to arrive
local function requestAndWaitForItems(itemName, count)
    print("\nRequesting " .. count .. "x " .. itemName)
    
    -- Check current inventory
    local startCount = countItem(itemName)
    print("Current inventory: " .. startCount)
    
    -- Send request
    rednet.send(jobsComputerId, {
        type = "REQUEST_ITEMS",
        item = itemName,
        count = count
    }, config.PROTOCOL)
    
    -- Wait for response
    local sender, response = rednet.receive(config.PROTOCOL, 10)
    if not (sender == jobsComputerId and response and response.type == "ITEMS_RESPONSE") then
        print("No response from Jobs Computer")
        return false
    end
    
    if not response.success then
        print("Request failed: " .. (response.error or "Unknown error"))
        return false
    end
    
    print("Jobs Computer sent " .. response.count .. " items")
    
    -- Now wait for items to actually arrive in inventory
    local targetCount = startCount + response.count
    local waitStart = os.clock()
    
    print("Waiting for items to arrive...")
    while os.clock() - waitStart < ITEM_WAIT_TIME do
        local currentCount = countItem(itemName)
        
        if currentCount >= targetCount then
            print("Items received! Total: " .. currentCount)
            return true
        end
        
        -- Show progress
        if math.floor(os.clock() - waitStart) % 2 == 0 then
            print("Still waiting... Current: " .. currentCount .. "/" .. targetCount)
        end
        
        sleep(0.5)
    end
    
    local finalCount = countItem(itemName)
    print("Timeout! Only received: " .. finalCount .. "/" .. targetCount)
    return finalCount > startCount  -- Return true if we got any items
end

-- Return items to ME system
local function returnItems()
    print("\nReturning items to ME system...")
    
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            turtle.select(slot)
            rednet.send(jobsComputerId, {
                type = "PULL_ITEMS",
                item = item.name,
                count = item.count
            }, config.PROTOCOL)
            
            -- Wait a bit for the pull
            sleep(0.5)
        end
    end
    
    turtle.select(1)
end

-- Craft an item
local function craftItem(recipeName, quantity)
    local recipe = recipes[recipeName]
    if not recipe then
        print("Unknown recipe: " .. recipeName)
        return false
    end
    
    quantity = quantity or 1
    local batches = math.ceil(quantity / recipe.result.count)
    
    print("\n=== Crafting " .. recipe.name .. " x" .. quantity .. " ===")
    print("Will craft " .. batches .. " batches")
    
    -- Clear inventory first
    returnItems()
    
    for batch = 1, batches do
        print("\n--- Batch " .. batch .. "/" .. batches .. " ---")
        
        -- Request all ingredients
        local ingredients = {}
        for _, ing in ipairs(recipe.ingredients) do
            local itemName = ing.item
            if not ingredients[itemName] then
                ingredients[itemName] = 0
            end
            ingredients[itemName] = ingredients[itemName] + ing.count
        end
        
        -- Request each unique ingredient
        local allReceived = true
        for itemName, totalCount in pairs(ingredients) do
            if not requestAndWaitForItems(itemName, totalCount) then
                allReceived = false
                break
            end
        end
        
        if not allReceived then
            print("Failed to get all ingredients!")
            returnItems()
            return false
        end
        
        -- Arrange items in crafting grid
        print("\nArranging items...")
        for _, ing in ipairs(recipe.ingredients) do
            -- Find the item in inventory
            for invSlot = 1, 16 do
                local item = turtle.getItemDetail(invSlot)
                if item and item.name == ing.item then
                    turtle.select(invSlot)
                    turtle.transferTo(ing.slot, ing.count)
                    break
                end
            end
        end
        
        -- Craft
        print("Crafting...")
        turtle.select(1)
        if turtle.craft() then
            print("Success!")
        else
            print("Craft failed!")
            returnItems()
            return false
        end
    end
    
    -- Return results
    sleep(1)
    returnItems()
    
    return true
end

-- Show menu
local function showMenu()
    clear()
    print("=== Simple Crafting Turtle ===")
    print()
    print("Turtle ID: " .. os.getComputerID())
    print("Jobs Computer: " .. (jobsComputerId and ("Connected #" .. jobsComputerId) or "Not Connected"))
    if peripheralName then
        print("Peripheral: " .. peripheralName)
    end
    print()
    print("Recipes:")
    local i = 1
    for id, recipe in pairs(recipes) do
        print("  " .. i .. ". " .. recipe.name)
        i = i + 1
    end
    print()
    print("Commands:")
    print("  1-9 - Craft recipe")
    print("  R - Return all items")
    print("  Q - Quit")
end

-- Main loop
local function main()
    findJobsComputer()
    
    -- Start heartbeat
    local heartbeatTimer = os.startTimer(config.HEARTBEAT_INTERVAL)
    
    while running do
        showMenu()
        
        local event, param, param2 = os.pullEvent()
        
        if event == "timer" and param == heartbeatTimer then
            sendHeartbeat()
            heartbeatTimer = os.startTimer(config.HEARTBEAT_INTERVAL)
            
        elseif event == "rednet_message" and param == jobsComputerId then
            local message = param2
            if message and message.type == "IDENTIFY" then
                handleIdentify(param, message)
            end
            
        elseif event == "key" then
            if param == keys.q then
                running = false
                
            elseif param == keys.r then
                returnItems()
                print("\nPress any key...")
                os.pullEvent("key")
                
            elseif param >= keys.one and param <= keys.nine then
                local index = param - keys.one + 1
                local recipeList = {}
                for id, recipe in pairs(recipes) do
                    table.insert(recipeList, id)
                end
                
                if index <= #recipeList then
                    clear()
                    print("How many to craft? ")
                    local amount = tonumber(read()) or 1
                    
                    craftItem(recipeList[index], amount)
                    print("\nPress any key...")
                    os.pullEvent("key")
                end
            end
        end
    end
    
    clear()
    print("Shutting down...")
    returnItems()
end

-- Run
main()