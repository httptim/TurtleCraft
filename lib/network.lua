-- lib/network.lua
-- Network communication library for CC:Tweaked Distributed Crafting System

local network = {}

-- Dependencies
local logger = dofile("lib/logger.lua")
local utils = dofile("lib/utils.lua")

-- Network state
local state = {
    protocol = nil,
    computerID = os.getComputerID(),
    wirelessModem = nil,
    wiredModem = nil,
    messageHandlers = {},
    pendingResponses = {},
    messageID = 0,
    initialized = false
}

-- Initialize network with config
function network.init(config)
    if state.initialized then
        logger.warn("Network already initialized", "NETWORK")
        return true
    end
    
    -- Set protocol
    state.protocol = config.REDNET_PROTOCOL or "crafting_system"
    
    -- Find and open wireless modem
    if config.PERIPHERALS.WIRELESS_MODEM then
        state.wirelessModem = peripheral.wrap(config.PERIPHERALS.WIRELESS_MODEM)
        if state.wirelessModem then
            rednet.open(config.PERIPHERALS.WIRELESS_MODEM)
            logger.info("Opened wireless modem: " .. config.PERIPHERALS.WIRELESS_MODEM, "NETWORK")
            
            -- Verify it's actually open
            if rednet.isOpen(config.PERIPHERALS.WIRELESS_MODEM) then
                logger.info("Wireless modem verified open", "NETWORK")
            else
                logger.error("Wireless modem failed to open properly", "NETWORK")
                return false
            end
        else
            logger.error("Failed to wrap wireless modem", "NETWORK")
            return false
        end
    else
        logger.error("No wireless modem configured", "NETWORK")
        return false
    end
    
    -- Find and open wired modem (if available)
    if config.PERIPHERALS.WIRED_MODEM then
        state.wiredModem = peripheral.wrap(config.PERIPHERALS.WIRED_MODEM)
        if state.wiredModem then
            state.wiredModem.open(os.getComputerID())
            logger.info("Opened wired modem: " .. config.PERIPHERALS.WIRED_MODEM, "NETWORK")
        end
    end
    
    -- Host protocol
    if state.wirelessModem then
        local hostname = config.COMPUTER_TYPE .. "_" .. os.getComputerID()
        rednet.host(state.protocol, hostname)
        logger.info("Hosting on protocol '" .. state.protocol .. "' with hostname '" .. hostname .. "'", "NETWORK")
    end
    
    state.initialized = true
    logger.info("Network initialized with protocol: " .. state.protocol, "NETWORK")
    return true
end

-- Shutdown network
function network.shutdown()
    if state.wirelessModem then
        rednet.unhost(state.protocol)
        rednet.close(peripheral.getName(state.wirelessModem))
    end
    
    if state.wiredModem then
        state.wiredModem.close(os.getComputerID())
    end
    
    state.initialized = false
    logger.info("Network shutdown", "NETWORK")
end

-- Generate unique message ID
local function generateMessageID()
    state.messageID = state.messageID + 1
    return string.format("%d_%d_%d", os.getComputerID(), os.clock(), state.messageID)
end

-- Create message envelope
local function createMessage(messageType, data, responseID)
    return {
        id = generateMessageID(),
        type = messageType,
        sender = os.getComputerID(),
        timestamp = os.clock(),
        data = data,
        responseID = responseID,
        protocol = state.protocol
    }
end

-- Send message via rednet
function network.send(recipient, messageType, data, waitForResponse)
    if not state.initialized then
        logger.error("Network not initialized", "NETWORK")
        return false, "Network not initialized"
    end
    
    local message = createMessage(messageType, data)
    
    -- Log the send
    logger.logNetworkSend(recipient, messageType, data)
    
    -- Send the message
    local success = rednet.send(recipient, message, state.protocol)
    
    if not success then
        logger.error("Failed to send message to " .. recipient, "NETWORK")
        return false, "Failed to send message"
    end
    
    -- If waiting for response, track it
    if waitForResponse then
        state.pendingResponses[message.id] = {
            sent = os.clock(),
            recipient = recipient,
            type = messageType
        }
        
        -- Wait for response with timeout
        local timeout = CONFIG.NETWORK_TIMEOUT or 5
        local timer = os.startTimer(timeout)
        
        while true do
            local event, p1, p2, p3 = os.pullEvent()
            
            if event == "timer" and p1 == timer then
                -- Timeout
                state.pendingResponses[message.id] = nil
                logger.warn("Response timeout for message " .. message.id, "NETWORK")
                return false, "Response timeout"
                
            elseif event == "rednet_message" and p1 == recipient then
                local response = p2
                if type(response) == "table" and response.responseID == message.id then
                    -- Got our response
                    state.pendingResponses[message.id] = nil
                    logger.logNetworkReceive(p1, response.type, response.data)
                    return true, response
                end
            end
        end
    end
    
    return true
end

-- Broadcast message
function network.broadcast(messageType, data)
    if not state.initialized then
        logger.error("Network not initialized", "NETWORK")
        return false
    end
    
    local message = createMessage(messageType, data)
    
    logger.logNetworkSend("BROADCAST", messageType, data)
    rednet.broadcast(message, state.protocol)
    
    return true
end

-- Send response to a message
function network.respond(originalMessage, responseType, responseData)
    if not originalMessage or not originalMessage.sender then
        logger.error("Invalid original message for response", "NETWORK")
        return false
    end
    
    local response = createMessage(responseType, responseData, originalMessage.id)
    
    logger.logNetworkSend(originalMessage.sender, responseType, responseData)
    return rednet.send(originalMessage.sender, response, state.protocol)
end

-- Register message handler
function network.on(messageType, handler)
    if not state.messageHandlers[messageType] then
        state.messageHandlers[messageType] = {}
    end
    
    table.insert(state.messageHandlers[messageType], handler)
    logger.debug("Registered handler for " .. messageType, "NETWORK")
end

-- Process incoming message
local function processMessage(sender, message)
    -- Validate message
    if type(message) ~= "table" or not message.type then
        logger.debug("Invalid message from " .. sender, "NETWORK")
        return
    end
    
    -- Check protocol
    if message.protocol ~= state.protocol then
        logger.debug("Wrong protocol from " .. sender .. ": " .. tostring(message.protocol), "NETWORK")
        return
    end
    
    -- Log receipt
    logger.logNetworkReceive(sender, message.type, message.data)
    
    -- Check if this is a response we're waiting for
    if message.responseID and state.pendingResponses[message.responseID] then
        -- This will be handled by the waiting send() call
        return
    end
    
    -- Call registered handlers
    local handlers = state.messageHandlers[message.type]
    if handlers then
        for _, handler in ipairs(handlers) do
            local success, err = pcall(handler, sender, message)
            if not success then
                logger.error("Handler error for " .. message.type .. ": " .. tostring(err), "NETWORK")
            end
        end
    else
        logger.debug("No handler for message type: " .. message.type, "NETWORK")
    end
end

-- Main message listening loop
function network.listen()
    if not state.initialized then
        logger.error("Network not initialized", "NETWORK")
        return
    end
    
    logger.info("Network listening started", "NETWORK")
    
    while true do
        local event, sender, message, protocol = os.pullEvent("rednet_message")
        
        if protocol == state.protocol then
            processMessage(sender, message)
        end
    end
end

-- Start listening in parallel
function network.startListening()
    return function()
        network.listen()
    end
end

-- Find computers by type
function network.findComputers(computerType, timeout)
    timeout = timeout or 2
    local found = {}
    
    -- Get all computers on our protocol first
    local allComputers = rednet.lookup(state.protocol)
    
    if allComputers then
        -- Convert single result to table
        if type(allComputers) == "number" then
            allComputers = {allComputers}
        end
        
        -- If we have computers, process them
        if type(allComputers) == "table" then
            for hostname, id in pairs(allComputers) do
                -- hostname might be the key or value depending on lookup result
                local computerId = nil
                local hostString = nil
                
                if type(hostname) == "number" then
                    -- ID is the key, need to do individual lookup
                    computerId = hostname
                    local hosts = rednet.lookup(state.protocol)
                    -- For each computer, check if it matches our type
                    if computerType then
                        -- Try specific hostname lookup
                        local specificHost = rednet.lookup(state.protocol, computerType .. "_" .. computerId)
                        if specificHost == computerId then
                            table.insert(found, computerId)
                        end
                    else
                        -- No type filter, add all
                        table.insert(found, computerId)
                    end
                elseif type(id) == "number" then
                    -- Normal case: hostname is string, id is number
                    computerId = id
                    hostString = hostname
                    
                    if computerType then
                        -- Check if hostname matches pattern
                        if string.sub(hostString, 1, #computerType + 1) == computerType .. "_" then
                            table.insert(found, computerId)
                        end
                    else
                        -- No type filter, add all
                        table.insert(found, computerId)
                    end
                end
            end
        end
    end
    
    -- Also try direct lookup with type pattern
    if computerType and #found == 0 then
        -- Try lookup with exact hostname pattern
        for i = 0, 255 do  -- Check reasonable computer ID range
            local hostname = computerType .. "_" .. i
            local result = rednet.lookup(state.protocol, hostname)
            if result then
                if type(result) == "number" then
                    table.insert(found, result)
                elseif type(result) == "table" then
                    for _, id in ipairs(result) do
                        if not utils.tableContains(found, id) then
                            table.insert(found, id)
                        end
                    end
                end
            end
        end
    end
    
    logger.debug("Found " .. #found .. " computers of type: " .. (computerType or "any"), "NETWORK")
    
    return found
end

-- Ping a computer
function network.ping(computerID, timeout)
    timeout = timeout or 2
    
    local success, response = network.send(computerID, "PING", {
        timestamp = os.clock()
    }, true)
    
    if success and response then
        local rtt = os.clock() - response.data.timestamp
        return true, rtt
    end
    
    return false
end

-- Get network statistics
function network.getStats()
    return {
        computerID = state.computerID,
        protocol = state.protocol,
        initialized = state.initialized,
        pendingResponses = #state.pendingResponses,
        messageHandlers = (function()
            local count = 0
            for msgType, handlers in pairs(state.messageHandlers) do
                count = count + #handlers
            end
            return count
        end)(),
        totalMessagesSent = state.messageID
    }
end

-- Wired network functions (for item transfer)
function network.sendWiredMessage(channel, replyChannel, message)
    if not state.wiredModem then
        logger.error("No wired modem available", "NETWORK")
        return false
    end
    
    state.wiredModem.transmit(channel, replyChannel, message)
    return true
end

function network.receiveWiredMessage(channel, timeout)
    if not state.wiredModem then
        logger.error("No wired modem available", "NETWORK")
        return nil
    end
    
    state.wiredModem.open(channel)
    
    local timer = nil
    if timeout then
        timer = os.startTimer(timeout)
    end
    
    while true do
        local event, side, senderChannel, replyChannel, message, distance = os.pullEvent()
        
        if event == "modem_message" and senderChannel == channel then
            if timer then os.cancelTimer(timer) end
            state.wiredModem.close(channel)
            return message, replyChannel, distance
            
        elseif event == "timer" and timer and side == timer then
            state.wiredModem.close(channel)
            return nil
        end
    end
end

-- Utility function to check network connectivity
function network.checkConnectivity()
    local report = {
        wireless = false,
        wired = false,
        protocol = state.protocol,
        jobs_computer = false,
        main_computer = false,
        turtles = 0
    }
    
    -- Check wireless
    if state.wirelessModem then
        report.wireless = true
        
        -- Try to find other computers
        local mains = network.findComputers("main")
        local jobs = network.findComputers("jobs")
        local turtles = network.findComputers("turtle")
        
        report.main_computer = #mains > 0
        report.jobs_computer = #jobs > 0
        report.turtles = #turtles
    end
    
    -- Check wired
    if state.wiredModem then
        report.wired = true
    end
    
    return report
end

-- Default ping handler
network.on("PING", function(sender, message)
    logger.debug("Received PING from " .. sender, "NETWORK")
    network.respond(message, "PONG", {
        timestamp = message.data.timestamp,
        computerID = os.getComputerID()
    })
end)

return network