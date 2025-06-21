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
        network.send(jobsComputerId, "heartbeat", {
            status = status,
            fuelLevel = turtle.getFuelLevel()
        })
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
    -- In CC:Tweaked, crafting grid is slots 1-9 (3x3 grid)
    -- Storage slots are 10-16
    local craftingSlots = {1, 2, 3, 4, 5, 6, 7, 8, 9}
    
    -- First, move any items in crafting slots to storage slots
    for _, slot in ipairs(craftingSlots) do
        if turtle.getItemCount(slot) > 0 then
            turtle.select(slot)
            for storageSlot = 10, 16 do
                if turtle.transferTo(storageSlot) then
                    break
                end
            end
        end
    end
    
    -- Map recipe pattern positions to turtle inventory slots
    -- Recipe pattern: row 1-3, col 1-3
    -- Turtle slots: 1 2 3
    --               4 5 6  
    --               7 8 9
    local slotMap = {
        [1] = {1, 1}, [2] = {1, 2}, [3] = {1, 3},
        [4] = {2, 1}, [5] = {2, 2}, [6] = {2, 3},
        [7] = {3, 1}, [8] = {3, 2}, [9] = {3, 3}
    }
    
    -- Place items according to recipe
    for slot = 1, 9 do
        local row, col = slotMap[slot][1], slotMap[slot][2]
        local requiredItem = recipe.pattern[row][col]
        
        if requiredItem then
            -- Find the item in inventory (only check storage slots)
            local sourceSlot = nil
            for checkSlot = 10, 16 do
                local item = turtle.getItemDetail(checkSlot)
                if item and item.name == requiredItem then
                    sourceSlot = checkSlot
                    break
                end
            end
            
            if sourceSlot then
                turtle.select(sourceSlot)
                turtle.transferTo(slot, 1)  -- Transfer 1 item
            else
                -- Try to find in crafting slots that we haven't used yet
                for checkSlot = slot + 1, 9 do
                    local item = turtle.getItemDetail(checkSlot)
                    if item and item.name == requiredItem then
                        turtle.select(checkSlot)
                        turtle.transferTo(slot, 1)
                        break
                    end
                end
            end
        end
    end
    
    -- Verify we have all required items placed
    for slot = 1, 9 do
        local row, col = slotMap[slot][1], slotMap[slot][2]
        local requiredItem = recipe.pattern[row][col]
        
        if requiredItem then
            local item = turtle.getItemDetail(slot)
            if not item or item.name ~= requiredItem then
                return false, "Failed to place " .. requiredItem .. " in slot " .. slot
            end
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
    
    -- Select slot 16 (output slot) before crafting
    turtle.select(16)
    
    -- Craft the item
    local craftSuccess = turtle.craft()
    
    status = "idle"
    
    if craftSuccess then
        return true, "Crafted " .. recipe.count .. "x " .. recipe.result
    else
        -- Debug: Show current inventory arrangement
        print("Current crafting grid:")
        for slot = 1, 9 do
            local item = turtle.getItemDetail(slot)
            if item then
                print("Slot " .. slot .. ": " .. item.name)
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
                        network.send(senderId, "pong", {
                            status = status,
                            fuelLevel = turtle.getFuelLevel(),
                            itemCount = getInventoryCount()
                        })
                elseif message.type == "status_request" then
                    network.send(senderId, "status_response", {
                        status = status,
                        fuelLevel = turtle.getFuelLevel(),
                        itemCount = getInventoryCount()
                    })
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
                    network.send(jobsComputerId, "unregister", {
                        reason = "shutdown"
                    })
                end
                break
            end
        end
        end
    end
end

-- Run main program
main()
