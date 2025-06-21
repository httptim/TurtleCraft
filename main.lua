-- Main Computer for TurtleCraft
-- User interface for the crafting system

local network = require("lib.network")

local COMPUTER_TYPE = "main"
local jobsComputerId = nil

-- Find Jobs Computer
local function findJobsComputer()
    print("Searching for Jobs Computer...")
    
    local jobsComputers = network.discover("jobs", 5)
    
    if #jobsComputers == 0 then
        printError("[X] No Jobs Computer found")
        return false
    end
    
    jobsComputerId = jobsComputers[1].id
    print("[OK] Found Jobs Computer ID: " .. jobsComputerId)
    return true
end

-- Get system status from Jobs Computer
local function getSystemStatus()
    if not jobsComputerId then
        return nil
    end
    
    -- Request status
    local success = network.send(jobsComputerId, "status_request", {})
    if not success then
        return nil
    end
    
    -- Wait for response
    local senderId, message = network.receive(2)
    if senderId == jobsComputerId and message and message.type == "status_response" then
        return message.data
    end
    
    return nil
end

-- Display main menu
local function displayMenu()
    term.clear()
    term.setCursorPos(1, 1)
    print("=== TurtleCraft Main Computer ===")
    print("ID: " .. os.getComputerID())
    
    if jobsComputerId then
        print("Jobs Computer: Connected (ID: " .. jobsComputerId .. ")")
    else
        print("Jobs Computer: Not connected")
    end
    
    print("\n--- Menu ---")
    print("[S] System Status")
    print("[R] Reconnect to Jobs Computer")
    print("[Q] Quit")
    print("\nChoice: ")
end

-- Show system status
local function showSystemStatus()
    term.clear()
    term.setCursorPos(1, 1)
    print("=== System Status ===")
    
    local status = getSystemStatus()
    if status then
        print("\nJobs Computer Status:")
        print("  Turtles: " .. (status.turtleCount or 0))
        print("  ME Bridge: " .. (status.hasMEBridge and "Connected" or "Not found"))
    else
        printError("\n[X] Failed to get status from Jobs Computer")
    end
    
    print("\nPress any key to continue...")
    os.pullEvent("key")
end

-- Main program
local function main()
    -- Initialize network
    if not network.initialize(COMPUTER_TYPE) then
        printError("Failed to initialize network")
        return
    end
    
    -- Find Jobs Computer
    findJobsComputer()
    
    -- Main loop
    while true do
        displayMenu()
        
        local event, key = os.pullEvent("key")
        
        if key == keys.s then
            showSystemStatus()
        elseif key == keys.r then
            term.clear()
            term.setCursorPos(1, 1)
            findJobsComputer()
            sleep(1)
        elseif key == keys.q then
            term.clear()
            term.setCursorPos(1, 1)
            print("Shutting down...")
            break
        end
    end
end

-- Handle network messages in background
local function handleNetworkMessages()
    while true do
        local senderId, message = network.receive()
        if message then
            -- Handle discovery requests
            local discoveryHandler = network.handleDiscovery(COMPUTER_TYPE, "MainComputer")
            discoveryHandler(senderId, message)
        end
    end
end

-- Run both main and network handler in parallel
parallel.waitForAny(main, handleNetworkMessages)