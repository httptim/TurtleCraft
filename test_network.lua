-- Network Test Script for TurtleCraft
-- Run this on any computer to test network connectivity

print("TurtleCraft Network Test")
print("========================")
print()

-- Find wireless modem
local modemSide = nil
for _, side in ipairs(peripheral.getNames()) do
    if peripheral.getType(side) == "modem" then
        local modem = peripheral.wrap(side)
        if modem.isWireless() then
            modemSide = side
            break
        end
    end
end

if not modemSide then
    print("ERROR: No wireless modem found!")
    return
end

print("Found wireless modem on " .. modemSide)
print("Computer ID: " .. os.getComputerID())
print()

-- Open rednet
rednet.open(modemSide)
print("Opened rednet on modem")

-- Check if open
if rednet.isOpen() then
    print("Rednet confirmed open")
else
    print("ERROR: Rednet failed to open!")
    return
end

print()
print("Looking for computers on protocol 'turtlecraft'...")

-- Look for all computers
local found = rednet.lookup("turtlecraft")
if found then
    print("\nFound computers:")
    if type(found) == "table" then
        for k, v in pairs(found) do
            print("  " .. tostring(k) .. " = " .. tostring(v))
        end
    else
        print("  ID: " .. tostring(found))
    end
else
    print("No computers found")
end

-- Look for specific services
print("\nLooking for specific services:")

local services = {"jobs", "main"}
for _, service in ipairs(services) do
    local id = rednet.lookup("turtlecraft", service)
    if id then
        print("  " .. service .. " -> ID " .. tostring(id))
    else
        print("  " .. service .. " -> not found")
    end
end

-- Host ourselves for testing
print("\nHosting as 'test'...")
rednet.host("turtlecraft", "test")

-- Send a broadcast
print("\nSending broadcast ping...")
rednet.broadcast({type = "TEST_PING", sender = os.getComputerID()}, "turtlecraft")

-- Listen for responses
print("\nListening for 5 seconds...")
local responses = 0
local timeout = os.startTimer(5)

while true do
    local event, p1, p2, p3 = os.pullEvent()
    
    if event == "rednet_message" then
        local sender, message, protocol = p1, p2, p3
        if protocol == "turtlecraft" then
            responses = responses + 1
            print("Response from ID " .. sender .. ": " .. textutils.serialize(message))
        end
    elseif event == "timer" and p1 == timeout then
        break
    end
end

print("\nReceived " .. responses .. " responses")

-- Cleanup
rednet.unhost("turtlecraft")
rednet.close()
print("\nTest complete!")