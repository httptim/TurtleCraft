# CC:Tweaked Distributed Crafting System

A sophisticated distributed crafting system for ComputerCraft: Tweaked that manages multiple crafting turtles through a centralized computer interface, with ME Bridge integration for seamless Applied Energistics 2 connectivity.

## ⚠️ IMPORTANT DISCLAIMER
**This is theoretical code and architecture documentation. None of the code examples, APIs, or implementations have been tested or proven to work. This serves as a design specification and reference guide for development purposes only.**

## 📚 DEVELOPMENT REFERENCE
**For Implementation**: This project includes `docs/CCTweaked.md` which contains comprehensive CC:Tweaked API documentation and usage examples. **All CC:Tweaked feature implementations must reference this documentation** to ensure correct API usage, syntax, and functionality.

**ME Bridge API**: When implementing ME Bridge functionality, request the Advanced Peripherals documentation link for accurate API reference.

## Features

### Core Functionality
- **Distributed Architecture**: Central computer manages multiple crafting turtles via rednet
- **ME Bridge Integration**: Seamless integration with Applied Energistics 2 networks
- **Priority System**: Set item priorities to control crafting order
- **Stock Management**: Maintain minimum inventory levels automatically
- **Recipe Management**: Comprehensive config-based recipe system
- **Real-time Monitoring**: GUI interface showing turtle status and crafting progress
- **Auto-Discovery**: Automatic turtle registration and management
- **Error Recovery**: Robust error handling and recovery mechanisms

### Advanced Features
- **Load Balancing**: Distribute crafting jobs across available turtles
- **Resource Optimization**: Intelligent resource allocation and planning
- **Automatic Dependency Resolution**: Recursively craft missing ingredients
- **Priority Job Reservation**: Reserve turtles for high-priority or minimum stock jobs
- **Batch Processing**: Efficient batch crafting for large orders
- **Logging System**: Comprehensive logging for debugging and monitoring
- **Hot Reload**: Update configs without system restart
- **Persistent Queues**: Job queues survive system restarts with auto-recovery

## System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ME Network    │◄──►│ Jobs Computer   │◄──►│ Main Computer   │
│   (via Bridge)  │    │ (Job Manager)   │    │    (GUI)        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │ (wired modems)        │ (wireless rednet)     │ (wireless rednet)
         │ [Item Transfers]      │ [Job Coordination]    │ [Status/Control]
         │                       ▼                       ▼
         │             ┌─────────────────────┐          ┌─────────────────┐
         │             │    Turtle Network   │          │  Config Files   │
         │             └─────────────────────┘          │   (Recipes)     │
         │                       │                      └─────────────────┘
         │       ┌───────────────┼───────────────┐
         ▼       ▼               ▼               ▼
    ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
    │  Turtle 1   │ │  Turtle 2   │ │  Turtle N   │
    │ (Crafter)   │ │ (Crafter)   │ │ (Crafter)   │
    │ WiFi + Wired│ │ WiFi + Wired│ │ WiFi + Wired│
    └─────────────┘ └─────────────┘ └─────────────┘
```

**Three-Computer Architecture:**
- **Main Computer**: GUI interface, user interaction, system monitoring
- **Jobs Computer**: ME Bridge access, job queue management, turtle coordination, item transfers
- **Turtles**: Crafting execution with automatic dependency resolution

**Network Functions:**
- **Wireless (Rednet)**: Job assignment, status updates, GUI communication
- **Wired (ME Bridge)**: Item requests, transfers, inventory management

## System Requirements

### Prerequisites
- **ComputerCraft: Tweaked** mod installed
- **Advanced Peripherals** mod installed
- **Applied Energistics 2** mod installed (recommended)
- **Two computers minimum** (Main Computer + Jobs Computer)
- **Two 3x3 monitor setups** (one for each computer)
- At least one **Crafty Turtle**
- ME Bridge connected to Jobs Computer
- **Wireless modems** on all computers and turtles (for rednet communication)
- **Wired modems** on Jobs Computer, turtles, and ME Bridge (for item transfers)

### Size Constraints
**CRITICAL**: The entire project must be under 1MB due to ComputerCraft storage limitations. All files, configs, and logs combined cannot exceed this limit.

### Hardware Setup
1. **Place Equipment**
   ```
   - Main Computer with wireless modem + 3x3 monitor setup
   - Jobs Computer with wireless modem + wired modem + 3x3 monitor setup
   - ME Bridge adjacent to Jobs Computer with wired modem
   - Crafty Turtles with wireless modem + wired modem each
   - Wired modem network connecting Jobs Computer, ME Bridge, and all turtles
   ```

2. **Monitor Configuration**
   ```
   - Main Computer Monitor: Job queuing interface and basic status
   - Jobs Computer Monitor: Detailed system dashboard and turtle management
   - Both monitors should be 3x3 (9 monitors total each)
   - Connect monitors to computers using network cables
   ```

3. **Configure Networks**
   - **Wireless Network**: All computers and turtles for rednet communication
   - **Wired Network**: Jobs Computer, ME Bridge, and turtles for item transfers
   - **Monitor Network**: Each computer connected to its respective 3x3 monitor
   - Set unique computer IDs for Main Computer, Jobs Computer, and each turtle
   - Configure ME Bridge connection to Jobs Computer via wired network

## Configuration

### Auto-Detection System

**On first startup, each computer will auto-detect its peripherals:**

#### Main Computer Startup:
```
╔══════════════════════════════════════════════════════════════╗
║                PERIPHERAL AUTO-DETECTION                    ║
╠══════════════════════════════════════════════════════════════╣
║ Scanning for peripherals...                                 ║
║                                                              ║
║ Found peripherals:                                           ║
║ 1. monitor_0 (right side) - 3x3 Monitor                     ║
║ 2. modem_1 (top side) - Wireless Modem                      ║
║                                                              ║
║ Configuration:                                               ║
║ • Monitor: monitor_0 ✓                                       ║
║ • Wireless Modem: modem_1 ✓                                  ║
║                                                              ║
║ Is this configuration correct? [Y/N]                        ║
╚══════════════════════════════════════════════════════════════╝
```

#### Jobs Computer Startup:
```
╔══════════════════════════════════════════════════════════════╗
║                PERIPHERAL AUTO-DETECTION                    ║
╠══════════════════════════════════════════════════════════════╣
║ Scanning for peripherals...                                 ║
║                                                              ║
║ Found peripherals:                                           ║
║ 1. monitor_0 (top side) - 3x3 Monitor                       ║
║ 2. modem_1 (left side) - Wireless Modem                     ║
║ 3. modem_2 (back side) - Wired Modem                        ║
║ 4. meBridge_0 (right side) - ME Bridge                      ║
║                                                              ║
║ Configuration:                                               ║
║ • Monitor: monitor_0 ✓                                       ║
║ • Wireless Modem: modem_1 ✓                                  ║
║ • Wired Modem: modem_2 ✓                                     ║
║ • ME Bridge: meBridge_0 ✓                                    ║
║                                                              ║
║ Is this configuration correct? [Y/N]                        ║
║ Save configuration to config.lua? [Y/N]                     ║
╚══════════════════════════════════════════════════════════════╝
```

#### Turtle Startup:
```
╔══════════════════════════════════════════════════════════════╗
║                PERIPHERAL AUTO-DETECTION                    ║
╠══════════════════════════════════════════════════════════════╣
║ Turtle Type: Crafty Turtle ✓                                ║
║                                                              ║
║ Found peripherals:                                           ║
║ 1. modem_0 (right side) - Wireless Modem                    ║
║ 2. modem_1 (left side) - Wired Modem                        ║
║                                                              ║
║ Configuration:                                               ║
║ • Wireless Modem: modem_0 ✓                                  ║
║ • Wired Modem: modem_1 ✓                                     ║
║ • Crafting: Built-in ✓                                       ║
║                                                              ║
║ Is this configuration correct? [Y/N]                        ║
║ Set turtle ID (1-10): [____]                                ║
╚══════════════════════════════════════════════════════════════╝
```

### Auto-Detection Features

**Peripheral Scanning:**
```lua
-- Example detection logic (theoretical)
function detectPeripherals()
    local peripherals = peripheral.getNames()
    local detected = {
        monitors = {},
        modems = {},
        me_bridges = {},
        other = {}
    }
    
    for _, name in pairs(peripherals) do
        local type = peripheral.getType(name)
        if type == "monitor" then
            -- Check if it's 3x3 by testing dimensions
            local monitor = peripheral.wrap(name)
            local w, h = monitor.getSize()
            if w >= 80 and h >= 20 then -- Approximate 3x3 size
                table.insert(detected.monitors, name)
            end
        elseif type == "modem" then
            local modem = peripheral.wrap(name)
            if modem.isWireless() then
                table.insert(detected.modems, {name = name, type = "wireless"})
            else
                table.insert(detected.modems, {name = name, type = "wired"})
            end
        elseif type == "meBridge" then
            table.insert(detected.me_bridges, name)
        end
    end
    
    return detected
end
```

**Configuration Generation:**
- Saves detected peripheral names to `config.lua`
- Creates backup of template as `config_template.lua`  
- Prompts user to confirm each peripheral assignment
- Allows manual override if detection is wrong

### Main Config File: `config_template.lua`

```lua
-- config_template.lua (template - actual config auto-generated)
CONFIG = {
    -- Network Settings
    MAIN_COMPUTER_ID = 1,       -- GUI Computer ID
    JOBS_COMPUTER_ID = 2,       -- Jobs Manager ID
    REDNET_PROTOCOL = "crafting_system",
    
    -- Auto-detected Peripherals (will be populated on startup)
    MONITOR_NAME = nil,             -- Auto-detected 3x3 monitor
    ME_BRIDGE_NAME = nil,           -- Auto-detected ME Bridge
    WIRED_MODEM_NAME = nil,         -- Auto-detected wired modem
    WIRELESS_MODEM_NAME = nil,      -- Auto-detected wireless modem
    
    -- System Settings
    UPDATE_INTERVAL = 5,        -- seconds
    MAX_RETRIES = 3,
    LOG_LEVEL = "INFO",         -- DEBUG, INFO, WARN, ERROR
    
    -- Job Management
    DEFAULT_PRIORITY = 10,
    DEFAULT_MIN_STOCK = 0,
    DEPENDENCY_RECURSION_LIMIT = 5,  -- Max recipe dependency depth
    RESERVED_PRIORITY_TURTLES = 1,   -- Turtles reserved for high-priority jobs
    
    -- System Limits
    MAX_TURTLES = 10,
    MAX_QUEUE_SIZE = 50,
    JOB_TIMEOUT = 300,          -- 5 minutes
    HEARTBEAT_INTERVAL = 30,    -- seconds
}
```

### Recipe Configuration: `recipes.lua`

```lua
-- recipes.lua
RECIPES = {
    -- Basic Recipe Format
    ["minecraft:stick"] = {
        pattern = {
            "minecraft:planks",
            "minecraft:planks"
        },
        output_count = 4,
        priority = 15,
        min_stock = 64
    },
    
    -- Shaped Recipe (3x3 grid)
    ["minecraft:chest"] = {
        pattern = {
            {"minecraft:planks", "minecraft:planks", "minecraft:planks"},
            {"minecraft:planks", "",                 "minecraft:planks"},
            {"minecraft:planks", "minecraft:planks", "minecraft:planks"}
        },
        output_count = 1,
        priority = 20,
        min_stock = 8
    },
    
    -- Alternative recipes
    ["minecraft:planks"] = {
        alternatives = {
            {
                pattern = {"minecraft:oak_log"},
                output_count = 4
            },
            {
                pattern = {"minecraft:birch_log"},
                output_count = 4
            }
        },
        priority = 25,
        min_stock = 128
    }
}
```

### Item Priority Configuration: `priorities.lua`

```lua
-- priorities.lua
ITEM_PRIORITIES = {
    -- Critical items (crafted first)
    ["minecraft:diamond_pickaxe"] = 100,
    ["minecraft:ender_chest"] = 95,
    
    -- High priority
    ["minecraft:chest"] = 80,
    ["minecraft:crafting_table"] = 75,
    
    -- Medium priority
    ["minecraft:stick"] = 50,
    ["minecraft:planks"] = 45,
    
    -- Low priority
    ["minecraft:torch"] = 20,
    ["minecraft:ladder"] = 15
}
```

## File Structure

**For Install Script Reference** - All files must fit within 1MB total per computer:

```
crafting_system/
├── README.md             # Documentation (this file)
├── main_computer.lua     # Main Computer GUI program (~25KB)
├── jobs_computer.lua     # Jobs Computer manager program (~30KB)
├── turtle.lua           # Turtle client program (~15KB)
├── config_template.lua   # Configuration template (~8KB)
├── config.lua           # Auto-generated configuration (created on startup)
├── recipes.lua          # Recipe definitions (~20KB)
├── priorities.lua       # Item priorities (~5KB)
├── lib/
│   ├── network.lua      # Rednet communication (~10KB)
│   ├── me_interface.lua # ME Bridge interface (~15KB)
│   ├── crafting.lua     # Crafting logic (~18KB)
│   ├── gui.lua          # Simple computer GUI components (~20KB)
│   ├── monitor_gui.lua  # 3x3 monitor display components (~25KB)
│   ├── job_manager.lua  # Job queue management (~25KB)
│   ├── dependency.lua   # Recipe dependency resolver (~12KB)
│   ├── logger.lua       # Logging system (~8KB)
│   └── utils.lua        # Utility functions (~10KB)
├── data/                # Runtime data (created automatically)
│   ├── turtle_registry.json
│   ├── crafting_queue.json
│   └── job_history.json
└── logs/                # System logs (auto-managed, size-limited)
    └── system.log
```

**Installation Distribution:**
- **Main Computer**: main_computer.lua, config_template.lua, lib/gui.lua, lib/monitor_gui.lua, lib/network.lua, lib/logger.lua, lib/utils.lua
- **Jobs Computer**: jobs_computer.lua, config_template.lua, recipes.lua, priorities.lua, lib/* (all libraries)
- **Each Turtle**: turtle.lua, config_template.lua, lib/network.lua, lib/crafting.lua, lib/logger.lua, lib/utils.lua

**Note**: `config.lua` is auto-generated on first startup after peripheral detection

**Estimated Sizes:**
- **Main Computer**: ~95KB (Simple GUI + Monitor + Auto-detection)
- **Jobs Computer**: ~150KB (Full system + Operations monitor + Auto-detection)
- **Each Turtle**: ~60KB (crafting-focused + Auto-detection)
- **Total Project Limit**: <1MB per computer

## Usage

### Starting the System

1. **Start Jobs Computer (First)**
   ```lua
   lua jobs_computer.lua
   ```
   - Will auto-detect peripherals on first run
   - Confirm detected ME Bridge, monitors, and modems
   - Save configuration when prompted

2. **Start Main Computer (Second)**
   ```lua
   lua main_computer.lua
   ```
   - Will auto-detect monitor and wireless modem
   - Confirm peripheral assignments
   - Will attempt to connect to Jobs Computer

3. **Start Turtles (Any Order)**
   ```lua
   -- On each turtle
   lua turtle.lua
   ```
   - Auto-detects wireless/wired modems and crafting capability
   - Prompts for unique turtle ID (1-10)
   - Auto-registers with Jobs Computer when started

4. **Interface Usage**
   - **Main Computer**: Use computer screen for job queuing, monitor shows overview
   - **Jobs Computer**: Monitor displays detailed operations dashboard
   - Search and queue crafting jobs from Main Computer interface
   - Monitor both displays for system status and progress

### First-Time Setup Process

**Expected startup sequence:**
1. Jobs Computer detects ME Bridge and creates network foundation
2. Main Computer connects to Jobs Computer and confirms communication
3. Each turtle registers automatically with Jobs Computer
4. System displays turtle count and confirms all connections
5. Ready to accept crafting jobs!

### GUI Interfaces

#### Main Computer - Computer Screen (Simple Job Queuing)
```
╔══════════════════════════════════════════════════════════════╗
║                    CRAFT JOB QUEUING                        ║
╠══════════════════════════════════════════════════════════════╣
║ Search Recipe: [minecraft:chest____________] [SEARCH]       ║
║                                                              ║
║ Found Recipes:                                               ║
║ > minecraft:chest          (8 planks)                       ║
║   minecraft:ender_chest    (8 obsidian + eye)               ║
║   minecraft:trapped_chest  (chest + tripwire)               ║
║                                                              ║
║ Selected: minecraft:chest                                    ║
║ Quantity: [16___] Priority: [20___] [QUEUE JOB]            ║
║                                                              ║
║ Jobs Computer Status: [ONLINE]  Queue: 5 jobs              ║
║ [VIEW MONITOR] [REFRESH] [EXIT]                             ║
╚══════════════════════════════════════════════════════════════╝
```

#### Main Computer - 3x3 Monitor (Simple Job Overview)
```
╔═════════════════════════════════════════════════════════════════════════════════════╗
║                           CRAFTING SYSTEM STATUS                                   ║
╠═════════════════════════════════════════════════════════════════════════════════════╣
║ System: ONLINE    Turtles: 4/6    Queue: 8 jobs    Jobs Computer: CONNECTED       ║
╠═════════════════════════════════════════════════════════════════════════════════════╣
║                                                                                     ║
║ ACTIVE JOBS:                         TURTLE STATUS:                                ║
║ • 64x Chest - Turtle #2 (75%)       • Turtle #1: CRAFTING                         ║
║ • 32x Iron Pickaxe - Turtle #4       • Turtle #2: CRAFTING                         ║
║ • 128x Planks - Turtle #1            • Turtle #3: IDLE                             ║
║                                      • Turtle #4: CRAFTING                         ║
║ WAITING JOBS:                        • Turtle #5: IDLE                             ║
║ • 128x Iron Ingots (Missing items)   • Turtle #6: OFFLINE                          ║
║ • 64x Torch (Queued)                                                               ║
║ • 32x Ladder (Queued)                RECENT ALERTS:                                ║
║ • 8x Ender Chest (HIGH PRIORITY)     • Low stock: Iron Ingots                      ║
║                                      • Turtle #6 offline 12min                     ║
║ COMPLETED TODAY: 247 jobs            • Auto-crafting: Planks                       ║
║                                                                                     ║
╚═════════════════════════════════════════════════════════════════════════════════════╝
```

#### Jobs Computer - 3x3 Monitor (Operations Dashboard)
```
╔═════════════════════════════════════════════════════════════════════════════════════╗
║                        JOBS COMPUTER - OPERATIONS                                  ║
╠═════════════════════════════════════════════════════════════════════════════════════╣
║ ME Bridge: CONNECTED    Jobs Processing: 1.2/min    Uptime: 2h 34m                ║
╠═════════════════════════════════════════════════════════════════════════════════════╣
║                                                                                     ║
║ JOB QUEUE:                           DEPENDENCIES:                  SYSTEM LOGS:   ║
║ 1. 128x Iron Ingots (P:50) WAITING   • 64x Chest needs 512x Planks [15:23:45] Job complete: 64x Planks ║
║ 2. 64x Torch (P:15) READY            • Auto-crafting Planks from Wood [15:23:42] Low stock: Iron Ingots ║
║ 3. 32x Ladder (P:10) READY           • ETA: 12 minutes              [15:23:38] Dependency: Planks      ║
║ 4. 8x Ender Chest (P:95) HIGH        • Missing: Iron Ingots for     [15:23:35] Queued: 8x Ender Chest ║
║                                         Pickaxe job                 [15:23:31] Error: Turtle #6       ║
║                                                                     [15:23:28] Auto-craft: Planks     ║
║ TURTLE ASSIGNMENTS:                   ME SYSTEM:                                                        ║
║ • Turtle #1: 128x Planks (ETA: 45s)   • Storage: 15.2TB / 64TB                                        ║
║ • Turtle #2: 64x Chest (ETA: 2m)      • Available Items: 1,247                                        ║
║ • Turtle #3: IDLE                     • Missing Resources: 3                                           ║
║ • Turtle #4: Iron Pickaxe (WAITING)   • Last Transfer: Wood → T#3                                     ║
║ • Turtle #5: IDLE (Reserved)                                                                           ║
║ • Turtle #6: OFFLINE (12min)          Load Balance: Round Robin                                        ║
║                                       Next Assignment: Turtle #1                                       ║
║                                                                                                         ║
╚═════════════════════════════════════════════════════════════════════════════════════╝
```

#### Menu Options (Main Computer)
**Computer Interface:**
- `[SEARCH]` - Search for recipes by name/item
- `[QUEUE JOB]` - Queue selected recipe with quantity/priority
- `[VIEW MONITOR]` - Switch focus to monitor view
- `[REFRESH]` - Refresh recipe search and status
- `[EXIT]` - Exit application

**Monitor Interface:**
- Live updating job status overview
- Real-time turtle status and progress bars
- Recent completed jobs history
- Resource alerts and stock warnings
- System metrics and performance data

#### Menu Options (Jobs Computer)
**Monitor Interface Only:**
- Live operations dashboard
- Job queue management display
- Dependency resolution tracking
- ME system integration status
- Turtle coordination and load balancing
- System logs and performance metrics
- All displays auto-refresh every 5 seconds

### Command Examples

#### Manual Crafting Commands
```lua
-- Queue a crafting job
craft("minecraft:stick", 64)

-- Set item priority
setPriority("minecraft:diamond_pickaxe", 100)

-- Update minimum stock
setMinStock("minecraft:chest", 16)

-- Check item availability
getStock("minecraft:planks")
```

## API Reference

**⚠️ THEORETICAL CODE - NOT TESTED**

### Main Computer API (GUI/Control)

#### Core Functions
```lua
-- System Management
startGUI()
startMonitorGUI()
stopGUI()
refreshDisplay()
refreshMonitor()

-- User Interaction (Computer GUI)
searchRecipes(search_term)
selectRecipe(recipe_name)
queueCraftRequest(item_name, quantity, priority?)
cancelCraftRequest(job_id)

-- Monitor Display
updateJobOverview()
updateSystemStatus()
updateTurtleStatus()

-- Jobs Computer Communication
sendJobsCommand(command, data)
getJobsStatus()
getCraftingQueue()
```

### Jobs Computer API (Job Management)

#### Core Functions
```lua
-- System Management
startJobManager()
startMonitorDashboard()
stopJobManager()
reloadConfig()

-- Crafting Management
queueCraft(item_name, quantity, priority?)
resolveDependencies(recipe)
cancelCraft(job_id)
getCraftingQueue()
processJobQueue()

-- Turtle Management
registerTurtle(turtle_id)
getTurtleStatus(turtle_id)
assignJob(turtle_id, job)
distributePriorityJobs()
balanceLoad()

-- Monitor Dashboard
updateOperationsDashboard()
updateJobQueueDisplay()
updateDependencyResolver()
updateMESystemStatus()
updateTurtleCoordination()
updateSystemLogs()

-- ME Integration
getItemCount(item_name)
requestItems(item_name, quantity)
insertItems(item_name, quantity)
checkStockLevels()
```

#### Network Protocol
```lua
-- Message Types (via wireless rednet)
MESSAGE_TYPES = {
    -- Turtle ↔ Jobs Computer
    REGISTER = "register",
    HEARTBEAT = "heartbeat", 
    JOB_ASSIGN = "job_assign",
    JOB_COMPLETE = "job_complete",
    JOB_FAILED = "job_failed",
    STATUS_UPDATE = "status_update",
    
    -- Main Computer ↔ Jobs Computer
    CRAFT_REQUEST = "craft_request",
    QUEUE_STATUS = "queue_status",
    SYSTEM_STATUS = "system_status",
    
    -- General
    SHUTDOWN = "shutdown"
}

-- Item Transfer Protocol (via wired modems - Jobs Computer only)
ITEM_OPERATIONS = {
    REQUEST_ITEMS = "request_items",
    DEPOSIT_ITEMS = "deposit_items",
    CHECK_STOCK = "check_stock"
}
```

### Turtle Client API

#### Core Functions
```lua
-- System Functions (wireless)
connectToController()
sendHeartbeat()
reportStatus(status)

-- Crafting Functions
executeCraft(recipe, quantity)
checkResources(recipe)

-- Item Management (wired modems + ME Bridge)
requestItemsFromME(item_name, quantity)
depositItemsToME(item_name, quantity)
getInventorySpace()
```

## Advanced Configuration

### Load Balancing

```lua
-- In config.lua
LOAD_BALANCING = {
    algorithm = "round_robin",  -- round_robin, least_loaded, priority
    consider_distance = true,   -- Factor in turtle distance
    max_queue_per_turtle = 5,   -- Max jobs per turtle
}
```

### Resource Management

```lua
-- Advanced resource settings
RESOURCE_MANAGEMENT = {
    auto_request_missing = true,    -- Auto-request from ME
    reserve_buffer = 0.1,          -- 10% buffer for critical items
    batch_size = 64,               -- Optimal batch size
    max_wait_time = 300,           -- Max wait for resources (seconds)
}
```

### Error Handling

```lua
-- Error handling configuration
ERROR_HANDLING = {
    auto_retry = true,
    max_retries = 3,
    retry_delay = 30,              -- seconds
    fallback_recipes = true,       -- Use alternative recipes
    turtle_recovery = true,        -- Auto-recover stuck turtles
}
```

## Troubleshooting

### Common Issues

#### Connection Problems
```bash
Problem: Turtles not connecting to Jobs Computer
Solution: 
1. Check wireless modems are enabled on turtles and Jobs Computer
2. Verify rednet protocol matches in config
3. Ensure computers are within wireless range
4. Check for ID conflicts
5. Start Jobs Computer before turtles

Problem: Main Computer not connecting to Jobs Computer
Solution:
1. Verify both computers have correct IDs in config
2. Check wireless modem connectivity
3. Ensure Jobs Computer is running and responsive
4. Check rednet protocol matches

Problem: Monitor not displaying correctly
Solution:
1. Check monitor is properly assembled (3x3 setup)
2. Verify network cable connects computer to monitor
3. Check MONITOR_SIDE configuration in config.lua
4. Test monitor connection with `peripheral.getNames()`
5. Ensure monitor has sufficient power
6. Try restarting the computer program

Problem: Items not transferring from ME system
Solution:
1. Verify wired modem network connects Jobs Computer to ME Bridge
2. Check ME Bridge is powered and connected
3. Ensure all wired modems are on same network
4. Test wired modem connectivity with peripheral.getNames()
5. Check Jobs Computer has both wired and wireless modems
```

#### Crafting Failures
```bash
Problem: Items not being crafted
Solution:
1. Verify recipe configuration
2. Check resource availability in ME system
3. Ensure crafting tables are placed correctly
4. Review turtle inventory space
```

#### Performance Issues
```bash
Problem: System running slowly
Solution:
1. Reduce UPDATE_INTERVAL in config
2. Limit MAX_CONCURRENT_JOBS
3. Optimize recipe patterns
4. Check for network congestion
```

### Debug Mode

Enable debug logging for detailed troubleshooting:
```lua
-- In config.lua
LOG_LEVEL = "DEBUG"
DEBUG_MODE = {
    network_traffic = true,
    crafting_steps = true,
    resource_tracking = true,
    performance_metrics = true
}
```

### Log Analysis

System logs include:
- Network communication
- Crafting operations
- Error conditions
- Performance metrics
- Resource usage

## Performance Optimization

### Size Optimization (Critical - 1MB Limit)

#### Code Minimization
```lua
-- Use short variable names in production
local t = turtle        -- instead of turtle
local r = rednet        -- instead of rednet
local p = peripheral    -- instead of peripheral

-- Remove debug code and comments from production builds
-- Compress JSON data where possible
-- Use efficient data structures
```

#### Memory Management
```lua
-- Clear unused variables
collectgarbage("collect")

-- Limit log file sizes with circular buffers
-- Compress stored data
-- Remove old queue entries automatically
```

#### Recommended Settings

#### Small Networks (1-3 turtles)
```lua
UPDATE_INTERVAL = 2
MAX_CONCURRENT_JOBS = 2
BATCH_SIZE = 32
```

#### Medium Networks (4-8 turtles)
```lua
UPDATE_INTERVAL = 5
MAX_CONCURRENT_JOBS = 3
BATCH_SIZE = 64
```

#### Large Networks (9+ turtles)
```lua
UPDATE_INTERVAL = 10
MAX_CONCURRENT_JOBS = 5
BATCH_SIZE = 128
```

## Contributing

### Development Setup
1. Fork the repository
2. Create feature branch
3. Follow Lua coding standards
4. Add comprehensive comments
5. Test with multiple turtle configurations

### Code Style
- Use clear, descriptive variable names
- Comment complex logic
- Follow consistent indentation (4 spaces)
- Use modular design patterns

### Testing Checklist
- [ ] Single turtle operation
- [ ] Multi-turtle coordination
- [ ] Network failure recovery
- [ ] Recipe validation
- [ ] ME Bridge integration
- [ ] GUI responsiveness

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- ComputerCraft: Tweaked team for the amazing mod
- Advanced Peripherals for ME Bridge functionality
- Applied Energistics 2 team for the storage system
- CC:Tweaked community for inspiration and support

## Version History

### v1.0.0 (In Development)
- Initial release
- Basic multi-turtle crafting
- ME Bridge integration
- Priority system
- GUI interface

**Note: All code and functionality described is theoretical and untested.**