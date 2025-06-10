# User Flow Diagram - CC:Tweaked Distributed Crafting System

## Overview
This document details the step-by-step user interactions from initial setup through daily operation of the distributed crafting system.

---

## System Startup Flow

### Phase 1: Jobs Computer Initialization (Start First)

```
USER STARTS JOBS COMPUTER
│
├─> Run: lua jobs_computer.lua
│
├─> PERIPHERAL AUTO-DETECTION
│   ╔══════════════════════════════════════════════════════════════╗
│   ║                PERIPHERAL AUTO-DETECTION                    ║
│   ╠══════════════════════════════════════════════════════════════╣
│   ║ Scanning for peripherals...                                 ║
│   ║                                                              ║
│   ║ Found peripherals:                                           ║
│   ║ 1. monitor_0 (top side) - 3x3 Monitor                       ║
│   ║ 2. modem_1 (left side) - Wireless Modem                     ║
│   ║ 3. modem_2 (back side) - Wired Modem                        ║
│   ║ 4. meBridge_0 (right side) - ME Bridge                      ║
│   ║                                                              ║
│   ║ Configuration:                                               ║
│   ║ • Monitor: monitor_0 ✓                                       ║
│   ║ • Wireless Modem: modem_1 ✓                                  ║
│   ║ • Wired Modem: modem_2 ✓                                     ║
│   ║ • ME Bridge: meBridge_0 ✓                                    ║
│   ║                                                              ║
│   ║ Is this configuration correct? [Y/N] _                      ║
│   ╚══════════════════════════════════════════════════════════════╝
│
├─> User presses 'Y'
│
├─> SAVE CONFIGURATION
│   ╔══════════════════════════════════════════════════════════════╗
│   ║ Save configuration to config.lua? [Y/N] _                   ║
│   ╚══════════════════════════════════════════════════════════════╝
│
├─> User presses 'Y'
│
├─> SYSTEM INITIALIZATION
│   • Loading recipes.lua... ✓
│   • Loading priorities.lua... ✓
│   • Connecting to ME Bridge... ✓
│   • Starting rednet listener... ✓
│   • Initializing job queue... ✓
│
└─> OPERATIONS DASHBOARD APPEARS ON 3x3 MONITOR
    (System ready, waiting for Main Computer and Turtles)
```

### Phase 2: Main Computer Initialization (Start Second)

```
USER STARTS MAIN COMPUTER
│
├─> Run: lua main_computer.lua
│
├─> PERIPHERAL AUTO-DETECTION
│   ╔══════════════════════════════════════════════════════════════╗
│   ║                PERIPHERAL AUTO-DETECTION                    ║
│   ╠══════════════════════════════════════════════════════════════╣
│   ║ Scanning for peripherals...                                 ║
│   ║                                                              ║
│   ║ Found peripherals:                                           ║
│   ║ 1. monitor_0 (right side) - 3x3 Monitor                     ║
│   ║ 2. modem_1 (top side) - Wireless Modem                      ║
│   ║                                                              ║
│   ║ Configuration:                                               ║
│   ║ • Monitor: monitor_0 ✓                                       ║
│   ║ • Wireless Modem: modem_1 ✓                                  ║
│   ║                                                              ║
│   ║ Is this configuration correct? [Y/N] _                      ║
│   ╚══════════════════════════════════════════════════════════════╝
│
├─> User presses 'Y'
│
├─> CONNECTING TO JOBS COMPUTER
│   • Opening rednet protocol... ✓
│   • Searching for Jobs Computer... ✓
│   • Establishing connection... ✓
│   • Verifying communication... ✓
│
├─> GUI INTERFACE LOADS ON COMPUTER SCREEN
│
└─> JOB OVERVIEW APPEARS ON 3x3 MONITOR
```

### Phase 3: Turtle Initialization (Start Any Time)

```
USER STARTS EACH TURTLE
│
├─> Run: lua turtle.lua
│
├─> TURTLE TYPE DETECTION
│   ╔══════════════════════════════════════════════════════════════╗
│   ║                PERIPHERAL AUTO-DETECTION                    ║
│   ╠══════════════════════════════════════════════════════════════╣
│   ║ Turtle Type: Crafty Turtle ✓                                ║
│   ║                                                              ║
│   ║ Found peripherals:                                           ║
│   ║ 1. modem_0 (right side) - Wireless Modem                    ║
│   ║ 2. modem_1 (left side) - Wired Modem                        ║
│   ║                                                              ║
│   ║ Configuration:                                               ║
│   ║ • Wireless Modem: modem_0 ✓                                  ║
│   ║ • Wired Modem: modem_1 ✓                                     ║
│   ║ • Crafting: Built-in ✓                                       ║
│   ║                                                              ║
│   ║ Is this configuration correct? [Y/N] _                      ║
│   ╚══════════════════════════════════════════════════════════════╝
│
├─> User presses 'Y'
│
├─> TURTLE ID SELECTION
│   ╔══════════════════════════════════════════════════════════════╗
│   ║ Set turtle ID (1-10): _                                     ║
│   ╚══════════════════════════════════════════════════════════════╝
│
├─> User enters '1' (or any unique number)
│
├─> REGISTERING WITH JOBS COMPUTER
│   • Opening rednet connection... ✓
│   • Registering with Jobs Computer... ✓
│   • Starting heartbeat... ✓
│   • Ready for job assignments
│
└─> TURTLE ENTERS IDLE STATE
    (Waiting for jobs from Jobs Computer)
```

---

## Crafting Job Flow

### Step 1: Recipe Search (Main Computer)

```
USER AT MAIN COMPUTER
│
├─> Looks at computer screen GUI
│   ╔══════════════════════════════════════════════════════════════╗
│   ║                    CRAFT JOB QUEUING                        ║
│   ╠══════════════════════════════════════════════════════════════╣
│   ║ Search Recipe: [________________] [SEARCH]                  ║
│   ║                                                              ║
│   ║ Found Recipes:                                               ║
│   ║ (Enter search term above)                                    ║
│   ║                                                              ║
│   ║ Jobs Computer Status: [ONLINE]  Queue: 0 jobs              ║
│   ║ [VIEW MONITOR] [REFRESH] [EXIT]                             ║
│   ╚══════════════════════════════════════════════════════════════╝
│
├─> User types "chest" in search box
│
├─> User clicks [SEARCH] or presses Enter
│
└─> SYSTEM SEARCHES RECIPES
    │
    ├─> Main Computer sends query to Jobs Computer
    ├─> Jobs Computer searches recipes.lua
    └─> Returns matching recipes
```

### Step 2: Recipe Selection

```
SEARCH RESULTS APPEAR
│
├─> Updated GUI shows:
│   ╔══════════════════════════════════════════════════════════════╗
│   ║                    CRAFT JOB QUEUING                        ║
│   ╠══════════════════════════════════════════════════════════════╣
│   ║ Search Recipe: [chest______________] [SEARCH]               ║
│   ║                                                              ║
│   ║ Found Recipes:                                               ║
│   ║ > minecraft:chest          (8 planks)          [SELECT]     ║
│   ║   minecraft:ender_chest    (8 obsidian + eye)  [SELECT]     ║
│   ║   minecraft:trapped_chest  (chest + tripwire)  [SELECT]     ║
│   ║                                                              ║
│   ║ Jobs Computer Status: [ONLINE]  Queue: 0 jobs              ║
│   ║ [VIEW MONITOR] [REFRESH] [EXIT]                             ║
│   ╚══════════════════════════════════════════════════════════════╝
│
├─> User clicks [SELECT] next to "minecraft:chest"
│   OR uses arrow keys and Enter
│
└─> RECIPE DETAILS LOAD
```

### Step 3: Job Configuration

```
RECIPE SELECTED
│
├─> GUI updates to show job configuration:
│   ╔══════════════════════════════════════════════════════════════╗
│   ║                    CRAFT JOB QUEUING                        ║
│   ╠══════════════════════════════════════════════════════════════╣
│   ║ Search Recipe: [minecraft:chest____] [SEARCH]               ║
│   ║                                                              ║
│   ║ Selected: minecraft:chest                                    ║
│   ║ Recipe: 8x minecraft:planks → 1x minecraft:chest            ║
│   ║                                                              ║
│   ║ Quantity: [____] Priority: [20___] [QUEUE JOB]             ║
│   ║                                                              ║
│   ║ (Priority: 1-100, higher = more urgent)                     ║
│   ║                                                              ║
│   ║ Jobs Computer Status: [ONLINE]  Queue: 0 jobs              ║
│   ║ [BACK] [VIEW MONITOR] [REFRESH]                             ║
│   ╚══════════════════════════════════════════════════════════════╝
│
├─> User enters quantity: 16
│
├─> User optionally adjusts priority (default 20)
│
└─> User clicks [QUEUE JOB]
```

### Step 4: Job Processing

```
JOB QUEUED
│
├─> MAIN COMPUTER
│   • Sends CRAFT_REQUEST to Jobs Computer
│   • Shows confirmation message
│   • Updates queue counter
│
├─> JOBS COMPUTER (automatic)
│   ├─> Receives craft request
│   ├─> Calculates requirements (16 chests = 128 planks)
│   ├─> Checks ME system stock
│   ├─> If materials missing:
│   │   └─> Queue dependency jobs (e.g., craft planks from logs)
│   ├─> Adds job to queue
│   └─> Assigns to available turtle
│
├─> TURTLE (automatic)
│   ├─> Receives job assignment
│   ├─> Requests materials via wired network
│   ├─> Arranges items in crafting grid
│   ├─> Executes crafting
│   ├─> Deposits results back to ME
│   └─> Reports completion
│
└─> MONITORS UPDATE
    ├─> Main Computer Monitor: Shows job progress
    └─> Jobs Computer Monitor: Shows detailed operations
```

---

## Monitor Views During Operation

### Main Computer Monitor (User's Overview)
```
╔═════════════════════════════════════════════════════════════════════════════════════╗
║                           CRAFTING SYSTEM STATUS                                   ║
╠═════════════════════════════════════════════════════════════════════════════════════╣
║ System: ONLINE    Turtles: 3/3    Queue: 1 job     Jobs Computer: CONNECTED       ║
╠═════════════════════════════════════════════════════════════════════════════════════╣
║                                                                                     ║
║ ACTIVE JOBS:                         TURTLE STATUS:                                ║
║ • 16x Chest - Turtle #1 (25%)       • Turtle #1: CRAFTING █████░░░░░              ║
║                                      • Turtle #2: IDLE                             ║
║                                      • Turtle #3: IDLE                             ║
║                                                                                     ║
║ WAITING JOBS:                        RECENT COMPLETED:                             ║
║ (none)                               • 64x Stick (2 min ago)                       ║
║                                      • 32x Torch (5 min ago)                      ║
║                                                                                     ║
║ SYSTEM ALERTS:                                                                      ║
║ • All systems operational                                                           ║
║                                                                                     ║
╚═════════════════════════════════════════════════════════════════════════════════════╝
```

### Jobs Computer Monitor (Operations Detail)
```
╔═════════════════════════════════════════════════════════════════════════════════════╗
║                        JOBS COMPUTER - OPERATIONS                                  ║
╠═════════════════════════════════════════════════════════════════════════════════════╣
║ ME Bridge: CONNECTED    Jobs/min: 0.5    Uptime: 15m 32s    CPU: 12%             ║
╠═════════════════════════════════════════════════════════════════════════════════════╣
║                                                                                     ║
║ JOB QUEUE:                           DEPENDENCIES:                  SYSTEM LOG:    ║
║ ID  Item           Qty  Pri Status   Resolving: minecraft:chest    [10:15:42] Job assigned T#1   ║
║ #1  Chest          16   20  ACTIVE   • Need 128x planks           [10:15:41] Request: 16x Chest ║
║                                      • Found in ME: 256x          [10:15:40] Turtle #3 registered║
║                                      • Ready to craft             [10:15:38] Turtle #2 registered║
║                                                                   [10:15:35] Turtle #1 registered║
║ TURTLE DETAILS:                      ME SYSTEM:                   [10:15:30] ME Bridge connected║
║ T#1: Crafting Chest (4/16)          Items: 15,234                [10:15:28] System initialized  ║
║      Progress: 25%                   Types: 487                                                   ║
║      ETA: 45 seconds                 Storage: 18.2%                                              ║
║ T#2: IDLE - Ready                    Energy: 125k RF                                             ║
║ T#3: IDLE - Ready                                                                                ║
║                                                                                                   ║
╚═════════════════════════════════════════════════════════════════════════════════════╝
```

---

## Common User Interactions

### Checking Job Status
```
USER WANTS TO CHECK STATUS
│
├─> Option 1: Look at Main Computer Monitor
│   └─> See job overview and turtle status
│
├─> Option 2: Press [REFRESH] on computer GUI
│   └─> Updates all displays immediately
│
└─> Option 3: Check Jobs Computer Monitor
    └─> See detailed operations and logs
```

### Canceling a Job
```
USER WANTS TO CANCEL
│
├─> At Main Computer GUI
├─> Navigate to active/queued jobs list
├─> Select job to cancel
├─> Press [CANCEL JOB]
├─> Confirm cancellation
└─> System returns materials to ME
```

### Handling Errors
```
ERROR OCCURS (e.g., Missing Materials)
│
├─> VISUAL ALERT
│   ├─> Main Monitor: Shows in alerts section
│   └─> Jobs Monitor: Details in system log
│
├─> USER RESPONSE OPTIONS
│   ├─> Add missing materials to ME system
│   ├─> Cancel affected jobs
│   └─> Wait for automatic retry
│
└─> SYSTEM RECOVERY
    └─> Automatically retries when materials available
```

### System Shutdown
```
USER SHUTTING DOWN
│
├─> Recommended Order:
│   1. Stop all turtles (Ctrl+T on each)
│   2. Stop Main Computer (Ctrl+T)
│   3. Stop Jobs Computer last (Ctrl+T)
│
└─> On Next Startup:
    ├─> Configs auto-load
    ├─> Jobs restore from queue
    └─> Turtles re-register automatically
```

---

## Advanced User Scenarios

### Setting Item Priorities
```
USER WANTS HIGH-PRIORITY ITEM
│
├─> When queuing job:
│   └─> Set Priority to 80-100 (high)
│
├─> System behavior:
│   ├─> High-priority jobs queue first
│   ├─> May interrupt lower priority jobs
│   └─> Reserved turtles handle critical items
```

### Bulk Crafting
```
USER NEEDS MANY ITEMS
│
├─> Queue multiple jobs:
│   ├─> Search and queue each type
│   ├─> System handles dependencies
│   └─> Load balances across turtles
│
└─> Monitor shows:
    ├─> Multiple active jobs
    ├─> Queue depth
    └─> Estimated completion times
```

### Minimum Stock Maintenance
```
AUTOMATIC STOCK MANAGEMENT
│
├─> Configured in recipes.lua:
│   └─> min_stock = 64
│
├─> System behavior:
│   ├─> Monitors stock levels
│   ├─> Auto-queues when below minimum
│   └─> Shows as "Auto-craft" in logs
│
└─> User sees:
    └─> Jobs appear automatically
```

---

## Troubleshooting User Issues

### "Can't Find Jobs Computer"
```
1. Check Jobs Computer is running
2. Verify wireless modem enabled (right-click modem)
3. Check computer IDs in config match
4. Restart both computers in correct order
```

### "Turtle Not Responding"
```
1. Check turtle has fuel (turtle.refuel())
2. Verify wireless modem enabled
3. Check wired network connected
4. Restart turtle with unique ID
```

### "Items Not Crafting"
```
1. Check ME system has materials
2. Verify recipe configured correctly
3. Check turtle has crafting table
4. Look for errors in Jobs Computer log
```

### "Monitor Not Updating"
```
1. Verify monitor properly connected
2. Check it's exactly 3x3 configuration
3. Try [REFRESH] button
4. Restart computer program
```