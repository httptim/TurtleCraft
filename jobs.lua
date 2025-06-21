-- Jobs Computer for TurtleCraft
-- Central coordinator for crafting operations

local network = require("lib.network")

local COMPUTER_TYPE = "jobs"
local turtles = {}
local meBridge = nil
local craftRequests = {}  -- Track active craft requests

-- Find ME Bridge peripheral
local function findMEBridge()
    meBridge = peripheral.find("me_bridge")
    if meBridge then
        print("[OK] ME Bridge found")
        return true
    else
        printError("[X] No ME Bridge found")
        return false
    end
end

-- Discover wired turtles
local function discoverWiredTurtles()
    print("\nDiscovering wired turtles...")
    local count = 0
    
    peripheral.find("modem", function(name, modem)
        if not modem.isWireless() then
            -- Get connected names on this modem
            local connected = modem.getNamesRemote()
            for _, remoteName in ipairs(connected) do
                if peripheral.getType(remoteName) == "turtle" then
                    count = count + 1
                    print("  [OK] Found turtle: " .. remoteName)
                end
            end
        end
    end)
    
    print("Found " .. count .. " wired turtles")
    return count
end

-- Handle turtle registration
local function handleTurtleRegistration(senderId, message)
    if message.type == "register" then
        local turtleData = message.data
        turtles[senderId] = {
            id = senderId,
            name = turtleData.name,
            status = "idle",
            lastSeen = os.time()
        }
        
        print("[OK] Turtle registered: " .. turtleData.name .. " (ID: " .. senderId .. ")")
        
        -- Send confirmation
        network.send(senderId, "register_confirm", {
            success = true,
            jobsComputerId = os.getComputerID()
        })
    end
end

-- Handle heartbeat from turtles
local function handleHeartbeat(senderId, message)
    if message.type == "heartbeat" and turtles[senderId] then
        turtles[senderId].lastSeen = os.time()
        turtles[senderId].status = message.data.status or "idle"
    end
end

-- Find an available turtle
local function findAvailableTurtle()
    for id, turtle in pairs(turtles) do
        if turtle.status == "idle" then
            -- Check if turtle is still responsive
            local timeSinceLastSeen = os.time() - turtle.lastSeen
            if timeSinceLastSeen < 30 then  -- 30 second timeout
                return id, turtle
            end
        end
    end
    return nil
end

-- Handle craft request from Main Computer
local function handleCraftRequest(senderId, message)
    if message.type == "craft_request" then
        local requestId = os.time() .. "_" .. senderId
        local recipe = message.data.recipe
        
        print("Craft request from Main Computer: " .. recipe)
        
        -- Find available turtle
        local turtleId = findAvailableTurtle()
        if not turtleId then
            network.send(senderId, "craft_response", {
                success = false,
                message = "No available turtles",
                recipe = recipe,
                requestId = requestId
            })
            return
        end
        
        -- Store request info
        craftRequests[requestId] = {
            mainComputerId = senderId,
            turtleId = turtleId,
            recipe = recipe,
            timestamp = os.time()
        }
        
        -- Forward to turtle
        turtles[turtleId].status = "crafting"
        network.send(turtleId, "craft_request", {
            recipe = recipe,
            requestId = requestId
        })
        
        print("Forwarded to Turtle " .. turtleId)
    end
end

-- Handle craft response from turtle
local function handleCraftResponse(senderId, message)
    if message.type == "craft_response" then
        local requestId = message.data.requestId
        local request = craftRequests[requestId]
        
        if request then
            -- Update turtle status
            if turtles[senderId] then
                turtles[senderId].status = "idle"
            end
            
            -- Forward response to Main Computer
            network.send(request.mainComputerId, "craft_response", message.data)
            
            -- Clean up request
            craftRequests[requestId] = nil
            
            print("Craft " .. (message.data.success and "succeeded" or "failed") .. ": " .. message.data.message)
        end
    end
end

-- Main program
local function main()
    term.clear()
    term.setCursorPos(1, 1)
    print("=== TurtleCraft Jobs Computer ===")
    print("ID: " .. os.getComputerID())
    print()
    
    -- Initialize network
    if not network.initialize(COMPUTER_TYPE) then
        printError("Failed to initialize network")
        return
    end
    
    -- Find ME Bridge
    findMEBridge()
    
    -- Initial wired turtle discovery
    discoverWiredTurtles()
    
    print("\nWaiting for turtle registrations...")
    print("Press Q to quit, D to discover turtles")
    print()
    
    -- Main event loop
    local discoveryTimer = os.startTimer(30)
    
    while true do
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "rednet_message" then
            local senderId, message = p1, p2
            if message and type(message) == "table" then
                -- Handle discovery requests
                local discoveryHandler = network.handleDiscovery(COMPUTER_TYPE, "JobsComputer")
                discoveryHandler(senderId, message)
                
                -- Handle turtle registration
                handleTurtleRegistration(senderId, message)
                
                -- Handle heartbeat
                handleHeartbeat(senderId, message)
                
                -- Handle status request
                if message.type == "status_request" then
                    -- Count turtles (can't use # on non-array table)
                    local turtleCount = 0
                    for _ in pairs(turtles) do
                        turtleCount = turtleCount + 1
                    end
                    
                    network.send(senderId, "status_response", {
                        turtleCount = turtleCount,
                        hasMEBridge = meBridge ~= nil
                    })
                end
                
                -- Handle craft requests and responses
                handleCraftRequest(senderId, message)
                handleCraftResponse(senderId, message)
            end
        elseif event == "timer" and p1 == discoveryTimer then
            -- Periodic turtle discovery
            discoverWiredTurtles()
            discoveryTimer = os.startTimer(30)
        elseif event == "key" then
            local key = p1
            if key == keys.q then
                print("\nShutting down...")
                break
            elseif key == keys.d then
                discoverWiredTurtles()
            end
        end
    end
end

-- Run main program
main()