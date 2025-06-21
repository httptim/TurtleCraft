-- Turtle client for TurtleCraft
-- Handles crafting operations and communication

local network = require("lib.network")
local recipes = require("recipes")

local COMPUTER_TYPE = "turtle"
local turtleName = "Turtle_" .. os.getComputerID()
local jobsComputerId = nil
local status = "idle"

-- Register with Jobs Computer
local function registerWithJobs()
    print("Searching for Jobs Computer...")
    
    -- Discover Jobs Computers
    local jobsComputers = network.discover("jobs", 5)
    
    if #jobsComputers == 0 then
        printError("[X] No Jobs Computer found")
        return false
    end
    
    -- Register with first Jobs Computer found
    local jobs = jobsComputers[1]
    print("Found Jobs Computer ID: " .. jobs.id)
    
    -- Send registration message directly without waiting for ack
    local message = {
        type = "register",
        data = {
            name = turtleName,
            fuelLevel = turtle.getFuelLevel(),
            hasWiredModem = peripheral.find("modem", function(name, m) return not m.isWireless() end) ~= nil
        },
        sender = os.getComputerID(),
        timestamp = os.time()
    }
    
    rednet.send(jobs.id, message, "crafting_system")
    
    -- Wait for registration confirmation
    local senderId, response = rednet.receive("crafting_system", 10)
    
    if senderId == jobs.id and response and response.type == "register_confirm" and response.data.success then
        jobsComputerId = jobs.id
        print("[OK] Registered with Jobs Computer")
        return true
    else
        printError("[X] Failed to register")
        return false
    end
end

-- Send heartbeat to Jobs Computer
local function sendHeartbeat()
    if jobsComputerId then
        -- Send heartbeat directly without waiting for ACK
        local message = {
            type = "heartbeat",
            data = {
                status = status,
                fuelLevel = turtle.getFuelLevel()
            },
            sender = os.getComputerID(),
            timestamp = os.time()
        }
        rednet.send(jobsComputerId, message, "crafting_system")
    end
end

-- Check inventory for items
local function getInventoryCount()
    local count = 0
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            count = count + item.count
        end
    end
    return count
end

-- Get inventory details
local function getInventory()
    local inventory = {}
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            inventory[slot] = item
        end
    end
    return inventory
end

-- Find item in inventory
local function findItem(itemName)
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item and item.name == itemName then
            return slot, item.count
        end
    end
    return nil, 0
end

-- Arrange items for crafting
local function arrangeItemsForCrafting(recipe)
    -- IMPORTANT: Turtle can only craft if it has EXACTLY the recipe items, nothing extra!
    -- First, we need to temporarily store ALL items
    
    -- Count required items
    local requiredItems = {}
    for row = 1, 3 do
        for col = 1, 3 do
            local item = recipe.pattern[row][col]
            if item then
                requiredItems[item] = (requiredItems[item] or 0) + 1
            end
        end
    end
    
    -- Store all current items and their locations
    local inventory = {}
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            if not inventory[item.name] then
                inventory[item.name] = {}
            end
            table.insert(inventory[item.name], {slot = slot, count = item.count})
        end
    end
    
    -- Check if we have required items
    for itemName, requiredCount in pairs(requiredItems) do
        local available = 0
        if inventory[itemName] then
            for _, info in ipairs(inventory[itemName]) do
                available = available + info.count
            end
        end
        if available < requiredCount then
            return false, "Need " .. requiredCount .. " " .. itemName .. ", have " .. available
        end
    end
    
    -- Clear ALL slots first by dropping extra items
    -- We'll pick them up after crafting
    print("Dropping extra items...")
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            local isRequired = requiredItems[item.name] and requiredItems[item.name] > 0
            if not isRequired then
                -- Drop items we don't need for this recipe
                turtle.select(slot)
                turtle.drop()  -- Drop in front
            end
        end
    end
    
    -- Now arrange ONLY the required items in the crafting grid
    -- Crafting grid slots: 1-3, 5-7, 9-11
    local slotMap = {
        {slot = 1, row = 1, col = 1}, {slot = 2, row = 1, col = 2}, {slot = 3, row = 1, col = 3},
        {slot = 5, row = 2, col = 1}, {slot = 6, row = 2, col = 2}, {slot = 7, row = 2, col = 3},
        {slot = 9, row = 3, col = 1}, {slot = 10, row = 3, col = 2}, {slot = 11, row = 3, col = 3}
    }
    
    -- Place items in correct positions
    local itemsPlaced = {}
    for _, mapping in ipairs(slotMap) do
        local requiredItem = recipe.pattern[mapping.row][mapping.col]
        if requiredItem then
            -- Find the item and move exactly 1 to the correct slot
            local placed = false
            for slot = 1, 16 do
                if not placed then
                    local item = turtle.getItemDetail(slot)
                    if item and item.name == requiredItem and (not itemsPlaced[requiredItem] or itemsPlaced[requiredItem] < requiredItems[requiredItem]) then
                        turtle.select(slot)
                        if slot ~= mapping.slot then
                            turtle.transferTo(mapping.slot, 1)
                        elseif item.count > 1 then
                            -- If item is already in correct slot but has more than 1, move extras
                            turtle.transferTo(16, item.count - 1)
                        end
                        itemsPlaced[requiredItem] = (itemsPlaced[requiredItem] or 0) + 1
                        placed = true
                    end
                end
            end
            
            if not placed then
                return false, "Failed to place " .. requiredItem
            end
        end
    end
    
    -- Drop any remaining items that aren't in the crafting grid
    for slot = 1, 16 do
        -- Skip crafting grid slots
        local isCraftingSlot = false
        for _, mapping in ipairs(slotMap) do
            if mapping.slot == slot then
                isCraftingSlot = true
                break
            end
        end
        
        if not isCraftingSlot and turtle.getItemCount(slot) > 0 then
            turtle.select(slot)
            turtle.drop()
        end
    end
    
    return true
end

-- Execute crafting
local function executeCraft(recipeName)
    local recipe = recipes.getRecipe(recipeName)
    if not recipe then
        return false, "Recipe not found: " .. recipeName
    end
    
    -- Update status
    status = "crafting"
    
    -- Debug: Print recipe pattern
    print("Recipe pattern for " .. recipeName .. ":")
    for row = 1, 3 do
        local rowStr = ""
        for col = 1, 3 do
            if recipe.pattern[row][col] then
                rowStr = rowStr .. "[X]"
            else
                rowStr = rowStr .. "[ ]"
            end
        end
        print(rowStr)
    end
    
    -- Arrange items
    local success, err = arrangeItemsForCrafting(recipe)
    if not success then
        status = "idle"
        return false, err
    end
    
    -- Find an empty slot for output (prefer slot 4, then 8, then 12-16)
    local outputSlot = nil
    for _, slot in ipairs({4, 8, 12, 13, 14, 15, 16}) do
        if turtle.getItemCount(slot) == 0 then
            outputSlot = slot
            break
        end
    end
    
    if not outputSlot then
        status = "idle"
        return false, "No empty slot for crafting output"
    end
    
    -- Select the output slot
    turtle.select(outputSlot)
    print("Output slot: " .. outputSlot)
    
    -- Craft the item
    local craftSuccess = turtle.craft()
    
    -- Pick up dropped items regardless of success
    print("Picking up dropped items...")
    turtle.suck()  -- Pick up items in front
    
    status = "idle"
    
    if craftSuccess then
        return true, "Crafted " .. recipe.count .. "x " .. recipe.result
    else
        -- Debug: Show current inventory arrangement
        print("Current crafting grid:")
        for _, slot in ipairs({1, 2, 3, 5, 6, 7, 9, 10, 11}) do
            local item = turtle.getItemDetail(slot)
            if item then
                print("Slot " .. slot .. ": " .. item.name .. " x" .. item.count)
            else
                print("Slot " .. slot .. ": empty")
            end
        end
        return false, "Crafting failed - check recipe arrangement"
    end
end

-- Main program
local function main()
    term.clear()
    term.setCursorPos(1, 1)
    print("=== TurtleCraft Turtle ===")
    print("ID: " .. os.getComputerID())
    print("Name: " .. turtleName)
    print()
    
    -- Initialize network
    if not network.initialize(COMPUTER_TYPE) then
        printError("Failed to initialize network")
        return
    end
    
    -- Check fuel
    if turtle.getFuelLevel() == 0 then
        printError("[!] Warning: No fuel!")
        print("Please add fuel to slot 1 and press any key")
        os.pullEvent("key")
        turtle.select(1)
        turtle.refuel()
    end
    print("Fuel: " .. turtle.getFuelLevel())
    
    -- Register with Jobs Computer
    local registered = false
    local retryCount = 0
    while not registered and retryCount < 3 do
        registered = registerWithJobs()
        if not registered then
            retryCount = retryCount + 1
            print("Retrying in 5 seconds... (" .. retryCount .. "/3)")
            sleep(5)
        end
    end
    
    if not registered then
        printError("Failed to register after 3 attempts")
        return
    end
    
    print("\nRunning... Press Q to quit")
    print("Status: " .. status)
    
    -- Main event loop
    local heartbeatTimer = os.startTimer(10)
    
    while true do
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "rednet_message" then
            local senderId, message = p1, p2
            if message and type(message) == "table" then
                -- Always handle discovery requests
                local discoveryHandler = network.handleDiscovery(COMPUTER_TYPE, turtleName)
                discoveryHandler(senderId, message)
                
                -- Handle commands from Jobs Computer (only if registered)
                if senderId == jobsComputerId then
                    if message.type == "ping" then
                        -- Send pong directly
                        local response = {
                            type = "pong",
                            data = {
                                status = status,
                                fuelLevel = turtle.getFuelLevel(),
                                itemCount = getInventoryCount()
                            },
                            sender = os.getComputerID(),
                            timestamp = os.time()
                        }
                        rednet.send(senderId, response, "crafting_system")
                elseif message.type == "status_request" then
                    -- Send status directly
                    local response = {
                        type = "status_response",
                        data = {
                            status = status,
                            fuelLevel = turtle.getFuelLevel(),
                            itemCount = getInventoryCount()
                        },
                        sender = os.getComputerID(),
                        timestamp = os.time()
                    }
                    rednet.send(senderId, response, "crafting_system")
                elseif message.type == "craft_request" then
                    print("Received craft request: " .. (message.data.recipe or "unknown"))
                    local success, result = executeCraft(message.data.recipe)
                    
                    -- Send response directly without waiting for ACK
                    local response = {
                        type = "craft_response",
                        data = {
                            success = success,
                            message = result,
                            recipe = message.data.recipe,
                            requestId = message.data.requestId
                        },
                        sender = os.getComputerID(),
                        timestamp = os.time()
                    }
                    rednet.send(senderId, response, "crafting_system")
                    
                    if success then
                        print("[OK] " .. result)
                    else
                        print("[X] " .. result)
                    end
                end
            end
        elseif event == "timer" and p1 == heartbeatTimer then
            -- Send heartbeat
            sendHeartbeat()
            heartbeatTimer = os.startTimer(10)
        elseif event == "key" then
            local key = p1
            if key == keys.q then
                print("\nShutting down...")
                if jobsComputerId then
                    -- Send unregister directly
                    local message = {
                        type = "unregister",
                        data = {
                            reason = "shutdown"
                        },
                        sender = os.getComputerID(),
                        timestamp = os.time()
                    }
                    rednet.send(jobsComputerId, message, "crafting_system")
                end
                break
            end
        end
        end
    end
end

-- Run main program
main()
