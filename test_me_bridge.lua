-- ME Bridge Test Script for TurtleCraft
-- Run this on the Jobs Computer to test ME Bridge functionality

print("TurtleCraft ME Bridge Test")
print("==========================")
print()

-- Load the ME Bridge library
local me_bridge = dofile("lib/me_bridge.lua")

-- Test connection
print("Testing ME Bridge connection...")
if me_bridge.init() then
    print("[OK] ME Bridge connected!")
else
    print("[FAIL] ME Bridge not found!")
    print("\nMake sure:")
    print("- Advanced Peripherals mod is installed")
    print("- ME Bridge is connected to this computer")
    print("- ME Bridge is powered and connected to ME network")
    return
end

print()

-- Test storage info
print("Testing storage information...")
local storageInfo = me_bridge.getStorageInfo()
if storageInfo then
    print("[OK] Storage info retrieved:")
    print("  Total: " .. (storageInfo.totalStorage or "Unknown"))
    print("  Used: " .. (storageInfo.usedStorage or "Unknown"))
    print("  Available: " .. (storageInfo.availableStorage or "Unknown"))
    if storageInfo.usagePercent then
        print("  Usage: " .. storageInfo.usagePercent .. "%")
    end
else
    print("[WARN] Could not retrieve storage info")
end

print()

-- Test energy info
print("Testing energy information...")
local energyInfo = me_bridge.getEnergyInfo()
if energyInfo then
    print("[OK] Energy info retrieved:")
    print("  Current: " .. (energyInfo.currentEnergy or "Unknown"))
    print("  Max: " .. (energyInfo.maxEnergy or "Unknown"))
    print("  Usage: " .. (energyInfo.energyUsage or "Unknown"))
    if energyInfo.energyPercent then
        print("  Level: " .. energyInfo.energyPercent .. "%")
    end
else
    print("[WARN] Could not retrieve energy info")
end

print()

-- Test item listing
print("Testing item listing...")
local items, err = me_bridge.listItems()
if items then
    print("[OK] Found " .. #items .. " items in ME system")
    
    -- Show first 5 items
    if #items > 0 then
        print("\nFirst few items:")
        for i = 1, math.min(5, #items) do
            local item = items[i]
            print("  " .. i .. ". " .. me_bridge.formatItem(item))
        end
        if #items > 5 then
            print("  ... and " .. (#items - 5) .. " more")
        end
    end
else
    print("[FAIL] Could not list items: " .. tostring(err))
end

print()

-- Test item search
print("Testing item search...")
print("Enter a search term (e.g. 'stone', 'iron', etc):")
write("> ")
local searchTerm = read()

if searchTerm and searchTerm ~= "" then
    local results, err = me_bridge.searchItems(searchTerm)
    if results then
        print("\nFound " .. #results .. " matching items:")
        for i = 1, math.min(5, #results) do
            local item = results[i]
            print("  " .. i .. ". " .. me_bridge.formatItem(item))
        end
        if #results > 5 then
            print("  ... and " .. (#results - 5) .. " more")
        end
    else
        print("[FAIL] Search failed: " .. tostring(err))
    end
end

print()

-- Test craftable items
print("Testing craftable items...")
local craftables, err = me_bridge.listCraftableItems()
if craftables then
    print("[OK] Found " .. #craftables .. " craftable items")
    
    -- Show first 5 craftable items
    if #craftables > 0 then
        print("\nFirst few craftable items:")
        for i = 1, math.min(5, #craftables) do
            local item = craftables[i]
            local displayName = item.displayName or item.name or "Unknown"
            print("  " .. i .. ". " .. displayName)
        end
        if #craftables > 5 then
            print("  ... and " .. (#craftables - 5) .. " more")
        end
    end
else
    print("[WARN] Could not list craftable items: " .. tostring(err))
end

print()

-- Test item export/import
print("Testing item export/import...")
print("This test requires a chest or inventory above the ME Bridge")
print("Would you like to test item export? (Y/N)")
local response = read()

if string.upper(response) == "Y" then
    print("\nEnter an item to export (e.g. minecraft:cobblestone):")
    write("> ")
    local itemName = read()
    
    if itemName and itemName ~= "" then
        print("Enter quantity (default 1):")
        write("> ")
        local quantity = tonumber(read()) or 1
        
        print("\nExporting " .. quantity .. "x " .. itemName .. " to container above...")
        local exported, err = me_bridge.exportItem(itemName, quantity, "up")
        
        if exported then
            print("[OK] Exported " .. exported .. " items")
            
            -- Try to import them back
            print("\nWould you like to import them back? (Y/N)")
            response = read()
            
            if string.upper(response) == "Y" then
                print("Importing items back from container above...")
                local imported, err = me_bridge.importItem(itemName, exported, "up")
                
                if imported then
                    print("[OK] Imported " .. imported .. " items back")
                else
                    print("[FAIL] Import failed: " .. tostring(err))
                end
            end
        else
            print("[FAIL] Export failed: " .. tostring(err))
        end
    end
end

print()

-- Test crafting CPUs
print("Testing crafting CPUs...")
local cpus, err = me_bridge.getCraftingCPUs()
if cpus then
    print("[OK] Found " .. #cpus .. " crafting CPUs")
    for i, cpu in ipairs(cpus) do
        local status = cpu.isBusy and "BUSY" or "IDLE"
        local storage = cpu.storage or "Unknown"
        print("  CPU " .. i .. ": " .. status .. " (Storage: " .. storage .. ")")
    end
else
    print("[WARN] Could not get crafting CPUs: " .. tostring(err))
end

print()
print("ME Bridge test complete!")
print()
print("Summary:")
print("- Connection: " .. (me_bridge.isConnected() and "[OK]" or "[FAIL]"))
print("- Items found: " .. (#items or 0))
print("- Craftables found: " .. (#craftables or 0))

-- Cleanup
me_bridge.disconnect()
print("\nDisconnected from ME Bridge")