-- Enhanced GitHub Installer for CC:Tweaked with Docker-style scrolling
-- Author: Http.Tim

-- Configuration for CC:Tweaked Distributed Crafting System
local REPO_OWNER = "httptim"  -- Change this to your GitHub username
local REPO_NAME = "TurtleCraft"
local BRANCH = "main"
local INSTALL_DIR = ""  -- Install in root directory

-- File manifest for CC:Tweaked Distributed Crafting System
local FILES = {
    -- Main programs (simplified system)
    {url = "jobs_computer.lua", path = "jobs_computer.lua"},
    {url = "turtle.lua", path = "turtle.lua"},
    
    -- Startup script
    {url = "startup.lua", path = "startup.lua"},
}

-- Directories to create  
local DIRECTORIES = {}

-- Launcher scripts
local LAUNCHERS = {
    {
        name = "start-jobs",
        content = [[-- Jobs Computer Launcher
shell.run("jobs_computer.lua")]]
    },
    {
        name = "start-turtle",
        content = [[-- Turtle Launcher
shell.run("turtle.lua")]]
    },
}

-- Theme colors (removing this - will use global colors API directly)

-- Terminal size
local width, height = term.getSize()

-- Scrolling window state
local scrollWindow = {
    x = 5,
    y = height + 10,  -- Off screen - we won't use the scroll window
    width = width - 10,
    height = 8,
    lines = {},
    maxLines = 100,  -- Keep last 100 lines in memory
    scrollPos = 0
}

-- Helper functions
local function centerText(y, text, color)
    term.setCursorPos(math.floor((width - #text) / 2) + 1, y)
    term.setTextColor(color or colors.white)
    term.write(text)
end

local function drawBox(x, y, w, h, title)
    term.setTextColor(colors.gray)
    term.setCursorPos(x, y)
    term.write("+" .. string.rep("-", w - 2) .. "+")
    
    if title then
        term.setCursorPos(x + 2, y)
        term.setTextColor(colors.cyan)
        term.write(" " .. title .. " ")
        term.setTextColor(colors.gray)
    end
    
    for i = 1, h - 2 do
        term.setCursorPos(x, y + i)
        term.write("|")
        term.setCursorPos(x + w - 1, y + i)
        term.write("|")
    end
    
    term.setCursorPos(x, y + h - 1)
    term.write("+" .. string.rep("-", w - 2) .. "+")
end

local function drawProgressBar(y, progress, label)
    local barWidth = width - 20  -- Leave room for brackets and percentage
    local filled = math.floor(barWidth * progress)
    
    term.setCursorPos(5, y)
    term.setTextColor(colors.white)
    term.clearLine()
    term.write(label)
    
    term.setCursorPos(5, y + 1)
    term.setTextColor(colors.gray)
    term.write("[")
    
    term.setTextColor(colors.green)
    term.write(string.rep("=", filled))
    if filled < barWidth then
        term.write(">")
        term.setTextColor(colors.gray)
        term.write(string.rep(" ", barWidth - filled - 1))
    end
    
    term.setTextColor(colors.gray)
    term.write("]")
    
    -- Put percentage after the bar
    term.write(" ")
    term.setTextColor(colors.white)
    term.write(string.format("%3d%%", math.floor(progress * 100)))
end

-- Initialize scroll window
local function initScrollWindow()
    -- Draw the scroll window box
    drawBox(scrollWindow.x, scrollWindow.y, scrollWindow.width, scrollWindow.height, "Download Log")
    
    -- Clear the inside
    term.setBackgroundColor(colors.gray)
    for i = 1, scrollWindow.height - 2 do
        term.setCursorPos(scrollWindow.x + 1, scrollWindow.y + i)
        term.write(string.rep(" ", scrollWindow.width - 2))
    end
    term.setBackgroundColor(colors.black)
end

-- Add line to scroll window
local function addScrollLine(text, color, lineId)
    -- Add to lines buffer
    local lineData = {text = text, color = color or colors.lightGray, id = lineId}
    
    if lineId then
        -- Update existing line with same ID
        for i, line in ipairs(scrollWindow.lines) do
            if line.id == lineId then
                scrollWindow.lines[i] = lineData
                updateScrollWindow()
                return
            end
        end
    end
    
    -- Add new line
    table.insert(scrollWindow.lines, lineData)
    
    -- Remove old lines if buffer is too large
    while #scrollWindow.lines > scrollWindow.maxLines do
        table.remove(scrollWindow.lines, 1)
    end
    
    -- Auto-scroll to bottom
    scrollWindow.scrollPos = math.max(0, #scrollWindow.lines - (scrollWindow.height - 2))
    
    -- Redraw the scroll window content
    updateScrollWindow()
end

-- Update scroll window display
function updateScrollWindow()
    term.setBackgroundColor(colors.gray)
    
    local displayHeight = scrollWindow.height - 2
    local startLine = scrollWindow.scrollPos + 1
    
    for i = 1, displayHeight do
        term.setCursorPos(scrollWindow.x + 1, scrollWindow.y + i)
        term.write(string.rep(" ", scrollWindow.width - 2))
        
        local lineIndex = startLine + i - 1
        if scrollWindow.lines[lineIndex] then
            local line = scrollWindow.lines[lineIndex]
            term.setCursorPos(scrollWindow.x + 2, scrollWindow.y + i)
            term.setTextColor(line.color)
            
            -- Truncate if too long
            local displayText = line.text
            if #displayText > scrollWindow.width - 4 then
                displayText = displayText:sub(1, scrollWindow.width - 7) .. "..."
            end
            term.write(displayText)
        end
    end
    
    -- Draw scroll indicator
    if #scrollWindow.lines > displayHeight then
        local scrollBarHeight = math.max(1, math.floor(displayHeight * displayHeight / #scrollWindow.lines))
        local scrollBarPos = math.floor((displayHeight - scrollBarHeight) * scrollWindow.scrollPos / (#scrollWindow.lines - displayHeight))
        
        term.setTextColor(colors.gray)
        for i = 1, displayHeight do
            term.setCursorPos(scrollWindow.x + scrollWindow.width - 2, scrollWindow.y + i)
            if i >= scrollBarPos + 1 and i <= scrollBarPos + scrollBarHeight then
                term.write("█")
            else
                term.write("│")
            end
        end
    end
    
    term.setBackgroundColor(colors.black)
end

local function clearScreen()
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1, 1)
end

local function drawTitle()
    clearScreen()
    
    -- ASCII art
    term.setTextColor(colors.cyan)
    centerText(2, " _   _ _   _         _____ _           ", colors.cyan)
    centerText(3, "| | | | | | |       |_   _(_)          ", colors.cyan)
    centerText(4, "| |_| | |_| |_ _ __   | |  _ _ __ ___  ", colors.cyan)
    centerText(5, "|  _  | __| __| '_ \\  | | | | '_ ` _ \\ ", colors.cyan)
    centerText(6, "| | | | |_| |_| |_) | | | | | | | | | |", colors.cyan)
    centerText(7, "\\_| |_/\\__|\\__| .__/  \\_/ |_|_| |_| |_|", colors.cyan)
    centerText(8, "              | |                      ", colors.cyan)
    centerText(9, "              |_|                      ", colors.cyan)
    
    centerText(11, "GitHub Installer", colors.lightBlue)
    centerText(12, "TurtleCraft - Simplified Crafting System", colors.white)
    centerText(13, "Jobs Computer & Turtle Architecture", colors.yellow)
end

-- Create progress bar string
local function makeProgressBar(progress, width)
    width = width or 20
    local filled = math.floor(width * progress)
    local bar = "["
    
    if filled > 0 then
        bar = bar .. string.rep("=", filled - 1)
        if filled < width then
            bar = bar .. ">"
        else
            bar = bar .. "="
        end
    end
    
    if filled < width then
        bar = bar .. string.rep(" ", width - filled)
    end
    
    bar = bar .. "]"
    return bar
end

-- Show progress with animated download bar
local function showProgress(current, total, fileInfo, fileProgress)
    local progress = current / total
    drawProgressBar(15, progress, string.format("Overall Progress: %d/%d files", current, total))
    
    -- Current file indicator
    term.setCursorPos(5, 18)
    term.setTextColor(colors.white)
    term.clearLine()
    local displayName = fileInfo.url
    if #displayName > width - 15 then
        displayName = "..." .. displayName:sub(-(width - 18))
    end
    term.write("Downloading: " .. displayName)
    
    -- Add file entry if not exists
    local status = string.format("[%3d/%3d]", current, total)
    local fileName = fileInfo.url:match("([^/]+)$") or fileInfo.url
    
    if fileProgress == 0 then
        -- Starting download
        local message = string.format("%s Pulling %s", status, fileName)
        addScrollLine(message, colors.white, "file_" .. current)
    end
    
    -- Update progress bar line
    local progressBar = makeProgressBar(fileProgress, 20)
    local sizeInfo = string.format("%3d%%", math.floor(fileProgress * 100))
    local progressMsg = string.format("         +-- %s %s", progressBar, sizeInfo)
    addScrollLine(progressMsg, colors.lightGray, "progress_" .. current)
end

-- Complete file download
local function completeFileDownload(current, total, fileInfo)
    -- Update file line with checkmark
    local status = string.format("[%3d/%3d]", current, total)
    local fileName = fileInfo.url:match("([^/]+)$") or fileInfo.url
    local message = string.format("%s [OK] Pulled %s", status, fileName)
    addScrollLine(message, colors.lime, "file_" .. current)
    
    -- Update progress bar to complete
    local progressMsg = string.format("         +-- %s 100%%", makeProgressBar(1, 20))
    addScrollLine(progressMsg, colors.lime, "progress_" .. current)
end

-- Download file with animated progress
local function downloadFile(fileInfo, index, total)
    -- Create directory if needed
    local dir = fs.getDir(fileInfo.path)
    if dir ~= "" and not fs.exists(dir) then
        fs.makeDir(dir)
    end
    
    -- Simulate progressive download with animated bar
    for i = 0, 10 do
        local progress = i / 10
        showProgress(index, total, fileInfo, progress)
        sleep(0.05)  -- Animate the progress bar
    end
    
    local url = string.format(
        "https://raw.githubusercontent.com/%s/%s/%s/%s",
        REPO_OWNER, REPO_NAME, BRANCH, fileInfo.url
    )
    
    local response = http.get(url)
    if not response then
        local errorMsg = string.format("         +-- [X] Failed to download", colors.red)
        addScrollLine(errorMsg, colors.red, "progress_" .. index)
        return false, "Failed to download: " .. fileInfo.url
    end
    
    local content = response.readAll()
    response.close()
    
    local file = fs.open(fileInfo.path, "w")
    if not file then
        local errorMsg = string.format("         +-- [X] Failed to write file", colors.red)
        addScrollLine(errorMsg, colors.red, "progress_" .. index)
        return false, "Failed to write: " .. fileInfo.path
    end
    
    file.write(content)
    file.close()
    
    -- Show completion
    completeFileDownload(index, total, fileInfo)
    
    return true
end

-- Main installation
local function install()
    drawTitle()
    
    -- Initialize scroll window
    initScrollWindow()
    
    -- Check HTTP
    if not http then
        addScrollLine("[X] HTTP API is not enabled", colors.red)
        sleep(2)
        return false
    end
    
    addScrollLine("Starting installation...", colors.white)
    addScrollLine("Repository: " .. REPO_OWNER .. "/" .. REPO_NAME, colors.white)
    addScrollLine("Branch: " .. BRANCH, colors.white)
    addScrollLine("", colors.white)
    
    -- Create directories
    addScrollLine("Creating directory structure...", colors.yellow)
    for _, dir in ipairs(DIRECTORIES) do
        if not fs.exists(dir) then
            fs.makeDir(dir)
            addScrollLine("  [OK] Created " .. dir, colors.lime)
        else
            addScrollLine("  [--] Exists " .. dir, colors.lightGray)
        end
    end
    
    addScrollLine("", colors.white)
    addScrollLine("Downloading files...", colors.yellow)
    
    -- Download files
    local total = #FILES
    for i, fileInfo in ipairs(FILES) do
        local success, err = downloadFile(fileInfo, i, total)
        if not success then
            addScrollLine("[X] Installation failed: " .. err, colors.red)
            sleep(3)
            return false
        end
    end
    
    -- Create launchers
    addScrollLine("", colors.white)
    addScrollLine("Creating launcher scripts...", colors.yellow)
    for _, launcher in ipairs(LAUNCHERS) do
        local file = fs.open("/" .. launcher.name, "w")
        if file then
            file.write(launcher.content)
            file.close()
            addScrollLine("  [OK] Created " .. launcher.name, colors.lime)
        end
    end
    
    addScrollLine("", colors.white)
    addScrollLine("+ Installation complete!", colors.lime)
    addScrollLine("", colors.white)
    addScrollLine("To start the system:", colors.yellow)
    addScrollLine("  1. Jobs Computer: Run 'start-jobs' or 'startup'", colors.white)
    addScrollLine("  2. Turtles: Run 'start-turtle' or 'startup'", colors.white)
    addScrollLine("", colors.white)
    addScrollLine("Setup Requirements:", colors.cyan)
    addScrollLine("  - Jobs Computer: ME Bridge attached (any side)", colors.white)
    addScrollLine("  - Turtles: Connect to same wired network", colors.white)
    addScrollLine("  - Both: Need wireless modems for rednet", colors.white)
    
    sleep(2)
    
    -- Show computer type selection
    local _, termHeight = term.getSize()
    term.setCursorPos(1, termHeight - 2)
    term.setTextColor(colors.yellow)
    print("Select computer type to start:")
    print("1) Jobs Computer  2) Turtle  3) Exit")
    write("Choice (1-3): ")
    local answer = read()
    
    if answer == "1" then
        term.clear()
        term.setCursorPos(1, 1)
        shell.run("start-jobs")
    elseif answer == "2" then
        term.clear()
        term.setCursorPos(1, 1)
        shell.run("start-turtle")
    end
    
    return true
end

-- Run installer
install()
term.setCursorPos(1, height)
print("")