-- Simple Jobs Computer for TurtleCraft
-- Manages ME system and coordinates with turtles

local ME_BRIDGE_SIDE = "back"  -- Change this to match your setup
local PROTOCOL = "turtlecraft"
local TIMEOUT = 30

-- State
local turtles = {}
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

local function waitForItemTransfer(turtleId, itemName, count)
    -- Give items time to transfer
    print("[Jobs] Waiting for item transfer to complete...")
    sleep(2)  -- Simple fixed delay
    
    -- For wired turtles, we could check inventory here
    -- But for wireless, we just trust the ME system
    return true
end

-- Handle turtle messages
local function handleMessage()
    local sender, message = rednet.receive(PROTOCOL, 1)
    if not sender or not message then return end
    
    if message.type == "REGISTER" then
        print("[Jobs] Turtle #" .. sender .. " registered")
        turtles[sender] = {
            id = sender,
            lastSeen = os.clock()
        }
        rednet.send(sender, {type = "REGISTER_ACK"}, PROTOCOL)
        
    elseif message.type == "HEARTBEAT" then
        if turtles[sender] then
            turtles[sender].lastSeen = os.clock()
        end
        
    elseif message.type == "REQUEST_ITEMS" then
        print("[Jobs] Turtle #" .. sender .. " requests " .. message.count .. "x " .. message.item)
        
        -- Check if ME Bridge is connected
        if not meBridge or not meBridge.getItem then
            rednet.send(sender, {
                type = "ITEMS_RESPONSE",
                success = false,
                error = "ME Bridge not connected"
            }, PROTOCOL)
            return
        end
        
        -- Export items to turtle
        local success = false
        local exported = 0
        
        -- For wireless turtles, export to a chest they can access
        -- For wired turtles, export directly to them
        -- This is simplified - assumes turtles pull from a shared chest
        
        local items = meBridge.getItem({name = message.item})
        if items and items.amount >= message.count then
            -- Simple export - you'll need to adjust based on your setup
            exported = meBridge.exportItem({name = message.item}, message.count, "up")
            if exported > 0 then
                success = true
                waitForItemTransfer(sender, message.item, exported)
            end
        end
        
        rednet.send(sender, {
            type = "ITEMS_RESPONSE",
            success = success,
            item = message.item,
            count = exported
        }, PROTOCOL)
        
    elseif message.type == "DEPOSIT_ITEMS" then
        print("[Jobs] Turtle #" .. sender .. " depositing items")
        -- Turtles should deposit to a chest that the ME system imports from
        rednet.send(sender, {
            type = "DEPOSIT_RESPONSE",
            success = true
        }, PROTOCOL)
    end
end

-- Show status
local function showStatus()
    clear()
    print("=== Simple Jobs Computer ===")
    print()
    print("ME Bridge: " .. (meBridge and "Connected" or "Not Connected"))
    print("Active Turtles: " .. #turtles)
    print()
    
    local now = os.clock()
    for id, turtle in pairs(turtles) do
        local age = math.floor(now - turtle.lastSeen)
        local status = age < 10 and "Online" or "Offline"
        print("  Turtle #" .. id .. " - " .. status)
    end
    
    print()
    print("Press Q to quit")
end

-- Clean up old turtles
local function cleanupTurtles()
    local now = os.clock()
    for id, turtle in pairs(turtles) do
        if now - turtle.lastSeen > 30 then
            turtles[id] = nil
        end
    end
end

-- Main loop
local function main()
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
                end
            end
        )
        
        break
    end
end

-- Run
main()