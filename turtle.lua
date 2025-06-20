-- Simple Crafting Turtle for TurtleCraft

local PROTOCOL = "turtlecraft"
local HEARTBEAT_INTERVAL = 5
local CHEST_DIRECTION = "front"  -- Where to get/put items

-- State
local jobsComputerId = nil
local running = true

-- Initialize
print("Simple Crafting Turtle Starting...")
print("Turtle ID: " .. os.getComputerID())

-- Open rednet
peripheral.find("modem", rednet.open)

-- Helper functions
local function clear()
    term.clear()
    term.setCursorPos(1, 1)
end

-- Find and register with Jobs Computer
local function findJobsComputer()
    print("Looking for Jobs Computer...")
    
    while not jobsComputerId do
        local id = rednet.lookup(PROTOCOL, "jobs")
        if id then
            print("Found Jobs Computer at ID " .. id)
            rednet.send(id, {type = "REGISTER"}, PROTOCOL)
            
            local sender, msg = rednet.receive(PROTOCOL, 5)
            if sender == id and msg and msg.type == "REGISTER_ACK" then
                jobsComputerId = id
                print("Registered successfully!")
                break
            end
        end
        
        print("Retrying in 5 seconds...")
        sleep(5)
    end
end

-- Send heartbeat
local function sendHeartbeat()
    if jobsComputerId then
        rednet.send(jobsComputerId, {type = "HEARTBEAT"}, PROTOCOL)
    end
end

-- Pull items from chest
local function pullItemsFromChest(itemName, count)
    turtle.select(1)
    
    -- Turn to face chest
    local pulled = 0
    
    for i = 1, 16 do
        if pulled >= count then break end
        
        turtle.select(i)
        local success = turtle.suck(count - pulled)
        
        if success then
            local detail = turtle.getItemDetail(i)
            if detail and detail.name == itemName then
                pulled = pulled + detail.count
            else
                -- Wrong item, put it back
                turtle.drop()
            end
        end
    end
    
    return pulled
end

-- Request items from Jobs Computer
local function requestItems(itemName, count)
    print("Requesting " .. count .. "x " .. itemName)
    
    rednet.send(jobsComputerId, {
        type = "REQUEST_ITEMS",
        item = itemName,
        count = count
    }, PROTOCOL)
    
    local sender, response = rednet.receive(PROTOCOL, 10)
    if sender == jobsComputerId and response and response.type == "ITEMS_RESPONSE" then
        if response.success then
            print("Jobs Computer sent items, pulling from chest...")
            
            -- Wait a bit for items to arrive
            sleep(3)
            
            -- Try to pull items from chest
            local pulled = pullItemsFromChest(itemName, count)
            if pulled >= count then
                print("Got all items!")
                return true
            else
                print("Only got " .. pulled .. " items")
                return false
            end
        else
            print("Failed: " .. (response.error or "Unknown error"))
            return false
        end
    end
    
    print("No response from Jobs Computer")
    return false
end

-- Deposit items to chest
local function depositItems()
    print("Depositing items...")
    
    for i = 1, 16 do
        turtle.select(i)
        turtle.drop()
    end
    
    rednet.send(jobsComputerId, {
        type = "DEPOSIT_ITEMS"
    }, PROTOCOL)
end

-- Simple crafting function
local function craft(recipe)
    print("\n=== Starting Craft: " .. recipe.name .. " ===")
    
    -- Clear inventory first
    depositItems()
    
    -- Request all items
    local allItemsReceived = true
    for _, ingredient in ipairs(recipe.ingredients) do
        if not requestItems(ingredient.item, ingredient.count) then
            allItemsReceived = false
            break
        end
    end
    
    if not allItemsReceived then
        print("Failed to get all items!")
        depositItems()
        return false
    end
    
    -- Wait to ensure all items have arrived
    print("Waiting for all items to settle...")
    sleep(2)
    
    -- Arrange items in crafting grid
    print("Arranging items...")
    for i, ingredient in ipairs(recipe.ingredients) do
        if ingredient.slot and ingredient.slot <= 16 then
            turtle.select(i)
            turtle.transferTo(ingredient.slot)
        end
    end
    
    -- Craft
    print("Crafting...")
    turtle.select(1)
    local success = turtle.craft()
    
    if success then
        print("Craft successful!")
    else
        print("Craft failed!")
    end
    
    -- Deposit results
    sleep(1)
    depositItems()
    
    return success
end

-- Show menu
local function showMenu()
    clear()
    print("=== Simple Crafting Turtle ===")
    print()
    print("Turtle ID: " .. os.getComputerID())
    print("Jobs Computer: " .. (jobsComputerId and ("Connected #" .. jobsComputerId) or "Not Connected"))
    print()
    print("Commands:")
    print("  C - Craft item")
    print("  T - Test craft (stick)")
    print("  Q - Quit")
end

-- Test craft - make a stick
local function testCraft()
    local stickRecipe = {
        name = "Stick",
        ingredients = {
            {item = "minecraft:oak_planks", count = 2, slot = 2},
            {item = "minecraft:oak_planks", count = 2, slot = 5}
        }
    }
    
    craft(stickRecipe)
end

-- Main loop
local function main()
    findJobsComputer()
    
    -- Heartbeat timer
    local heartbeatTimer = os.startTimer(HEARTBEAT_INTERVAL)
    
    while running do
        showMenu()
        
        local event, param = os.pullEvent()
        
        if event == "timer" and param == heartbeatTimer then
            sendHeartbeat()
            heartbeatTimer = os.startTimer(HEARTBEAT_INTERVAL)
            
        elseif event == "key" then
            if param == keys.q then
                running = false
                
            elseif param == keys.c then
                clear()
                print("Enter item to craft (e.g., minecraft:stick):")
                local itemName = read()
                
                -- For demo, just request 64 of the item
                -- In real use, you'd have recipes defined
                requestItems(itemName, 64)
                sleep(2)
                depositItems()
                
            elseif param == keys.t then
                testCraft()
                print("\nPress any key to continue...")
                os.pullEvent("key")
            end
        end
    end
    
    clear()
    print("Shutting down...")
end

-- Run
main()