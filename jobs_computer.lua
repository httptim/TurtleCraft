-- Jobs Computer for TurtleCraft
-- Central manager for the distributed crafting system

local config = dofile("config.lua")
local network = dofile("lib/network.lua")

-- State
local running = true
local turtles = {}

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
    print("Press Q to quit")
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
            running = true
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
    
    print("Jobs Computer ready!")
    print("Waiting for connections...")
    sleep(2)
    
    -- Main loop
    local lastHealthCheck = os.clock()
    local lastDisplay = os.clock()
    
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
        
        -- Update display
        if os.clock() - lastDisplay > 1 then
            displayStatus()
            lastDisplay = os.clock()
        end
        
        -- Check for user input (non-blocking)
        local timer = os.startTimer(0.1)
        local event, p1, p2 = os.pullEvent()
        if event == "key" and p1 == keys.q then
            running = false
        elseif event == "timer" and p1 == timer then
            -- Timer expired, continue loop
        else
            os.cancelTimer(timer)
        end
    end
    
    -- Cleanup
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