-- ME Bridge Interface Library for TurtleCraft
-- Provides interface to Applied Energistics 2 ME System via Advanced Peripherals

local config = dofile("config.lua")
local logger = dofile("lib/logger.lua")

local me_bridge = {}

-- State
local bridge = nil
local connected = false

-- Initialize ME Bridge connection
function me_bridge.init()
    if config.DEBUG then
        print("[ME Bridge] Initializing ME Bridge interface...")
    end
    
    -- First try the configured ME Bridge name
    if config.ME_BRIDGE_NAME then
        bridge = peripheral.wrap(config.ME_BRIDGE_NAME)
        if bridge then
            connected = true
            if config.DEBUG then
                print("[ME Bridge] Connected to configured bridge: " .. config.ME_BRIDGE_NAME)
            end
            logger.info("ME Bridge connected: " .. config.ME_BRIDGE_NAME)
            return true
        end
    end
    
    -- Try to find ME Bridge
    bridge = peripheral.find("meBridge")
    if bridge then
        connected = true
        local bridgeName = peripheral.getName(bridge)
        if config.DEBUG then
            print("[ME Bridge] Found ME Bridge: " .. bridgeName)
        end
        logger.info("ME Bridge connected: " .. bridgeName)
        return true
    end
    
    if config.DEBUG then
        print("[ME Bridge] No ME Bridge found!")
    end
    logger.error("Failed to find ME Bridge")
    return false
end

-- Check if connected
function me_bridge.isConnected()
    return connected and bridge ~= nil
end

-- Get bridge handle for direct access
function me_bridge.getBridge()
    return bridge
end

-- List all items in ME system
function me_bridge.listItems()
    if not connected then
        return nil, "Not connected to ME Bridge"
    end
    
    local ok, result = pcall(bridge.listItems)
    if not ok then
        logger.error("Failed to list items: " .. tostring(result))
        return nil, tostring(result)
    end
    
    return result
end

-- Get specific item details
function me_bridge.getItem(itemName)
    if not connected then
        return nil, "Not connected to ME Bridge"
    end
    
    local ok, result = pcall(bridge.getItem, {name = itemName})
    if not ok then
        logger.error("Failed to get item: " .. tostring(result))
        return nil, tostring(result)
    end
    
    return result
end

-- Search for items by partial name
function me_bridge.searchItems(searchTerm)
    if not connected then
        return nil, "Not connected to ME Bridge"
    end
    
    local items, err = me_bridge.listItems()
    if not items then
        return nil, err
    end
    
    local results = {}
    local searchLower = string.lower(searchTerm)
    
    for _, item in ipairs(items) do
        if item.name and string.find(string.lower(item.name), searchLower) then
            table.insert(results, item)
        elseif item.displayName and string.find(string.lower(item.displayName), searchLower) then
            table.insert(results, item)
        end
    end
    
    return results
end

-- Export items from ME to a direction (for turtle access)
function me_bridge.exportItem(itemName, count, direction)
    if not connected then
        return nil, "Not connected to ME Bridge"
    end
    
    direction = direction or "up"  -- Default to up for turtle access
    
    local item = {name = itemName}
    local ok, result = pcall(bridge.exportItem, item, direction, count)
    if not ok then
        logger.error("Failed to export item: " .. tostring(result))
        return nil, tostring(result)
    end
    
    if config.DEBUG then
        print("[ME Bridge] Exported " .. tostring(result) .. "x " .. itemName .. " to " .. direction)
    end
    logger.info("Exported " .. tostring(result) .. "x " .. itemName)
    
    return result
end

-- Import items from a direction into ME
function me_bridge.importItem(itemName, count, direction)
    if not connected then
        return nil, "Not connected to ME Bridge"
    end
    
    direction = direction or "up"  -- Default to up for turtle access
    
    local item = {name = itemName}
    local ok, result = pcall(bridge.importItem, item, direction, count)
    if not ok then
        logger.error("Failed to import item: " .. tostring(result))
        return nil, tostring(result)
    end
    
    if config.DEBUG then
        print("[ME Bridge] Imported " .. tostring(result) .. "x " .. itemName .. " from " .. direction)
    end
    logger.info("Imported " .. tostring(result) .. "x " .. itemName)
    
    return result
end

-- Export items to specific slot of inventory
function me_bridge.exportItemToSlot(itemName, count, direction, slot)
    if not connected then
        return nil, "Not connected to ME Bridge"
    end
    
    -- Advanced Peripherals ME Bridge may support slot targeting
    -- This is implementation-specific
    local item = {name = itemName}
    local ok, result = pcall(function()
        if bridge.exportItemToSlot then
            return bridge.exportItemToSlot(item, direction, count, slot)
        else
            -- Fallback to regular export
            return bridge.exportItem(item, direction, count)
        end
    end)
    
    if not ok then
        logger.error("Failed to export to slot: " .. tostring(result))
        return nil, tostring(result)
    end
    
    return result
end

-- Check if item can be crafted
function me_bridge.isItemCraftable(itemName)
    if not connected then
        return false, "Not connected to ME Bridge"
    end
    
    local item = {name = itemName}
    local ok, result = pcall(bridge.isItemCraftable, item)
    if not ok then
        logger.error("Failed to check craftable: " .. tostring(result))
        return false, tostring(result)
    end
    
    return result
end

-- List all craftable items
function me_bridge.listCraftableItems()
    if not connected then
        return nil, "Not connected to ME Bridge"
    end
    
    local ok, result = pcall(bridge.listCraftableItems)
    if not ok then
        logger.error("Failed to list craftable items: " .. tostring(result))
        return nil, tostring(result)
    end
    
    return result
end

-- Craft items (returns crafting job)
function me_bridge.craftItem(itemName, count)
    if not connected then
        return nil, "Not connected to ME Bridge"
    end
    
    local item = {name = itemName}
    local ok, result = pcall(bridge.craftItem, item, count)
    if not ok then
        logger.error("Failed to craft item: " .. tostring(result))
        return nil, tostring(result)
    end
    
    if config.DEBUG then
        print("[ME Bridge] Started crafting " .. count .. "x " .. itemName)
    end
    logger.info("Crafting " .. count .. "x " .. itemName)
    
    return result
end

-- Get storage information
function me_bridge.getStorageInfo()
    if not connected then
        return nil, "Not connected to ME Bridge"
    end
    
    local info = {}
    
    -- Get total storage
    local ok, total = pcall(bridge.getTotalItemStorage)
    if ok then
        info.totalStorage = total
    end
    
    -- Get used storage
    ok, used = pcall(bridge.getUsedItemStorage)
    if ok then
        info.usedStorage = used
    end
    
    -- Get available storage
    ok, available = pcall(bridge.getAvailableItemStorage)
    if ok then
        info.availableStorage = available
    end
    
    -- Calculate percentage if we have the data
    if info.totalStorage and info.usedStorage then
        info.usagePercent = math.floor((info.usedStorage / info.totalStorage) * 100)
    end
    
    return info
end

-- Get energy information
function me_bridge.getEnergyInfo()
    if not connected then
        return nil, "Not connected to ME Bridge"
    end
    
    local info = {}
    
    -- Get current energy
    local ok, energy = pcall(bridge.getEnergyStorage)
    if ok then
        info.currentEnergy = energy
    end
    
    -- Get max energy
    ok, maxEnergy = pcall(bridge.getMaxEnergyStorage)
    if ok then
        info.maxEnergy = maxEnergy
    end
    
    -- Get energy usage
    ok, usage = pcall(bridge.getEnergyUsage)
    if ok then
        info.energyUsage = usage
    end
    
    -- Calculate percentage if we have the data
    if info.currentEnergy and info.maxEnergy then
        info.energyPercent = math.floor((info.currentEnergy / info.maxEnergy) * 100)
    end
    
    return info
end

-- Get crafting CPUs
function me_bridge.getCraftingCPUs()
    if not connected then
        return nil, "Not connected to ME Bridge"
    end
    
    local ok, result = pcall(bridge.getCraftingCPUs)
    if not ok then
        logger.error("Failed to get crafting CPUs: " .. tostring(result))
        return nil, tostring(result)
    end
    
    return result
end

-- Utility function to format item display
function me_bridge.formatItem(item)
    if not item then return "Unknown Item" end
    
    local display = item.displayName or item.name or "Unknown"
    local count = item.amount or item.count or 0
    
    return string.format("%s x%d", display, count)
end

-- Disconnect and cleanup
function me_bridge.disconnect()
    connected = false
    bridge = nil
    logger.info("ME Bridge disconnected")
end

return me_bridge