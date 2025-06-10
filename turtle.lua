-- turtle.lua
-- Turtle client for CC:Tweaked Distributed Crafting System
-- Handles crafting execution and communication with Jobs Computer

-- Load libraries
local utils = dofile("lib/utils.lua")
local logger = dofile("lib/logger.lua")
local network = dofile("lib/network.lua")

-- Load configuration template
dofile("config_template.lua")

-- Global state
local state = {
    running = true,
    registered = false,
    jobsComputerID = nil,
    currentJob = nil,
    status = TURTLE_STATUS.STARTING,
    turtleID = nil,
    heartbeatInterval = 30,
    updateInterval = 5
}

-- Check if turtle has crafting capability
local function checkCraftingCapability()
    -- Check if turtle.craft exists (Crafty Turtle)
    if not turtle.craft then
        return false, "Not a crafty turtle"
    end
    
    -- Test crafting capability
    local success = pcall(turtle.craft, 0)
    return true, "Crafting capability confirmed"
end

-- Detect and configure peripherals
local function detectAndConfigure()
    -- Auto-detect peripherals
    local detected = utils.detectPeripherals()
    
    -- Get computer type
    local computerType, subtype = utils.detectComputerType()
    
    -- Display detection results
    utils.displayPeripheralDetection(detected, computerType)
    
    -- Check crafting capability
    local canCraft, craftMessage = checkCraftingCapability()
    if not canCraft then
        term.setCursorPos(3, 10)
        term.setTextColor(colors.red)
        print("ERROR: " .. craftMessage)
        print("This program requires a Crafty Turtle!")
        term.setTextColor(colors.white)
        return nil
    end
    
    -- Check for required peripherals
    local hasWireless = #detected.modems.wireless > 0
    local hasWired = #detected.modems.wired > 0
    
    if not hasWireless or not hasWired then
        term.setCursorPos(3, 18)
        term.setTextColor(colors.red)
        print("ERROR: Missing required peripherals!")
        if not hasWireless then print("  - No wireless modem detected") end
        if not hasWired then print("  - No wired modem detected") end
        term.setTextColor(colors.white)
        return nil
    end
    
    -- Build configuration
    local config = {
        computer_type = "turtle",
        wireless_modem = detected.modems.wireless[1] or nil,
        wired_modem = detected.modems.wired[1] or nil
    }
    
    -- Display configuration
    local y = utils.displayConfiguration(config, "turtle")
    
    -- Confirm configuration
    if not utils.promptYesNo("Is this configuration correct?", 3, y + 1) then
        return nil
    end
    
    -- Get turtle ID
    y = y + 2
    state.turtleID = utils.promptNumber("Set turtle ID (1-10): ", 3, y, 1, CONFIG.MAX_TURTLES or 10)
    config.turtle_id = state.turtleID
    
    -- Save configuration
    y = y + 1
    term.setCursorPos(3, y)
    if utils.promptYesNo("Save configuration?", 3, y) then
        utils.saveConfig(config)
        sleep(0.5)
    end
    
    return config
end

-- Initialize system
local function initialize()
    utils.clearScreen()
    print("CC:Tweaked Distributed Crafting System - Turtle")
    print("===============================================")
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
        state.turtleID = config.turtle_id or config.TURTLE_ID
    end
    
    print("\nInitializing system components...")
    
    -- Update global CONFIG
    CONFIG.COMPUTER_TYPE = config.computer_type or CONFIG.COMPUTER_TYPE
    CONFIG.PERIPHERALS.WIRELESS_MODEM = config.wireless_modem or CONFIG.PERIPHERALS.WIRELESS_MODEM
    CONFIG.PERIPHERALS.WIRED_MODEM = config.wired_modem or CONFIG.PERIPHERALS.WIRED_MODEM
    CONFIG.TURTLE_ID = state.turtleID
    
    -- Initialize logger
    print("  * Initializing logger...")
    logger.init(CONFIG)
    logger.info("Turtle #" .. state.turtleID .. " starting up", "TURTLE")
    
    -- Initialize network
    print("  * Initializing network...")
    if not network.init(CONFIG) then
        logger.error("Failed to initialize network", "TURTLE")
        return false
    end
    
    print("  * System ready!")
    
    return true
end

-- Register with Jobs Computer
local function registerWithJobsComputer()
    logger.info("Searching for Jobs Computer...", "TURTLE")
    
    local maxAttempts = 10
    local attempt = 0
    
    while attempt < maxAttempts and not state.registered do
        attempt = attempt + 1
        
        -- Find jobs computers
        local jobsComputers = network.findComputers("jobs")
        
        if #jobsComputers > 0 then
            state.jobsComputerID = jobsComputers[1]
            logger.info("Found Jobs Computer with ID: " .. state.jobsComputerID, "TURTLE")
            
            -- Send registration request
            local success, response = network.send(
                state.jobsComputerID, 
                MESSAGE_TYPES.REGISTER, 
                {
                    turtleID = state.turtleID,
                    type = "crafty",
                    capabilities = {
                        crafting = true,
                        wired = CONFIG.PERIPHERALS.WIRED_MODEM ~= nil
                    }
                },
                true  -- wait for response
            )
            
            if success and response and response.data.success then
                state.registered = true
                state.status = TURTLE_STATUS.IDLE
                
                -- Update intervals from config
                if response.data.config then
                    state.heartbeatInterval = response.data.config.heartbeatInterval or state.heartbeatInterval
                    state.updateInterval = response.data.config.updateInterval or state.updateInterval
                end
                
                logger.info("Successfully registered with Jobs Computer", "TURTLE")
                return true
            else
                logger.warn("Registration failed, attempt " .. attempt, "TURTLE")
            end
        else
            logger.debug("No Jobs Computer found, attempt " .. attempt .. "/" .. maxAttempts, "TURTLE")
        end
        
        sleep(2)
    end
    
    logger.error("Failed to register with Jobs Computer", "TURTLE")
    return false
end

-- Send heartbeat
local function sendHeartbeat()
    if not state.registered or not state.jobsComputerID then
        return
    end
    
    network.send(state.jobsComputerID, MESSAGE_TYPES.HEARTBEAT, {
        turtleID = state.turtleID,
        status = state.status,
        fuel = turtle.getFuelLevel(),
        currentJob = state.currentJob
    })
end

-- Message handlers
local function setupMessageHandlers()
    -- Job assignment
    network.on(MESSAGE_TYPES.JOB_ASSIGN, function(sender, message)
        if sender == state.jobsComputerID then
            logger.info("Received job assignment: " .. (message.data.item or "unknown"), "TURTLE")
            
            -- Accept the job
            state.currentJob = message.data
            state.status = TURTLE_STATUS.BUSY
            
            network.respond(message, MESSAGE_TYPES.JOB_ACCEPT, {
                turtleID = state.turtleID,
                jobId = message.data.jobId
            })
            
            -- Job execution will be implemented in later phases
        end
    end)
    
    -- Shutdown command
    network.on(MESSAGE_TYPES.SHUTDOWN, function(sender, message)
        if sender == state.jobsComputerID then
            logger.info("Shutdown command received", "TURTLE")
            state.running = false
        end
    end)
end

-- Display status
local function displayStatus()
    utils.clearScreen()
    print("CC:Tweaked Distributed Crafting System - Turtle #" .. state.turtleID)
    print("====================================================")
    print()
    print("Status: " .. state.status)
    print("Jobs Computer: " .. (state.registered and "CONNECTED" or "NOT CONNECTED"))
    print("Jobs Computer ID: " .. (state.jobsComputerID or "None"))
    print()
    print("Fuel Level: " .. turtle.getFuelLevel())
    print()
    
    if state.currentJob then
        print("Current Job:")
        print("  Item: " .. (state.currentJob.item or "None"))
        print("  Quantity: " .. (state.currentJob.quantity or 0))
    else
        print("Current Job: None")
    end
    
    print()
    print("Press Q to quit")
end

-- Heartbeat loop
local function heartbeatLoop()
    while state.running do
        if state.registered then
            sendHeartbeat()
            sleep(state.heartbeatInterval)
        else
            -- Try to re-register
            registerWithJobsComputer()
            sleep(10)
        end
    end
end

-- Status update loop
local function statusUpdateLoop()
    while state.running do
        if state.registered and state.jobsComputerID then
            -- Send status update
            network.send(state.jobsComputerID, MESSAGE_TYPES.TURTLE_STATUS, {
                turtleID = state.turtleID,
                status = state.status,
                fuel = turtle.getFuelLevel(),
                inventory = {
                    -- Will implement inventory checking in later phases
                }
            })
        end
        
        sleep(state.updateInterval)
    end
end

-- User input loop
local function inputLoop()
    while state.running do
        local event, key = os.pullEvent("key")
        
        if key == keys.q then
            state.running = false
            logger.info("Shutdown requested by user", "TURTLE")
        elseif key == keys.f then
            -- Refuel from slot 16
            turtle.select(16)
            local refueled = turtle.refuel()
            if refueled then
                logger.info("Refueled. New level: " .. turtle.getFuelLevel(), "TURTLE")
            else
                logger.warn("No fuel in slot 16", "TURTLE")
            end
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
    
    print("\nStarting Turtle #" .. state.turtleID .. "...")
    
    -- Check fuel
    if turtle.getFuelLevel() < 100 then
        print("\nWARNING: Low fuel level!")
        print("Place fuel in slot 16 and press F to refuel")
        print()
    end
    
    -- Register with Jobs Computer
    if not registerWithJobsComputer() then
        print("\nWARNING: Could not register with Jobs Computer")
        print("The turtle will keep trying to connect...")
        print("Make sure the Jobs Computer is running!")
        print()
        print("Press any key to continue...")
        os.pullEvent("key")
    end
    
    logger.info("Turtle #" .. state.turtleID .. " ready for jobs", "TURTLE")
    
    -- Start parallel tasks
    parallel.waitForAny(
        network.startListening(),
        heartbeatLoop,
        statusUpdateLoop,
        displayLoop,
        inputLoop
    )
    
    -- Shutdown
    logger.info("Turtle #" .. state.turtleID .. " shutting down", "TURTLE")
    
    -- Notify Jobs Computer if connected
    if state.registered and state.jobsComputerID then
        network.send(state.jobsComputerID, MESSAGE_TYPES.SHUTDOWN, {
            turtleID = state.turtleID,
            reason = "Turtle shutting down"
        })
    end
    
    network.shutdown()
    
    utils.clearScreen()
    print("Turtle #" .. state.turtleID .. " shutdown complete.")
end

-- Error handling wrapper
local function safeMain()
    local success, error = pcall(main)
    
    if not success then
        logger.error("Fatal error: " .. tostring(error), "TURTLE")
        print("\nFATAL ERROR: " .. tostring(error))
        print("\nPress any key to exit...")
        os.pullEvent("key")
    end
end

-- Run the program
safeMain()