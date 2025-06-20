-- Simple Network Library for TurtleCraft
-- Uses rednet properly according to CC:Tweaked docs

local network = {}
local config = dofile("config.lua")

-- Find and open wireless modem
function network.init()
    print("[Network] Initializing...")
    
    -- Find wireless modem
    local modemSide = nil
    for _, side in ipairs(peripheral.getNames()) do
        if peripheral.getType(side) == "modem" then
            local modem = peripheral.wrap(side)
            if modem.isWireless() then
                modemSide = side
                break
            end
        end
    end
    
    if not modemSide then
        print("[Network] ERROR: No wireless modem found!")
        return false
    end
    
    -- Open modem for rednet
    rednet.open(modemSide)
    print("[Network] Opened modem on " .. modemSide)
    
    -- Verify it's open
    if not rednet.isOpen(modemSide) then
        print("[Network] ERROR: Failed to open modem!")
        return false
    end
    
    print("[Network] Initialization complete")
    return true
end

-- Host a service
function network.host(hostname)
    rednet.host(config.PROTOCOL, hostname)
    print("[Network] Hosting as '" .. hostname .. "' on protocol '" .. config.PROTOCOL .. "'")
end

-- Find computers
function network.findComputers(hostname)
    if config.DEBUG then
        print("[Network] Looking for '" .. (hostname or "any") .. "' on protocol '" .. config.PROTOCOL .. "'")
    end
    
    local computers = {}
    
    if hostname then
        -- Look for specific hostname
        local id = rednet.lookup(config.PROTOCOL, hostname)
        if id then
            if type(id) == "table" then
                computers = id
            else
                computers = {id}
            end
        end
    else
        -- Look for all computers on protocol
        local found = rednet.lookup(config.PROTOCOL)
        if found then
            if type(found) == "table" then
                -- Found can be either array of IDs or table of hostname->ID
                for k, v in pairs(found) do
                    if type(v) == "number" then
                        table.insert(computers, v)
                    elseif type(k) == "number" then
                        table.insert(computers, k)
                    end
                end
            else
                computers = {found}
            end
        end
    end
    
    if config.DEBUG then
        print("[Network] Found " .. #computers .. " computer(s)")
    end
    
    return computers
end

-- Send a message
function network.send(recipient, msgType, data)
    local message = {
        type = msgType,
        data = data,
        sender = os.getComputerID(),
        time = os.clock()
    }
    
    local success = rednet.send(recipient, message, config.PROTOCOL)
    
    if config.DEBUG then
        print("[Network] Sent " .. msgType .. " to " .. recipient .. " - " .. (success and "OK" or "FAILED"))
    end
    
    return success
end

-- Broadcast a message
function network.broadcast(msgType, data)
    local message = {
        type = msgType,
        data = data,
        sender = os.getComputerID(),
        time = os.clock()
    }
    
    rednet.broadcast(message, config.PROTOCOL)
    
    if config.DEBUG then
        print("[Network] Broadcast " .. msgType)
    end
end

-- Receive messages (non-blocking check)
function network.receive(timeout)
    local sender, message, protocol = rednet.receive(config.PROTOCOL, timeout or 0)
    
    if sender and type(message) == "table" and message.type then
        if config.DEBUG then
            print("[Network] Received " .. message.type .. " from " .. sender)
        end
        return sender, message
    end
    
    return nil, nil
end

-- Simple ping test
function network.ping(target)
    network.send(target, "PING", {})
    
    local startTime = os.clock()
    local timeout = 2
    
    while os.clock() - startTime < timeout do
        local sender, message = network.receive(0.1)
        if sender == target and message and message.type == "PONG" then
            return true, os.clock() - startTime
        end
    end
    
    return false
end

-- Cleanup
function network.close()
    rednet.unhost(config.PROTOCOL)
    rednet.close()
    print("[Network] Closed")
end

return network