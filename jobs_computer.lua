-- Jobs Computer for TurtleCraft
-- Central manager for the distributed crafting system

local config = dofile("config.lua")
local network = dofile("lib/network.lua")
local me_bridge = dofile("lib/me_bridge.lua")

-- State
local running = true
local turtles = {}
local wiredTurtles = {}  -- Maps peripheral names to turtle IDs
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
        local wiredInfo = ""
        if turtle.peripheralName then
            wiredInfo = " [" .. turtle.peripheralName .. "]"
        end
        print("  - Turtle #" .. turtle.id .. " (" .. status .. ")" .. wiredInfo)
    end
    
    -- Show wired turtles awaiting discovery
    local wiredCount = 0
    for _, name in ipairs(peripheral.getNames()) do
        local pType = peripheral.getType(name)
        if pType == "turtle" then
            wiredCount = wiredCount + 1
        end
    end
    if wiredCount > 0 then
        print("\nWired Turtles: " .. wiredCount .. " detected")
    end
    print()
    print("Commands:")
    print("  I - Show ME Items")
    print("  S - Search Items")
    print("  D - Discover wired turtles")
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
        local turtleRecord = nil
        for i, turtle in ipairs(turtles) do
            if turtle.id == sender then
                turtle.lastSeen = os.clock()
                turtle.status = "online"
                found = true
                turtleRecord = turtle
                break
            end
        end
        
        if not found then
            turtleRecord = {
                id = sender,
                status = "online",
                lastSeen = os.clock(),
                peripheralName = nil  -- Will be set during discovery
            }
            table.insert(turtles, turtleRecord)
        end
        
        -- Send acknowledgment
        network.send(sender, "REGISTER_ACK", {
            success = true,
            jobsComputerID = os.getComputerID()
        })
        
        -- Auto-discover if we don't know this turtle's peripheral name yet
        if not turtleRecord.peripheralName then
            print("[Jobs] Running auto-discovery for new turtle...")
            os.queueEvent("start_discovery")
        end
        
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
        
        -- Find the turtle's peripheral name
        local turtlePeripheral = nil
        for _, turtle in ipairs(turtles) do
            if turtle.id == sender and turtle.peripheralName then
                turtlePeripheral = turtle.peripheralName
                print("[Jobs] Found peripheral name in turtles array: " .. turtlePeripheral)
                break
            end
        end
        
        if not turtlePeripheral then
            -- Try to find in wiredTurtles mapping
            for peripheral, id in pairs(wiredTurtles) do
                if id == sender then
                    turtlePeripheral = peripheral
                    print("[Jobs] Found peripheral name in wiredTurtles: " .. turtlePeripheral)
                    break
                end
            end
        end
        
        if not turtlePeripheral then
            network.send(sender, "ITEMS_RESPONSE", {
                success = false,
                error = "Turtle peripheral not found - run discovery (D)",
                item = itemName
            })
            print("[Jobs] Error: Turtle peripheral name not found")
            return
        end
        
        print("[Jobs] About to export " .. count .. "x " .. itemName .. " to " .. turtlePeripheral)
        
        -- Export items from ME to turtle using peripheral name
        local exported, err = me_bridge.exportItemToPeripheral(itemName, count, turtlePeripheral)
        
        print("[Jobs] Export result: exported=" .. tostring(exported) .. ", err=" .. tostring(err))
        
        if exported and exported > 0 then
            network.send(sender, "ITEMS_RESPONSE", {
                success = true,
                item = itemName,
                count = exported
            })
            print("[Jobs] Exported " .. exported .. "x " .. itemName .. " to " .. turtlePeripheral)
        else
            network.send(sender, "ITEMS_RESPONSE", {
                success = false,
                error = err or "Failed to export items",
                item = itemName
            })
            print("[Jobs] Failed to export: " .. tostring(err))
            print("[Jobs] Item: " .. itemName .. ", Count: " .. count .. ", Peripheral: " .. turtlePeripheral)
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
        local isDiscoveryItem = message.data.isDiscoveryItem
        
        if isDiscoveryItem then
            print("\n[Jobs] Returning discovery item from Turtle #" .. sender)
        else
            print("\n[Jobs] Turtle #" .. sender .. " depositing " .. count .. "x " .. itemName)
        end
        
        -- Find the turtle's peripheral name
        local turtlePeripheral = nil
        for _, turtle in ipairs(turtles) do
            if turtle.id == sender and turtle.peripheralName then
                turtlePeripheral = turtle.peripheralName
                break
            end
        end
        
        if not turtlePeripheral then
            for peripheral, id in pairs(wiredTurtles) do
                if id == sender then
                    turtlePeripheral = peripheral
                    break
                end
            end
        end
        
        if not turtlePeripheral then
            -- Fallback to direction-based import if no peripheral name
            local imported, err = me_bridge.importItem(itemName, count, "up")
            if imported then
                network.send(sender, "DEPOSIT_RESPONSE", {
                    success = true,
                    item = itemName,
                    count = imported
                })
                print("[Jobs] Imported " .. imported .. "x " .. itemName .. " from turtle (direction)")
            else
                network.send(sender, "DEPOSIT_RESPONSE", {
                    success = false,
                    error = err or "Failed to import items"
                })
                print("[Jobs] Failed to import: " .. tostring(err))
            end
            return
        end
        
        -- Import items from turtle to ME using peripheral name
        local imported, err = me_bridge.importItemFromPeripheral(itemName, count, turtlePeripheral)
        if imported then
            network.send(sender, "DEPOSIT_RESPONSE", {
                success = true,
                item = itemName,
                count = imported
            })
            if isDiscoveryItem then
                print("[Jobs] Discovery item returned to ME system")
            else
                print("[Jobs] Imported " .. imported .. "x " .. itemName .. " from turtle")
            end
        else
            network.send(sender, "DEPOSIT_RESPONSE", {
                success = false,
                error = err or "Failed to import items"
            })
            print("[Jobs] Failed to import: " .. tostring(err))
        end
        
    elseif message.type == "JOB_ACK" then
        -- Turtle acknowledged job assignment
        local jobId = message.data.jobId
        local accepted = message.data.accepted
        
        if accepted then
            print("\n[Jobs] Turtle #" .. sender .. " accepted job " .. jobId)
        else
            print("\n[Jobs] Turtle #" .. sender .. " rejected job: " .. (message.data.reason or "Unknown"))
        end
        
    elseif message.type == "JOB_COMPLETE" then
        -- Turtle completed a job
        local jobId = message.data.jobId
        local success = message.data.success
        
        if success then
            print("\n[Jobs] Turtle #" .. sender .. " completed job " .. jobId)
            print("[Jobs] Crafted: " .. (message.data.crafted or 0) .. " items")
        else
            print("\n[Jobs] Turtle #" .. sender .. " failed job " .. jobId)
            print("[Jobs] Error: " .. (message.data.error or "Unknown"))
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
        
    elseif message.type == "PULL_ITEM" then
        -- Turtle wants us to pull an item from it
        local slot = message.data.slot
        local itemName = message.data.item
        local count = message.data.count
        
        print("\n[Jobs] PULL_ITEM request from Turtle #" .. sender)
        print("[Jobs] Item: " .. itemName .. " x" .. count .. " from slot " .. slot)
        
        -- Find turtle's peripheral name
        local turtlePeripheral = nil
        for _, turtle in ipairs(turtles) do
            if turtle.id == sender and turtle.peripheralName then
                turtlePeripheral = turtle.peripheralName
                break
            end
        end
        
        if not turtlePeripheral then
            for peripheral, id in pairs(wiredTurtles) do
                if id == sender then
                    turtlePeripheral = peripheral
                    break
                end
            end
        end
        
        if not turtlePeripheral then
            print("[Jobs] Error: Turtle peripheral not found")
            network.send(sender, "PULL_RESPONSE", {
                success = false,
                error = "Turtle peripheral not found"
            })
            return
        end
        
        print("[Jobs] Using peripheral: " .. turtlePeripheral)
        
        -- Pull the item from turtle to ME
        if me_bridge.isConnected() then
            local imported, err = me_bridge.importItemFromPeripheral(itemName, count, turtlePeripheral)
            print("[Jobs] Import result: imported=" .. tostring(imported) .. ", err=" .. tostring(err))
            
            if imported and imported > 0 then
                network.send(sender, "PULL_RESPONSE", {
                    success = true,
                    count = imported
                })
                print("[Jobs] Successfully pulled " .. imported .. "x " .. itemName .. " from turtle")
            else
                network.send(sender, "PULL_RESPONSE", {
                    success = false,
                    error = err or "Failed to pull item"
                })
                print("[Jobs] Failed to pull item: " .. tostring(err))
            end
        else
            network.send(sender, "PULL_RESPONSE", {
                success = false,
                error = "ME Bridge not connected"
            })
            print("[Jobs] Error: ME Bridge not connected")
        end
        
    elseif message.type == "CRAFT_REQUEST" then
        -- Main Computer requesting a craft
        local recipeName = message.data.recipe
        local quantity = message.data.quantity
        
        print("\n[Jobs] Craft request from Main Computer:")
        print("[Jobs] Recipe: " .. recipeName .. " x" .. quantity)
        
        -- Find an available turtle
        local availableTurtle = nil
        for _, turtle in ipairs(turtles) do
            if turtle.status == "online" then
                availableTurtle = turtle
                break
            end
        end
        
        if not availableTurtle then
            print("[Jobs] No turtles available!")
            network.send(sender, "CRAFT_RESPONSE", {
                success = false,
                error = "No turtles available"
            })
            return
        end
        
        -- Send job to turtle
        local jobId = "job_" .. os.epoch("local")
        print("[Jobs] Assigning job " .. jobId .. " to Turtle #" .. availableTurtle.id)
        
        network.send(availableTurtle.id, "JOB_ASSIGN", {
            id = jobId,
            type = "CRAFT",
            recipe = recipeName,
            quantity = quantity
        })
        
        -- Send response to Main Computer
        network.send(sender, "CRAFT_RESPONSE", {
            success = true,
            jobId = jobId,
            turtleId = availableTurtle.id
        })
        
    elseif message.type == "DISCOVERY_RESPONSE" then
        -- Turtle is reporting it received the discovery item
        local peripheralName = message.data.peripheralName
        print("\n[Jobs] Turtle #" .. sender .. " identified as " .. peripheralName)
        
        -- Update mapping
        wiredTurtles[peripheralName] = sender
        
        -- Update turtle record
        for i, turtle in ipairs(turtles) do
            if turtle.id == sender then
                turtle.peripheralName = peripheralName
                break
            end
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

-- Discover wired turtles
local function discoverWiredTurtles()
    clear()
    print("Wired Turtle Discovery")
    print("=====================")
    print()
    print("Scanning for wired turtles...")
    print()
    
    local turtlePeripherals = {}
    
    -- Find all turtle peripherals
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "turtle" then
            table.insert(turtlePeripherals, name)
            print("Found turtle peripheral: " .. name)
        end
    end
    
    if #turtlePeripherals == 0 then
        print("\nNo wired turtles found!")
        print("Make sure turtles are connected via wired modems.")
        print("\nPress any key to continue...")
        os.pullEvent("key")
        return
    end
    
    print("\nStarting discovery process...")
    print("Using direct ID method...")
    print()
    
    -- Clear previous mappings
    wiredTurtles = {}
    
    -- For each turtle peripheral
    for _, peripheralName in ipairs(turtlePeripherals) do
        print("Testing " .. peripheralName .. "...")
        
        -- Wrap the turtle
        local turtle = peripheral.wrap(peripheralName)
        if turtle then
            -- Get the turtle's computer ID directly
            local turtleId = turtle.getID()
            if turtleId then
                print("  [OK] Turtle #" .. turtleId .. " identified as " .. peripheralName)
                
                -- Update mapping
                wiredTurtles[peripheralName] = turtleId
                
                -- Update turtle record if it's registered
                for i, t in ipairs(turtles) do
                    if t.id == turtleId then
                        t.peripheralName = peripheralName
                        print("  [OK] Matched to registered turtle")
                        break
                    end
                end
            else
                print("  [X] Could not get ID from peripheral")
            end
        else
            print("  [X] Failed to wrap peripheral")
        end
    end
    
    print("\nDiscovery complete!")
    print("\nMapped turtles:")
    local mappedCount = 0
    for peripheral, turtleId in pairs(wiredTurtles) do
        print("  " .. peripheral .. " -> Turtle #" .. turtleId)
        mappedCount = mappedCount + 1
    end
    
    if mappedCount == 0 then
        print("  No turtles were mapped.")
        print("  Make sure:")
        print("  - Turtles are connected via wired modems")
        print("  - Wired modems are activated (red ring)")
    end
    
    print("\nReturning to main display...")
    sleep(2)
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
            elseif p1 == keys.d then
                discoverWiredTurtles()
            end
        elseif event == "timer" and p1 == timer then
            -- Timer expired, continue loop
        elseif event == "start_discovery" then
            os.cancelTimer(timer)
            -- Run quick discovery without UI
            print("[Jobs] Running auto-discovery...")
            local foundNew = false
            for _, name in ipairs(peripheral.getNames()) do
                if peripheral.getType(name) == "turtle" and not wiredTurtles[name] then
                    local turtle = peripheral.wrap(name)
                    if turtle then
                        local turtleId = turtle.getID()
                        if turtleId then
                            wiredTurtles[name] = turtleId
                            -- Update turtle record
                            for i, t in ipairs(turtles) do
                                if t.id == turtleId then
                                    t.peripheralName = name
                                    print("[Jobs] Mapped Turtle #" .. turtleId .. " to " .. name)
                                    foundNew = true
                                    break
                                end
                            end
                        end
                    end
                end
            end
            if not foundNew then
                print("[Jobs] No new turtles found to map")
            end
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