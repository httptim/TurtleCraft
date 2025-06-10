-- jobs_computer.lua
-- Jobs Computer for CC:Tweaked Distributed Crafting System
-- Central operations manager, ME Bridge interface, and turtle coordinator

-- Load libraries
local utils = dofile("lib/utils.lua")
local logger = dofile("lib/logger.lua")
local network = dofile("lib/network.lua")

-- Load configuration template
dofile("config_template.lua")

-- Global state
local state = {
    running = true,
    turtles = {},  -- registered turtles
    queue = {},    -- job queue
    meBridge = nil,
    connected = {
        mainComputers = {},
        turtles = {}
    }
}

-- Detect and configure peripherals
local function detectAndConfigure()
    -- Auto-detect peripherals
    local detected = utils.detectPeripherals()
    
    -- Display detection results
    utils.displayPeripheralDetection(detected, "jobs")
    
    -- Check for required peripherals
    local hasMonitor = #detected.monitors > 0
    local hasWireless = #detected.modems.wireless > 0
    local hasWired = #detected.modems.wired > 0
    local hasMEBridge = #detected.me_bridges > 0
    
    if not hasMonitor or not hasWireless or not hasWired or not hasMEBridge then
        term.setCursorPos(3, 18)
        term.setTextColor(colors.red)
        print("ERROR: Missing required peripherals!")
        if not hasMonitor then print("  - No monitor detected") end
        if not hasWireless then print("  - No wireless modem detected") end
        if not hasWired then print("  - No wired modem detected") end
        if not hasMEBridge then print("  - No ME Bridge detected") end
        term.setTextColor(colors.white)
        return nil
    end
    
    -- Build configuration
    local config = {
        computer_type = "jobs",
        monitor = detected.monitors[1] and detected.monitors[1].name or nil,
        wireless_modem = detected.modems.wireless[1] or nil,
        wired_modem = detected.modems.wired[1] or nil,
        me_bridge = detected.me_bridges[1] or nil
    }
    
    -- Display configuration
    utils.displayConfiguration(config, "jobs")
    
    -- Confirm configuration
    if not utils.promptYesNo("Is this configuration correct?", 3, 19) then
        return nil
    end
    
    -- Save configuration?
    term.setCursorPos(3, 20)
    if utils.promptYesNo("Save configuration to config.lua?", 3, 20) then
        utils.saveConfig(config)
        sleep(0.5)
    end
    
    return config
end

-- Initialize system
local function initialize()
    utils.clearScreen()
    print("CC:Tweaked Distributed Crafting System - Jobs Computer")
    print("======================================================")
    print()
    
    -- Check for existing config
    local config = utils.loadConfig()
    
    if not config then
        print("No configuration found. Starting auto-detection...")
        sleep(1)
        
        config = detectAndConfigure()
        if not config then
            print("\nConfiguration cancelled. Exiting...")
            return false
        end
    else
        print("Loaded existing configuration.")
    end
    
    -- Update global CONFIG
    CONFIG.COMPUTER_TYPE = config.computer_type or CONFIG.COMPUTER_TYPE
    CONFIG.PERIPHERALS.MONITOR = config.monitor or CONFIG.PERIPHERALS.MONITOR
    CONFIG.PERIPHERALS.WIRELESS_MODEM = config.wireless_modem or CONFIG.PERIPHERALS.WIRELESS_MODEM
    CONFIG.PERIPHERALS.WIRED_MODEM = config.wired_modem or CONFIG.PERIPHERALS.WIRED_MODEM
    CONFIG.PERIPHERALS.ME_BRIDGE = config.me_bridge or CONFIG.PERIPHERALS.ME_BRIDGE
    
    -- Initialize logger
    logger.init(CONFIG)
    logger.info("Jobs Computer starting up", "JOBS")
    
    -- Initialize network
    if not network.init(CONFIG) then
        logger.error("Failed to initialize network", "JOBS")
        return false
    end
    
    -- Initialize ME Bridge
    if CONFIG.PERIPHERALS.ME_BRIDGE then
        state.meBridge = peripheral.wrap(CONFIG.PERIPHERALS.ME_BRIDGE)
        if state.meBridge then
            logger.info("ME Bridge connected: " .. CONFIG.PERIPHERALS.ME_BRIDGE, "JOBS")
        else
            logger.error("Failed to wrap ME Bridge", "JOBS")
            return false
        end
    end
    
    return true
end

-- Turtle management
local function registerTurtle(turtleID, turtleData)
    state.turtles[turtleID] = {
        id = turtleID,
        type = turtleData.type or "crafty",
        status = TURTLE_STATUS.IDLE,
        lastHeartbeat = os.clock(),
        jobsCompleted = 0,
        currentJob = nil,
        registered = os.clock()
    }
    
    logger.info("Turtle #" .. turtleID .. " registered", "JOBS")
    
    -- Notify main computers
    broadcastSystemUpdate()
end

local function updateTurtleHeartbeat(turtleID)
    if state.turtles[turtleID] then
        state.turtles[turtleID].lastHeartbeat = os.clock()
    end
end

local function checkTurtleHealth()
    local timeout = CONFIG.TURTLE_OFFLINE_TIMEOUT or 120
    local currentTime = os.clock()
    
    for id, turtle in pairs(state.turtles) do
        if currentTime - turtle.lastHeartbeat > timeout then
            if turtle.status ~= TURTLE_STATUS.OFFLINE then
                turtle.status = TURTLE_STATUS.OFFLINE
                logger.warn("Turtle #" .. id .. " marked offline", "JOBS")
                
                -- Handle any active job
                if turtle.currentJob then
                    -- Will reassign job in later phases
                    logger.error("Turtle #" .. id .. " went offline with active job", "JOBS")
                end
            end
        end
    end
end

-- System status broadcasting
function broadcastSystemUpdate()
    local status = {
        turtles = utils.tableCount(state.turtles),
        queue = #state.queue,
        activeTurtles = 0,
        meBridge = state.meBridge ~= nil
    }
    
    -- Count active turtles
    for _, turtle in pairs(state.turtles) do
        if turtle.status ~= TURTLE_STATUS.OFFLINE then
            status.activeTurtles = status.activeTurtles + 1
        end
    end
    
    network.broadcast(MESSAGE_TYPES.STATUS_UPDATE, status)
end

-- Message handlers
local function setupMessageHandlers()
    -- Turtle registration
    network.on(MESSAGE_TYPES.REGISTER, function(sender, message)
        logger.info("Registration request from computer #" .. sender, "JOBS")
        
        -- Register the turtle
        registerTurtle(sender, message.data or {})
        
        -- Send acknowledgment
        network.respond(message, MESSAGE_TYPES.REGISTER_ACK, {
            success = true,
            config = {
                updateInterval = CONFIG.UPDATE_INTERVAL,
                heartbeatInterval = CONFIG.HEARTBEAT_INTERVAL
            }
        })
    end)
    
    -- Turtle heartbeat
    network.on(MESSAGE_TYPES.HEARTBEAT, function(sender, message)
        updateTurtleHeartbeat(sender)
        
        -- Send acknowledgment
        network.respond(message, MESSAGE_TYPES.HEARTBEAT_ACK, {
            timestamp = os.clock()
        })
    end)
    
    -- System status request
    network.on(MESSAGE_TYPES.SYSTEM_STATUS, function(sender, message)
        local status = {
            turtles = utils.tableCount(state.turtles),
            queue = #state.queue,
            meBridge = state.meBridge ~= nil,
            activeTurtles = 0
        }
        
        for _, turtle in pairs(state.turtles) do
            if turtle.status ~= TURTLE_STATUS.OFFLINE then
                status.activeTurtles = status.activeTurtles + 1
            end
        end
        
        network.respond(message, MESSAGE_TYPES.SYSTEM_STATUS, status)
    end)
    
    -- Craft request (from Main Computer)
    network.on(MESSAGE_TYPES.CRAFT_REQUEST, function(sender, message)
        logger.info("Craft request from computer #" .. sender .. ": " .. 
                   (message.data.item or "unknown"), "JOBS")
        
        -- In Phase 1, just acknowledge receipt
        -- Full implementation in later phases
        network.respond(message, MESSAGE_TYPES.QUEUE_STATUS, {
            success = true,
            jobId = "job_" .. os.clock(),
            position = #state.queue + 1,
            size = #state.queue + 1
        })
    end)
    
    -- Recipe search (from Main Computer)
    network.on(MESSAGE_TYPES.RECIPE_SEARCH, function(sender, message)
        logger.info("Recipe search from computer #" .. sender .. ": " .. 
                   (message.data.term or ""), "JOBS")
        
        -- In Phase 1, return empty results
        -- Full implementation in Phase 3
        network.respond(message, MESSAGE_TYPES.RECIPE_RESULT, {
            recipes = {},
            searchTerm = message.data.term
        })
    end)
end

-- Display status (temporary until monitor GUI is implemented)
local function displayStatus()
    utils.clearScreen()
    print("CC:Tweaked Distributed Crafting System - Jobs Computer")
    print("======================================================")
    print()
    print("Status:")
    print("  ME Bridge: " .. (state.meBridge and "CONNECTED" or "NOT CONNECTED"))
    print("  Registered Turtles: " .. utils.tableCount(state.turtles))
    print("  Jobs in Queue: " .. #state.queue)
    print()
    print("Computer ID: " .. os.getComputerID())
    print()
    
    -- Show turtle status
    print("Turtles:")
    for id, turtle in pairs(state.turtles) do
        local status = turtle.status
        if turtle.status == TURTLE_STATUS.OFFLINE then
            status = status .. " (last seen " .. 
                    utils.formatTime(os.clock() - turtle.lastHeartbeat) .. " ago)"
        end
        print(string.format("  #%d: %s", id, status))
    end
    
    print()
    print("Press Q to quit")
end

-- Health check loop
local function healthCheckLoop()
    while state.running do
        checkTurtleHealth()
        sleep(10)  -- Check every 10 seconds
    end
end

-- Status broadcast loop
local function statusBroadcastLoop()
    while state.running do
        broadcastSystemUpdate()
        sleep(CONFIG.UPDATE_INTERVAL or 5)
    end
end

-- User input loop
local function inputLoop()
    while state.running do
        local event, key = os.pullEvent("key")
        
        if key == keys.q then
            state.running = false
            logger.info("Shutdown requested by user", "JOBS")
        elseif key == keys.d then
            -- Dump debug info
            logger.dumpState()
            local stats = network.getStats()
            logger.info("Network stats: " .. textutils.serialize(stats), "JOBS")
        end
    end
end

-- Display loop
local function displayLoop()
    while state.running do
        displayStatus()
        sleep(1)
    end
end

-- Main program
local function main()
    -- Initialize system
    if not initialize() then
        print("\nInitialization failed. Press any key to exit...")
        os.pullEvent("key")
        return
    end
    
    -- Setup message handlers
    setupMessageHandlers()
    
    print("\nStarting Jobs Computer...")
    sleep(1)
    
    -- Create data directories
    utils.ensureDirectory("data")
    utils.ensureDirectory("logs")
    
    -- Test ME Bridge connection
    if state.meBridge then
        local success, result = pcall(state.meBridge.listItems)
        if success then
            logger.info("ME Bridge test successful", "JOBS")
        else
            logger.warn("ME Bridge test failed: " .. tostring(result), "JOBS")
        end
    end
    
    logger.info("Jobs Computer ready and waiting for connections", "JOBS")
    
    -- Start parallel tasks
    parallel.waitForAny(
        network.startListening(),
        healthCheckLoop,
        statusBroadcastLoop,
        displayLoop,
        inputLoop
    )
    
    -- Shutdown
    logger.info("Jobs Computer shutting down", "JOBS")
    
    -- Notify all connected computers
    network.broadcast(MESSAGE_TYPES.SHUTDOWN, {
        reason = "Jobs Computer shutting down"
    })
    
    sleep(1)  -- Give time for messages to send
    network.shutdown()
    
    utils.clearScreen()
    print("Jobs Computer shutdown complete.")
end

-- Error handling wrapper
local function safeMain()
    local success, error = pcall(main)
    
    if not success then
        logger.error("Fatal error: " .. tostring(error), "JOBS")
        print("\nFATAL ERROR: " .. tostring(error))
        print("\nPress any key to exit...")
        os.pullEvent("key")
    end
end

-- Run the program
safeMain()