-- Turtle Client for TurtleCraft
-- Crafting turtle that connects to the Jobs Computer

local config = dofile("config.lua")
local network = dofile("lib/network.lua")

-- State
local running = true
local jobsComputerID = nil
local registered = false
local discoveryMode = false
local expectedPeripheral = nil

-- Clear screen helper
local function clear()
    term.clear()
    term.setCursorPos(1, 1)
end

-- Check if this is a crafty turtle
local function isCraftyTurtle()
    return turtle ~= nil and turtle.craft ~= nil
end

-- Display status
local function displayStatus()
    clear()
    print("TurtleCraft - Turtle Client")
    print("===========================")
    print()
    print("Turtle ID: " .. os.getComputerID())
    print("Type: " .. (isCraftyTurtle() and "Crafty Turtle" or "Not a crafty turtle!"))
    print("Jobs Computer: " .. (registered and "REGISTERED (ID: " .. jobsComputerID .. ")" or "NOT REGISTERED"))
    print()
    
    if turtle then
        print("Fuel Level: " .. turtle.getFuelLevel())
    end
    
    print()
    print("Commands:")
    print("  R - Re-register with Jobs Computer")
    print("  F - Refuel from slot 16")
    print("  G - Get items from ME system")
    print("  D - Deposit items to ME system")
    print("  Q - Quit")
end

-- Register with Jobs Computer
local function registerWithJobsComputer()
    print("\n[Turtle] Searching for Jobs Computer...")
    
    -- First try the configured ID
    if config.JOBS_COMPUTER_ID then
        print("[Turtle] Trying configured ID: " .. config.JOBS_COMPUTER_ID)
        
        network.send(config.JOBS_COMPUTER_ID, "REGISTER", {
            turtleType = "crafty",
            fuelLevel = turtle and turtle.getFuelLevel() or 0
        })
        
        -- Wait for response
        local startTime = os.clock()
        while os.clock() - startTime < 3 do
            local sender, message = network.receive(0.1)
            if sender == config.JOBS_COMPUTER_ID and message and message.type == "REGISTER_ACK" then
                if message.data.success then
                    jobsComputerID = config.JOBS_COMPUTER_ID
                    registered = true
                    print("[Turtle] Successfully registered!")
                    return true
                end
            end
        end
    end
    
    -- Try to find by hostname
    print("[Turtle] Searching by hostname...")
    local computers = network.findComputers("jobs")
    
    for _, id in ipairs(computers) do
        print("[Turtle] Trying Jobs Computer ID " .. id .. "...")
        
        network.send(id, "REGISTER", {
            turtleType = "crafty",
            fuelLevel = turtle and turtle.getFuelLevel() or 0
        })
        
        -- Wait for response
        local startTime = os.clock()
        while os.clock() - startTime < 3 do
            local sender, message = network.receive(0.1)
            if sender == id and message and message.type == "REGISTER_ACK" then
                if message.data.success then
                    jobsComputerID = id
                    registered = true
                    print("[Turtle] Successfully registered with Jobs Computer ID " .. id .. "!")
                    return true
                end
            end
        end
    end
    
    print("[Turtle] Could not register with Jobs Computer!")
    print("[Turtle] Make sure Jobs Computer is running first")
    return false
end

-- Send heartbeat
local function sendHeartbeat()
    if registered and jobsComputerID then
        network.send(jobsComputerID, "HEARTBEAT", {
            fuelLevel = turtle and turtle.getFuelLevel() or 0,
            status = "idle"
        })
    end
end

-- Handle incoming messages
local function handleMessage(sender, message)
    if not message or not message.type then return end
    
    if message.type == "PONG" then
        -- Handled by ping function
        
    elseif message.type == "HEARTBEAT_ACK" and sender == jobsComputerID then
        -- Heartbeat acknowledged
        
    elseif message.type == "JOB_ASSIGN" and sender == jobsComputerID then
        print("\n[Turtle] Received job assignment!")
        -- Job handling will be implemented in later phases
        network.send(jobsComputerID, "JOB_ACK", {
            accepted = false,
            reason = "Not implemented yet"
        })
        
    elseif message.type == "DISCOVERY_START" and sender == jobsComputerID then
        -- Jobs Computer is about to send a discovery item
        discoveryMode = true
        expectedPeripheral = message.data.peripheralName
        print("\n[Turtle] Entering discovery mode for " .. expectedPeripheral)
        
    elseif message.type == "DISCOVERY_ACTION" and sender == jobsComputerID then
        -- Legacy discovery action support
        print("\n[Turtle] Discovery action not implemented")
    end
end

-- Check for newly received items during discovery
local function checkDiscoveryItem()
    if not discoveryMode or not expectedPeripheral then
        return
    end
    
    -- Check all slots for new items
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item and item.count > 0 then
            -- We found an item - report back to Jobs Computer
            print("[Turtle] Received discovery item in slot " .. slot)
            
            network.send(jobsComputerID, "DISCOVERY_RESPONSE", {
                peripheralName = expectedPeripheral
            })
            
            -- Clear discovery mode
            discoveryMode = false
            expectedPeripheral = nil
            
            -- Drop the item back down for Jobs Computer to collect
            turtle.select(slot)
            turtle.dropDown()
            print("[Turtle] Dropped discovery item for return")
            
            return true
        end
    end
    
    return false
end

-- Request items from ME system
local function requestItems()
    if not registered or not jobsComputerID then
        print("\n[Turtle] Not registered with Jobs Computer!")
        sleep(2)
        return
    end
    
    clear()
    print("Request Items from ME System")
    print("============================")
    print()
    print("Enter item name (e.g. minecraft:cobblestone):")
    write("> ")
    local itemName = read()
    
    if itemName == "" then
        return
    end
    
    print("Enter quantity (default 64):")
    write("> ")
    local quantity = read()
    quantity = tonumber(quantity) or 64
    
    print("\n[Turtle] Requesting " .. quantity .. "x " .. itemName .. "...")
    
    network.send(jobsComputerID, "REQUEST_ITEMS", {
        item = itemName,
        count = quantity
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
                    print("[Turtle] Received " .. message.data.count .. "x " .. message.data.item)
                else
                    print("[Turtle] Failed: " .. (message.data.error or "Unknown error"))
                end
                break
            end
        elseif event == "timer" and p1 == timeout then
            print("[Turtle] Request timed out!")
            break
        end
    end
    
    print("\nPress any key to continue...")
    os.pullEvent("key")
end

-- Deposit items to ME system
local function depositItems()
    if not registered or not jobsComputerID then
        print("\n[Turtle] Not registered with Jobs Computer!")
        sleep(2)
        return
    end
    
    clear()
    print("Deposit Items to ME System")
    print("==========================")
    print()
    print("Current inventory:")
    
    -- Show inventory
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            print(string.format("Slot %2d: %s x%d", slot, item.name, item.count))
        end
    end
    
    print()
    print("Enter slot number to deposit (1-16):")
    write("> ")
    local slot = tonumber(read())
    
    if not slot or slot < 1 or slot > 16 then
        return
    end
    
    turtle.select(slot)
    local item = turtle.getItemDetail()
    if not item then
        print("\n[Turtle] Slot is empty!")
        sleep(2)
        return
    end
    
    print("Deposit all " .. item.count .. " items? (Y/N)")
    local confirm = read()
    if string.upper(confirm) ~= "Y" then
        return
    end
    
    print("\n[Turtle] Depositing " .. item.count .. "x " .. item.name .. "...")
    
    -- First drop the items
    if turtle.dropDown() then
        -- Then notify Jobs Computer
        network.send(jobsComputerID, "DEPOSIT_ITEMS", {
            item = item.name,
            count = item.count
        })
        
        -- Wait for response
        local timeout = os.startTimer(5)
        while true do
            local event, p1, p2, p3 = os.pullEvent()
            if event == "rednet_message" then
                local sender, message, protocol = p1, p2, p3
                if sender == jobsComputerID and message and message.type == "DEPOSIT_RESPONSE" then
                    os.cancelTimer(timeout)
                    if message.data.success then
                        print("[Turtle] Deposited " .. message.data.count .. "x " .. message.data.item)
                    else
                        print("[Turtle] Failed: " .. (message.data.error or "Unknown error"))
                    end
                    break
                end
            elseif event == "timer" and p1 == timeout then
                print("[Turtle] Deposit confirmation timed out!")
                break
            end
        end
    else
        print("[Turtle] Failed to drop items!")
    end
    
    print("\nPress any key to continue...")
    os.pullEvent("key")
end

-- Main function
local function main()
    clear()
    
    -- Check if this is a crafty turtle
    if not isCraftyTurtle() then
        print("ERROR: This program requires a Crafty Turtle!")
        print("\nPress any key to exit...")
        os.pullEvent("key")
        return
    end
    
    print("Starting Turtle Client...")
    
    -- Initialize network
    if not network.init() then
        print("Failed to initialize network!")
        return
    end
    
    -- Host ourselves (optional)
    network.host("turtle_" .. os.getComputerID())
    
    print("Turtle ready!")
    sleep(1)
    
    -- Try to register
    registerWithJobsComputer()
    
    -- Main loop
    local lastDisplay = os.clock()
    local lastHeartbeat = os.clock()
    local lastDiscoveryCheck = os.clock()
    
    while running do
        -- Check for messages
        local sender, message = network.receive(0.1)
        if sender then
            handleMessage(sender, message)
        end
        
        -- Send heartbeat
        if registered and os.clock() - lastHeartbeat > config.HEARTBEAT_INTERVAL then
            sendHeartbeat()
            lastHeartbeat = os.clock()
        end
        
        -- Check for discovery items
        if discoveryMode and os.clock() - lastDiscoveryCheck > 0.2 then
            checkDiscoveryItem()
            lastDiscoveryCheck = os.clock()
        end
        
        -- Update display
        if os.clock() - lastDisplay > 1 then
            displayStatus()
            lastDisplay = os.clock()
        end
        
        -- Check for user input (non-blocking)
        local timer = os.startTimer(0.1)
        local event, p1, p2 = os.pullEvent()
        if event == "key" then
            os.cancelTimer(timer)
            if p1 == keys.q then
                running = false
            elseif p1 == keys.r then
                print("\n[Turtle] Re-registering...")
                registered = false
                registerWithJobsComputer()
                sleep(1)
            elseif p1 == keys.f and turtle then
                turtle.select(16)
                if turtle.refuel() then
                    print("\n[Turtle] Refueled! New level: " .. turtle.getFuelLevel())
                else
                    print("\n[Turtle] No fuel in slot 16!")
                end
                sleep(1)
            elseif p1 == keys.g then
                requestItems()
            elseif p1 == keys.d then
                depositItems()
            end
        elseif event == "timer" and p1 == timer then
            -- Timer expired, continue loop
        else
            os.cancelTimer(timer)
        end
    end
    
    -- Cleanup
    if registered and jobsComputerID then
        -- Tell Jobs Computer we're shutting down
        network.send(jobsComputerID, "UNREGISTER", {})
        sleep(0.1)  -- Give time for message to send
    end
    
    network.close()
    clear()
    print("Turtle stopped.")
end

-- Run with error handling
local ok, err = pcall(main)
if not ok then
    print("ERROR: " .. tostring(err))
    print("\nPress any key to exit...")
    os.pullEvent("key")
end