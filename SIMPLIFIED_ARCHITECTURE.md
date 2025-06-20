# TurtleCraft Simplified Architecture Design

## Overview
This document outlines a simplified architecture for TurtleCraft that:
1. Removes the Main Computer entirely
2. Fixes the timing issue where turtles start crafting before receiving all materials
3. Maintains all core functionality (ME system integration, turtle crafting, item management)

## Current Issues

### 1. Timing Problem
The current implementation has a critical timing issue in the item request flow:
- Jobs Computer calls `bridge.exportItemToPeripheral()` and immediately sends `ITEMS_RESPONSE`
- Turtle receives `ITEMS_RESPONSE` and starts waiting for items
- Items may still be in transit through the ME system/wired network
- Turtle may timeout or start crafting before items actually arrive

### 2. Unnecessary Complexity
The Main Computer adds an extra layer without providing essential functionality:
- It only provides a user interface for craft requests
- All actual work is done by Jobs Computer and Turtles
- Removing it simplifies the communication flow

## Proposed Solution

### Architecture Changes

#### 1. Remove Main Computer
- Jobs Computer becomes the primary interface
- Add simple crafting commands directly to Jobs Computer's UI
- Maintain existing monitor display capabilities on Jobs Computer

#### 2. Fix Item Transfer Verification

The key insight is that **the ME Bridge's `exportItemToPeripheral()` is asynchronous** - it initiates the transfer but doesn't guarantee completion.

**Solution**: Implement item arrival verification in Jobs Computer before sending `ITEMS_RESPONSE`.

### Implementation Details

#### Jobs Computer Changes

1. **Enhanced Item Export Function** (in `jobs_computer.lua`):
```lua
-- New function to export items with verification
local function exportItemWithVerification(itemName, count, turtlePeripheral, turtleId)
    print("[Jobs] Starting verified export of " .. count .. "x " .. itemName)
    
    -- Step 1: Check initial turtle inventory
    local turtle = peripheral.wrap(turtlePeripheral)
    if not turtle then
        return nil, "Failed to wrap turtle peripheral"
    end
    
    -- Count how many of this item the turtle already has
    local initialCount = 0
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item and item.name == itemName then
            initialCount = initialCount + item.count
        end
    end
    print("[Jobs] Turtle initially has " .. initialCount .. "x " .. itemName)
    
    -- Step 2: Export the items
    local exported, err = me_bridge.exportItemToPeripheral(itemName, count, turtlePeripheral)
    if not exported or exported == 0 then
        return nil, err or "Failed to export items"
    end
    
    print("[Jobs] ME Bridge reported export of " .. exported .. " items, verifying arrival...")
    
    -- Step 3: Wait for items to arrive with timeout
    local timeout = 5 -- 5 seconds timeout
    local startTime = os.clock()
    local verified = false
    local finalCount = initialCount
    
    while os.clock() - startTime < timeout do
        -- Count items in turtle
        local currentCount = 0
        for slot = 1, 16 do
            local item = turtle.getItemDetail(slot)
            if item and item.name == itemName then
                currentCount = currentCount + item.count
            end
        end
        
        -- Check if we received the expected amount
        if currentCount >= initialCount + exported then
            finalCount = currentCount
            verified = true
            print("[Jobs] Verified: Turtle now has " .. currentCount .. "x " .. itemName)
            break
        end
        
        sleep(0.1) -- Check every 100ms
    end
    
    if not verified then
        local currentCount = finalCount - initialCount
        return nil, "Timeout: Only received " .. currentCount .. " of " .. exported .. " items"
    end
    
    return exported
end
```

2. **Update REQUEST_ITEMS Handler**:
```lua
elseif message.type == "REQUEST_ITEMS" then
    -- ... existing peripheral checks ...
    
    -- Use the new verified export function
    local exported, err = exportItemWithVerification(itemName, count, turtlePeripheral, sender)
    
    if exported and exported > 0 then
        network.send(sender, "ITEMS_RESPONSE", {
            success = true,
            item = itemName,
            count = exported,
            verified = true  -- New field to indicate verification
        })
        print("[Jobs] Successfully exported and verified " .. exported .. "x " .. itemName)
    else
        network.send(sender, "ITEMS_RESPONSE", {
            success = false,
            error = err or "Failed to export items",
            item = itemName
        })
        print("[Jobs] Failed to export: " .. tostring(err))
    end
```

3. **Add Craft Command to Jobs Computer UI**:
```lua
-- In displayStatus() function, add:
print("  C - Craft Item")

-- In main loop key handling, add:
elseif p1 == keys.c then
    craftItem()  -- New function

-- New function for crafting interface
local function craftItem()
    clear()
    print("Craft Item")
    print("==========")
    print()
    
    -- Show available recipes
    local recipes = dofile("recipes.lua")
    local recipeList = recipes.list()
    
    print("Available recipes:")
    for i, name in ipairs(recipeList) do
        print(string.format("%2d. %s", i, name))
    end
    
    print("\nEnter recipe number (or 0 to cancel):")
    write("> ")
    local choice = tonumber(read())
    
    if not choice or choice == 0 or choice > #recipeList then
        return
    end
    
    local recipeName = recipeList[choice]
    
    print("\nEnter quantity:")
    write("> ")
    local quantity = tonumber(read()) or 1
    
    -- Find available turtle
    local availableTurtle = nil
    for _, turtle in ipairs(turtles) do
        if turtle.status == "online" and turtle.peripheralName then
            availableTurtle = turtle
            break
        end
    end
    
    if not availableTurtle then
        print("\nNo turtles available!")
        sleep(2)
        return
    end
    
    -- Send job to turtle
    local jobId = "job_" .. os.epoch("local")
    print("\nAssigning job " .. jobId .. " to Turtle #" .. availableTurtle.id)
    
    network.send(availableTurtle.id, "JOB_ASSIGN", {
        id = jobId,
        type = "CRAFT",
        recipe = recipeName,
        quantity = quantity
    })
    
    print("Job sent! Check turtle for progress.")
    sleep(2)
end
```

#### Turtle Changes

1. **Simplified Item Request Handling** (in `crafting_v2.lua`):
```lua
function crafting_v2.requestItems(network, jobsComputerID, itemsNeeded)
    local received = {}
    
    -- Send all item requests
    print("Sending item requests to Jobs Computer...")
    for itemName, count in pairs(itemsNeeded) do
        print("  Requesting " .. count .. "x " .. itemName)
        network.send(jobsComputerID, "REQUEST_ITEMS", {
            item = itemName,
            count = count
        })
        sleep(0.1)  -- Prevent network overload
    end
    
    -- Wait for all responses
    local itemsToReceive = {}
    for itemName, count in pairs(itemsNeeded) do
        itemsToReceive[itemName] = count
    end
    
    local responseTimeout = os.startTimer(15)  -- Increased timeout since verification takes time
    while next(itemsToReceive) do
        local event, p1, p2, p3 = os.pullEvent()
        if event == "timer" and p1 == responseTimeout then
            local missing = ""
            for item, _ in pairs(itemsToReceive) do
                missing = missing .. item .. ", "
            end
            return nil, "Timeout waiting for: " .. missing
        elseif event == "rednet_message" then
            local sender, message = p1, p2
            if sender == jobsComputerID and message and message.type == "ITEMS_RESPONSE" then
                if message.data.success then
                    local itemName = message.data.item
                    received[itemName] = message.data.count
                    itemsToReceive[itemName] = nil
                    
                    -- If Jobs Computer verified the items, we can trust they're here
                    if message.data.verified then
                        print("  [OK] Verified delivery of " .. itemName)
                    else
                        print("  Response received for " .. itemName)
                    end
                else
                    os.cancelTimer(responseTimeout)
                    local itemName = message.data.item or "unknown"
                    return nil, "Failed to get " .. itemName .. ": " .. (message.data.error or "Unknown")
                end
            end
        end
    end
    os.cancelTimer(responseTimeout)
    
    -- Since Jobs Computer now verifies delivery, we can do a quick final check
    print("\nVerifying final inventory...")
    local finalInventory = {}
    for slot = 1, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item then
            finalInventory[item.name] = (finalInventory[item.name] or 0) + item.count
        end
    end
    
    -- Verify we have everything
    for itemName, neededCount in pairs(itemsNeeded) do
        local haveCount = finalInventory[itemName] or 0
        if haveCount < neededCount then
            return nil, "Missing items after delivery: " .. itemName .. " (have " .. haveCount .. ", need " .. neededCount .. ")"
        end
    end
    
    print("All items verified in inventory!")
    return received
end
```

### Communication Flow

#### Simplified Craft Request Flow
```
User at Jobs Computer          Jobs Computer              Turtle
        │                           │                        │
        ├─Selects recipe─────────>  │                        │
        ├─Enters quantity────────>  │                        │
        │                           │                        │
        │                           ├──JOB_ASSIGN──────────>│
        │                           │  {recipe, quantity}    │
        │                           │                        │
        │                           <──JOB_ACK──────────────┤
        │                           │  {accepted: true}      │
        │                           │                        │
        │                           <──REQUEST_ITEMS────────┤
        │                           │  {item, count}         │
        │                           │                        │
        │                           ├─exportItemWithVerification()
        │                           ├─[Verify arrival]       │
        │                           │                        │
        │                           ├──ITEMS_RESPONSE──────>│
        │                           │  {verified: true}      │
        │                           │                        │
        │                           │                 [Craft]├─
        │                           │                        │
        │                           <──PULL_ITEM───────────┤
        │                           │  {crafted items}       │
        │                           │                        │
        │                           <──JOB_COMPLETE─────────┤
        │                           │  {success: true}       │
```

### Benefits of This Approach

1. **Reliability**: Items are verified to be in the turtle before crafting starts
2. **Simplicity**: Removes an entire computer from the system
3. **Efficiency**: Direct communication between Jobs Computer and Turtles
4. **Maintainability**: Fewer components to manage and debug
5. **User Experience**: Craft commands available directly where the work happens

### Migration Steps

1. **Update Jobs Computer** with:
   - Item verification function
   - Direct crafting UI
   - Enhanced status display

2. **Update Turtle** to:
   - Trust verified deliveries from Jobs Computer
   - Maintain existing crafting logic

3. **Remove Main Computer**:
   - No longer needed in the system
   - Users interact directly with Jobs Computer

### Alternative Considerations

If you want to maintain a separate UI computer later, you can:
- Add a simple "Terminal Computer" that sends commands to Jobs Computer
- Use monitors attached to Jobs Computer for status display
- Create a web interface using the HTTP API

This design maintains all functionality while solving the timing issue and reducing complexity.