-- lib/utils.lua
-- Utility functions for the CC:Tweaked Distributed Crafting System

local utils = {}

-- Terminal formatting utilities
function utils.clearScreen()
    term.clear()
    term.setCursorPos(1, 1)
end

function utils.drawBox(x, y, width, height, title)
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    
    -- Draw corners
    term.setCursorPos(x, y)
    write("+")  -- top left
    term.setCursorPos(x + width - 1, y)
    write("+")  -- top right
    term.setCursorPos(x, y + height - 1)
    write("+")  -- bottom left
    term.setCursorPos(x + width - 1, y + height - 1)
    write("+")  -- bottom right
    
    -- Draw horizontal lines
    for i = x + 1, x + width - 2 do
        term.setCursorPos(i, y)
        write("-")  -- top
        term.setCursorPos(i, y + height - 1)
        write("-")  -- bottom
    end
    
    -- Draw vertical lines
    for i = y + 1, y + height - 2 do
        term.setCursorPos(x, i)
        write("|")  -- left
        term.setCursorPos(x + width - 1, i)
        write("|")  -- right
    end
    
    -- Draw title if provided
    if title then
        term.setCursorPos(x + 2, y)
        term.setTextColor(colors.yellow)
        write(" " .. title .. " ")
    end
    
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
end

-- Peripheral detection functions
function utils.detectPeripherals()
    local detected = {
        monitors = {},
        modems = {
            wireless = {},
            wired = {}
        },
        me_bridges = {},
        other = {}
    }
    
    local peripheralNames = peripheral.getNames()
    
    for _, name in ipairs(peripheralNames) do
        local pType = peripheral.getType(name)
        
        if pType == "monitor" then
            -- Check if it's a 3x3 monitor
            local monitor = peripheral.wrap(name)
            if monitor then
                local width, height = monitor.getSize()
                -- A 3x3 monitor typically has size around 39x13 at scale 0.5
                if width >= 30 and height >= 10 then
                    table.insert(detected.monitors, {
                        name = name,
                        width = width,
                        height = height,
                        is3x3 = true
                    })
                else
                    table.insert(detected.monitors, {
                        name = name,
                        width = width,
                        height = height,
                        is3x3 = false
                    })
                end
            end
            
        elseif pType == "modem" then
            local modem = peripheral.wrap(name)
            if modem and modem.isWireless then
                if modem.isWireless() then
                    table.insert(detected.modems.wireless, name)
                else
                    table.insert(detected.modems.wired, name)
                end
            end
            
        elseif pType == "meBridge" then
            table.insert(detected.me_bridges, name)
            
        else
            table.insert(detected.other, {name = name, type = pType})
        end
    end
    
    return detected
end

-- Computer type detection
function utils.detectComputerType()
    -- Check if it's a turtle
    if turtle then
        -- Check if it's a crafty turtle
        if peripheral.find("workbench") or turtle.craft then
            return "turtle", "crafty"
        else
            return "turtle", "mining"
        end
    end
    
    -- For regular computers, we'll need user input or config
    return "computer", nil
end

-- Display peripheral detection results
function utils.displayPeripheralDetection(detected, computerType)
    utils.clearScreen()
    utils.drawBox(1, 1, 62, 20, "PERIPHERAL AUTO-DETECTION")
    
    local y = 3
    term.setCursorPos(3, y)
    print("Scanning for peripherals...")
    y = y + 2
    
    -- Display computer type
    if computerType == "turtle" then
        term.setCursorPos(3, y)
        term.setTextColor(colors.lime)
        print("Turtle Type: Crafty Turtle [OK]")
        term.setTextColor(colors.white)
        y = y + 2
    end
    
    term.setCursorPos(3, y)
    print("Found peripherals:")
    y = y + 1
    
    local peripheralCount = 1
    
    -- List monitors
    for i, monitor in ipairs(detected.monitors) do
        term.setCursorPos(3, y)
        local monitorDesc = monitor.is3x3 and "3x3 Monitor" or 
                           string.format("%dx%d Monitor", monitor.width, monitor.height)
        print(string.format("%d. %s (%s) - %s", 
            peripheralCount, monitor.name, utils.getSide(monitor.name), monitorDesc))
        y = y + 1
        peripheralCount = peripheralCount + 1
    end
    
    -- List wireless modems
    for i, modem in ipairs(detected.modems.wireless) do
        term.setCursorPos(3, y)
        print(string.format("%d. %s (%s) - Wireless Modem", 
            peripheralCount, modem, utils.getSide(modem)))
        y = y + 1
        peripheralCount = peripheralCount + 1
    end
    
    -- List wired modems
    for i, modem in ipairs(detected.modems.wired) do
        term.setCursorPos(3, y)
        print(string.format("%d. %s (%s) - Wired Modem", 
            peripheralCount, modem, utils.getSide(modem)))
        y = y + 1
        peripheralCount = peripheralCount + 1
    end
    
    -- List ME Bridges
    for i, bridge in ipairs(detected.me_bridges) do
        term.setCursorPos(3, y)
        print(string.format("%d. %s (%s) - ME Bridge", 
            peripheralCount, bridge, utils.getSide(bridge)))
        y = y + 1
        peripheralCount = peripheralCount + 1
    end
    
    return y
end

-- Get side from peripheral name
function utils.getSide(peripheralName)
    -- Extract side from peripheral name (e.g., "monitor_0" might be on "top")
    local sides = {"top", "bottom", "left", "right", "front", "back"}
    
    for _, side in ipairs(sides) do
        if peripheral.isPresent(side) and peripheral.getType(side) then
            local sidePeripheral = peripheral.wrap(side)
            local sideName = peripheral.getName(sidePeripheral)
            if sideName == peripheralName then
                return side .. " side"
            end
        end
    end
    
    -- If not found by side, it might be networked
    return "network"
end

-- Configuration display
function utils.displayConfiguration(config, computerType)
    local y = 15
    term.setCursorPos(3, y)
    print("Configuration:")
    y = y + 1
    
    if config.monitor then
        term.setCursorPos(3, y)
        term.setTextColor(colors.green)
        print("* Monitor: " .. config.monitor .. " [OK]")
        term.setTextColor(colors.white)
        y = y + 1
    end
    
    if config.wireless_modem then
        term.setCursorPos(3, y)
        term.setTextColor(colors.green)
        print("* Wireless Modem: " .. config.wireless_modem .. " [OK]")
        term.setTextColor(colors.white)
        y = y + 1
    end
    
    if config.wired_modem then
        term.setCursorPos(3, y)
        term.setTextColor(colors.green)
        print("* Wired Modem: " .. config.wired_modem .. " [OK]")
        term.setTextColor(colors.white)
        y = y + 1
    end
    
    if config.me_bridge then
        term.setCursorPos(3, y)
        term.setTextColor(colors.green)
        print("* ME Bridge: " .. config.me_bridge .. " [OK]")
        term.setTextColor(colors.white)
        y = y + 1
    end
    
    if computerType == "turtle" then
        term.setCursorPos(3, y)
        term.setTextColor(colors.green)
        print("* Crafting: Built-in [OK]")
        term.setTextColor(colors.white)
        y = y + 1
    end
    
    return y
end

-- Prompt for yes/no
function utils.promptYesNo(prompt, x, y)
    term.setCursorPos(x, y)
    write(prompt .. " [Y/N] ")
    
    while true do
        local event, key = os.pullEvent("key")
        if key == keys.y then
            write("Y")
            return true
        elseif key == keys.n then
            write("N")
            return false
        end
    end
end

-- Prompt for number input
function utils.promptNumber(prompt, x, y, min, max)
    term.setCursorPos(x, y)
    write(prompt)
    local inputX = x + #prompt
    
    local input = ""
    while true do
        term.setCursorPos(inputX, y)
        term.write(input .. "_    ")
        
        local event, param = os.pullEvent()
        if event == "key" then
            if param == keys.enter and input ~= "" then
                local num = tonumber(input)
                if num and num >= min and num <= max then
                    return num
                else
                    term.setCursorPos(x, y + 1)
                    term.setTextColor(colors.red)
                    write("Please enter a number between " .. min .. " and " .. max)
                    term.setTextColor(colors.white)
                    sleep(2)
                    term.setCursorPos(x, y + 1)
                    term.clearLine()
                end
            elseif param == keys.backspace and #input > 0 then
                input = input:sub(1, -2)
            end
        elseif event == "char" and tonumber(param) then
            if #input < 2 then
                input = input .. param
            end
        end
    end
end

-- Save configuration to file
function utils.saveConfig(config, filename)
    filename = filename or "config.lua"
    
    local file = fs.open(filename, "w")
    if not file then
        return false, "Failed to open file for writing"
    end
    
    file.writeLine("-- Auto-generated configuration file")
    file.writeLine("-- Generated on: " .. os.date())
    file.writeLine("")
    file.writeLine("local CONFIG = {")
    
    -- Write computer type
    file.writeLine("    COMPUTER_TYPE = \"" .. (config.computer_type or "unknown") .. "\",")
    file.writeLine("    COMPUTER_ID = " .. os.getComputerID() .. ",")
    file.writeLine("")
    
    -- Write peripherals
    file.writeLine("    PERIPHERALS = {")
    if config.monitor then
        file.writeLine("        MONITOR = \"" .. config.monitor .. "\",")
    end
    if config.wireless_modem then
        file.writeLine("        WIRELESS_MODEM = \"" .. config.wireless_modem .. "\",")
    end
    if config.wired_modem then
        file.writeLine("        WIRED_MODEM = \"" .. config.wired_modem .. "\",")
    end
    if config.me_bridge then
        file.writeLine("        ME_BRIDGE = \"" .. config.me_bridge .. "\",")
    end
    file.writeLine("    },")
    
    -- Write turtle ID if applicable
    if config.turtle_id then
        file.writeLine("")
        file.writeLine("    TURTLE_ID = " .. config.turtle_id .. ",")
    end
    
    file.writeLine("}")
    file.writeLine("")
    file.writeLine("-- Load template configuration and merge")
    file.writeLine("dofile(\"config_template.lua\")")
    file.writeLine("for k, v in pairs(CONFIG) do")
    file.writeLine("    _G.CONFIG[k] = v")
    file.writeLine("end")
    file.writeLine("")
    file.writeLine("return CONFIG")
    
    file.close()
    return true
end

-- Load configuration from file
function utils.loadConfig(filename)
    filename = filename or "config.lua"
    
    if not fs.exists(filename) then
        return nil, "Configuration file not found"
    end
    
    local ok, result = pcall(dofile, filename)
    if not ok then
        return nil, "Failed to load configuration: " .. tostring(result)
    end
    
    return CONFIG  -- Global CONFIG should be set by dofile
end

-- Table utilities
function utils.tableContains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

function utils.tableCount(table)
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end

function utils.deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[utils.deepCopy(orig_key)] = utils.deepCopy(orig_value)
        end
        setmetatable(copy, utils.deepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- String utilities
function utils.split(str, delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(str, delimiter, from)
    
    while delim_from do
        table.insert(result, string.sub(str, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(str, delimiter, from)
    end
    
    table.insert(result, string.sub(str, from))
    return result
end

function utils.trim(str)
    return str:match("^%s*(.-)%s*$")
end

-- File utilities
function utils.ensureDirectory(path)
    if not fs.exists(path) then
        fs.makeDir(path)
    end
end

-- Time formatting
function utils.formatTime(seconds)
    if seconds < 60 then
        return string.format("%ds", seconds)
    elseif seconds < 3600 then
        return string.format("%dm %ds", math.floor(seconds / 60), seconds % 60)
    else
        return string.format("%dh %dm", math.floor(seconds / 3600), 
                           math.floor((seconds % 3600) / 60))
    end
end

-- Progress bar
function utils.drawProgressBar(x, y, width, progress, max, color)
    color = color or colors.green
    local filled = math.floor((progress / max) * width)
    
    term.setCursorPos(x, y)
    term.setBackgroundColor(colors.gray)
    term.write(string.rep(" ", width))
    
    term.setCursorPos(x, y)
    term.setBackgroundColor(color)
    term.write(string.rep(" ", filled))
    
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
end

return utils