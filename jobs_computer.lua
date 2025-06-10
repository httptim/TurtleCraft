-- Jobs Computer for TurtleCraft
-- Central manager for the distributed crafting system

local config = dofile("config.lua")
local network = dofile("lib/network.lua")
local me_bridge = dofile("lib/me_bridge.lua")

-- State
local running = true
local turtles = {}
local meConnected = false
local meStatus = {
    connected = false,
    itemCount = 0,
    storageUsed = 0,
    storageTotal = 0,
    lastUpdate = 0
}

-- Clear screen helper
local function clear()
    term.clear()
    term.setCursorPos(1, 1)
end

-- Display status
local function displayStatus()
    clear()
    print("TurtleCraft - Jobs Computer")
    print("===========================")
    print()
    print("Computer ID: " .. os.getComputerID())
    print("Status: RUNNING")
    print("Protocol: " .. config.PROTOCOL)
    print()
    
    -- ME System Status
    print("ME System: " .. (meStatus.connected and "CONNECTED" or "NOT CONNECTED"))
    if meStatus.connected then
        print("  Items: " .. meStatus.itemCount)
        print("  Storage: " .. meStatus.storageUsed .. "/" .. meStatus.storageTotal .. " (" .. meStatus.storagePercent .. "%)")
    end
    print()
    
    print("Registered Turtles: " .. #turtles)
    local now = os.clock()
    for i, turtle in ipairs(turtles) do
        local status = turtle.status
        if turtle.status == "offline" then
            local offlineTime = math.floor(now - turtle.lastSeen)
            status = status .. " - " .. offlineTime .. "s ago"
        end
        print("  - Turtle #" .. turtle.id .. " (" .. status .. ")")
    end
    print()
    print("Commands:")
    print("  I - Show ME Items")
    print("  S - Search Items") 
    print("  Q - Quit")
end

-- Handle incoming messages
local function handleMessage(sender, message)
    if not message or not message.type then return end
    
    if message.type == "PING" then
        network.send(sender, "PONG", {})
        
    elseif message.type == "REGISTER" then
        print("\n[Jobs] Turtle #" .. sender .. " registering")
        
        -- Add turtle to list
        local found = false
        for i, turtle in ipairs(turtles) do
            if turtle.id == sender then
                turtle.lastSeen = os.clock()
                turtle.status = "online"
                found = true
                break
            end
        end
        
        if not found then
            table.insert(turtles, {
                id = sender,
                status = "online",
                lastSeen = os.clock()
            })
        end
        
        -- Send acknowledgment
        network.send(sender, "REGISTER_ACK", {
            success = true,
            jobsComputerID = os.getComputerID()
        })
        
    elseif message.type == "HEARTBEAT" then
        -- Update turtle last seen time
        for i, turtle in ipairs(turtles) do
            if turtle.id == sender then
                turtle.lastSeen = os.clock()
                turtle.status = "online"
                break
            end
        end
        
        network.send(sender, "HEARTBEAT_ACK", {})
        
    elseif message.type == "STATUS_REQUEST" then
        -- Count active turtles
        local activeTurtles = 0
        for _, turtle in ipairs(turtles) do
            if turtle.status ~= "offline" then
                activeTurtles = activeTurtles + 1
            end
        end
        
        network.send(sender, "STATUS_RESPONSE", {
            turtleCount = #turtles,
            activeTurtleCount = activeTurtles,
            running = true,
            meConnected = meStatus.connected,
            meItemCount = meStatus.itemCount
        })
        
    elseif message.type == "UNREGISTER" then
        -- Turtle is shutting down gracefully
        for i = #turtles, 1, -1 do
            if turtles[i].id == sender then
                print("\n[Jobs] Turtle #" .. sender .. " unregistered")
                table.remove(turtles, i)
                break
            end
        end
        
        network.send(sender, "UNREGISTER_ACK", {})
        
    elseif message.type == "REQUEST_ITEMS" then
        -- Turtle requesting items from ME system
        if not me_bridge.isConnected() then
            network.send(sender, "ITEMS_RESPONSE", {
                success = false,
                error = "ME Bridge not connected"
            })
            return
        end
        
        local itemName = message.data.item
        local count = message.data.count or 64
        
        print("\n[Jobs] Turtle #" .. sender .. " requesting " .. count .. "x " .. itemName)
        
        -- Export items from ME to turtle (assuming turtle is adjacent)
        local exported, err = me_bridge.exportItem(itemName, count, "up")
        if exported then
            network.send(sender, "ITEMS_RESPONSE", {
                success = true,
                item = itemName,
                count = exported
            })
            print("[Jobs] Exported " .. exported .. "x " .. itemName .. " to turtle")
        else
            network.send(sender, "ITEMS_RESPONSE", {
                success = false,
                error = err or "Failed to export items"
            })
            print("[Jobs] Failed to export: " .. tostring(err))
        end
        
    elseif message.type == "DEPOSIT_ITEMS" then
        -- Turtle depositing items to ME system
        if not me_bridge.isConnected() then
            network.send(sender, "DEPOSIT_RESPONSE", {
                success = false,
                error = "ME Bridge not connected"
            })
            return
        end
        
        local itemName = message.data.item
        local count = message.data.count or 64
        
        print("\n[Jobs] Turtle #" .. sender .. " depositing " .. count .. "x " .. itemName)
        
        -- Import items from turtle to ME (assuming turtle is adjacent)
        local imported, err = me_bridge.importItem(itemName, count, "up")
        if imported then
            network.send(sender, "DEPOSIT_RESPONSE", {
                success = true,
                item = itemName,
                count = imported
            })
            print("[Jobs] Imported " .. imported .. "x " .. itemName .. " from turtle")
        else
            network.send(sender, "DEPOSIT_RESPONSE", {
                success = false,
                error = err or "Failed to import items"
            })
            print("[Jobs] Failed to import: " .. tostring(err))
        end
        
    elseif message.type == "CHECK_STOCK" then
        -- Check stock level of an item
        if not me_bridge.isConnected() then
            network.send(sender, "STOCK_RESPONSE", {
                success = false,
                error = "ME Bridge not connected"
            })
            return
        end
        
        local itemName = message.data.item
        local item = me_bridge.getItem(itemName)
        
        if item then
            network.send(sender, "STOCK_RESPONSE", {
                success = true,
                item = itemName,
                count = item.amount or item.count or 0
            })
        else
            network.send(sender, "STOCK_RESPONSE", {
                success = true,
                item = itemName,
                count = 0
            })
        end
    end
end

-- Check turtle health
local function checkTurtleHealth()
    local now = os.clock()
    local activeTurtles = {}
    
    for i, turtle in ipairs(turtles) do
        -- Check if turtle should be marked offline
        if now - turtle.lastSeen > config.TURTLE_OFFLINE_TIMEOUT then
            if turtle.status ~= "offline" then
                print("\n[Jobs] Turtle #" .. turtle.id .. " went offline")
                turtle.status = "offline"
            end
        elseif turtle.status == "offline" then
            -- Turtle came back online
            turtle.status = "online"
            print("\n[Jobs] Turtle #" .. turtle.id .. " came back online")
        end
        
        -- Only keep turtles that have been seen recently
        if now - turtle.lastSeen < config.TURTLE_REMOVE_TIMEOUT then
            table.insert(activeTurtles, turtle)
        else
            print("\n[Jobs] Removing inactive turtle #" .. turtle.id)
        end
    end
    
    turtles = activeTurtles
end

-- Update ME system status
local function updateMEStatus()
    if not me_bridge.isConnected() then
        meStatus.connected = false
        return
    end
    
    meStatus.connected = true
    meStatus.lastUpdate = os.clock()
    
    -- Get storage info
    local storageInfo = me_bridge.getStorageInfo()
    if storageInfo then
        meStatus.storageUsed = storageInfo.usedStorage or 0
        meStatus.storageTotal = storageInfo.totalStorage or 0
        meStatus.storagePercent = storageInfo.usagePercent or 0
    end
    
    -- Get item count
    local items = me_bridge.listItems()
    if items then
        meStatus.itemCount = #items
    end
end

-- Show ME items
local function showMEItems()
    if not me_bridge.isConnected() then
        print("\n[ME] Not connected to ME Bridge!")
        sleep(2)
        return
    end
    
    clear()
    print("ME System Items")
    print("===============")
    print()
    
    local items, err = me_bridge.listItems()
    if not items then
        print("Error: " .. tostring(err))
        print("\nPress any key to continue...")
        os.pullEvent("key")
        return
    end
    
    print("Total items: " .. #items)
    print()
    
    -- Show first 15 items
    local count = math.min(15, #items)
    for i = 1, count do
        local item = items[i]
        print(string.format("%2d. %s", i, me_bridge.formatItem(item)))
    end
    
    if #items > 15 then
        print("\n... and " .. (#items - 15) .. " more items")
    end
    
    print("\nPress any key to continue...")
    os.pullEvent("key")
end

-- Search for items
local function searchMEItems()
    if not me_bridge.isConnected() then
        print("\n[ME] Not connected to ME Bridge!")
        sleep(2)
        return
    end
    
    clear()
    print("ME Item Search")
    print("==============")
    print()
    print("Enter search term (or empty to cancel):")
    write("> ")
    
    local searchTerm = read()
    if searchTerm == "" then
        return
    end
    
    print("\nSearching for '" .. searchTerm .. "'...")
    
    local results, err = me_bridge.searchItems(searchTerm)
    if not results then
        print("Error: " .. tostring(err))
        print("\nPress any key to continue...")
        os.pullEvent("key")
        return
    end
    
    clear()
    print("Search Results for '" .. searchTerm .. "'")
    print("================================")
    print()
    print("Found " .. #results .. " items:")
    print()
    
    if #results == 0 then
        print("No items found.")
    else
        local count = math.min(15, #results)
        for i = 1, count do
            local item = results[i]
            print(string.format("%2d. %s", i, me_bridge.formatItem(item)))
        end
        
        if #results > 15 then
            print("\n... and " .. (#results - 15) .. " more items")
        end
    end
    
    print("\nPress any key to continue...")
    os.pullEvent("key")
end

-- Main function
local function main()
    clear()
    print("Starting Jobs Computer...")
    
    -- Initialize network
    if not network.init() then
        print("Failed to initialize network!")
        return
    end
    
    -- Host ourselves
    network.host("jobs")
    
    -- Initialize ME Bridge
    print("Connecting to ME Bridge...")
    if me_bridge.init() then
        print("ME Bridge connected!")
        meConnected = true
        updateMEStatus()
    else
        print("ME Bridge not found - running without ME integration")
        meConnected = false
    end
    
    print("Jobs Computer ready!")
    print("Waiting for connections...")
    sleep(2)
    
    -- Main loop
    local lastHealthCheck = os.clock()
    local lastDisplay = os.clock()
    local lastMEUpdate = os.clock()
    
    while running do
        -- Check for messages
        local sender, message = network.receive(0.1)
        if sender then
            handleMessage(sender, message)
        end
        
        -- Periodic health check
        if os.clock() - lastHealthCheck > 10 then
            checkTurtleHealth()
            lastHealthCheck = os.clock()
        end
        
        -- Update ME status
        if meConnected and os.clock() - lastMEUpdate > 30 then
            updateMEStatus()
            lastMEUpdate = os.clock()
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
            elseif p1 == keys.i then
                showMEItems()
            elseif p1 == keys.s then
                searchMEItems()
            end
        elseif event == "timer" and p1 == timer then
            -- Timer expired, continue loop
        else
            os.cancelTimer(timer)
        end
    end
    
    -- Cleanup
    if meConnected then
        me_bridge.disconnect()
    end
    network.close()
    clear()
    print("Jobs Computer stopped.")
end

-- Run with error handling
local ok, err = pcall(main)
if not ok then
    print("ERROR: " .. tostring(err))
    print("\nPress any key to exit...")
    os.pullEvent("key")
end