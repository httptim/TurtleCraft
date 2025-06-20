-- Simple Jobs Computer for TurtleCraft
-- Manages ME system and sends items directly to turtles

-- Helper function to create config if it doesn't exist
local function createDefaultConfig()
    print("No config.lua found. Creating default configuration...")
    
    -- Detect ME Bridges
    local meBridges = {}
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "meBridge" then
            table.insert(meBridges, name)
        end
    end
    
    local selectedBridge = nil
    
    if #meBridges == 0 then
        print("Warning: No ME Bridge detected!")
        print("You'll need to attach one and update config.lua")
    elseif #meBridges == 1 then
        selectedBridge = meBridges[1]
        print("Found ME Bridge: " .. selectedBridge)
    else
        -- Multiple ME Bridges, ask user
        print("\nMultiple ME Bridges detected:")
        for i, bridge in ipairs(meBridges) do
            print(i .. ") " .. bridge)
        end
        write("\nSelect ME Bridge (1-" .. #meBridges .. "): ")
        local choice = tonumber(read())
        if choice and choice >= 1 and choice <= #meBridges then
            selectedBridge = meBridges[choice]
        end
    end
    
    -- Write config file
    local file = fs.open("config.lua", "w")
    file.write("-- TurtleCraft Configuration\n")
    file.write("-- Auto-generated on first run\n")
    file.write("\n")
    file.write("local config = {\n")
    file.write("    -- Network Settings\n")
    file.write("    PROTOCOL = \"turtlecraft\",\n")
    file.write("    \n")
    if selectedBridge then
        file.write("    -- ME Bridge Settings (auto-detected)\n")
        file.write("    ME_BRIDGE_NAME = \"" .. selectedBridge .. "\",\n")
    else
        file.write("    -- ME Bridge Settings (will auto-detect)\n")
        file.write("    -- ME_BRIDGE_NAME = \"meBridge_0\",\n")
    end
    file.write("    \n")
    file.write("    -- Timeouts\n")
    file.write("    NETWORK_TIMEOUT = 5,\n")
    file.write("    HEARTBEAT_INTERVAL = 30,\n")
    file.write("    TURTLE_OFFLINE_TIMEOUT = 60,  -- Mark offline after 1 minute\n")
    file.write("    TURTLE_REMOVE_TIMEOUT = 180,  -- Remove from list after 3 minutes\n")
    file.write("    \n")
    file.write("    -- Debug\n")
    file.write("    DEBUG = false,\n")
    file.write("}\n")
    file.write("\n")
    file.write("return config\n")
    file.close()
    
    print("\nConfig file created: config.lua")
    print("Press any key to continue...")
    os.pullEvent("key")
    
    return dofile("config.lua")
end

-- Load or create config
local config
if fs.exists("config.lua") then
    config = dofile("config.lua")
else
    config = createDefaultConfig()
end

-- State
local turtles = {}
local wiredTurtles = {}  -- Maps peripheral names to turtle IDs
local meBridge = nil

-- Initialize
print("Simple Jobs Computer Starting...")
print("Computer ID: " .. os.getComputerID())

-- Open rednet
peripheral.find("modem", rednet.open)
rednet.host(config.PROTOCOL, "jobs")

-- Connect to ME Bridge
if config.ME_BRIDGE_NAME then
    meBridge = peripheral.wrap(config.ME_BRIDGE_NAME)
    if meBridge then
        print("ME Bridge connected via config: " .. config.ME_BRIDGE_NAME)
    end
end

if not meBridge then
    meBridge = peripheral.find("meBridge")
    if meBridge then
        print("ME Bridge found: " .. peripheral.getName(meBridge))
    end
end

if not meBridge then
    error("No ME Bridge found! Please attach an ME Bridge to this computer.")
end

-- Helper functions
local function clear()
    term.clear()
    term.setCursorPos(1, 1)
end

-- Discover wired turtles
local function discoverWiredTurtles()
    print("\n[Discovery] Scanning for wired turtles...")
    local found = 0
    
    for _, name in ipairs(peripheral.getNames()) do
        local pType = peripheral.getType(name)
        if pType == "turtle" then
            print("[Discovery] Found turtle: " .. name)
            found = found + 1
            
            -- Tell all registered turtles to identify themselves
            for id, turtle in pairs(turtles) do
                rednet.send(id, {
                    type = "IDENTIFY",
                    peripheralName = name
                }, config.PROTOCOL)
            end
        end
    end
    
    print("[Discovery] Found " .. found .. " wired turtles")
    return found
end

-- Handle turtle messages
local function handleMessage()
    local sender, message = rednet.receive(config.PROTOCOL, 0.5)
    if not sender or not message then return end
    
    if message.type == "REGISTER" then
        print("\n[Jobs] Turtle #" .. sender .. " registered")
        turtles[sender] = {
            id = sender,
            lastSeen = os.clock(),
            peripheralName = nil
        }
        rednet.send(sender, {type = "REGISTER_ACK"}, config.PROTOCOL)
        
    elseif message.type == "HEARTBEAT" then
        if turtles[sender] then
            turtles[sender].lastSeen = os.clock()
        end
        
    elseif message.type == "IDENTIFY_RESPONSE" then
        local peripheralName = message.peripheralName
        print("\n[Jobs] Turtle #" .. sender .. " identified as " .. peripheralName)
        
        wiredTurtles[peripheralName] = sender
        if turtles[sender] then
            turtles[sender].peripheralName = peripheralName
        end
        
    elseif message.type == "REQUEST_ITEMS" then
        print("\n[Jobs] Turtle #" .. sender .. " requests " .. message.count .. "x " .. message.item)
        
        -- Find turtle's peripheral name
        local turtlePeripheral = nil
        if turtles[sender] then
            turtlePeripheral = turtles[sender].peripheralName
        end
        
        if not turtlePeripheral then
            rednet.send(sender, {
                type = "ITEMS_RESPONSE",
                success = false,
                error = "Turtle not identified - run discovery"
            }, config.PROTOCOL)
            return
        end
        
        -- Export items directly to turtle
        local exported = 0
        local success = false
        
        if meBridge and meBridge.exportItemToPeripheral then
            exported = meBridge.exportItemToPeripheral(
                {name = message.item},
                turtlePeripheral,
                message.count
            )
            
            if exported and exported > 0 then
                success = true
                print("[Jobs] Exported " .. exported .. "x " .. message.item)
            end
        end
        
        -- Send response immediately - turtle will wait for items to arrive
        rednet.send(sender, {
            type = "ITEMS_RESPONSE",
            success = success,
            item = message.item,
            count = exported,
            expected = message.count
        }, config.PROTOCOL)
        
    elseif message.type == "PULL_ITEMS" then
        print("\n[Jobs] Turtle #" .. sender .. " returning items")
        
        -- Find turtle's peripheral name
        local turtlePeripheral = nil
        if turtles[sender] then
            turtlePeripheral = turtles[sender].peripheralName
        end
        
        if turtlePeripheral and meBridge and meBridge.importItemFromPeripheral then
            local imported = meBridge.importItemFromPeripheral(
                {name = message.item},
                turtlePeripheral,
                message.count or 64
            )
            print("[Jobs] Imported " .. (imported or 0) .. " items")
        end
        
        rednet.send(sender, {type = "PULL_RESPONSE", success = true}, config.PROTOCOL)
    end
end

-- Show status
local function showStatus()
    clear()
    print("=== Simple Jobs Computer ===")
    print()
    print("ME Bridge: " .. (meBridge and "Connected" or "Not Connected"))
    print("Protocol: " .. config.PROTOCOL)
    print()
    
    local onlineCount = 0
    local now = os.clock()
    
    for id, turtle in pairs(turtles) do
        if now - turtle.lastSeen < config.TURTLE_OFFLINE_TIMEOUT then
            onlineCount = onlineCount + 1
            local wiredInfo = turtle.peripheralName and (" [" .. turtle.peripheralName .. "]") or " [wireless]"
            print("  Turtle #" .. id .. wiredInfo)
        end
    end
    
    print("\nOnline Turtles: " .. onlineCount)
    print()
    print("Commands:")
    print("  D - Discover wired turtles")
    print("  Q - Quit")
end

-- Clean up old turtles
local function cleanupTurtles()
    local now = os.clock()
    for id, turtle in pairs(turtles) do
        if now - turtle.lastSeen > config.TURTLE_REMOVE_TIMEOUT then
            turtles[id] = nil
            
            -- Clean up wired mapping too
            for pName, tId in pairs(wiredTurtles) do
                if tId == id then
                    wiredTurtles[pName] = nil
                end
            end
        end
    end
end

-- Main loop
local function main()
    -- Initial discovery
    discoverWiredTurtles()
    
    while true do
        showStatus()
        
        parallel.waitForAny(
            function()
                while true do
                    handleMessage()
                end
            end,
            function()
                while true do
                    cleanupTurtles()
                    sleep(5)
                end
            end,
            function()
                -- Auto-discovery every 30 seconds
                while true do
                    sleep(30)
                    discoverWiredTurtles()
                end
            end,
            function()
                while true do
                    local event, key = os.pullEvent("key")
                    if key == keys.q then
                        clear()
                        print("Shutting down...")
                        rednet.unhost(config.PROTOCOL)
                        return
                    elseif key == keys.d then
                        discoverWiredTurtles()
                        sleep(2)
                    end
                end
            end
        )
        
        break
    end
end

-- Run
main()