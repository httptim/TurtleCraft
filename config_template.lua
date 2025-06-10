-- CC:Tweaked Distributed Crafting System Configuration Template
-- This template is used to generate config.lua with auto-detected peripherals

CONFIG = {
    -- System Identification
    COMPUTER_TYPE = nil,  -- Auto-detected: "main", "jobs", or "turtle"
    COMPUTER_ID = os.getComputerID(),
    
    -- Network Settings
    MAIN_COMPUTER_ID = 1,       -- ID of the Main Computer (GUI)
    JOBS_COMPUTER_ID = 2,       -- ID of the Jobs Computer (Operations)
    REDNET_PROTOCOL = "crafting_system",
    NETWORK_TIMEOUT = 5,        -- seconds to wait for network responses
    
    -- Auto-detected Peripherals (populated during startup)
    PERIPHERALS = {
        MONITOR = nil,          -- monitor name (e.g., "monitor_0")
        WIRELESS_MODEM = nil,   -- wireless modem name (e.g., "modem_1")
        WIRED_MODEM = nil,      -- wired modem name (e.g., "modem_2")
        ME_BRIDGE = nil,        -- ME Bridge name (e.g., "meBridge_0")
    },
    
    -- System Performance Settings
    UPDATE_INTERVAL = 5,        -- seconds between status updates
    HEARTBEAT_INTERVAL = 30,    -- seconds between turtle heartbeats
    MAX_RETRIES = 3,            -- maximum retry attempts for operations
    RETRY_DELAY = 2,            -- seconds between retries
    
    -- Logging Configuration
    LOG_LEVEL = "INFO",         -- DEBUG, INFO, WARN, ERROR
    LOG_FILE = "logs/system.log",
    MAX_LOG_SIZE = 50000,       -- bytes before rotation
    LOG_ROTATION_COUNT = 3,     -- number of old logs to keep
    
    -- Job Management Settings
    DEFAULT_PRIORITY = 10,      -- default job priority (1-100)
    HIGH_PRIORITY_THRESHOLD = 80,
    RESERVED_PRIORITY_TURTLES = 1,  -- turtles reserved for high-priority jobs
    JOB_TIMEOUT = 300,          -- seconds before job times out
    MAX_QUEUE_SIZE = 50,        -- maximum jobs in queue
    
    -- Crafting Settings
    DEFAULT_MIN_STOCK = 0,      -- default minimum stock level
    DEPENDENCY_RECURSION_LIMIT = 5,  -- max depth for recipe dependencies
    BATCH_SIZE = 64,            -- default crafting batch size
    
    -- Turtle Management
    MAX_TURTLES = 10,           -- maximum number of turtles
    TURTLE_STARTUP_DELAY = 2,   -- seconds between turtle startups
    TURTLE_OFFLINE_TIMEOUT = 120,  -- seconds before marking turtle offline
    
    -- ME System Settings
    ME_CACHE_TIMEOUT = 10,      -- seconds to cache ME inventory
    ME_REQUEST_DELAY = 0.5,     -- seconds between ME requests
    ME_MAX_EXPORT_SIZE = 64,    -- max items per export operation
    
    -- Display Settings
    MONITOR_TEXT_SCALE = 0.5,   -- text scale for monitors
    GUI_UPDATE_RATE = 0.5,      -- seconds between GUI updates
    MONITOR_UPDATE_RATE = 2,    -- seconds between monitor updates
    
    -- Load Balancing
    LOAD_BALANCE_ALGORITHM = "round_robin",  -- round_robin, least_loaded, random
    CONSIDER_DISTANCE = false,  -- factor in turtle distance (future feature)
    MAX_JOBS_PER_TURTLE = 5,    -- maximum concurrent jobs per turtle
    
    -- Error Recovery
    AUTO_RECOVER = true,        -- automatically recover from errors
    AUTO_RESTART_DELAY = 30,    -- seconds before auto-restart after crash
    SAVE_STATE_INTERVAL = 60,   -- seconds between state saves
    
    -- Performance Optimization
    CACHE_RECIPES = true,       -- cache recipe lookups
    COMPRESS_LOGS = true,       -- compress old log files
    MINIMIZE_NETWORK = true,    -- batch network messages when possible
    
    -- Debug Settings
    DEBUG_MODE = false,         -- enable debug features
    VERBOSE_LOGGING = false,    -- log all network traffic
    SIMULATE_FAILURES = false,  -- randomly simulate failures for testing
    
    -- Feature Flags
    FEATURES = {
        AUTO_STOCK = true,      -- maintain minimum stock levels
        HOT_RELOAD = true,      -- reload configs without restart
        METRICS = true,         -- collect performance metrics
        ALERTS = true,          -- show system alerts
    },
    
    -- File Paths
    PATHS = {
        RECIPES = "recipes.lua",
        PRIORITIES = "priorities.lua",
        TURTLE_REGISTRY = "data/turtle_registry.json",
        JOB_QUEUE = "data/job_queue.json",
        SYSTEM_STATE = "data/system_state.json",
    },
}

-- Peripheral detection profiles for different computer types
PERIPHERAL_PROFILES = {
    main = {
        required = {"monitor", "modem"},
        optional = {},
        modem_type = "wireless"
    },
    jobs = {
        required = {"monitor", "modem", "meBridge"},
        optional = {},
        modem_type = "both"  -- needs both wireless and wired
    },
    turtle = {
        required = {"modem"},
        optional = {"crafting_table"},
        modem_type = "both"  -- needs both wireless and wired
    }
}

-- Color scheme for consistent UI
COLORS = {
    -- Status colors
    success = colors.green,
    error = colors.red,
    warning = colors.orange,
    info = colors.lightBlue,
    
    -- UI colors
    title = colors.yellow,
    background = colors.black,
    text = colors.white,
    border = colors.gray,
    
    -- State colors
    active = colors.lime,
    idle = colors.lightGray,
    offline = colors.red,
    
    -- Priority colors
    high_priority = colors.red,
    medium_priority = colors.yellow,
    low_priority = colors.green,
}

-- Message type constants
MESSAGE_TYPES = {
    -- System messages
    REGISTER = "register",
    REGISTER_ACK = "register_ack",
    HEARTBEAT = "heartbeat",
    HEARTBEAT_ACK = "heartbeat_ack",
    SHUTDOWN = "shutdown",
    
    -- Job messages
    CRAFT_REQUEST = "craft_request",
    JOB_ASSIGN = "job_assign",
    JOB_ACCEPT = "job_accept",
    JOB_COMPLETE = "job_complete",
    JOB_FAILED = "job_failed",
    JOB_CANCEL = "job_cancel",
    
    -- Status messages
    STATUS_UPDATE = "status_update",
    QUEUE_STATUS = "queue_status",
    SYSTEM_STATUS = "system_status",
    TURTLE_STATUS = "turtle_status",
    
    -- Query messages
    RECIPE_SEARCH = "recipe_search",
    RECIPE_RESULT = "recipe_result",
    STOCK_CHECK = "stock_check",
    STOCK_RESULT = "stock_result",
}

-- Job status constants
JOB_STATUS = {
    PENDING = "pending",
    ASSIGNED = "assigned",
    CRAFTING = "crafting",
    COMPLETE = "complete",
    FAILED = "failed",
    CANCELLED = "cancelled",
    WAITING = "waiting",  -- waiting for resources
}

-- Turtle status constants
TURTLE_STATUS = {
    IDLE = "idle",
    BUSY = "busy",
    OFFLINE = "offline",
    ERROR = "error",
    STARTING = "starting",
}

-- Validation function to ensure config is properly set
function validateConfig()
    local errors = {}
    
    -- Check computer type
    if not CONFIG.COMPUTER_TYPE then
        table.insert(errors, "Computer type not detected")
    end
    
    -- Check required peripherals based on computer type
    if CONFIG.COMPUTER_TYPE and PERIPHERAL_PROFILES[CONFIG.COMPUTER_TYPE] then
        local profile = PERIPHERAL_PROFILES[CONFIG.COMPUTER_TYPE]
        
        -- Check monitor (if required)
        if profile.required and table.contains(profile.required, "monitor") then
            if not CONFIG.PERIPHERALS.MONITOR then
                table.insert(errors, "Monitor not detected (required)")
            end
        end
        
        -- Check modem
        if profile.required and table.contains(profile.required, "modem") then
            if not CONFIG.PERIPHERALS.WIRELESS_MODEM and 
               (profile.modem_type ~= "both" or not CONFIG.PERIPHERALS.WIRED_MODEM) then
                table.insert(errors, "Modem not detected (required)")
            end
        end
        
        -- Check ME Bridge (jobs computer only)
        if CONFIG.COMPUTER_TYPE == "jobs" and not CONFIG.PERIPHERALS.ME_BRIDGE then
            table.insert(errors, "ME Bridge not detected (required for Jobs Computer)")
        end
    end
    
    return #errors == 0, errors
end

-- Helper function for table.contains
function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

-- Export configuration
return CONFIG