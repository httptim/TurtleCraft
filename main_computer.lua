-- Main Computer for TurtleCraft
-- User interface for the distributed crafting system

local config = dofile("config.lua")
local network = dofile("lib/network.lua")

-- State
local running = true
local jobsComputerID = nil
local connected = false
local systemStatus = {
    turtleCount = 0,
    activeTurtleCount = 0,
    jobsRunning = false
}

-- Clear screen helper
local function clear()
    term.clear()
    term.setCursorPos(1, 1)
end

-- Display status
local function displayStatus()
    clear()
    print("TurtleCraft - Main Computer")
    print("===========================")
    print()
    print("Computer ID: " .. os.getComputerID())
    print("Jobs Computer: " .. (connected and "CONNECTED (ID: " .. jobsComputerID .. ")" or "NOT CONNECTED"))
    print()
    
    if connected then
        print("System Status:")
        if systemStatus.activeTurtleCount < systemStatus.turtleCount then
            print("  Turtles: " .. systemStatus.activeTurtleCount .. "/" .. systemStatus.turtleCount .. " active")
        else
            print("  Turtles: " .. systemStatus.turtleCount)
        end
        print("  Jobs Running: " .. (systemStatus.jobsRunning and "Yes" or "No"))
    end
    
    print()
    print("Commands:")
    print("  R - Reconnect to Jobs Computer")
    print("  S - Request Status Update")
    print("  Q - Quit")
end

-- Connect to Jobs Computer
local function connectToJobsComputer()
    print("\n[Main] Searching for Jobs Computer...")
    
    -- First try the configured ID
    if config.JOBS_COMPUTER_ID then
        print("[Main] Trying configured ID: " .. config.JOBS_COMPUTER_ID)
        local success, rtt = network.ping(config.JOBS_COMPUTER_ID)
        if success then
            jobsComputerID = config.JOBS_COMPUTER_ID
            connected = true
            print("[Main] Connected to Jobs Computer! (RTT: " .. string.format("%.3f", rtt) .. "s)")
            return true
        end
    end
    
    -- Try to find by hostname
    print("[Main] Searching by hostname...")
    local computers = network.findComputers("jobs")
    
    if #computers > 0 then
        print("[Main] Found " .. #computers .. " Jobs Computer(s)")
        
        for _, id in ipairs(computers) do
            print("[Main] Testing ID " .. id .. "...")
            local success, rtt = network.ping(id)
            if success then
                jobsComputerID = id
                connected = true
                print("[Main] Connected to Jobs Computer ID " .. id .. "! (RTT: " .. string.format("%.3f", rtt) .. "s)")
                return true
            end
        end
    end
    
    print("[Main] Could not find Jobs Computer!")
    print("[Main] Make sure Jobs Computer is running first")
    return false
end

-- Request status update
local function requestStatus()
    if not connected or not jobsComputerID then
        print("\n[Main] Not connected to Jobs Computer!")
        return
    end
    
    network.send(jobsComputerID, "STATUS_REQUEST", {})
end

-- Handle incoming messages
local function handleMessage(sender, message)
    if not message or not message.type then return end
    
    if message.type == "PONG" then
        -- Handled by ping function
        
    elseif message.type == "STATUS_RESPONSE" and sender == jobsComputerID then
        systemStatus.turtleCount = message.data.turtleCount or 0
        systemStatus.activeTurtleCount = message.data.activeTurtleCount or systemStatus.turtleCount
        systemStatus.jobsRunning = message.data.running or false
    end
end

-- Main function
local function main()
    clear()
    print("Starting Main Computer...")
    
    -- Initialize network
    if not network.init() then
        print("Failed to initialize network!")
        return
    end
    
    -- Host ourselves (optional, but helps with debugging)
    network.host("main")
    
    print("Main Computer ready!")
    sleep(1)
    
    -- Try to connect to Jobs Computer
    connectToJobsComputer()
    
    -- Request initial status
    if connected then
        requestStatus()
    end
    
    -- Main loop
    local lastDisplay = os.clock()
    local lastStatusRequest = os.clock()
    
    while running do
        -- Check for messages
        local sender, message = network.receive(0.1)
        if sender then
            handleMessage(sender, message)
        end
        
        -- Periodic status request
        if connected and os.clock() - lastStatusRequest > 5 then
            requestStatus()
            lastStatusRequest = os.clock()
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
                print("\n[Main] Reconnecting...")
                connected = false
                connectToJobsComputer()
                if connected then
                    requestStatus()
                end
                sleep(1)
            elseif p1 == keys.s then
                requestStatus()
            end
        elseif event == "timer" and p1 == timer then
            -- Timer expired, continue loop
        else
            os.cancelTimer(timer)
        end
    end
    
    -- Cleanup
    network.close()
    clear()
    print("Main Computer stopped.")
end

-- Run with error handling
local ok, err = pcall(main)
if not ok then
    print("ERROR: " .. tostring(err))
    print("\nPress any key to exit...")
    os.pullEvent("key")
end