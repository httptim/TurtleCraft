-- Network diagnostic tool for CC:Tweaked Distributed Crafting System

print("Network Diagnostic Tool")
print("======================")
print()

-- Check peripherals
print("Checking peripherals...")
local peripherals = peripheral.getNames()
print("Found " .. #peripherals .. " peripherals:")
for _, name in ipairs(peripherals) do
    local pType = peripheral.getType(name)
    print("  - " .. name .. " (" .. pType .. ")")
    
    if pType == "modem" then
        local modem = peripheral.wrap(name)
        if modem.isWireless and modem.isWireless() then
            print("    [Wireless modem]")
        else
            print("    [Wired modem]")
        end
    end
end

print()
print("Computer ID: " .. os.getComputerID())
print()

-- Find wireless modem
local wirelessModem = nil
for _, name in ipairs(peripherals) do
    if peripheral.getType(name) == "modem" then
        local modem = peripheral.wrap(name)
        if modem.isWireless and modem.isWireless() then
            wirelessModem = name
            break
        end
    end
end

if not wirelessModem then
    print("ERROR: No wireless modem found!")
    return
end

-- Open modem
print("Opening wireless modem: " .. wirelessModem)
rednet.open(wirelessModem)

if rednet.isOpen(wirelessModem) then
    print("Modem opened successfully")
else
    print("ERROR: Failed to open modem!")
    return
end

print()
print("Testing rednet...")

-- Define protocol
local protocol = "crafting_system"

-- Host ourselves for testing
local hostname = "test_" .. os.getComputerID()
rednet.host(protocol, hostname)
print("Hosting as: " .. hostname .. " on protocol: " .. protocol)

print()
print("Looking for computers on protocol...")

-- Look for all computers
local computers = rednet.lookup(protocol)
if computers then
    print("Found computers:")
    if type(computers) == "table" then
        for k, v in pairs(computers) do
            print("  - " .. tostring(k) .. " = " .. tostring(v))
        end
    else
        print("  - ID: " .. tostring(computers))
    end
else
    print("No computers found on protocol")
end

print()
print("Looking for specific computer types...")

-- Look for each type
local types = {"main", "jobs", "turtle"}
for _, computerType in ipairs(types) do
    print("\nLooking for " .. computerType .. " computers:")
    
    -- Try different lookup methods
    for i = 0, 10 do
        local hostname = computerType .. "_" .. i
        local result = rednet.lookup(protocol, hostname)
        if result then
            print("  Found " .. hostname .. " at ID: " .. tostring(result))
        end
    end
end

print()
print("Waiting for incoming messages (10 seconds)...")
print("Press any key to exit")

-- Listen for messages
local timer = os.startTimer(10)
while true do
    local event, p1, p2, p3 = os.pullEvent()
    
    if event == "rednet_message" then
        print("Message from " .. p1 .. ": " .. textutils.serialize(p2))
    elseif event == "timer" and p1 == timer then
        print("Timeout - no messages received")
        break
    elseif event == "key" then
        print("Exiting...")
        break
    end
end

-- Clean up
rednet.unhost(protocol)
rednet.close(wirelessModem)
print("\nDiagnostic complete")