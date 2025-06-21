-- Turtle client for TurtleCraft
-- Handles crafting operations and communication

local network = require("lib.network")

local COMPUTER_TYPE = "turtle"
local turtleName = "Turtle_" .. os.getComputerID()
local jobsComputerId = nil
local status = "idle"

-- Register with Jobs Computer
local function registerWithJobs()
    print("Searching for Jobs Computer...")
    
    -- Discover Jobs Computers
    local jobsComputers = network.discover("jobs", 5)
    
    if #jobsComputers == 0 then
        printError("[X] No Jobs Computer found")
        return false
    end
    
    -- Register with first Jobs Computer found
    local jobs = jobsComputers[1]
    print("Found Jobs Computer ID: " .. jobs.id)
    
    local success = network.send(jobs.id, "register", {
        name = turtleName,
        fuelLevel = turtle.getFuelLevel(),
        hasWiredModem = peripheral.find("modem", function(name, m) return not m.isWireless() end) ~= nil
    }, 10)
    
    if success then
        jobsComputerId = jobs.id
        print("[OK] Registered with Jobs Computer")
        return true
    else
        printError("[X] Failed to register")
        return false
    end
end

-- Send heartbeat to Jobs Computer
local function sendHeartbeat()
    if jobsComputerId then
        network.send(jobsComputerId, "heartbeat", {
            status = status,
            fuelLevel = turtle.getFuelLevel()
        })
    end
end

-- Check inventory for items
local function getInventoryCount()
    local count = 0
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            count = count + item.count
        end
    end
    return count
end

-- Main program
local function main()
    term.clear()
    term.setCursorPos(1, 1)
    print("=== TurtleCraft Turtle ===")
    print("ID: " .. os.getComputerID())
    print("Name: " .. turtleName)
    print()
    
    -- Initialize network
    if not network.initialize(COMPUTER_TYPE) then
        printError("Failed to initialize network")
        return
    end
    
    -- Check fuel
    if turtle.getFuelLevel() == 0 then
        printError("[!] Warning: No fuel!")
        print("Please add fuel to slot 1 and press any key")
        os.pullEvent("key")
        turtle.select(1)
        turtle.refuel()
    end
    print("Fuel: " .. turtle.getFuelLevel())
    
    -- Register with Jobs Computer
    local registered = false
    local retryCount = 0
    while not registered and retryCount < 3 do
        registered = registerWithJobs()
        if not registered then
            retryCount = retryCount + 1
            print("Retrying in 5 seconds... (" .. retryCount .. "/3)")
            sleep(5)
        end
    end
    
    if not registered then
        printError("Failed to register after 3 attempts")
        return
    end
    
    print("\nRunning... Press Q to quit")
    print("Status: " .. status)
    
    -- Main event loop
    local heartbeatTimer = os.startTimer(10)
    
    while true do
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "rednet_message" then
            local senderId, message = p1, p2
            if message and type(message) == "table" and senderId == jobsComputerId then
                -- Handle info requests
                local infoHandler = network.handleInfoRequest(COMPUTER_TYPE, turtleName)
                infoHandler(senderId, message)
                
                -- Handle commands from Jobs Computer
                if message.type == "ping" then
                    network.send(senderId, "pong", {
                        status = status,
                        fuelLevel = turtle.getFuelLevel(),
                        itemCount = getInventoryCount()
                    })
                elseif message.type == "status_request" then
                    network.send(senderId, "status_response", {
                        status = status,
                        fuelLevel = turtle.getFuelLevel(),
                        itemCount = getInventoryCount()
                    })
                end
            end
        elseif event == "timer" and p1 == heartbeatTimer then
            -- Send heartbeat
            sendHeartbeat()
            heartbeatTimer = os.startTimer(10)
        elseif event == "key" then
            local key = p1
            if key == keys.q then
                print("\nShutting down...")
                if jobsComputerId then
                    network.send(jobsComputerId, "unregister", {
                        reason = "shutdown"
                    })
                end
                break
            end
        end
    end
end

-- Run main program
main()