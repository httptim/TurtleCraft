-- Simple Jobs Computer for TurtleCraft
-- Manages ME system and sends items directly to turtles

local ME_BRIDGE_SIDE = "back"  -- Change this to match your setup
local PROTOCOL = "turtlecraft"

-- State
local turtles = {}
local wiredTurtles = {}  -- Maps peripheral names to turtle IDs
local meBridge = nil

-- Initialize
print("Simple Jobs Computer Starting...")
print("Computer ID: " .. os.getComputerID())

-- Open rednet
peripheral.find("modem", rednet.open)
rednet.host(PROTOCOL, "jobs")

-- Connect to ME Bridge
meBridge = peripheral.wrap(ME_BRIDGE_SIDE)
if not meBridge then
    error("No ME Bridge found on " .. ME_BRIDGE_SIDE)
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
                }, PROTOCOL)
            end
        end
    end
    
    print("[Discovery] Found " .. found .. " wired turtles")
    return found
end

-- Handle turtle messages
local function handleMessage()
    local sender, message = rednet.receive(PROTOCOL, 0.5)
    if not sender or not message then return end
    
    if message.type == "REGISTER" then
        print("\n[Jobs] Turtle #" .. sender .. " registered")
        turtles[sender] = {
            id = sender,
            lastSeen = os.clock(),
            peripheralName = nil
        }
        rednet.send(sender, {type = "REGISTER_ACK"}, PROTOCOL)
        
        -- Auto-discover if we have wired turtles
        discoverWiredTurtles()
        
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
            }, PROTOCOL)
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
        }, PROTOCOL)
        
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
        
        rednet.send(sender, {type = "PULL_RESPONSE", success = true}, PROTOCOL)
    end
end

-- Show status
local function showStatus()
    clear()
    print("=== Simple Jobs Computer ===")
    print()
    print("ME Bridge: " .. (meBridge and "Connected" or "Not Connected"))
    print("Protocol: " .. PROTOCOL)
    print()
    
    local onlineCount = 0
    local now = os.clock()
    
    for id, turtle in pairs(turtles) do
        if now - turtle.lastSeen < 10 then
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
        if now - turtle.lastSeen > 30 then
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
                local event, key = os.pullEvent("key")
                if key == keys.q then
                    clear()
                    print("Shutting down...")
                    rednet.unhost(PROTOCOL)
                    return
                elseif key == keys.d then
                    discoverWiredTurtles()
                    sleep(2)
                end
            end
        )
        
        break
    end
end

-- Run
main()