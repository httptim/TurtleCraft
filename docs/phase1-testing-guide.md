# Phase 1 Testing Guide

## Overview
Phase 1 implements the core infrastructure of the CC:Tweaked Distributed Crafting System:
- Peripheral auto-detection
- Network communication
- Logging system
- Computer registration and heartbeat

## Prerequisites

### Hardware Setup
1. **Jobs Computer** (ID should be 2)
   - 3x3 Monitor connected
   - Wireless Modem attached
   - Wired Modem attached
   - ME Bridge connected via wired network

2. **Main Computer** (ID should be 1)
   - 3x3 Monitor connected
   - Wireless Modem attached

3. **Crafty Turtles** (any IDs)
   - Wireless Modem attached
   - Wired Modem attached
   - Must be Crafty Turtles (with crafting table)

### File Installation
Each computer needs specific files:

**Jobs Computer:**
```
/jobs_computer.lua
/config_template.lua
/recipes.lua
/priorities.lua
/lib/utils.lua
/lib/logger.lua
/lib/network.lua
```

**Main Computer:**
```
/main_computer.lua
/config_template.lua
/lib/utils.lua
/lib/logger.lua
/lib/network.lua
```

**Each Turtle:**
```
/turtle.lua
/config_template.lua
/lib/utils.lua
/lib/logger.lua
/lib/network.lua
```

## Testing Procedure

### Step 1: Start Jobs Computer (FIRST)
```lua
lua jobs_computer.lua
```

**Expected behavior:**
1. Auto-detection screen appears showing:
   - Monitor detected
   - Wireless modem detected
   - Wired modem detected
   - ME Bridge detected
2. Confirm configuration with 'Y'
3. Save configuration with 'Y'
4. System starts and shows status screen
5. "Jobs Computer ready and waiting for connections" message

**Verify:**
- No errors in startup
- ME Bridge shows as "CONNECTED"
- Logs created in `/logs/system.log`

### Step 2: Start Main Computer
```lua
lua main_computer.lua
```

**Expected behavior:**
1. Auto-detection screen appears showing:
   - Monitor detected
   - Wireless modem detected
2. Confirm configuration with 'Y'
3. Save configuration with 'Y'
4. System attempts to connect to Jobs Computer
5. Shows "Connected to Jobs Computer" with RTT time
6. Status screen appears

**Verify:**
- Successfully connects to Jobs Computer
- Shows Jobs Computer as "ONLINE"
- Can see turtle count (should be 0)

### Step 3: Start Turtles
On each turtle:
```lua
lua turtle.lua
```

**Expected behavior:**
1. Auto-detection confirms it's a Crafty Turtle
2. Shows wireless and wired modems detected
3. Confirm configuration with 'Y'
4. Enter turtle ID (1-10)
5. Save configuration with 'Y'
6. Registers with Jobs Computer
7. Shows "Successfully registered"

**Verify:**
- Turtle shows as "CONNECTED" to Jobs Computer
- Main Computer shows increased turtle count
- Jobs Computer shows turtle in list

## Testing Commands

### On Any Computer
- **Q** - Quit the program
- **D** - Dump debug information

### On Turtle
- **F** - Refuel from slot 16 (if fuel is low)

## Debugging

### Check Logs
Look in `/logs/system.log` on each computer for detailed information.

### Common Issues

**"No Jobs Computer found"**
- Ensure Jobs Computer started first
- Check wireless modems are attached
- Verify computer IDs (Jobs should be 2)

**"ME Bridge not detected"**
- Check wired modem connection
- Ensure ME Bridge has power
- Verify peripheral name

**"Failed to initialize network"**
- Check modem peripheral names
- Ensure modems are on correct sides
- Look for errors in logs

### Network Connectivity Test
On Main Computer, press 'D' to dump debug info. Check:
- Network initialized: true
- Protocol: "crafting_system"
- Message handlers registered

## Success Criteria

Phase 1 is successful when:
1. ✓ All computers start without errors
2. ✓ Peripherals are auto-detected correctly
3. ✓ Configuration files are saved
4. ✓ Main Computer connects to Jobs Computer
5. ✓ Turtles register with Jobs Computer
6. ✓ Heartbeat messages maintain connections
7. ✓ Status updates propagate between computers
8. ✓ Logs capture all major events
9. ✓ System remains stable over time

## Next Steps

After Phase 1 testing is complete:
- Phase 2: ME Bridge integration and item management
- Phase 3: Recipe system and dependency resolution
- Phase 4: Job queue and distribution
- Phase 5+: User interfaces

## Troubleshooting Tips

1. **Start Order Matters**: Always start Jobs Computer first
2. **Check IDs**: Main=1, Jobs=2 (or update config_template.lua)
3. **Modem Activation**: Right-click modems to ensure they're on
4. **Clean Start**: Delete config.lua files to re-run detection
5. **Log Level**: Set to DEBUG in config for more info

## Size Check

Run this on each computer to verify size constraints:
```lua
local size = 0
for _, file in ipairs(fs.list("/")) do
    if not fs.isDir(file) then
        size = size + fs.getSize(file)
    end
end
-- Check /lib/ directory
if fs.exists("/lib") then
    for _, file in ipairs(fs.list("/lib")) do
        size = size + fs.getSize("/lib/" .. file)
    end
end
print("Total size: " .. size .. " bytes")
```

Target sizes:
- Main Computer: <150KB
- Jobs Computer: <150KB  
- Turtle: <60KB