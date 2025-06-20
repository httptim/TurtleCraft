-- Test script to verify crafting_v2 improvements
-- This tests the simplified item request flow

local crafting_v2 = dofile("lib/crafting_v2.lua")

-- Mock network and jobsComputerID for testing
local mockNetwork = {
    send = function(id, msgType, data)
        print("[MOCK] Sending to " .. id .. ": " .. msgType)
        if data then
            for k, v in pairs(data) do
                print("  " .. k .. " = " .. tostring(v))
            end
        end
    end,
    receive = function(timeout)
        -- Simulate no responses
        sleep(timeout or 0.1)
        return nil, nil
    end
}

local mockJobsID = 999

-- Test the getInventory function
print("=== Testing getInventory ===")
local inventory = crafting_v2.getInventory()
print("Current inventory:")
for slot, item in pairs(inventory) do
    print("  Slot " .. slot .. ": " .. item.name .. " x" .. item.count)
end

print("\n=== Testing requestItems (mock) ===")
-- This will timeout but shows the improved messaging
local items = {
    ["minecraft:planks"] = 4,
    ["minecraft:stick"] = 2
}

print("Note: This test will timeout as it's using mock network")
print("The goal is to verify the improved status messages")

local success, err = crafting_v2.requestItems(mockNetwork, mockJobsID, items)
if not success then
    print("\nExpected error: " .. err)
else
    print("\nUnexpected success in mock test")
end

print("\n=== Test Complete ===")
print("The crafting_v2 library has been updated with:")
print("- Simplified item waiting logic") 
print("- Better status messages with [OK] and [X] markers")
print("- Clearer step-by-step progress indicators")
print("- More robust error messages")