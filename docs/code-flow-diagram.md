# Code Flow Diagram - CC:Tweaked Distributed Crafting System

## System Architecture Overview

The distributed crafting system consists of three main components communicating through different channels:
- **Wireless (Rednet)**: Control messages and status updates
- **Wired Modems**: Item transfers between ME system and turtles
- **Monitors**: Visual feedback to users

---

## Component Structure

```
┌─────────────────────────────────────────────────────────────────────┐
│                          MAIN COMPUTER                              │
│                    (User Interface & Control)                       │
├─────────────────────────────────────────────────────────────────────┤
│ main_computer.lua                                                   │
│   ├── lib/network.lua (rednet communication)                       │
│   ├── lib/gui.lua (computer screen interface)                      │
│   ├── lib/monitor_gui.lua (3x3 monitor display)                    │
│   ├── lib/logger.lua (logging)                                     │
│   └── lib/utils.lua (utilities)                                    │
│                                                                     │
│ Key Functions:                                                      │
│   • detectPeripherals() - Auto-detect monitor and modem            │
│   • connectToJobsComputer() - Establish rednet connection          │
│   • searchRecipes(term) - Query available recipes                  │
│   • queueCraftRequest(item, qty, priority) - Submit job            │
│   • updateMonitorDisplay() - Refresh 3x3 monitor                   │
│   • handleUserInput() - Process GUI events                         │
│   • getSystemStatus() - Poll Jobs Computer for updates             │
└─────────────────────────┬───────────────────────────────────────────┘
                         │
                         │ Rednet Protocol (Wireless)
                         │ Messages: CRAFT_REQUEST, QUEUE_STATUS
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          JOBS COMPUTER                              │
│                  (Central Operations Manager)                       │
├─────────────────────────────────────────────────────────────────────┤
│ jobs_computer.lua                                                   │
│   ├── lib/network.lua (rednet + wired communication)               │
│   ├── lib/me_interface.lua (ME Bridge operations)                  │
│   ├── lib/job_manager.lua (queue management)                       │
│   ├── lib/dependency.lua (recipe resolution)                       │
│   ├── lib/monitor_gui.lua (operations dashboard)                   │
│   ├── lib/logger.lua (logging)                                     │
│   ├── lib/utils.lua (utilities)                                    │
│   ├── recipes.lua (recipe definitions)                             │
│   └── priorities.lua (item priorities)                             │
│                                                                     │
│ Key Functions:                                                      │
│   • detectPeripherals() - Find ME Bridge, modems, monitor          │
│   • initializeMEBridge() - Connect to AE2 system                   │
│   • processJobQueue() - Main job processing loop                   │
│   • resolveDependencies(recipe) - Calculate required items         │
│   • assignJobToTurtle(job) - Distribute work                       │
│   • requestItemsFromME(items) - Get items from storage             │
│   • handleTurtleMessages() - Process turtle communications         │
│   • updateOperationsDashboard() - Refresh monitor display          │
└────────────┬──────────────────────────┬─────────────────────────────┘
            │                          │
            │ Rednet (Wireless)        │ Wired Network
            │ Job Control              │ Item Transfers
            │                          │
            ▼                          ▼
┌─────────────────────────┐    ┌─────────────────────┐
│    TURTLE NETWORK       │    │     ME BRIDGE       │
├─────────────────────────┤    ├─────────────────────┤
│ Multiple Crafty Turtles │    │ Advanced Peripherals│
│ Running turtle.lua      │    │ ME System Interface │
└─────────────────────────┘    └─────────────────────┘
```

---

## Detailed Module Interactions

### 1. Network Communication (`lib/network.lua`)

**Shared by all computers:**
```lua
-- Protocol definition
PROTOCOL = "crafting_system"

-- Message types
MESSAGE_TYPES = {
    -- Registration
    REGISTER = "register",
    REGISTER_ACK = "register_ack",
    
    -- Heartbeat
    HEARTBEAT = "heartbeat",
    HEARTBEAT_ACK = "heartbeat_ack",
    
    -- Job Management
    CRAFT_REQUEST = "craft_request",
    JOB_ASSIGN = "job_assign",
    JOB_ACCEPT = "job_accept",
    JOB_COMPLETE = "job_complete",
    JOB_FAILED = "job_failed",
    
    -- Status
    STATUS_UPDATE = "status_update",
    QUEUE_STATUS = "queue_status",
    SYSTEM_STATUS = "system_status",
    
    -- Control
    SHUTDOWN = "shutdown"
}

-- Functions
sendMessage(recipient, messageType, data)
broadcast(messageType, data)
listen() -- Returns sender, message
registerProtocol()
```

### 2. ME Interface (`lib/me_interface.lua`)

**Jobs Computer only:**
```lua
-- ME Bridge wrapper
MEInterface = {
    bridge = nil,
    connected = false
}

-- Functions
MEInterface:connect(bridgeName)
MEInterface:listItems()
MEInterface:getItem(itemName)
MEInterface:exportItem(itemName, count, direction)
MEInterface:importItem(direction)
MEInterface:getCraftables()
MEInterface:requestCrafting(itemName, count)
MEInterface:getEnergyStorage()
```

### 3. Job Management (`lib/job_manager.lua`)

**Jobs Computer only:**
```lua
-- Job structure
Job = {
    id = number,
    item = string,
    quantity = number,
    priority = number,
    status = "pending|assigned|crafting|complete|failed",
    assignedTurtle = number|nil,
    dependencies = table,
    createdAt = number,
    startedAt = number|nil,
    completedAt = number|nil
}

-- Queue management
JobQueue = {
    pending = {},    -- Priority queue
    active = {},     -- Currently processing
    completed = {},  -- History (limited)
}

-- Functions
JobQueue:add(item, quantity, priority)
JobQueue:getNext()
JobQueue:updateStatus(jobId, status)
JobQueue:reassign(jobId)
JobQueue:save()
JobQueue:load()
```

### 4. Crafting Logic (`lib/crafting.lua`)

**Turtle only:**
```lua
-- Crafting functions
CraftingSystem = {}

-- Functions
CraftingSystem:arrangeMaterials(pattern)
CraftingSystem:executeCraft()
CraftingSystem:checkInventory(required)
CraftingSystem:requestMaterials(items)
CraftingSystem:depositResults()
CraftingSystem:clearInventory()
```

### 5. GUI Components (`lib/gui.lua`)

**Main Computer only:**
```lua
-- GUI framework
GUI = {
    elements = {},
    focused = nil
}

-- UI Elements
Button = {x, y, width, height, text, onClick}
TextBox = {x, y, width, value, onChange}
List = {x, y, width, height, items, selected}
Label = {x, y, text, color}

-- Functions
GUI:draw()
GUI:handleClick(x, y)
GUI:handleKey(key)
GUI:addElement(element)
GUI:setFocus(element)
```

---

## Communication Flow Examples

### 1. Turtle Registration Flow
```
Turtle                    Jobs Computer              Main Computer
  │                            │                           │
  ├──REGISTER──────────────────>                          │
  │  {id, type, modems}        │                          │
  │                            │                          │
  <──REGISTER_ACK──────────────┤                          │
  │  {success, config}         │                          │
  │                            │                          │
  │                            ├──STATUS_UPDATE──────────>│
  │                            │  {turtles: +1}           │
  │                            │                          │
  └────────HEARTBEAT loop──────>                          │
```

### 2. Job Queue Flow
```
Main Computer            Jobs Computer              Turtle
     │                        │                        │
     ├──CRAFT_REQUEST───────>│                        │
     │  {item, qty, priority} │                        │
     │                        │                        │
     │                        ├─resolveDependencies()  │
     │                        ├─checkMEStock()         │
     │                        ├─createJob()            │
     │                        │                        │
     <──QUEUE_STATUS──────────┤                        │
     │  {jobId, position}     │                        │
     │                        │                        │
     │                        ├──JOB_ASSIGN──────────>│
     │                        │  {job details}         │
     │                        │                        │
     │                        <──JOB_ACCEPT───────────┤
     │                        │                        │
     │                        ├─transferItems()───────>│
     │                        │  (via wired network)   │
     │                        │                        │
     <──STATUS_UPDATE─────────┤                        ├─craft()
     │  {job: crafting}       │                        │
     │                        │                        │
     │                        <──JOB_COMPLETE─────────┤
     │                        │  {jobId, output}       │
     │                        │                        │
     │                        ├─retrieveItems()<───────┤
     │                        │                        │
     <──STATUS_UPDATE─────────┤                        │
     │  {job: complete}       │                        │
```

### 3. Error Recovery Flow
```
Jobs Computer              Failed Turtle           New Turtle
     │                           │                      │
     ├──HEARTBEAT────────────────X (timeout)           │
     │                           │                      │
     ├─detectFailure()           │                      │
     ├─markTurtleOffline()       │                      │
     ├─retrieveJob()             │                      │
     │                           │                      │
     ├──JOB_ASSIGN─────────────────────────────────────>│
     │  {reassigned job}         │                      │
     │                           │                      │
     <──JOB_ACCEPT─────────────────────────────────────┤
     │                           │                      │
     └─continueProcessing()      │                      │
```

---

## Data Flow

### Recipe Resolution
```
recipes.lua ──> JobManager ──> DependencyResolver ──> MEInterface
                    │               │                      │
                    │               ├─checkStock()────────>│
                    │               │                      │
                    │               <─missingItems─────────┤
                    │               │                      │
                    │               ├─recursiveResolve()   │
                    │               │                      │
                    <───────────────┤                      │
                    dependencies    │                      │
```

### Monitor Updates
```
System State ──> Monitor GUI ──> Display Buffer ──> Physical Monitor
     │               │                 │                    │
     ├─jobs          ├─format()        ├─optimize()        │
     ├─turtles       ├─layout()        ├─colors()          │
     ├─alerts        ├─tables()        └─write()──────────>│
     └─metrics       └─charts()                            │
```

---

## File Dependencies

### Main Computer Files
```
main_computer.lua
├── config.lua (auto-generated)
├── lib/network.lua
├── lib/gui.lua
├── lib/monitor_gui.lua
├── lib/logger.lua
└── lib/utils.lua
```

### Jobs Computer Files
```
jobs_computer.lua
├── config.lua (auto-generated)
├── recipes.lua
├── priorities.lua
├── lib/network.lua
├── lib/me_interface.lua
├── lib/job_manager.lua
├── lib/dependency.lua
├── lib/monitor_gui.lua
├── lib/logger.lua
└── lib/utils.lua
```

### Turtle Files
```
turtle.lua
├── config.lua (auto-generated)
├── lib/network.lua
├── lib/crafting.lua
├── lib/logger.lua
└── lib/utils.lua
```

---

## Key Design Decisions

1. **Separation of Concerns**
   - Main Computer: User interface only
   - Jobs Computer: All business logic
   - Turtles: Crafting execution only

2. **Network Architecture**
   - Wireless for control (flexibility)
   - Wired for items (reliability)
   - Separate protocols prevent interference

3. **Fault Tolerance**
   - Every component can reconnect
   - Jobs persist through restarts
   - Automatic failover for turtles

4. **Scalability**
   - Modular design allows easy expansion
   - Load balancing prevents bottlenecks
   - Queue system handles bursts

5. **User Experience**
   - Auto-detection reduces setup complexity
   - Visual feedback on large monitors
   - Clear error messages and recovery