-- lib/logger.lua
-- Logging system with circular buffer and log rotation

local logger = {}

-- Log levels
logger.LEVELS = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4
}

-- Level names for display
local LEVEL_NAMES = {
    [1] = "DEBUG",
    [2] = "INFO",
    [3] = "WARN",
    [4] = "ERROR"
}

-- Level colors for terminal output
local LEVEL_COLORS = {
    [1] = colors.gray,
    [2] = colors.white,
    [3] = colors.orange,
    [4] = colors.red
}

-- Logger state
local state = {
    level = logger.LEVELS.INFO,
    logFile = "logs/system.log",
    maxSize = 50000,  -- 50KB default
    rotationCount = 3,
    buffer = {},
    bufferSize = 100,  -- Keep last 100 messages in memory
    initialized = false
}

-- Initialize logger with config
function logger.init(config)
    if config then
        state.level = logger.LEVELS[config.LOG_LEVEL] or logger.LEVELS.INFO
        state.logFile = config.LOG_FILE or state.logFile
        state.maxSize = config.MAX_LOG_SIZE or state.maxSize
        state.rotationCount = config.LOG_ROTATION_COUNT or state.rotationCount
    end
    
    -- Ensure log directory exists
    local logDir = fs.getDir(state.logFile)
    if logDir ~= "" and not fs.exists(logDir) then
        fs.makeDir(logDir)
    end
    
    -- Check if rotation is needed
    if fs.exists(state.logFile) then
        local size = fs.getSize(state.logFile)
        if size > state.maxSize then
            logger.rotate()
        end
    end
    
    state.initialized = true
    logger.info("Logger initialized")
end

-- Rotate log files
function logger.rotate()
    -- Delete oldest rotation
    local oldestFile = state.logFile .. "." .. state.rotationCount
    if fs.exists(oldestFile) then
        fs.delete(oldestFile)
    end
    
    -- Rotate existing files
    for i = state.rotationCount - 1, 1, -1 do
        local currentFile = state.logFile .. "." .. i
        local nextFile = state.logFile .. "." .. (i + 1)
        
        if fs.exists(currentFile) then
            fs.move(currentFile, nextFile)
        end
    end
    
    -- Move current log to .1
    if fs.exists(state.logFile) then
        fs.move(state.logFile, state.logFile .. ".1")
    end
end

-- Format log message
local function formatMessage(level, message, source)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local levelName = LEVEL_NAMES[level] or "UNKNOWN"
    local sourceStr = source and (" [" .. source .. "]") or ""
    
    return string.format("[%s] %s%s: %s", timestamp, levelName, sourceStr, message)
end

-- Write to log file
local function writeToFile(formattedMessage)
    if not state.initialized then
        return
    end
    
    -- Check file size before writing
    if fs.exists(state.logFile) then
        local size = fs.getSize(state.logFile)
        if size > state.maxSize then
            logger.rotate()
        end
    end
    
    -- Append to log file
    local file = fs.open(state.logFile, "a")
    if file then
        file.writeLine(formattedMessage)
        file.close()
    end
end

-- Add to circular buffer
local function addToBuffer(level, message, source)
    local entry = {
        timestamp = os.clock(),
        level = level,
        message = message,
        source = source
    }
    
    table.insert(state.buffer, entry)
    
    -- Maintain circular buffer size
    while #state.buffer > state.bufferSize do
        table.remove(state.buffer, 1)
    end
end

-- Core logging function
local function log(level, message, source)
    -- Check if we should log this level
    if level < state.level then
        return
    end
    
    -- Convert non-string messages
    if type(message) ~= "string" then
        message = textutils.serialize(message)
    end
    
    -- Format the message
    local formattedMessage = formatMessage(level, message, source)
    
    -- Add to buffer
    addToBuffer(level, message, source)
    
    -- Write to file
    writeToFile(formattedMessage)
    
    -- Print to terminal if appropriate
    if level >= logger.LEVELS.WARN then
        local oldColor = term.getTextColor()
        term.setTextColor(LEVEL_COLORS[level])
        print(formattedMessage)
        term.setTextColor(oldColor)
    end
end

-- Public logging functions
function logger.debug(message, source)
    log(logger.LEVELS.DEBUG, message, source)
end

function logger.info(message, source)
    log(logger.LEVELS.INFO, message, source)
end

function logger.warn(message, source)
    log(logger.LEVELS.WARN, message, source)
end

function logger.error(message, source)
    log(logger.LEVELS.ERROR, message, source)
end

-- Set logging level
function logger.setLevel(level)
    if type(level) == "string" then
        state.level = logger.LEVELS[level:upper()] or logger.LEVELS.INFO
    elseif type(level) == "number" then
        state.level = level
    end
end

-- Get current log level
function logger.getLevel()
    return state.level
end

-- Get buffered messages
function logger.getBuffer(minLevel)
    minLevel = minLevel or logger.LEVELS.DEBUG
    
    local filtered = {}
    for _, entry in ipairs(state.buffer) do
        if entry.level >= minLevel then
            table.insert(filtered, entry)
        end
    end
    
    return filtered
end

-- Get recent messages as formatted strings
function logger.getRecentMessages(count, minLevel)
    count = count or 10
    minLevel = minLevel or logger.LEVELS.INFO
    
    local messages = {}
    local buffer = logger.getBuffer(minLevel)
    
    -- Get last 'count' messages
    local startIdx = math.max(1, #buffer - count + 1)
    for i = startIdx, #buffer do
        local entry = buffer[i]
        local formatted = formatMessage(entry.level, entry.message, entry.source)
        table.insert(messages, formatted)
    end
    
    return messages
end

-- Clear log file and buffer
function logger.clear()
    state.buffer = {}
    
    if fs.exists(state.logFile) then
        fs.delete(state.logFile)
    end
    
    logger.info("Logger cleared")
end

-- Performance logging helpers
function logger.startTimer(name)
    if not state.timers then
        state.timers = {}
    end
    
    state.timers[name] = os.clock()
end

function logger.endTimer(name, message)
    if not state.timers or not state.timers[name] then
        return
    end
    
    local elapsed = os.clock() - state.timers[name]
    local msg = string.format("%s (took %.3fs)", message or name, elapsed)
    
    logger.debug(msg, "TIMER")
    state.timers[name] = nil
    
    return elapsed
end

-- Network message logging
function logger.logNetworkSend(recipient, messageType, data)
    if state.level <= logger.LEVELS.DEBUG then
        local msg = string.format("SEND -> %s: %s %s", 
            tostring(recipient), 
            messageType,
            data and ("(" .. #textutils.serialize(data) .. " bytes)") or "")
        logger.debug(msg, "NETWORK")
    end
end

function logger.logNetworkReceive(sender, messageType, data)
    if state.level <= logger.LEVELS.DEBUG then
        local msg = string.format("RECV <- %s: %s %s", 
            tostring(sender), 
            messageType,
            data and ("(" .. #textutils.serialize(data) .. " bytes)") or "")
        logger.debug(msg, "NETWORK")
    end
end

-- Error context logging
function logger.logError(error, context)
    logger.error(error, context)
    
    -- Log stack trace if available
    if debug and debug.traceback then
        local trace = debug.traceback()
        logger.debug("Stack trace:\n" .. trace, context)
    end
end

-- Metrics logging
local metrics = {}

function logger.metric(name, value)
    if not metrics[name] then
        metrics[name] = {
            count = 0,
            sum = 0,
            min = value,
            max = value,
            last = value
        }
    end
    
    local m = metrics[name]
    m.count = m.count + 1
    m.sum = m.sum + value
    m.last = value
    m.min = math.min(m.min, value)
    m.max = math.max(m.max, value)
    
    if state.level <= logger.LEVELS.DEBUG then
        logger.debug(string.format("Metric %s: %.2f", name, value), "METRICS")
    end
end

function logger.getMetrics()
    local result = {}
    
    for name, data in pairs(metrics) do
        result[name] = {
            count = data.count,
            average = data.sum / data.count,
            min = data.min,
            max = data.max,
            last = data.last
        }
    end
    
    return result
end

-- Dump current state for debugging
function logger.dumpState()
    local dumpFile = state.logFile .. ".dump"
    local file = fs.open(dumpFile, "w")
    
    if file then
        file.writeLine("=== Logger State Dump ===")
        file.writeLine("Time: " .. os.date())
        file.writeLine("Level: " .. LEVEL_NAMES[state.level])
        file.writeLine("Buffer Size: " .. #state.buffer)
        file.writeLine("")
        
        file.writeLine("=== Recent Messages ===")
        for _, entry in ipairs(state.buffer) do
            local formatted = formatMessage(entry.level, entry.message, entry.source)
            file.writeLine(formatted)
        end
        
        file.writeLine("")
        file.writeLine("=== Metrics ===")
        local metrics = logger.getMetrics()
        file.writeLine(textutils.serialize(metrics))
        
        file.close()
        logger.info("State dumped to " .. dumpFile)
    end
end

return logger