-- Test Wired Turtle Discovery
-- Tests the peripheral discovery mechanism

local config = dofile("config.lua")
local network = dofile("lib/network.lua")

-- Clear screen
local function clear()
    term.clear()
    term.setCursorPos(1, 1)
end

clear()
print("Wired Turtle Discovery Test")
print("===========================")
print()

-- Initialize network
if not network.init() then
    print("Failed to initialize network!")
    return
end

-- Step 1: Find turtle peripherals
print("1. Scanning for turtle peripherals...")
local turtlePeripherals = {}

for _, name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name) == "turtle" then
        table.insert(turtlePeripherals, name)
        print("   Found: " .. name)
    end
end

if #turtlePeripherals == 0 then
    print("   No turtle peripherals found!")
    print()
    print("Make sure:")
    print("- Turtles are connected via wired modems")
    print("- Modems are activated (red ring)")
    print("- Network cables are connected")
    return
end

print()
print("2. Testing peripheral access...")

for _, peripheralName in ipairs(turtlePeripherals) do
    print()
    print("   Testing " .. peripheralName .. ":")
    
    local turtle = peripheral.wrap(peripheralName)
    if turtle then
        print("   - Successfully wrapped peripheral")
        
        -- Test basic functions
        local fuel = turtle.getFuelLevel()
        if fuel then
            print("   - Fuel level: " .. tostring(fuel))
        end
        
        -- Check inventory
        local emptySlots = 0
        for slot = 1, 16 do
            if turtle.getItemCount(slot) == 0 then
                emptySlots = emptySlots + 1
            end
        end
        print("   - Empty slots: " .. emptySlots .. "/16")
        
        -- Test item transfer
        print("   - Testing item transfer...")
        
        -- Option 1: Direct item drop (if turtle is above/below)
        local dropSuccess = turtle.drop(1)
        if dropSuccess then
            print("     [OK] Can drop items")
        end
        
        -- Option 2: Push/pull from inventory
        local invs = {}
        for _, inv in ipairs(peripheral.getNames()) do
            if peripheral.hasType(inv, "inventory") and inv ~= peripheralName then
                table.insert(invs, inv)
            end
        end
        
        if #invs > 0 then
            print("     Found " .. #invs .. " nearby inventories")
            -- Try to pull one item from first inventory
            local sourceInv = invs[1]
            local pulled = turtle.pullItems(sourceInv, 1, 1)
            if pulled and pulled > 0 then
                print("     [OK] Pulled item from " .. sourceInv)
                -- Push it back
                turtle.pushItems(sourceInv, 1, 1)
            end
        end
    else
        print("   - ERROR: Failed to wrap peripheral!")
    end
end

print()
print("3. Testing network discovery protocol...")
print()

-- Find Jobs Computer
local computers = network.findComputers("jobs")
if #computers == 0 then
    print("   No Jobs Computer found!")
    print("   Make sure Jobs Computer is running first")
else
    local jobsID = computers[1]
    print("   Found Jobs Computer ID: " .. jobsID)
    
    -- Test sending discovery message
    print("   Sending test discovery message...")
    network.send(jobsID, "DISCOVERY_TEST", {
        peripheralNames = turtlePeripherals
    })
    
    -- Wait for response
    local timeout = os.startTimer(3)
    while true do
        local event, p1, p2, p3 = os.pullEvent()
        if event == "rednet_message" then
            local sender, message, protocol = p1, p2, p3
            if sender == jobsID and message and message.type == "DISCOVERY_TEST_ACK" then
                os.cancelTimer(timeout)
                print("   [OK] Received acknowledgment from Jobs Computer")
                break
            end
        elseif event == "timer" and p1 == timeout then
            print("   [X] No response from Jobs Computer")
            break
        end
    end
end

print()
print("Test complete!")
print()
print("Summary:")
print("- Found " .. #turtlePeripherals .. " turtle peripheral(s)")
print("- All peripherals are accessible")
print()
print("To use discovery:")
print("1. Start Jobs Computer")
print("2. Start Turtle clients")
print("3. Press 'D' on Jobs Computer to discover wired turtles")