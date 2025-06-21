-- Network library for TurtleCraft
-- Handles rednet and wired modem communication

local PROTOCOL = "crafting_system"

local network = {}

-- Initialize network connections
function network.initialize(computerType)
    local success = false
    
    -- Find and open wireless modem
    local wirelessModem = peripheral.find("modem", function(name, modem)
        return modem.isWireless()
    end)
    
    if wirelessModem then
        rednet.open(peripheral.getName(wirelessModem))
        success = true
        print("[OK] Wireless modem opened")
    else
        printError("[X] No wireless modem found")
    end
    
    -- For Jobs Computer, also look for wired modems
    if computerType == "jobs" then
        local wiredModems = {}
        peripheral.find("modem", function(name, modem)
            if not modem.isWireless() then
                table.insert(wiredModems, name)
                modem.open(os.getComputerID())
            end
        end)
        
        if #wiredModems > 0 then
            print("[OK] Found " .. #wiredModems .. " wired modems")
        else
            print("[!] No wired modems found")
        end
    end
    
    -- Register this computer with rednet hosting
    -- Each computer needs a unique hostname
    local hostname = computerType .. "_" .. os.getComputerID()
    rednet.host(PROTOCOL, hostname)
    print("[OK] Registered as: " .. hostname)
    
    return success
end

-- Send a message with automatic retry
function network.send(targetId, messageType, data, timeout)
    timeout = timeout or 5
    local message = {
        type = messageType,
        data = data,
        sender = os.getComputerID(),
        timestamp = os.time()
    }
    
    rednet.send(targetId, message, PROTOCOL)
    
    -- Wait for acknowledgment
    local senderId, response = rednet.receive(PROTOCOL, timeout)
    if senderId == targetId and response and response.type == "ack" then
        return true
    end
    
    return false
end

-- Broadcast a message
function network.broadcast(messageType, data)
    local message = {
        type = messageType,
        data = data,
        sender = os.getComputerID(),
        timestamp = os.time()
    }
    
    rednet.broadcast(message, PROTOCOL)
end

-- Receive a message
function network.receive(timeout)
    local senderId, message = rednet.receive(PROTOCOL, timeout)
    
    if message and type(message) == "table" and message.type then
        -- Send acknowledgment for non-broadcast messages
        if senderId and message.type ~= "broadcast" then
            local ack = {
                type = "ack",
                originalType = message.type,
                timestamp = os.time()
            }
            rednet.send(senderId, ack, PROTOCOL)
        end
        
        return senderId, message
    end
    
    return nil, nil
end

-- Discover computers on the network
function network.discover(computerType, timeout)
    timeout = timeout or 2
    
    -- Broadcast a discovery request
    print("Broadcasting discovery request for: " .. computerType)
    local message = {
        type = "discover",
        data = {requestedType = computerType},
        sender = os.getComputerID(),
        timestamp = os.time()
    }
    rednet.broadcast(message, PROTOCOL)
    
    -- Collect responses
    local computers = {}
    local timer = os.startTimer(timeout)
    
    while true do
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "timer" and p1 == timer then
            break
        elseif event == "rednet_message" then
            local senderId, msg, protocol = p1, p2, p3
            if protocol == PROTOCOL and msg and type(msg) == "table" and msg.type == "discover_response" then
                if msg.data.type == computerType then
                    table.insert(computers, {
                        id = senderId,
                        type = msg.data.type,
                        name = msg.data.name or (computerType .. "_" .. senderId)
                    })
                    print("  Found " .. msg.data.type .. " computer ID: " .. senderId)
                end
            end
        end
    end
    
    print("Discovery complete. Found " .. #computers .. " " .. computerType .. " computers")
    return computers
end

-- Handle discovery requests
function network.handleDiscovery(computerType, computerName)
    return function(senderId, message)
        if message.type == "discover" then
            -- Respond if they're looking for our type or any type
            if not message.data.requestedType or message.data.requestedType == computerType then
                local response = {
                    type = "discover_response",
                    data = {
                        type = computerType,
                        name = computerName or (computerType .. "_" .. os.getComputerID())
                    },
                    sender = os.getComputerID(),
                    timestamp = os.time()
                }
                rednet.send(senderId, response, PROTOCOL)
                print("Responded to discovery from computer " .. senderId)
            end
        end
    end
end

return network