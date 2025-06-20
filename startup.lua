-- Simple TurtleCraft Startup Script

local function clear()
    term.clear()
    term.setCursorPos(1, 1)
end

-- Check if this is a turtle
if turtle then
    print("Starting Turtle Program...")
    shell.run("turtle.lua")
    return
end

-- Check if labeled as jobs computer
local label = os.getComputerLabel()
if label and label:lower() == "jobs" then
    print("Starting Jobs Computer...")
    shell.run("jobs_computer.lua")
    return
end

-- Otherwise show menu
while true do
    clear()
    print("=== TurtleCraft Startup ===")
    print()
    print("What is this computer?")
    print()
    print("1. Jobs Computer (ME System Manager)")
    print("2. Exit")
    print()
    print("Choice: ")
    
    local choice = read()
    
    if choice == "1" then
        os.setComputerLabel("jobs")
        print("\nLabeled as Jobs Computer")
        print("Starting Jobs Computer...")
        sleep(2)
        shell.run("jobs_computer.lua")
        break
    elseif choice == "2" then
        clear()
        print("Exiting...")
        break
    end
end