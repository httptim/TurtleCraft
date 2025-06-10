-- TurtleCraft Configuration
-- Simple, clean configuration for the distributed crafting system

local config = {
    -- Network Settings
    PROTOCOL = "turtlecraft",
    
    -- Computer IDs (optional - system will use network discovery if not set)
    -- Uncomment and set this if you want to skip network discovery
    -- JOBS_COMPUTER_ID = 2,  -- The Jobs Computer ID
    
    -- Timeouts
    NETWORK_TIMEOUT = 5,
    HEARTBEAT_INTERVAL = 30,
    
    -- Debug
    DEBUG = true,
}

return config