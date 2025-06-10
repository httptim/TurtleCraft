# TurtleCraft Progress Report

## Summary
Successfully completed Phase 1 (Core Infrastructure & Networking) and Phase 2 (ME Bridge Integration) of the distributed crafting system. All three components communicate reliably, and the Jobs Computer can now interact with Applied Energistics 2 ME systems.

## Key Discoveries

### 1. Network Issues Resolved
**Problem**: The original implementation had complex peripheral detection and network discovery that wasn't working properly.

**Solution**: 
- Simplified to use rednet properly according to CC:Tweaked documentation
- Jobs Computer hosts itself with `rednet.host(protocol, "jobs")`
- Other computers find it with `rednet.lookup(protocol, "jobs")`
- No hardcoded computer IDs required

### 2. Event Handling
**Problem**: Original code used `os.pullEvent(timeout)` which doesn't exist in CC:Tweaked.

**Solution**: 
- Use timers for non-blocking event loops
- Proper event handling pattern:
```lua
local timer = os.startTimer(0.1)
local event, p1, p2 = os.pullEvent()
if event == "timer" and p1 == timer then
    -- timeout
else
    os.cancelTimer(timer)
    -- handle other events
end
```

### 3. Turtle Management
**Problem**: Broken turtles remained in the Jobs Computer list indefinitely.

**Solution**: 
- Heartbeat system with configurable timeouts
- Three states: online → offline (60s) → removed (180s)
- Graceful shutdown with UNREGISTER message
- Main Computer shows active/total turtle count

### 4. Wired Turtle Discovery
**Problem**: Wired modem turtle peripherals have generic names (turtle_0, turtle_1) that don't match their computer IDs.

**Solution**:
- Direct discovery using `turtle.getID()` peripheral method
- Automatic discovery when turtles register
- Manual discovery with 'D' key on Jobs Computer
- Maps peripheral names to turtle IDs for direct control

## What Works Now

### ✅ Core Networking
- Reliable computer discovery using rednet protocols
- No hardcoded IDs needed (Jobs Computer can be any ID)
- Debug mode shows all network traffic
- Network test tool for troubleshooting

### ✅ Jobs Computer
- Hosts itself on network as "jobs"
- Tracks registered turtles with heartbeats
- Automatically removes offline turtles
- Shows turtle status (online/offline with time)
- Wired turtle discovery (D key or automatic)
- Shows peripheral names for wired turtles
- Responds to status requests
- ME Bridge integration (when available)
- Interactive ME commands (I - show items, S - search)
- Handles item transfer requests from turtles

### ✅ Main Computer  
- Automatically finds Jobs Computer on network
- Shows connection status
- Displays active/total turtle count
- Shows ME system status (connected/items count)
- Updates every 5 seconds
- Reconnect command (R key)

### ✅ Turtle Client
- Registers with Jobs Computer
- Sends heartbeats every 30 seconds
- Graceful shutdown/unregister
- Re-registration command (R key)
- Fuel level display and refuel command (F key)
- Get items from ME system (G key)
- Deposit items to ME system (D key)

### ✅ Installation & Setup
- Updated installer with correct file list (7 files)
- Startup menu for easy program selection
- All test files removed for cleaner installation
- Clear setup instructions

## Current Limitations

1. **No Job Queue** - Can't actually assign crafting jobs
2. **No Recipe System** - No recipe definitions or crafting logic
3. **No Persistence** - Turtle list is lost on Jobs Computer restart
4. **Basic Text UI** - No fancy graphics or monitors
5. **Fixed Transfer Direction** - ME Bridge assumes turtle is above for item transfers

## Completed Phases

### ✅ Phase 1: Core Infrastructure & Networking
- Network library with rednet wrapper
- Service discovery system
- Heartbeat and health monitoring
- Auto-reconnection logic
- Debug mode and logging

### ✅ Phase 2: ME Bridge Integration
- ME Bridge library with full API
- Item listing and searching
- Item export/import functionality
- Stock level monitoring
- Storage and energy status
- Interactive testing tools

### ✅ Phase 3: Recipe System & Basic Crafting
- Recipe definitions for basic items (planks, sticks, chests, etc.)
- Crafting library with inventory management
- Turtle-side crafting execution
- Job assignment from Main Computer to turtles
- Automatic item request and deposit during crafting
- Interactive crafting menu on turtle (C key)

## Next Steps (Recommended Order)

### Phase 4: Advanced Recipe System & Dependency Resolution
1. Create `lib/dependency.lua` for dependency resolution
2. Add recursive crafting (craft ingredients if not available)
3. Add recipe validation and alternative recipes
4. Implement resource checking before job assignment
5. Add crafting queue with multiple recipes

### Phase 5: Job Queue & Distribution System
1. Create `lib/job_manager.lua` for job queue management
2. Add priority queue implementation
3. Implement job assignment to turtles
4. Add job status tracking and completion handling
5. Create load balancing system

### Phase 6: Advanced Text Interfaces
1. Add crafting commands to Main Computer
2. Create job queue display
3. Add recipe search functionality
4. Implement job status monitoring

### Phase 7: Persistence & Advanced Features
1. Save/restore turtle registry
2. Persist job queue state
3. Add configuration hot-reload
4. Implement error recovery mechanisms

## Technical Details

### File Structure (Current)
```
/
├── config.lua           # Configuration (protocol, timeouts, ME Bridge)
├── recipes.lua          # Recipe definitions
├── lib/
│   ├── network.lua      # Network library (rednet wrapper)
│   ├── me_bridge.lua    # ME Bridge interface library
│   └── crafting.lua     # Crafting operations library
├── jobs_computer.lua    # Central manager with job assignment
├── main_computer.lua    # User interface with crafting requests
├── turtle.lua           # Turtle client with crafting execution
└── startup.lua          # Menu selector
```

### Network Protocol
- Protocol name: "turtlecraft"
- Service discovery: Jobs Computer hosts as "jobs"
- Message format: `{type, data, sender, time}`
- Core messages: PING/PONG, REGISTER, HEARTBEAT, STATUS_REQUEST, UNREGISTER
- ME messages: REQUEST_ITEMS, ITEMS_RESPONSE, DEPOSIT_ITEMS, DEPOSIT_RESPONSE, CHECK_STOCK, STOCK_RESPONSE
- Job messages: JOB_ASSIGN, JOB_ACK, JOB_COMPLETE
- Craft messages: CRAFT_REQUEST, CRAFT_RESPONSE
- Discovery messages: DISCOVERY_START (legacy), DISCOVERY_RESPONSE (legacy)

### Configuration Options
```lua
PROTOCOL = "turtlecraft"          -- Network protocol name
NETWORK_TIMEOUT = 5               -- Network operation timeout
HEARTBEAT_INTERVAL = 30           -- Turtle heartbeat frequency
TURTLE_OFFLINE_TIMEOUT = 60       -- Mark offline after 1 minute
TURTLE_REMOVE_TIMEOUT = 180       -- Remove from list after 3 minutes
DEBUG = true                      -- Show network messages
-- ME_BRIDGE_NAME = "meBridge_0"  -- Optional: specify ME Bridge peripheral
```

## Current Status

**Phase 1, 2 & 3 Complete**: The system has solid networking, ME Bridge integration, and basic crafting functionality. Turtles can craft items on demand, automatically requesting materials from the ME system and depositing results back.

**Ready for Phase 4**: The next step is to implement advanced recipe features like dependency resolution, which will enable recursive crafting (automatically crafting ingredients when needed) and more complex crafting chains.

## Key Insights

1. **Simplicity wins**: Using rednet's built-in service discovery was much more reliable than custom protocols
2. **Event handling**: Proper timer-based event loops are essential in CC:Tweaked
3. **ME Bridge integration**: The Advanced Peripherals ME Bridge provides a clean API for ME system interaction
4. **Modular design**: Separating concerns into libraries (network, ME bridge) makes the code maintainable

## Testing the Current System

1. **Wired Discovery**: Connect turtles via wired modems, press D on Jobs Computer
2. **Item Transfer**: Use G/D keys on turtle to test item requests/deposits  
3. **Crafting**:
   - Press C on Main Computer to request crafting jobs
   - Press C on Turtle to craft items directly
   - Jobs Computer automatically assigns craft jobs to available turtles
4. **Status Monitoring**: All computers show real-time status updates
5. **Auto-discovery**: New turtles are discovered automatically when they register