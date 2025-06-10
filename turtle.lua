-- Turtle Client for TurtleCraft
-- Crafting turtle that connects to the Jobs Computer

local config = dofile("config.lua")
local network = dofile("lib/network.lua")

-- State
local running = true
local jobsComputerID = nil
local registered = false

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
    end
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