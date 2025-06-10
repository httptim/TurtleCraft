-- main_computer.lua
-- Main Computer for CC:Tweaked Distributed Crafting System
-- Provides GUI interface and system monitoring

-- Load libraries
local utils = dofile("lib/utils.lua")
local logger = dofile("lib/logger.lua")
local network = dofile("lib/network.lua")

-- Load configuration template
dofile("config_template.lua")

-- Global state
local state = {
    running = true,
    connected = false,
    jobsComputerID = nil,
    systemStatus = {
        turtles = 0,
        queue = 0,
        jobs_computer = "OFFLINE"
    }
}

-- Detect and configure peripherals
local function detectAndConfigure()
    -- Auto-detect peripherals
    local detected = utils.detectPeripherals()
    
    -- Display detection results
    utils.displayPeripheralDetection(detected, "main")
    
    -- Check for required peripherals
    local hasMonitor = #detected.monitors > 0
    local hasWireless = #detected.modems.wireless > 0
    
    if not hasMonitor or not hasWireless then
        term.setCursorPos(3, 18)
        term.setTextColor(colors.red)
        print("ERROR: Missing required peripherals!")
        if not hasMonitor then print("  - No monitor detected") end
        if not hasWireless then print("  - No wireless modem detected") end
        term.setTextColor(colors.white)
        return nil
    end
    
    -- Build configuration
    local config = {
        computer_type = "main",
        monitor = detected.monitors[1] and detected.monitors[1].name or nil,
        wireless_modem = detected.modems.wireless[1] or nil
    }
    
    -- Display configuration
    utils.displayConfiguration(config, "main")
    
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
    print("CC:Tweaked Distributed Crafting System - Main Computer")
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
    
    print("\nInitializing system components...")
    
    -- Update global CONFIG
    CONFIG.COMPUTER_TYPE = config.computer_type or CONFIG.COMPUTER_TYPE
    CONFIG.PERIPHERALS.MONITOR = config.monitor or CONFIG.PERIPHERALS.MONITOR
    CONFIG.PERIPHERALS.WIRELESS_MODEM = config.wireless_modem or CONFIG.PERIPHERALS.WIRELESS_MODEM
    
    -- Initialize logger
    print("  * Initializing logger...")
    logger.init(CONFIG)
    logger.info("Main Computer starting up", "MAIN")
    
    -- Initialize network
    print("  * Initializing network...")
    if not network.init(CONFIG) then
        logger.error("Failed to initialize network", "MAIN")
        return false
    end
    
    print("  * System ready!")
    
    return true
end

-- Connect to Jobs Computer
local function connectToJobsComputer()
    logger.info("Searching for Jobs Computer...", "MAIN")
    
    -- First, let's check what's available on the network
    local allComputers = rednet.lookup(CONFIG.REDNET_PROTOCOL)
    if allComputers then
        logger.info("All computers on protocol: " .. textutils.serialize(allComputers), "MAIN")
    else
        logger.warn("No computers found on protocol: " .. CONFIG.REDNET_PROTOCOL, "MAIN")
    end
    
    local maxAttempts = 10
    local attempt = 0
    
    while attempt < maxAttempts and not state.connected do
        attempt = attempt + 1
        
        -- Try direct connection to known Jobs Computer ID
        if CONFIG.JOBS_COMPUTER_ID then
            logger.info("Trying direct connection to Jobs Computer ID: " .. CONFIG.JOBS_COMPUTER_ID, "MAIN")
            
            -- Try to ping it directly
            local success, rtt = network.ping(CONFIG.JOBS_COMPUTER_ID)
            
            if success then
                state.jobsComputerID = CONFIG.JOBS_COMPUTER_ID
                state.connected = true
                state.systemStatus.jobs_computer = "ONLINE"
                logger.info(string.format("Connected to Jobs Computer (RTT: %.3fs)", rtt), "MAIN")
                
                -- Request initial status
                network.send(state.jobsComputerID, MESSAGE_TYPES.SYSTEM_STATUS, {})
                
                return true
            else
                logger.warn("Jobs Computer ID " .. CONFIG.JOBS_COMPUTER_ID .. " not responding", "MAIN")
            end
        end
        
        -- Find jobs computers by type
        local jobsComputers = network.findComputers("jobs")
        logger.debug("Found " .. #jobsComputers .. " jobs computers", "MAIN")
        
        if #jobsComputers > 0 then
            state.jobsComputerID = jobsComputers[1]
            logger.info("Found Jobs Computer with ID: " .. state.jobsComputerID, "MAIN")
            
            -- Try to ping it
            local success, rtt = network.ping(state.jobsComputerID)
            
            if success then
                state.connected = true
                state.systemStatus.jobs_computer = "ONLINE"
                logger.info(string.format("Connected to Jobs Computer (RTT: %.3fs)", rtt), "MAIN")
                
                -- Request initial status
                network.send(state.jobsComputerID, MESSAGE_TYPES.SYSTEM_STATUS, {})
                
                return true
            else
                logger.warn("Jobs Computer found but not responding", "MAIN")
            end
        else
            logger.debug("No Jobs Computer found, attempt " .. attempt .. "/" .. maxAttempts, "MAIN")
        end
        
        sleep(2)
    end
    
    logger.error("Failed to connect to Jobs Computer", "MAIN")
    return false
end

-- Message handlers
local function setupMessageHandlers()
    -- System status updates
    network.on(MESSAGE_TYPES.STATUS_UPDATE, function(sender, message)
        if sender == state.jobsComputerID then
            if message.data.turtles then
                state.systemStatus.turtles = message.data.turtles
            end
            if message.data.queue then
                state.systemStatus.queue = message.data.queue
            end
            logger.debug("Status update received", "MAIN")
        end
    end)
    
    -- Queue status responses
    network.on(MESSAGE_TYPES.QUEUE_STATUS, function(sender, message)
        if sender == state.jobsComputerID then
            state.systemStatus.queue = message.data.size or 0
            logger.debug("Queue status: " .. state.systemStatus.queue, "MAIN")
        end
    end)
    
    -- Recipe search results
    network.on(MESSAGE_TYPES.RECIPE_RESULT, function(sender, message)
        if sender == state.jobsComputerID then
            -- Will be used in later phases for GUI
            logger.info("Received " .. #message.data.recipes .. " recipes", "MAIN")
        end
    end)
end

-- Display basic status (temporary until GUI is implemented)
local function displayStatus()
    utils.clearScreen()
    print("CC:Tweaked Distributed Crafting System - Main Computer")
    print("======================================================")
    print()
    print("Status:")
    print("  Jobs Computer: " .. state.systemStatus.jobs_computer)
    print("  Connected Turtles: " .. state.systemStatus.turtles)
    print("  Jobs in Queue: " .. state.systemStatus.queue)
    print()
    print("Computer ID: " .. os.getComputerID())
    print("Jobs Computer ID: " .. (state.jobsComputerID or "Not connected"))
    print()
    print("Press Q to quit")
    print()
    
    -- Show recent logs
    local logs = logger.getRecentMessages(5, logger.LEVELS.INFO)
    print("Recent Activity:")
    for _, log in ipairs(logs) do
        print("  " .. log)
    end
end

-- Status update loop
local function statusUpdateLoop()
    while state.running do
        if state.connected then
            -- Request updated status
            network.send(state.jobsComputerID, MESSAGE_TYPES.SYSTEM_STATUS, {})
        else
            -- Try to reconnect
            connectToJobsComputer()
        end
        
        sleep(CONFIG.UPDATE_INTERVAL or 5)
    end
end

-- User input loop
local function inputLoop()
    while state.running do
        local event, key = os.pullEvent("key")
        
        if key == keys.q then
            state.running = false
            logger.info("Shutdown requested by user", "MAIN")
        elseif key == keys.r then
            -- Refresh display
            displayStatus()
        elseif key == keys.d then
            -- Dump debug info
            logger.dumpState()
            local stats = network.getStats()
            logger.info("Network stats: " .. textutils.serialize(stats), "MAIN")
        end
    end
end

-- Display loop
local function displayLoop()
    while state.running do
        displayStatus()
        sleep(CONFIG.GUI_UPDATE_RATE or 0.5)
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
    
    print("\nStarting Main Computer...")
    
    -- Connect to Jobs Computer
    if not connectToJobsComputer() then
        print("\nWARNING: Could not connect to Jobs Computer")
        print("The system will keep trying to connect...")
        print("Make sure the Jobs Computer is running!")
        print()
        print("Press any key to continue...")
        os.pullEvent("key")
    end
    
    -- Start parallel tasks
    parallel.waitForAny(
        network.startListening(),
        statusUpdateLoop,
        displayLoop,
        inputLoop
    )
    
    -- Shutdown
    logger.info("Main Computer shutting down", "MAIN")
    network.shutdown()
    
    utils.clearScreen()
    print("Main Computer shutdown complete.")
end

-- Error handling wrapper
local function safeMain()
    local success, error = pcall(main)
    
    if not success then
        logger.error("Fatal error: " .. tostring(error), "MAIN")
        print("\nFATAL ERROR: " .. tostring(error))
        print("\nPress any key to exit...")
        os.pullEvent("key")
    end
end

-- Run the program
safeMain()