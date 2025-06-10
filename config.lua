-- TurtleCraft Configuration
-- Simple, clean configuration for the distributed crafting system

local config = {
    -- Network Settings
    PROTOCOL = "turtlecraft",
    
    -- Computer IDs (optional - system will use network discovery if not set)
    -- Uncomment and set this if you want to skip network discovery
    -- JOBS_COMPUTER_ID = 2,  -- The Jobs Computer ID
    
    -- ME Bridge Settings (optional - will auto-detect if not set)
    -- ME_BRIDGE_NAME = "meBridge_0",  -- The peripheral name of the ME Bridge
    
    -- Timeouts
    NETWORK_TIMEOUT = 5,
    HEARTBEAT_INTERVAL = 30,
    TURTLE_OFFLINE_TIMEOUT = 60,  -- Mark offline after 1 minute
    TURTLE_REMOVE_TIMEOUT = 180,  -- Remove from list after 3 minutes
    
    -- Debug
    DEBUG = true,
}

return config