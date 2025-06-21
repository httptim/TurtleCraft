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
    -- Clear crafting grid (slots 1-3, 5-7, 9-11 in turtle)
    local craftingSlots = {1, 2, 3, 5, 6, 7, 9, 10, 11}
    
    -- First, move any items in crafting slots to storage slots (12-16)
    for _, slot in ipairs(craftingSlots) do
        if turtle.getItemCount(slot) > 0 then
            turtle.select(slot)
            for storageSlot = 12, 16 do
                if turtle.transferTo(storageSlot) then
                    break
                end
            end
        end
    end
    
    -- Now arrange items according to recipe pattern
    local slotMap = {
        [1] = {1, 1}, [2] = {1, 2}, [3] = {1, 3},
        [5] = {2, 1}, [6] = {2, 2}, [7] = {2, 3},
        [9] = {3, 1}, [10] = {3, 2}, [11] = {3, 3}
    }
    
    for slot, pos in pairs(slotMap) do
        local row, col = pos[1], pos[2]
        local requiredItem = recipe.pattern[row][col]
        
        if requiredItem then
            -- Find the item in inventory
            local sourceSlot = findItem(requiredItem)
            if sourceSlot then
                turtle.select(sourceSlot)
                turtle.transferTo(slot, 1)  -- Transfer 1 item
            else
                return false, "Missing item: " .. requiredItem
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
    
    -- Arrange items
    local success, err = arrangeItemsForCrafting(recipe)
    if not success then
        status = "idle"
        return false, err
    end
    
    -- Craft the item
    turtle.select(1)  -- Select first slot for crafting
    local craftSuccess = turtle.craft()
    
    status = "idle"
    
    if craftSuccess then
        return true, "Crafted " .. recipe.count .. "x " .. recipe.result
    else
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
                    
                    network.send(senderId, "craft_response", {
                        success = success,
                        message = result,
                        recipe = message.data.recipe,
                        requestId = message.data.requestId
                    })
                    
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
