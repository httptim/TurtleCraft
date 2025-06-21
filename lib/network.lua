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
    
    -- Use rednet.lookup to find ALL computers hosting our protocol
    local results = {rednet.lookup(PROTOCOL)}
    
    print("Found " .. #results .. " computers on network")
    
    local computers = {}
    for _, id in ipairs(results) do
        print("  Checking computer ID: " .. id)
        -- Get more info about each computer to check its type
        local sent = network.send(id, "info_request", {}, 1)
        if sent then
            local senderId, response = network.receive(1)
            
            if senderId == id and response and response.type == "info_response" then
                print("    Type: " .. (response.data.type or "unknown"))
                -- Check if this is the type we're looking for
                if response.data.type == computerType then
                    table.insert(computers, {
                        id = id,
                        type = response.data.type,
                        name = response.data.name or (computerType .. "_" .. id)
                    })
                    print("    [OK] Added to results")
                end
            else
                print("    [!] No response")
            end
        else
            print("    [!] Failed to send info request")
        end
    end
    
    return computers
end

-- Handle info requests for discovery
function network.handleInfoRequest(computerType, computerName)
    return function(senderId, message)
        if message.type == "info_request" then
            network.send(senderId, "info_response", {
                type = computerType,
                name = computerName or (computerType .. "_" .. os.getComputerID())
            })
        end
    end
end

return network